import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/media_capture.dart';
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
  String? _capturedTitle;
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
      setState(() {
        _video = info;
        // اللصق اليدوي يُلغي العنوان الملتقَط من المتصفح
        if (_capturedTitle != null) _capturedTitle = null;
      });
    }
  }

  Future<void> _openBrowser(String? url) async {
    if (kIsWeb) {
      _snack('المتصفح الداخلي متاح على تطبيق الجوال، الصق الرابط مباشرة.');
      return;
    }
    final result = await context.push<MediaCapture>(
      '/browser${url != null ? '?url=${Uri.encodeComponent(url)}' : ''}',
    );
    if (result != null && result.url.isNotEmpty) {
      _urlCtrl.text = result.url;
      setState(() => _capturedTitle = MediaCapture.normalizeTitle(result.title));
      _refresh();
      if ((_nameCtrl.text.trim().isEmpty) &&
          _capturedTitle != null &&
          VideoUtils.inspect(result.url).source != VideoSource.webPage) {
        _nameCtrl.text = _capturedTitle!;
      }
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
            videoTitle: _capturedTitle,
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
                      const SizedBox(height: 28),
                      _Label('اسم الغرفة'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _nameCtrl,
                        hint: 'مثال: سهرة فيلم الجمعة',
                        prefixIcon: Icons.movie_filter_rounded,
                        validator: Validators.roomName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 24),
                      _Label('رابط المشاهدة'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _urlCtrl,
                        hint: 'يوتيوب أو رابط مباشر (mp4 / m3u8)',
                        prefixIcon: Icons.link_rounded,
                        keyboardType: TextInputType.url,
                        validator: Validators.videoUrl,
                        suffix: IconButton(
                          tooltip: 'التقاط من المتصفح',
                          icon: Icon(Icons.travel_explore_rounded,
                              color: context.text1),
                          onPressed: () => _openBrowser(null),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DetectionPill(
                        video: _video,
                        capturedTitle: _capturedTitle,
                      ),
                      const SizedBox(height: 26),
                      _Label('أو تصفّح موقعًا والتقط الفيديو أثناء تشغيله'),
                      const SizedBox(height: 10),
                      _QuickSitesRow(onSelect: _openBrowser),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => _openBrowser(null),
                          icon: const Icon(Icons.language_rounded, size: 19),
                          label: const Text('فتح المتصفح الداخلي'),
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
              decoration: BoxDecoration(
                color: context.cardColor,
                border: Border(top: BorderSide(color: context.line)),
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
                  Text(
                    'تحصل على كود دعوة قصير تشاركه مع أصدقائك',
                    style: TextStyle(color: context.text3, fontSize: 12),
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
            color: context.mono,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.add_rounded, color: context.onMono),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سهرة جديدة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: context.text1,
                ),
              ),
              Text(
                'أدخل التفاصيل وادعُ أصدقاءك للمشاهدة معًا',
                style: TextStyle(color: context.text3, fontSize: 12.5),
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
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: context.text2,
      ),
    );
  }
}

class _DetectionPill extends StatelessWidget {
  const _DetectionPill({required this.video, this.capturedTitle});

  final VideoInfo? video;
  final String? capturedTitle;

  @override
  Widget build(BuildContext context) {
    final source = video?.source;
    if (video == null || source == null || source == VideoSource.unknown) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.variant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.help_outline_rounded, size: 17, color: context.text3),
            const SizedBox(width: 8),
            Text(
              'الصق رابطًا ليُحدَّد نوعه تلقائيًّا',
              style: TextStyle(color: context.text3, fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    final icon = switch (source) {
      VideoSource.youtube => Icons.smart_display_rounded,
      VideoSource.directVideo => Icons.movie_filter_rounded,
      VideoSource.webPage => Icons.language_rounded,
      VideoSource.unknown => Icons.help_outline_rounded,
    };
    final ready = source.playable;
    final color = ready ? context.mono : context.text2;
    final bg = ready ? context.mono.withValues(alpha: 0.08) : context.variant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ready
              ? context.mono.withValues(alpha: 0.35)
              : context.line,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ready
                      ? '${source.label} — جاهز للتشغيل داخل الغرفة'
                      : '${source.label} — يُعرض داخل متصفح الغرفة',
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (capturedTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'العنوان الملتقَط: $capturedTitle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: context.text3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSitesRow extends StatelessWidget {
  const _QuickSitesRow({required this.onSelect});
  final void Function(String url) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: QuickSite.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final site = QuickSite.all[i];
          return InkWell(
            borderRadius: BorderRadius.circular(21),
            onTap: () => onSelect(site.url),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: context.variant,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: context.line),
              ),
              child: Row(
                children: [
                  Icon(site.icon, size: 16, color: context.text2),
                  const SizedBox(width: 6),
                  Text(
                    site.name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.text2,
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
