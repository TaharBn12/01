import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/video_utils.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/user_avatar.dart';
import '../data/room_model.dart';
import '../data/rooms_repository.dart';
import 'widgets/room_card.dart';

enum _Filter { all, live, youtube, direct }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Stream<List<RoomModel>> _rooms =
      context.read<RoomsRepository>().watchRooms();

  _Filter _filter = _Filter.all;
  String _query = '';
  bool _joining = false;

  List<RoomModel> _apply(List<RoomModel> rooms) {
    return rooms.where((room) {
      if (_filter == _Filter.live && !room.isLive) return false;
      if (_filter == _Filter.youtube &&
          room.source != VideoSource.youtube) {
        return false;
      }
      if (_filter == _Filter.direct &&
          room.source != VideoSource.directVideo) {
        return false;
      }
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matchName = room.name.toLowerCase().contains(q);
        final matchHost = room.hostName.toLowerCase().contains(q);
        final matchCode = room.id.toLowerCase() == q ||
            room.id.toLowerCase().contains(q);
        if (!matchName && !matchHost && !matchCode) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openRoom(RoomModel room) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }
    setState(() => _joining = true);
    try {
      await context
          .read<RoomsRepository>()
          .joinRoom(room.id, AppUser.fromFirebase(user));
      if (mounted) context.push('/room/${room.id}');
    } on RoomsFailure catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('تعذّر دخول الغرفة، حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _joinByCodeDialog() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.login_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('الدخول بكود الغرفة'),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'ABC-123',
            counterText: '',
          ),
          onSubmitted: (v) => Navigator.pop(dialogCtx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text),
            child: const Text('دخول'),
          ),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    if (!mounted) return;
    final repo = context.read<RoomsRepository>();
    final room = await repo.findByCode(code);
    if (!mounted) return;
    if (room == null) {
      _snack('لا توجد غرفة بهذا الكود');
      return;
    }
    await _openRoom(room);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'صديقنا';

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/room/new'),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'إنشاء غرفة',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: StreamBuilder<List<RoomModel>>(
          stream: _rooms,
          builder: (context, snapshot) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      name: displayName,
                      photoUrl: user?.photoURL,
                      onJoinCode: _joinByCodeDialog,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText:
                              'ابحث عن غرفة بالاسم أو المضيف أو الكود...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => setState(() {
                                    _query = '';
                                  }),
                                ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _chip('الكل', _Filter.all),
                          _chip('نشط الآن', _Filter.live),
                          _chip('يوتيوب', _Filter.youtube),
                          _chip('روابط مباشرة', _Filter.direct),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppLoader(label: 'جارٍ تحميل الغرف...'),
                    )
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorView(
                        error: snapshot.error!,
                        onRetry: () => setState(() {}),
                      ),
                    )
                  else
                    _roomsSliver(snapshot.data ?? []),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _roomsSliver(List<RoomModel> all) {
    final rooms = _apply(all);
    if (rooms.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: _query.isNotEmpty
              ? Icons.search_off_rounded
              : Icons.live_tv_rounded,
          title: _query.isNotEmpty ? 'لا نتائج مطابقة' : 'لا توجد غرف بعد',
          message: _query.isNotEmpty
              ? 'جرّب كلمة بحث مختلفة أو تصفية أخرى.'
              : 'كن أول من يبدأ جلسة مشاهدة جماعية!\n'
                  'أنشئ غرفة، أضف رابط الفيديو، وادعُ أصدقاءك بالكود.',
          action: _query.isNotEmpty
              ? null
              : SizedBox(
                  width: 220,
                  child: GradientButton(
                    label: 'إنشاء أول غرفة',
                    icon: Icons.add_rounded,
                    onPressed: () => context.push('/room/new'),
                  ),
                ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / 340).floor().clamp(1, 4).toInt();
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.92,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => RoomCard(
                room: rooms[i],
                onTap: _joining ? () {} : () => _openRoom(rooms[i]),
              ),
              childCount: rooms.length,
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, _Filter value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.primary.withValues(alpha: 0.25),
        labelStyle: TextStyle(
          color: selected ? AppColors.primaryLight : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.photoUrl,
    required this.onJoinCode,
  });

  final String name;
  final String? photoUrl;
  final VoidCallback onJoinCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/settings'),
                child: UserAvatar(name: name, photoUrl: photoUrl, radius: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${Formatters.greeting()} 👋',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'الدخول بكود غرفة',
                onPressed: onJoinCode,
                icon: const Icon(Icons.key_rounded),
              ),
              IconButton(
                tooltip: 'الإعدادات',
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const AppLogo(size: 46, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      AppConstants.appTagline,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
