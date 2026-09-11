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
import '../../../core/widgets/gradient_button.dart' show AppLogo;
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
        final matchTitle = (room.videoTitle ?? '').toLowerCase().contains(q);
        final matchCode = room.id.toLowerCase().contains(q);
        if (!matchName && !matchHost && !matchTitle && !matchCode) {
          return false;
        }
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
        title: Row(
          children: [
            Icon(Icons.login_rounded, color: dialogCtx.mono),
            const SizedBox(width: 8),
            const Text('الدخول بكود الغرفة'),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
          maxLength: 6,
          decoration: const InputDecoration(hintText: 'ABC-123', counterText: ''),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'غرفة جديدة',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<RoomModel>>(
          stream: _rooms,
          builder: (context, snapshot) {
            final all = snapshot.data ?? const [];
            final rooms = _apply(all);
            final liveCount = all.where((r) => r.isLive).length;

            return RefreshIndicator(
              color: context.mono,
              backgroundColor: context.cardColor,
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 500));
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
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: _SectionTitle(
                        liveCount: liveCount,
                        total: all.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SearchField(
                        value: _query,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        children: [
                          _FilterPill(
                            label: 'الكل',
                            selected: _filter == _Filter.all,
                            onTap: () =>
                                setState(() => _filter = _Filter.all),
                          ),
                          _FilterPill(
                            label: 'مباشر',
                            selected: _filter == _Filter.live,
                            onTap: () =>
                                setState(() => _filter = _Filter.live),
                          ),
                          _FilterPill(
                            label: 'يوتيوب',
                            selected: _filter == _Filter.youtube,
                            onTap: () =>
                                setState(() => _filter = _Filter.youtube),
                          ),
                          _FilterPill(
                            label: 'مباشر (رابط)',
                            selected: _filter == _Filter.direct,
                            onTap: () =>
                                setState(() => _filter = _Filter.direct),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                  else if (rooms.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _emptyState(context),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 8, bottom: 110),
                      sliver: SliverList.builder(
                        itemCount: rooms.length,
                        itemBuilder: (context, i) => RoomCard(
                          room: rooms[i],
                          onTap:
                              _joining ? () {} : () => _openRoom(rooms[i]),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final searching = _query.isNotEmpty || _filter != _Filter.all;
    return EmptyState(
      icon: searching ? Icons.search_off_rounded : Icons.live_tv_rounded,
      title: searching ? 'لا نتائج مطابقة' : 'لا توجد غرف بعد',
      message: searching
          ? 'جرّب كلمة بحث مختلفة أو تصفية أخرى.'
          : 'كن أول من يبدأ جلسة مشاهدة جماعية.\n'
              'أنشئ غرفة، التقط رابط الفيديو، وادعُ أصدقاءك بالكود.',
      action: searching
          ? null
          : SizedBox(
              width: 220,
              child: FilledButton.icon(
                onPressed: () => context.push('/room/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إنشاء أول غرفة'),
              ),
            ),
    );
  }
}

// ===================================================================

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
      child: Row(
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
                  Formatters.greeting(),
                  style: TextStyle(
                    color: context.text3,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: context.text1,
                  ),
                ),
              ],
            ),
          ),
          _CircleButton(
            icon: Icons.key_rounded,
            tooltip: 'الدخول بكود غرفة',
            onTap: onJoinCode,
          ),
          _CircleButton(
            icon: Icons.settings_outlined,
            tooltip: 'الإعدادات',
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: context.line),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.liveCount, required this.total});

  final int liveCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: context.text1,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(width: 10),
        const AppLogo(size: 30, radius: 9),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: context.variant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: liveCount > 0 ? context.mono : context.text3,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$liveCount مباشر',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: context.text2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(fontSize: 13.5, color: context.text1),
        decoration: InputDecoration(
          hintText: 'ابحث عن غرفة أو عنوان فيديو أو مضيف أو كود...',
          hintStyle: TextStyle(fontSize: 12.5, color: context.text3),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: context.text3),
          filled: true,
          fillColor: context.variant,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: value.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => onChanged(''),
                ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? context.mono : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? context.mono : context.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: selected ? context.onMono : context.text2,
            ),
          ),
        ),
      ),
    );
  }
}
