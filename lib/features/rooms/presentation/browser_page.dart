import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show Factory, kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/media_capture.dart';
import '../../../core/utils/video_utils.dart';
import '../../../core/widgets/gradient_button.dart';

/// المتصفح الداخلي:
/// - يحظر الإعلانات والنوافذ المنبثقة ومتتبّعات الإشهار على مستوى الصفحة.
/// - يلتقط رابط الفيديو (mp4/m3u8/youtube) فور تشغيله مع عنوان الصفحة.
/// - يعرض زرًّا عائمًا عند الالتقاط؛ بالضغط عليه تظهر بطاقة الفيديو وعنوانه.
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
  String? _pageTitle;
  MediaCapture? _capture;
  bool _loading = true;
  int _loadingProgress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  // ============================ حظر الإعلانات ============================

  static const String _adBlockScript = r'''
(function () {
  var AD_DOMAINS = new RegExp(
    'doubleclick|googlesyndication|googleadservices|googletagservices|'
    + 'google-analytics|googletag|adsystem|adservice|adnxs|adtech|'
    + 'adsterra|popads|popcash|propellerads|propeller|adsafeprotected|'
    + 'moatads|scorecardresearch|quantserve|rubiconproject|casalemedia|'
    + 'criteo|outbrain|taboola|zedo|smartadserver|yieldmo|pubmatic|'
    + 'openx\\.net|bidswitch|teads|mgid|adroll|clicksor|exoclick|'
    + 'juicyads|hilltopads|adskeeper|trafficstars|onclk|clickadu|adcash|'
    + 'adcolony|applovin|unityads|revcontent|adnow|aniview|adsupply|'
    + 'popunder|adsystem|yieldlab|adform|advertising\\.com|/ads/|_ads_|'
    + 'ads-banner|adserver|google_ad|adsbygoogle',
    'i'
  );
  function isAd(u) { return typeof u === 'string' && AD_DOMAINS.test(u); }

  // 1) إخفاء عناصر الإعلانات الشائعة بالـ CSS (تُحقن مرة واحدة)
  if (!window.__cinemaAdCss) {
  window.__cinemaAdCss = true;
  var css = ''
    + '[id^="ad-"],[id$="-ad"],[id^="ads-"],[id^="google_ads"],'
    + '[id="ad"],[id="ads"],[class="ad"],[class="ads"],'
    + '[class*="ad-banner"],[class*="ad_container"],[class*="ad-container"],'
    + '[class*="ad-wrapper"],[class*="adsbox"],[class*="ads-box"],'
    + '[class*="banner-ad"],[class*="BannerAd"],[class*="advertisement"],'
    + 'ins.adsbygoogle,iframe[src*="doubleclick"],iframe[src*="googlesyndication"],'
    + 'iframe[src*="adsterra"],iframe[src*="popads"],iframe[src*="propeller"],'
    + 'iframe[src*="adnxs"],iframe[src*="adsystem"],iframe[src*="adservice"],'
    + 'iframe[src*="clickadu"],iframe[src*="adcash"],[id*="google_ads"],'
    + '[class*="GoogleActiveView"],[class*="sponsored-ad"]{display:none!important;visibility:hidden!important;}';
  try {
    var st = document.createElement('style');
    st.setAttribute('type', 'text/css');
    st.textContent = css;
    (document.head || document.documentElement).appendChild(st);
  } catch (e) {}
  }

  // 2) منع النوافذ المنبثقة (popups / popunders)
  if (!window.__cinemaPopups) {
  window.__cinemaPopups = true;
  try {
    window.open = function () { return null; };
    window.__defineSetter__ && window.__defineSetter__('opener', function () {});
  } catch (e) {}
  }

  // 3) اعتراض طلبات الإعلانات في XHR / fetch
  if (!window.__cinemaNet) {
  window.__cinemaNet = true;
  try {
    var origOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (method, url) {
      if (isAd(String(url))) { this.abort(); return; }
      return origOpen.apply(this, arguments);
    };
  } catch (e) {}
  try {
    if (window.fetch) {
      var origFetch = window.fetch;
      window.fetch = function (input, init) {
        var u = (typeof input === 'string') ? input
          : (input && input.url) || '';
        if (isAd(u)) return Promise.reject(new Error('blocked'));
        return origFetch.apply(this, arguments);
      };
    }
  } catch (e) {}
  }

  // 4) اعتراض مصادر iframe / script / embed الإعلانية (مرة واحدة)
  if (!window.__cinemaSrc) {
  window.__cinemaSrc = true;
  ['HTMLIFrameElement', 'HTMLScriptElement', 'HTMLEmbedElement', 'HTMLObjectElement']
    .forEach(function (name) {
      var ctor = window[name];
      if (!ctor || !ctor.prototype) return;
      var desc = Object.getOwnPropertyDescriptor(ctor.prototype, 'src');
      if (!desc || !desc.set) return;
      try {
        Object.defineProperty(ctor.prototype, 'src', {
          configurable: true,
          enumerable: desc.enumerable,
          get: function () { return desc.get ? desc.get.call(this) : ''; },
          set: function (v) {
            if (!isAd(String(v))) desc.set.call(this, v);
          }
        });
      } catch (e) {}
    });
  }

  // 5) إزالة عناصر الإعلانات التي تُحقن ديناميكيًّا
  function sweep(root) {
    try {
      var nodes = (root || document).querySelectorAll &&
        (root || document).querySelectorAll(
          'iframe,ins,div,section,[id],[class]'
        );
      if (!nodes) return;
      for (var i = 0; i < nodes.length; i++) {
        var n = nodes[i];
        var src = n.src || n.getAttribute && n.getAttribute('src') || '';
        var cls = ((n.id || '') + ' ' + (n.className || '')).toString();
        if (isAd(src) || /(^|[-\s_])(ad|ads|advert|sponsored)([-\s_]|$)/i.test(cls)) {
          if (n.remove) n.remove();
          else if (n.parentNode) n.parentNode.removeChild(n);
        }
      }
    } catch (e) {}
  }
  if (document.documentElement && !window.__cinemaMO) {
    try {
      window.__cinemaMO = true;
      var mo = new MutationObserver(function (muts) {
        for (var m = 0; m < muts.length; m++) {
          var added = muts[m].addedNodes;
          for (var i = 0; i < added.length; i++) {
            if (added[i].nodeType === 1) sweep(added[i]);
          }
        }
      });
      mo.observe(document.documentElement,
        { childList: true, subtree: true });
    } catch (e) { window.__cinemaMO = false; }
  }
  if (!window.__cinemaSweep) {
    window.__cinemaSweep = true;
    setInterval(sweep, 2500);
  }
})();
''';

  // ========================= التقاط الفيديو =========================

  static const String _detectorScript = r'''
(function () {
  if (window.__cinemaDetector) return;
  window.__cinemaDetector = true;

  var AD_DOMAINS = /doubleclick|googlesyndication|googleadservices|adnxs|adsterra|popads|propeller|adsystem|adservice|clickadu|adcash|adskeeper|moatads|smartadserver|pubmatic|rubiconproject|casalemedia|yieldmo|aniview/i;
  var mediaPattern = /\.(mp4|m3u8|webm|ogv|ogg|mov|m4v|ts|mpd)(\?|#|$)/i;

  function pageTitle() {
    var og = document.querySelector('meta[property="og:title"]');
    if (og && og.content) return og.content;
    var tw = document.querySelector('meta[name="twitter:title"]');
    if (tw && tw.content) return tw.content;
    return document.title || '';
  }
  function report(url) {
    if (!url) return;
    if (url.indexOf('blob:') === 0) return;
    if (AD_DOMAINS.test(url)) return;
    var payload = JSON.stringify({ url: url, title: pageTitle() });
    try { window.VideoDetector.postMessage(payload); } catch (e) {}
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
      setTimeout(function () { scanVideoTags(); scanResources(); }, 1200);
    }
  }, true);
  // التقاط أوّلي شامل عند الجاهزية
  setTimeout(function () { scanVideoTags(); scanResources(); }, 800);
  setInterval(function () { scanVideoTags(); scanResources(); }, 3500);
})();
''';

  @override
  void initState() {
    super.initState();
    final start = VideoUrlNormalizer.normalize(widget.initialUrl ?? _home);
    _currentUrl = start;
    _urlBarCtrl.text = start;

    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
        )
        ..addJavaScriptChannel(
          'VideoDetector',
          onMessageReceived: (JavaScriptMessage message) =>
              _onMediaMessage(message.message),
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) async {
              setState(() {
                _loading = true;
                _currentUrl = url;
                _urlBarCtrl.text = url;
                _capture = null;
                _pageTitle = null;
              });
              await _controller?.runJavaScript(_adBlockScript);
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
              await _controller?.runJavaScript(_adBlockScript);
              await _controller?.runJavaScript(_detectorScript);
              await _readPageTitle();
              await _updateNavFlags();
              _checkYouTube(url);
              // حقنة إضافية بعد تحميل المحتوى الديناميكي
              Future.delayed(const Duration(seconds: 2), () async {
                await _controller?.runJavaScript(_adBlockScript);
                await _controller?.runJavaScript(_detectorScript);
              });
            },
            onUrlChange: (change) {
              final url = change.url ?? '';
              if (url.isEmpty) return;
              setState(() => _currentUrl = url);
              _urlBarCtrl.text = url;
              _checkYouTube(url);
            },
            onWebResourceError: (_) {},
          ),
        )
        ..loadRequest(Uri.parse(start));
    }
  }

  Future<void> _readPageTitle() async {
    try {
      final raw =
          await _controller?.runJavaScriptReturningResult('document.title');
      var title = raw?.toString();
      // بعض المنصات تُرجع النص بين علامتي اقتباس
      if (title != null &&
          title.length >= 2 &&
          title.startsWith('"') &&
          title.endsWith('"')) {
        try {
          title = jsonDecode(title) as String?;
        } catch (_) {}
      }
      if (title != null && title.isNotEmpty && title != 'null') {
        final clean = MediaCapture.normalizeTitle(title);
        if (clean != null && mounted) setState(() => _pageTitle = clean);
      }
    } catch (_) {}
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
    if (VideoUtils.extractYouTubeId(url) != null) {
      _acceptCapture(MediaCapture(url: url, title: _pageTitle), priority: 2);
    }
  }

  void _onMediaMessage(String raw) {
    if (raw.isEmpty) return;
    String url = raw;
    String? title;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      url = data['url']?.toString() ?? raw;
      title = data['title']?.toString();
    } catch (_) {
      // رسالة بصيغة رابط مباشر قديمة
    }
    final info = VideoUtils.inspect(url);
    final priority = info.source == VideoSource.directVideo ? 3 : 1;
    _acceptCapture(
      MediaCapture(
        url: url,
        title: MediaCapture.normalizeTitle(title) ?? _pageTitle,
      ),
      priority: priority,
    );
  }

  void _acceptCapture(MediaCapture capture, {required int priority}) {
    final current = _capture;
    final currentPriority = current == null
        ? 0
        : VideoUtils.inspect(current.url).source == VideoSource.directVideo
            ? 3
            : VideoUtils.isYouTube(current.url)
                ? 2
                : 1;
    if (current == null || priority > currentPriority) {
      setState(() => _capture = capture);
    } else if (current.title == null && capture.title != null) {
      setState(
        () => _capture = MediaCapture(url: current.url, title: capture.title),
      );
    }
  }

  Future<void> _navigate(String input) async {
    var url = input.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeQueryComponent(url)}';
      }
    }
    FocusScope.of(context).unfocus();
    setState(() => _capture = null);
    await _controller?.loadRequest(Uri.parse(url));
  }

  /// زر شريط الأدوات: استخدام رابط الصفحة الحالية حتى دون التقاط فيديو
  void _useCurrentPage() {
    context.pop(
      MediaCapture(
        url: _currentUrl,
        title: MediaCapture.normalizeTitle(_pageTitle),
      ),
    );
  }

  Future<void> _openCaptureSheet() async {
    final capture = _capture;
    if (capture == null) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => _CaptureSheet(capture: capture),
    );
    if (confirmed == true && mounted) context.pop(capture);
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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 4,
        title: Row(
          children: [
            _NavIcon(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: _canGoBack ? () => _controller?.goBack() : null,
            ),
            _NavIcon(
              icon: Icons.arrow_forward_ios_rounded,
              onTap:
                  _canGoForward ? () => _controller?.goForward() : null,
            ),
            _NavIcon(
              icon: Icons.refresh_rounded,
              onTap: () => _controller?.reload(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _urlBarCtrl,
                  textInputAction: TextInputAction.go,
                  onSubmitted: _navigate,
                  style: TextStyle(fontSize: 12.5, color: context.text1),
                  decoration: InputDecoration(
                    hintText: 'ابحث أو الصق رابطًا...',
                    hintStyle: TextStyle(fontSize: 12, color: context.text3),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.mono, width: 1.4),
                    ),
                    filled: true,
                    fillColor: context.variant,
                    prefixIcon: Icon(Icons.lock_outline_rounded,
                        size: 13, color: context.text3),
                  ),
                ),
              ),
            ),
            _NavIcon(
              icon: Icons.check_rounded,
              onTap: _useCurrentPage,
              foreground: context.mono,
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
                  valueColor: AlwaysStoppedAnimation(context.mono),
                ),
              )
            : null,
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: _capture == null
            ? const SizedBox.shrink(key: ValueKey('no-capture'))
            : _CaptureFab(
                key: const ValueKey('capture'),
                source: VideoUtils.inspect(_capture!.url).source,
                onTap: _openCaptureSheet,
              ),
      ),
      body: _controller == null
          ? const SizedBox.shrink()
          : WebViewWidget(
              controller: _controller!,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
    );
  }
}

// ===================================================================

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.onTap, this.foreground});

  final IconData icon;
  final VoidCallback? onTap;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? context.text3.withValues(alpha: 0.35)
        : (foreground ?? context.text1);
    return IconButton(
      iconSize: 19,
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
      icon: Icon(icon, color: color),
      onPressed: onTap,
    );
  }
}

/// الزر العائم الذي يظهر عند التقاط فيديو
class _CaptureFab extends StatefulWidget {
  const _CaptureFab({super.key, required this.source, required this.onTap});

  final VideoSource source;
  final VoidCallback onTap;

  @override
  State<_CaptureFab> createState() => _CaptureFabState();
}

class _CaptureFabState extends State<_CaptureFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (widget.source) {
      VideoSource.youtube => Icons.smart_display_rounded,
      VideoSource.directVideo => Icons.movie_rounded,
      _ => Icons.language_rounded,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: context.mono
                      .withValues(alpha: 0.12 + _c.value * 0.22),
                  blurRadius: 18 + _c.value * 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: context.mono,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: context.onMono, size: 21),
              const SizedBox(width: 8),
              Text(
                'تم التقاط فيديو',
                style: TextStyle(
                  color: context.onMono,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_upward_rounded,
                  color: context.onMono, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة تأكيد الالتقاط: تعرض المعاينة وعنوان الفيديو والرابط
class _CaptureSheet extends StatelessWidget {
  const _CaptureSheet({required this.capture});

  final MediaCapture capture;

  @override
  Widget build(BuildContext context) {
    final info = VideoUtils.inspect(capture.url);
    final icon = switch (info.source) {
      VideoSource.youtube => Icons.smart_display_rounded,
      VideoSource.directVideo => Icons.movie_rounded,
      VideoSource.webPage => Icons.language_rounded,
      VideoSource.unknown => Icons.help_outline_rounded,
    };
    final title = MediaCapture.normalizeTitle(capture.title) ??
        (info.source == VideoSource.youtube
            ? 'فيديو يوتيوب'
            : 'فيديو من الصفحة');
    final thumbnail = info.youtubeId != null
        ? VideoUtils.youtubeThumbnail(info.youtubeId!)
        : null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: context.text2),
                const SizedBox(width: 8),
                Text(
                  info.source == VideoSource.youtube
                      ? 'فيديو يوتيوب جاهز'
                      : info.source == VideoSource.directVideo
                          ? 'رابط فيديو مباشر جاهز'
                          : 'رابط الصفحة جاهز',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.text2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: thumbnail,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            ColoredBox(color: context.variant),
                        errorWidget: (_, _, _) => _thumbArt(context, icon),
                      )
                    : _thumbArt(context, icon),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: context.text1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.link_rounded, size: 13, color: context.text3),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    info.url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: context.text3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GradientButton(
              label: 'استخدام هذا الفيديو',
              icon: Icons.play_circle_fill_rounded,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('تجاهل والمتابعة في التصفح'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbArt(BuildContext context, IconData icon) {
    return ColoredBox(
      color: context.variant,
      child: Icon(icon, size: 46, color: context.text3),
    );
  }
}
