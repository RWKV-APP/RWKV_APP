// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:local_web_search/src/ui/search_browser_panel.dart';

class SearchBrowserDebugApp extends StatelessWidget {
  final Set<String> simulatedUnavailableEngineIds;

  const SearchBrowserDebugApp({
    super.key,
    this.simulatedUnavailableEngineIds = const <String>{},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Local Web Search Debug',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF808080))
            .copyWith(
              primary: const Color(0xFF202020),
              onPrimary: const Color(0xFFFFFFFF),
              primaryContainer: const Color(0xFFE0E0E0),
              onPrimaryContainer: const Color(0xFF202020),
              surface: const Color(0xFFFFFFFF),
              onSurface: const Color(0xFF202020),
              surfaceContainerHighest: const Color(0xFFE0E0E0),
              onSurfaceVariant: const Color(0xFF666666),
              outline: const Color(0xFF8A8A8A),
              outlineVariant: const Color(0xFFC8C8C8),
              error: const Color(0xFF202020),
              onError: const Color(0xFFFFFFFF),
            ),
        useMaterial3: true,
      ),
      home: SearchBrowserPanel(
        simulatedUnavailableEngineIds: simulatedUnavailableEngineIds,
      ),
    );
  }
}
