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
    _urlCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _urlCtrl.removeListener(_refresh);
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    final text = _urlCtrl.text.trim();
    final info = text.isEmpty ? null : VideoUtils.inspect(text);
    if (info?.source != _video?.source || info?.url != _video?.url) {
      setState(() => _video = info);
    }
  }

  Future<void> _openBrowser(String? url) async {
    if (kIsWeb) {
      _snack('المتصفح الداخلي متاح على تطبيق الجوال، الصق الرابط مباشرة.');
      return;
    }
    final result = await context.push<String>(
      '/browser${url != null ? '?url=${Uri.encodeComponent(url)}' : ''}',
    );
    if (result != null && result.isNotEmpty) {
      _urlCtrl.text = result;
      _refresh();
    }
  }

  Future<void> _create() async {
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
    } catch (_) {
      _snack('تعذّر إنشاء الغرفة، تحقق من اتصالك وبيانات Firebase.');
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
      appBar: AppBar(title: const Text('إنشاء غرفة')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Intro(),
                      const SizedBox(height: 24),
                      const _Label('اسم الغرفة'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _nameCtrl,
                        hint: 'مثال: سهرة فيلم الجمعة 🍿',
                        prefixIcon: Icons.movie_filter_rounded,
                        validator: Validators.roomName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 22),
                      const _Label('رابط المشاهدة'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _urlCtrl,
                        hint: 'رابط يوتيوب أو رابط فيديو مباشر (mp4 / m3u8)',
                        prefixIcon: Icons.link_rounded,
                        keyboardType: TextInputType.url,
                        validator: Validators.videoUrl,
                        suffix: IconButton(
                          tooltip: 'التقاط من المتصفح',
                          icon: const Icon(Icons.travel_explore_rounded,
                              color: AppColors.primaryLight),
                          onPressed: () => _openBrowser(null),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DetectionPill(video: _video),
                      const SizedBox(height: 22),
                      const _Label('تصفّح موقعًا لالتقاط الفيديو'),
                      const SizedBox(height: 10),
                      _QuickSitesRow(onSelect: _openBrowser),
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => _openBrowser(null),
                          icon: const Icon(Icons.language_rounded, size: 19),
                          label: const Text('فتح المتصفح الداخلي'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.of(context).viewPadding.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GradientButton(
                    label: 'إنشاء الغرفة وبدء المشاهدة',
                    icon: Icons.play_circle_fill_rounded,
                    loading: _creating,
                    onPressed: _create,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تحصل على كود دعوة قصير تشاركه مع أصدقائك',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سهرة جديدة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'أدخل تفاصيل الغرفة وادعُ أصدقاءك للمشاهدة معًا',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _DetectionPill extends StatelessWidget {
  const _DetectionPill({required this.video});
  final VideoInfo? video;

  @override
  Widget build(BuildContext context) {
    final source = video?.source;
    if (video == null || source == null || source == VideoSource.unknown) {
      return _hint(
        Icons.help_outline_rounded,
        'الصق رابطًا ليتم تحديد نوعه تلقائيًّا',
        AppColors.textMuted,
      );
    }
    final (color, icon) = switch (source) {
      VideoSource.youtube => (AppColors.youtube, Icons.smart_display_rounded),
      VideoSource.directVideo =>
        (AppColors.success, Icons.movie_filter_rounded),
      VideoSource.webPage => (AppColors.warning, Icons.language_rounded),
      VideoSource.unknown => (AppColors.textMuted, Icons.help_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              source.playable
                  ? '${source.label} — جاهز للتشغيل داخل الغرفة'
                  : '${source.label} — سيُعرض داخل متصفح الغرفة',
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hint(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12.5)),
          ],
        ),
      );
}

class _QuickSitesRow extends StatelessWidget {
  const _QuickSitesRow({required this.onSelect});
  final void Function(String url) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: QuickSite.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final site = QuickSite.all[i];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelect(site.url),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(site.icon, size: 17, color: site.color),
                  const SizedBox(width: 6),
                  Text(
                    site.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
