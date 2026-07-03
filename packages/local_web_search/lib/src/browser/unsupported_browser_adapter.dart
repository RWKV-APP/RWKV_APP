// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:local_web_search/src/browser/search_browser_controller.dart';

class UnsupportedBrowserAdapter extends StatefulWidget {
  final SearchBrowserController controller;
  final String message;

  const UnsupportedBrowserAdapter({
    super.key,
    required this.controller,
    required this.message,
  });

  @override
  State<UnsupportedBrowserAdapter> createState() =>
      _UnsupportedBrowserAdapterState();
}

class _UnsupportedBrowserAdapterState extends State<UnsupportedBrowserAdapter>
    implements SearchBrowserControllerDelegate {
  @override
  bool get supportsBrowserActions => false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.attach(this);
      widget.controller.markError(widget.message);
    });
  }

  @override
  void dispose() {
    widget.controller.detach(this);
    super.dispose();
  }

  @override
  Future<Object?> evaluateJavaScript(String source) async {
    final _ = source;
    throw UnsupportedError(widget.message);
  }

  @override
  Future<void> loadUrl(String url) async {
    final _ = url;
    widget.controller.markError(widget.message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
