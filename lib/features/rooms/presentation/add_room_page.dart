import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/video_utils.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/data/app_user.dart';
import '../data/rooms_repository.dart';

class AddRoomPage extends StatefulWidget {
  const AddRoomPage({super.key});

  @override
  State<AddRoomPage> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  VideoInfo? _video;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl.addListener(_refreshDetection);
  }

  @override
  void dispose() {
    _urlCtrl.removeListener(_refreshDetection);
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _refreshDetection() {
    final text = _urlCtrl.text.trim();
    if (text.isEmpty) {
      if (_video != null) setState(() => _video = null);
      return;
    }
    final info = VideoUtils.inspect(text);
    setState(() => _video = info);
  }

  Future<void> _openBrowser(String? url) async {
    if (kIsWeb) {
      _snack('المتصفح الداخلي متاح داخل تطبيق الجوال. '
          'على الويب الصق الرابط مباشرة.');
      return;
    }
    final result = await context.push<String>(
      '/browser${url != null ? '?url=${Uri.encodeComponent(url)}' : ''}',
    );
    if (result != null && result.isNotEmpty) {
      _urlCtrl.text = result;
      _refreshDetection();
    }
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }
    setState(() => _creating = true);
    try {
      final room = await context.read<RoomsRepository>().createRoom(
            name: _nameCtrl.text,
            rawVideoUrl: _urlCtrl.text,
            host: AppUser.fromFirebase(user),
          );
      if (mounted) context.pushReplacement('/room/${room.id}');
    } on RoomsFailure catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('تعذّر إنشاء الغرفة، تأكد من اتصالك وإعداد Firebase.');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء غرفة مشاهدة')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  step: '1',
                  title: 'بيانات الغرفة',
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _nameCtrl,
                        label: 'اسم الغرفة',
                        hint: 'مثال: سهرة فيلم الرعب 🍿',
                        prefixIcon: Icons.meeting_room_outlined,
                        validator: Validators.roomName,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  step: '2',
                  title: 'ماذا ستشاهدون؟',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _urlCtrl,
                        label: 'رابط مباشر للفيديو',
                        hint: 'https://youtube.com/watch?v=... أو رابط mp4/m3u8',
                        prefixIcon: Icons.link_rounded,
                        keyboardType: TextInputType.url,
                        validator: Validators.videoUrl,
                        suffix: IconButton(
                          tooltip: 'لصق من المتصفح',
                          icon: const Icon(Icons.travel_explore_rounded,
                              color: AppColors.primaryLight),
                          onPressed: () => _openBrowser(null),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetectionBanner(video: _video),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openBrowser(null),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryLight,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.language_rounded),
                          label: const Text(
                            'فتح المتصفح والتقاط رابط الفيديو تلقائيًّا',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'مواقع سريعة',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _QuickSites(onSelect: _openBrowser),
                const SizedBox(height: 26),
                GradientButton(
                  label: 'إنشاء الغرفة وبدء المشاهدة',
                  icon: Icons.play_circle_fill_rounded,
                  loading: _creating,
                  onPressed: _createRoom,
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'سيمكنك دعوة الأصدقاء بكود الغرفة فور إنشائها',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.step,
    required this.title,
    required this.child,
  });

  final String step;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DetectionBanner extends StatelessWidget {
  const _DetectionBanner({required this.video});
  final VideoInfo? video;

  @override
  Widget build(BuildContext context) {
    if (video == null || video!.source == VideoSource.unknown) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.help_outline_rounded,
                size: 18, color: AppColors.textMuted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'الصق رابطًا ليتم تحديد نوعه تلقائيًّا',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }
    final Color color = switch (video!.source) {
      VideoSource.youtube => AppColors.youtube,
      VideoSource.directVideo => AppColors.success,
      VideoSource.webPage => AppColors.warning,
      VideoSource.unknown => AppColors.textMuted,
    };
    final IconData icon = switch (video!.source) {
      VideoSource.youtube => Icons.smart_display_rounded,
      VideoSource.directVideo => Icons.movie_filter_rounded,
      VideoSource.webPage => Icons.language_rounded,
      VideoSource.unknown => Icons.help_outline_rounded,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم اكتشاف: ${video!.source.label}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  video!.source.playable
                      ? 'جاهز للتشغيل داخل الغرفة'
                      : 'سيُعرض داخل متصفح الغرفة',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 20),
        ],
      ),
    );
  }
}

class _QuickSites extends StatelessWidget {
  const _QuickSites({required this.onSelect});
  final void Function(String url) onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: QuickSite.all
          .map(
            (site) => SizedBox(
              width: 108,
              child: Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelect(site.url),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: site.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(site.icon, color: site.color, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          site.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
