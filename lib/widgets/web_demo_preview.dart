// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/func/web_demo.dart';
import 'package:zone/store/p.dart';

@visibleForTesting
bool? debugWebDemoInlinePreviewSupported;

class WebDemoPreviewPanel extends ConsumerWidget {
  final String raw;
  final String label;
  final double height;
  final bool compact;

  const WebDemoPreviewPanel({
    super.key,
    required this.raw,
    required this.label,
    this.height = 300,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final document = extractFirstWebDemoHtml(raw);
    if (document == null) return const SizedBox.shrink();

    final html = document.html;
    final canInlinePreview = debugWebDemoInlinePreviewSupported ?? (Platform.isMacOS || Platform.isWindows);
    final titleStyle = theme.textTheme.labelMedium?.copyWith(
      color: appTheme.qb0,
      fontWeight: FontWeight.w600,
    );

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: .circular(8),
        border: Border.all(color: appTheme.qb12, width: .5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const .symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.web_asset_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: titleStyle,
                  ),
                ),
                _WebDemoPreviewAction(
                  tooltip: "Continue editing",
                  icon: Icons.edit_outlined,
                  onTap: () => P.webDemo.prepareContinuation(html: html),
                ),
                const SizedBox(width: 4),
                _WebDemoPreviewAction(
                  tooltip: "Open in browser",
                  icon: Icons.open_in_browser_rounded,
                  onTap: () => P.webDemo.openHtmlInSystemBrowser(html: html, label: label),
                ),
              ],
            ),
          ),
          Container(height: .5, color: appTheme.qb12),
          if (canInlinePreview)
            SizedBox(
              height: height,
              child: _WebDemoInlineWebView(html: html),
            ),
          if (!canInlinePreview)
            _WebDemoRawPreview(
              html: html,
              height: height,
            ),
        ],
      ),
    );
  }
}

class _WebDemoInlineWebView extends StatelessWidget {
  final String html;

  const _WebDemoInlineWebView({required this.html});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;
    final baseUri = WebUri("https://rwkv-web-demo.local/");

    return InAppWebView(
      key: ValueKey<int>(html.hashCode),
      initialData: InAppWebViewInitialData(
        data: html,
        mimeType: "text/html",
        encoding: "utf-8",
        baseUrl: baseUri,
        historyUrl: baseUri,
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: false,
        supportMultipleWindows: false,
        useShouldOverrideUrlLoading: true,
        useShouldInterceptRequest: true,
        allowFileAccessFromFileURLs: false,
        allowUniversalAccessFromFileURLs: false,
        transparentBackground: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url;
        if (url == null) return NavigationActionPolicy.CANCEL;
        if (url.host == baseUri.host) return NavigationActionPolicy.ALLOW;
        return NavigationActionPolicy.CANCEL;
      },
      shouldInterceptRequest: (controller, request) async {
        final url = request.url;
        if (url.host == baseUri.host) return null;
        if (url.scheme == "data" || url.scheme == "blob" || url.scheme == "about") return null;
        return WebResourceResponse(
          contentType: "text/plain",
          data: Uint8List(0),
          headers: const <String, String>{},
          statusCode: 403,
          reasonPhrase: "Blocked",
        );
      },
    );
  }
}

class _WebDemoRawPreview extends StatelessWidget {
  final String html;
  final double height;

  const _WebDemoRawPreview({
    required this.html,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        padding: const .all(10),
        child: Text(
          html,
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: "monospace"),
        ),
      ),
    );
  }
}

class _WebDemoPreviewAction extends ConsumerWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _WebDemoPreviewAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Icon(icon, size: 18, color: primary.withValues(alpha: .86)),
        ),
      ),
    );
  }
}
