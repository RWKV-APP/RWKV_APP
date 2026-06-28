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
    this.height = 420,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final appTheme = ref.watch(P.app.theme);
    final document = extractFirstWebDemoHtml(raw);
    final html = document?.html;
    final canInlinePreview = debugWebDemoInlinePreviewSupported ?? (Platform.isMacOS || Platform.isWindows);
    final bytes = html == null ? raw.length : html.length;
    final status = document == null
        ? raw.trim().isEmpty
              ? "Waiting"
              : "Parsing"
        : document.complete
        ? "Complete"
        : "Live";
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
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: titleStyle,
                      ),
                      Text(
                        "$status · ${_formatBytes(bytes)}",
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TextStyle(color: appTheme.qb5, fontSize: 11, height: 1.1),
                      ),
                    ],
                  ),
                ),
                if (html != null)
                  _WebDemoPreviewAction(
                    tooltip: "View source",
                    icon: Icons.code_rounded,
                    onTap: () => showWebDemoSourceSheet(context: context, source: html, label: label),
                  ),
                if (html != null) const SizedBox(width: 4),
                if (html != null)
                  _WebDemoPreviewAction(
                    tooltip: "Continue editing",
                    icon: Icons.edit_outlined,
                    onTap: () => P.webDemo.prepareContinuation(html: html),
                  ),
                if (html != null) const SizedBox(width: 4),
                if (html != null)
                  _WebDemoPreviewAction(
                    tooltip: "Open in browser",
                    icon: Icons.open_in_browser_rounded,
                    onTap: () => P.webDemo.openHtmlInSystemBrowser(html: html, label: label),
                  ),
              ],
            ),
          ),
          Container(height: .5, color: appTheme.qb12),
          if (html == null)
            _WebDemoWaitingPreview(
              raw: raw,
              height: height,
            ),
          if (html != null && canInlinePreview)
            SizedBox(
              height: height,
              child: _WebDemoInlineWebView(
                html: html,
                complete: document?.complete ?? false,
              ),
            ),
          if (html != null && !canInlinePreview)
            _WebDemoExternalPreviewFallback(
              height: height,
            ),
        ],
      ),
    );
  }
}

class _WebDemoInlineWebView extends StatelessWidget {
  final String html;
  final bool complete;

  const _WebDemoInlineWebView({
    required this.html,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;
    final baseUri = WebUri("https://rwkv-web-demo.local/");

    return InAppWebView(
      key: ValueKey<int>(_previewKey(html: html, complete: complete)),
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

class _WebDemoWaitingPreview extends ConsumerWidget {
  final String raw;
  final double height;

  const _WebDemoWaitingPreview({
    required this.raw,
    required this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final appTheme = ref.watch(P.app.theme);
    final hasText = raw.trim().isNotEmpty;

    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 10),
            Text(
              hasText ? "Waiting for HTML document" : "Waiting for first tokens",
              style: TextStyle(color: appTheme.qb5, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebDemoExternalPreviewFallback extends ConsumerWidget {
  final double height;

  const _WebDemoExternalPreviewFallback({
    required this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);

    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(Icons.open_in_browser_rounded, color: theme.colorScheme.primary.withValues(alpha: .72)),
            const SizedBox(height: 8),
            Text(
              "Inline preview is unavailable on this platform.",
              style: TextStyle(color: appTheme.qb5, fontSize: 12),
              textAlign: .center,
            ),
          ],
        ),
      ),
    );
  }
}

void showWebDemoSourceSheet({
  required BuildContext context,
  required String source,
  required String label,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _WebDemoSourceSheet(source: source, label: label);
    },
  );
}

class _WebDemoSourceSheet extends ConsumerWidget {
  final String source;
  final String label;

  const _WebDemoSourceSheet({
    required this.source,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final height = MediaQuery.sizeOf(context).height * .78;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const .symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.code_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "$label source",
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: const TextStyle(fontWeight: .w700),
                  ),
                ),
                IconButton(
                  tooltip: "Close",
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Container(height: .5, color: appTheme.qb12),
          Expanded(
            child: SingleChildScrollView(
              padding: const .all(16),
              child: SelectableText(
                source,
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: "monospace", height: 1.35),
              ),
            ),
          ),
        ],
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

String _formatBytes(int bytes) {
  if (bytes < 1024) return "$bytes B";
  final value = bytes / 1024;
  if (value < 1024) return "${value.toStringAsFixed(1)} KB";
  return "${(value / 1024).toStringAsFixed(1)} MB";
}

int _previewKey({
  required String html,
  required bool complete,
}) {
  if (complete) return html.hashCode;
  return html.length ~/ 1800;
}
