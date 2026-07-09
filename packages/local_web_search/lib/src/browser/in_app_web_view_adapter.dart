// Dart imports:
import 'dart:async';

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
  static const bool _logWebViewLoads = bool.fromEnvironment(
    'LOCAL_WEB_SEARCH_LOG_WEBVIEW_LOADS',
    defaultValue: true,
  );
  static const Duration _resizePlaceholderDuration = Duration(
    milliseconds: 320,
  );

  InAppWebViewController? _webViewController;
  final InAppWebViewKeepAlive _keepAlive = InAppWebViewKeepAlive();
  Timer? _resizePlaceholderTimer;
  Size? _lastViewSize;
  String? _pendingUrl;
  bool _hasCommittedPage = false;
  bool _showResizePlaceholder = false;
  bool _resizePlaceholderFrameScheduled = false;

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
    _resizePlaceholderTimer?.cancel();
    widget.controller.detach(this);
    unawaited(InAppWebViewController.disposeKeepAlive(_keepAlive));
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
    final backgroundColor = theme.colorScheme.surface;
    final showPlaceholder =
        !_hasCommittedPage ||
        widget.controller.loading ||
        _showResizePlaceholder;

    return LayoutBuilder(
      builder: (context, constraints) {
        _handleViewSize(constraints.biggest);

        return ColoredBox(
          color: backgroundColor,
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: InAppWebView(
                    keepAlive: _keepAlive,
                    initialUrlRequest: URLRequest(
                      url: WebUri(widget.initialUrl),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      javaScriptCanOpenWindowsAutomatically: false,
                      supportMultipleWindows: false,
                      useShouldOverrideUrlLoading: false,
                      transparentBackground: true,
                      underPageBackgroundColor: backgroundColor,
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
                      _debugLog('[local_web_search] load start: $url');
                      _markPageCommitted(false);
                      widget.controller.markLoading(true);
                      widget.controller.markCurrentUrl(url?.toString());
                    },
                    onPageCommitVisible: (controller, url) {
                      _markPageCommitted(_isVisiblePageUrl(url));
                    },
                    onLoadStop: (controller, url) {
                      _debugLog('[local_web_search] load stop: $url');
                      _markPageCommitted(_isVisiblePageUrl(url));
                      widget.controller.markLoading(false);
                      widget.controller.markCurrentUrl(url?.toString());
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress >= 100) {
                        widget.controller.markLoading(false);
                      }
                    },
                    onReceivedError: (controller, request, error) {
                      _debugLog(
                        '[local_web_search] load error: ${request.url} ${error.description}',
                      );
                      if (request.isForMainFrame ?? true) {
                        _markPageCommitted(false);
                      }
                      widget.controller.markLoading(false);
                      widget.controller.markError(error.description);
                    },
                    onWebContentProcessDidTerminate: (controller) {
                      _debugLog(
                        '[local_web_search] web content process terminated',
                      );
                      _markPageCommitted(false);
                      widget.controller.markLoading(false);
                      widget.controller.markError(
                        'Web content process terminated.',
                      );
                    },
                  ),
                ),
              ),
              if (showPlaceholder)
                const Positioned.fill(
                  child: IgnorePointer(child: _BrowserLoadingPlaceholder()),
                ),
            ],
          ),
        );
      },
    );
  }

  void _debugLog(String message) {
    if (!_logWebViewLoads) return;
    debugPrint(message);
  }

  void _handleViewSize(Size size) {
    final previousSize = _lastViewSize;
    _lastViewSize = size;
    if (previousSize == null) return;
    if (previousSize == size) return;
    if (size.width <= 0 || size.height <= 0) return;

    if (_showResizePlaceholder) {
      _scheduleResizePlaceholderHide();
      return;
    }
    if (_resizePlaceholderFrameScheduled) return;
    _resizePlaceholderFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _resizePlaceholderFrameScheduled = false;
        _showResizePlaceholder = true;
      });
      _scheduleResizePlaceholderHide();
    });
  }

  void _scheduleResizePlaceholderHide() {
    _resizePlaceholderTimer?.cancel();
    _resizePlaceholderTimer = Timer(_resizePlaceholderDuration, () {
      if (!mounted) return;
      if (!_showResizePlaceholder) return;
      setState(() {
        _showResizePlaceholder = false;
      });
    });
  }

  void _markPageCommitted(bool committed) {
    if (_hasCommittedPage == committed) return;
    if (!mounted) {
      _hasCommittedPage = committed;
      return;
    }
    setState(() {
      _hasCommittedPage = committed;
    });
  }

  bool _isVisiblePageUrl(WebUri? url) {
    final value = url?.toString();
    if (value == null) return false;
    if (value.isEmpty) return false;
    return value != 'about:blank';
  }
}

class _BrowserLoadingPlaceholder extends StatelessWidget {
  const _BrowserLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  size: 28,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading web page...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
