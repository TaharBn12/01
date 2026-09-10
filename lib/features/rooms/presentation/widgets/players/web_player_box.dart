import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../core/theme/app_theme.dart';

/// يعرض صفحات الويب العامة داخل إطار المشاهدة (لا يدعم المزامنة)
class WebPlayerBox extends StatefulWidget {
  const WebPlayerBox({super.key, required this.url});

  final String url;

  @override
  State<WebPlayerBox> createState() => _WebPlayerBoxState();
}

class _WebPlayerBoxState extends State<WebPlayerBox> {
  WebViewController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (_) {
              if (mounted) setState(() => _loading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: kIsWeb || _controller == null
            ? Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(18),
                child: const Text(
                  'عرض صفحات الويب داخل المشاهدة متاح على تطبيق الجوال.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : Stack(
                children: [
                  WebViewWidget(controller: _controller!),
                  if (_loading)
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
