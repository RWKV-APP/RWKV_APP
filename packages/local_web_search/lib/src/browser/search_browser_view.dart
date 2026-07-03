// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:local_web_search/src/browser/in_app_web_view_adapter.dart';
import 'package:local_web_search/src/browser/search_browser_controller.dart';
import 'package:local_web_search/src/browser/unsupported_browser_adapter.dart';

class SearchBrowserView extends StatelessWidget {
  final SearchBrowserController controller;
  final String initialUrl;

  const SearchBrowserView({
    super.key,
    required this.controller,
    this.initialUrl = 'https://www.google.com/',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    if (kIsWeb) {
      return UnsupportedBrowserAdapter(
        controller: controller,
        message: 'Web is not supported by this desktop debug package.',
      );
    }

    if (Platform.isLinux) {
      return UnsupportedBrowserAdapter(
        controller: controller,
        message:
            'Linux browser adapter is reserved for a future CEF implementation.',
      );
    }

    if (Platform.isMacOS || Platform.isWindows) {
      return InAppWebViewBrowserAdapter(
        controller: controller,
        initialUrl: initialUrl,
      );
    }

    return UnsupportedBrowserAdapter(
      controller: controller,
      message: 'Only macOS, Windows, and Linux desktop targets are planned.',
    );
  }
}
