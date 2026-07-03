// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:local_web_search/src/browser/search_browser_controller.dart';

class InAppWebViewBrowserAdapter extends StatefulWidget {
  final SearchBrowserController controller;
  final String initialUrl;

  const InAppWebViewBrowserAdapter({
    super.key,
    required this.controller,
    required this.initialUrl,
  });

  @override
  State<InAppWebViewBrowserAdapter> createState() =>
      _InAppWebViewBrowserAdapterState();
}

class _InAppWebViewBrowserAdapterState extends State<InAppWebViewBrowserAdapter>
    implements SearchBrowserControllerDelegate {
  static const String _desktopChromeUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';

  InAppWebViewController? _webViewController;
  String? _pendingUrl;

  @override
  bool get supportsBrowserActions => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.attach(this);
    });
  }

  @override
  void dispose() {
    widget.controller.detach(this);
    super.dispose();
  }

  @override
  Future<Object?> evaluateJavaScript(String source) async {
    final webViewController = _webViewController;
    if (webViewController == null) {
      throw StateError('WebView is not ready.');
    }
    return webViewController.evaluateJavascript(source: source);
  }

  @override
  Future<void> loadUrl(String url) async {
    final webViewController = _webViewController;
    if (webViewController == null) {
      _pendingUrl = url;
      return;
    }
    await webViewController.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: false,
        supportMultipleWindows: false,
        useShouldOverrideUrlLoading: false,
        transparentBackground: false,
        mediaPlaybackRequiresUserGesture: true,
        userAgent: _desktopChromeUserAgent,
      ),
      onWebViewCreated: (controller) async {
        _webViewController = controller;
        final pendingUrl = _pendingUrl;
        if (pendingUrl == null) return;
        _pendingUrl = null;
        await loadUrl(pendingUrl);
      },
      onLoadStart: (controller, url) {
        debugPrint('[local_web_search] load start: $url');
        widget.controller.markLoading(true);
        widget.controller.markCurrentUrl(url?.toString());
      },
      onLoadStop: (controller, url) {
        debugPrint('[local_web_search] load stop: $url');
        widget.controller.markLoading(false);
        widget.controller.markCurrentUrl(url?.toString());
      },
      onProgressChanged: (controller, progress) {
        if (progress >= 100) {
          widget.controller.markLoading(false);
        }
      },
      onReceivedError: (controller, request, error) {
        debugPrint(
          '[local_web_search] load error: ${request.url} ${error.description}',
        );
        widget.controller.markLoading(false);
        widget.controller.markError(error.description);
      },
      onWebContentProcessDidTerminate: (controller) {
        debugPrint('[local_web_search] web content process terminated');
        widget.controller.markLoading(false);
        widget.controller.markError('Web content process terminated.');
      },
    );
  }
}
