import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/video_utils.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/data/app_user.dart';
import '../data/room_model.dart';
import '../data/rooms_repository.dart';
import 'widgets/chat_panel.dart';
import 'widgets/participants_view.dart';
import 'widgets/players/direct_player_box.dart';
import 'widgets/players/web_player_box.dart';
import 'widgets/players/youtube_player_box.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key, required this.roomId});

  final String roomId;

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  late final RoomsRepository _repo;
  late final String _myUid;
  late final Stream<RoomModel> _roomStream;
  late final Stream<PlaybackState> _playbackStream;

  bool _joined = false;
  String? _joinError;

  @override
  void initState() {
    super.initState();
    _repo = context.read<RoomsRepository>();
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    _roomStream = _repo.watchRoom(widget.roomId).asBroadcastStream();
    _playbackStream = _roomStream
        .map((room) => room.playback)
        .where((state) => state != null)
        .cast<PlaybackState>()
        .asBroadcastStream();

    _join();
  }

  Future<void> _join() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }
    try {
      await _repo.joinRoom(widget.roomId, AppUser.fromFirebase(user));
      if (mounted) setState(() => _joined = true);
    } catch (e) {
      if (mounted) setState(() => _joinError = 'تعذّر دخول الغرفة');
    }
  }

  Future<void> _leave() async {
    if (_myUid.isNotEmpty) {
      unawaited(_repo.leaveRoom(widget.roomId, _myUid));
    }
  }

  void _onLocalPlayback(bool isPlaying, double positionSeconds) {
    // يرفع المضيف حالة التشغيل إلى Firestore لتتم مزامنة الضيوف
    unawaited(
      _repo.updatePlayback(
        roomId: widget.roomId,
        hostUid: _myUid,
        isPlaying: isPlaying,
        positionSeconds: positionSeconds,
      ),
    );
  }

  Future<void> _share(RoomModel room) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'دعوة مشاهدة جماعية',
        text: '🎬 أدعوك لمشاهدة «${room.name}» معي في سينما جماعية!\n'
            'كود الغرفة: ${room.id}\n'
            'أو افتح الرابط: https://watchtogether.app/room/${room.id}',
      ),
    );
  }

  Future<void> _changeVideoDialog(RoomModel room) async {
    final ctrl = TextEditingController(text: room.videoUrl);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('تغيير الفيديو'),
        content: Form(
          key: formKey,
          child: AppTextField(
            controller: ctrl,
            label: 'رابط الفيديو الجديد',
            hint: 'يوتيوب أو رابط مباشر mp4/m3u8',
            prefixIcon: Icons.movie_creation_outlined,
            keyboardType: TextInputType.url,
            validator: Validators.videoUrl,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogCtx, ctrl.text);
              }
            },
            child: const Text('تغيير ومزامنة الجميع'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await _repo.changeVideo(widget.roomId, result);
      _snack('تم تحديث الفيديو ومزامنته مع جميع الحضور ✅');
    } catch (_) {
      _snack('تعذّر تغيير الفيديو');
    }
  }

  Future<void> _closeRoomDialog(RoomModel room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('إنهاء غرفة المشاهدة؟'),
        content: const Text(
          'سيتم إنهاء البث لجميع الحضور. يمكن دائمًا إنشاء غرفة جديدة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.live),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('إنهاء البث'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.closeRoom(widget.roomId);
    if (mounted) context.pop();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------- المشغّلات

  Widget _buildPlayer(RoomModel room) {
    switch (room.source) {
      case VideoSource.youtube:
        if (room.youtubeId == null) return _scaffold(room, _webPlayer(room));
        return _scaffold(
          room,
          YoutubePlayerBox(
            key: ValueKey('yt-${room.videoUrl}'),
            videoId: room.youtubeId!,
            isHost: room.hostUid == _myUid,
            myUid: _myUid,
            playbackStream: _playbackStream,
            onLocalPlayback: _onLocalPlayback,
            initialPlayback: room.playback,
          ),
        );
      case VideoSource.directVideo:
        return _scaffold(
          room,
          DirectPlayerBox(
            key: ValueKey('dv-${room.videoUrl}'),
            url: room.videoUrl,
            isHost: room.hostUid == _myUid,
            myUid: _myUid,
            autoplay: true,
            playbackStream: _playbackStream,
            onLocalPlayback: _onLocalPlayback,
            initialPlayback: room.playback,
          ),
        );
      case VideoSource.webPage:
      case VideoSource.unknown:
        return _scaffold(room, _webPlayer(room));
    }
  }

  Widget _webPlayer(RoomModel room) {
    if (kIsWeb) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'رابط الغرفة: ${room.videoUrl}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return WebPlayerBox(key: ValueKey('web-${room.videoUrl}'), url: room.videoUrl);
  }

  // --------------------------------------------------------------- الواجهة

  Widget _scaffold(RoomModel room, Widget player) {
    final isHost = room.hostUid == _myUid;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (room.isLive)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.live,
                    shape: BoxShape.circle,
                  ),
                ),
              Flexible(
                child: Text(
                  room.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'دعوة الأصدقاء',
              onPressed: () => _share(room),
              icon: const Icon(Icons.ios_share_rounded),
            ),
            if (isHost)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'change') _changeVideoDialog(room);
                  if (value == 'close') _closeRoomDialog(room);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'change',
                    child: Row(
                      children: [
                        Icon(Icons.sync_alt_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('تغيير الفيديو'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'close',
                    child: Row(
                      children: [
                        Icon(Icons.power_settings_new_rounded,
                            size: 18, color: AppColors.live),
                        SizedBox(width: 10),
                        Text('إنهاء البث',
                            style: TextStyle(color: AppColors.live)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'الدردشة', icon: Icon(Icons.chat_bubble_outline_rounded, size: 18)),
              Tab(text: 'الحضور', icon: Icon(Icons.groups_2_outlined, size: 18)),
            ],
          ),
        ),
        body: PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) _leave();
          },
          child: Column(
            children: [
              if (!room.isLive) _endedBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: player,
              ),
              _infoBar(room, isHost),
              Expanded(
                child: TabBarView(
                  children: [
                    ChatPanel(room: room),
                    ParticipantsView(room: room),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _endedBanner() => Container(
        width: double.infinity,
        color: AppColors.live.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_rounded, size: 16, color: AppColors.live),
            SizedBox(width: 8),
            Text(
              'انتهى بث هذه الغرفة',
              style:
                  TextStyle(color: AppColors.live, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  Widget _infoBar(RoomModel room, bool isHost) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          UserAvatar(
            name: room.hostName,
            photoUrl: room.hostPhotoUrl,
            radius: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        room.hostName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.workspace_premium_rounded,
                        size: 14, color: AppColors.warning),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      isHost ? Icons.verified_rounded : Icons.sync_rounded,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHost ? 'أنت تتحكم بالمشاهدة للجميع' : 'تتم المزامنة مع المضيف',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _CodeChip(code: room.id, onTap: () => _share(room)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RoomModel>(
      stream: _roomStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(body: AppLoader(label: 'جارٍ فتح الغرفة...'));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(
              icon: Icons.meeting_room_outlined,
              title: 'الغرفة غير موجودة',
              message: 'قد يكون كود الغرفة خاطئًا أو تم إنهاؤها.',
              action: SizedBox(
                width: 200,
                child: GradientButton(
                  label: 'العودة للرئيسية',
                  icon: Icons.home_rounded,
                  onPressed: () => context.go('/'),
                ),
              ),
            ),
          );
        }

        if (_joinError != null && !_joined) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              error: _joinError!,
              onRetry: () {
                setState(() => _joinError = null);
                _join();
              },
            ),
          );
        }

        return _buildPlayer(snapshot.data!);
      },
    );
  }

  @override
  void dispose() {
    _leave();
    super.dispose();
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code, required this.onTap});

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: AppColors.primary.withValues(alpha: 0.14),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
      avatar: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primaryLight),
      label: Text(
        code,
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}
