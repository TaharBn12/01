import 'package:flutter/foundation.dart' show Factory, kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/video_utils.dart';

/// المتصفح الداخلي:
/// - يفتح المواقع الشهيرة (يوتيوب، جوجل...).
/// - يحقن سكربت مراقبة يلتقط رابط الفيديو المباشر (mp4/m3u8...)
///   فور تشغيل أي فيديو HTML5 داخل الصفحة.
/// - يميّز روابط يوتيوب ويعرض زرًّا مباشرًّا لاستخدامها.
class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  static const String _home = 'https://www.google.com';

  WebViewController? _controller;
  final TextEditingController _urlBarCtrl = TextEditingController();

  String _currentUrl = _home;
  String? _detectedMediaUrl;
  bool _loading = true;
  int _loadingProgress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  /// سكربت مراقبة وسائط HTML5 داخل الصفحة
  static const String _detectorScript = r'''
(function () {
  if (window.__cinemaDetector) return;
  window.__cinemaDetector = true;
  var mediaPattern = /\.(mp4|m3u8|webm|ogv|ogg|mov|m4v|ts)(\?|#|$)/i;
  function report(url) {
    if (!url) return;
    if (url.indexOf('blob:') === 0) return;
    try { window.VideoDetector.postMessage(url); } catch (e) {}
  }
  function scanVideoTags() {
    var vids = document.querySelectorAll('video');
    for (var i = 0; i < vids.length; i++) {
      var v = vids[i];
      var u = v.currentSrc || v.src;
      if (u) report(u);
      var sources = v.querySelectorAll('source');
      for (var j = 0; j < sources.length; j++) report(sources[j].src);
    }
  }
  function scanResources() {
    try {
      var entries = performance.getEntriesByType('resource');
      for (var i = 0; i < entries.length; i++) {
        if (mediaPattern.test(entries[i].name)) report(entries[i].name);
      }
    } catch (e) {}
  }
  document.addEventListener('play', function (e) {
    if (e.target && e.target.tagName === 'VIDEO') {
      scanVideoTags();
      setTimeout(scanResources, 1200);
    }
  }, true);
  setInterval(function () { scanVideoTags(); scanResources(); }, 3000);
})();
''';

  @override
  void initState() {
    super.initState();
    final start =
        VideoUrlNormalizer.normalize(widget.initialUrl ?? _home);
    _currentUrl = start;
    _urlBarCtrl.text = start;

    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          // وكيل جوال لتجربة موقع خفيف غالبًا ما يعرض مشغّل HTML5
          'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
        )
        ..addJavaScriptChannel(
          'VideoDetector',
          onMessageReceived: (JavaScriptMessage message) {
            _onMediaDetected(message.message);
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              setState(() {
                _loading = true;
                _currentUrl = url;
                _urlBarCtrl.text = url;
                _detectedMediaUrl = null;
              });
            },
            onProgress: (p) {
              setState(() => _loadingProgress = p);
              if (p >= 100) setState(() => _loading = false);
            },
            onPageFinished: (url) async {
              setState(() {
                _loading = false;
                _currentUrl = url;
                _urlBarCtrl.text = url;
              });
              await _controller?.runJavaScript(_detectorScript);
              await _updateNavFlags();
              _checkYouTube(url);
            },
            onUrlChange: (change) {
              final url = change.url ?? '';
              if (url.isEmpty) return;
              setState(() => _currentUrl = url);
              _urlBarCtrl.text = url;
              _checkYouTube(url);
            },
            onWebResourceError: (error) {
              // نتجاهل أخطاء الموارد الفرعية
            },
          ),
        )
        ..loadRequest(Uri.parse(start));
    }
  }

  Future<void> _updateNavFlags() async {
    final controller = _controller;
    if (controller == null) return;
    final back = await controller.canGoBack();
    final forward = await controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = back;
        _canGoForward = forward;
      });
    }
  }

  void _checkYouTube(String url) {
    if (VideoUtils.extractYouTubeId(url) != null &&
        (_detectedMediaUrl == null)) {
      setState(() => _detectedMediaUrl = url);
    }
  }

  void _onMediaDetected(String url) {
    if (url.isEmpty) return;
    // نلتقط أول رابط وسائط صالح؛ الروابط اللاحقة تحدّث إن كانت أفضل
    final current = _detectedMediaUrl;
    final isDirect = VideoUtils.isDirectVideo(url);
    if (current == null ||
        (isDirect && !VideoUtils.isDirectVideo(current))) {
      setState(() => _detectedMediaUrl = url);
    }
  }

  Future<void> _navigate(String input) async {
    var url = input.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url =
            'https://www.google.com/search?q=${Uri.encodeQueryComponent(url)}';
      }
    }
    FocusScope.of(context).unfocus();
    setState(() => _detectedMediaUrl = null);
    await _controller?.loadRequest(Uri.parse(url));
  }

  void _useDetectedLink() {
    final url = _detectedMediaUrl;
    if (url != null && url.isNotEmpty) {
      context.pop(url);
    } else {
      context.pop(_currentUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('المتصفح')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'المتصفح الداخلي متاح داخل تطبيق الجوال.\n'
              'على الويب يمكنك لصق رابط الفيديو مباشرة في صفحة إنشاء الغرفة.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final detected = _detectedMediaUrl;
    final detectedInfo =
        detected != null ? VideoUtils.inspect(detected) : null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            IconButton(
              tooltip: 'رجوع',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed:
                  _canGoBack ? () => _controller?.goBack() : null,
            ),
            IconButton(
              tooltip: 'أمام',
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onPressed:
                  _canGoForward ? () => _controller?.goForward() : null,
            ),
            IconButton(
              tooltip: 'إعادة تحميل',
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: () => _controller?.reload(),
            ),
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _urlBarCtrl,
                  textInputAction: TextInputAction.go,
                  onSubmitted: _navigate,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ابحث أو اكتب رابطًا...',
                    hintStyle:
                        const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        size: 14),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'استخدام رابط الصفحة الحالية',
              icon: const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.primaryLight),
              onPressed: _useDetectedLink,
            ),
          ],
        ),
        bottom: _loading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          _QuickLinksBar(onTap: (site) => _navigate(site.url)),
          Expanded(
            child: _controller == null
                ? const SizedBox.shrink()
                : WebViewWidget(
                    controller: _controller!,
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => SizeTransition(
              sizeFactor: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: detected == null
                ? const SizedBox.shrink(key: ValueKey('none'))
                : _DetectedBanner(
                    key: const ValueKey('detected'),
                    url: detected,
                    isYoutube: detectedInfo?.source == VideoSource.youtube,
                    isDirect: detectedInfo?.source == VideoSource.directVideo,
                    onUse: _useDetectedLink,
                    onDismiss: () =>
                        setState(() => _detectedMediaUrl = null),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinksBar extends StatelessWidget {
  const _QuickLinksBar({required this.onTap});
  final void Function(QuickSite site) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: QuickSite.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final site = QuickSite.all[i];
          return ActionChip(
            avatar: Icon(site.icon, size: 15, color: site.color),
            label: Text(site.name),
            onPressed: () => onTap(site),
          );
        },
      ),
    );
  }
}

class _DetectedBanner extends StatelessWidget {
  const _DetectedBanner({
    super.key,
    required this.url,
    required this.isYoutube,
    required this.isDirect,
    required this.onUse,
    required this.onDismiss,
  });

  final String url;
  final bool isYoutube;
  final bool isDirect;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final Color color = isYoutube
        ? AppColors.youtube
        : isDirect
            ? AppColors.success
            : AppColors.primary;
    final IconData icon = isYoutube
        ? Icons.smart_display_rounded
        : isDirect
            ? Icons.movie_rounded
            : Icons.language_rounded;
    final title = isYoutube
        ? 'تم العثور على فيديو يوتيوب'
        : isDirect
            ? 'تم التقاط رابط فيديو مباشر 🎯'
            : 'رابط الصفحة الحالية جاهز';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onDismiss,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onUse,
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: const Text('استخدام هذا الرابط في الغرفة'),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
