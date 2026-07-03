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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: SearchBrowserPanel(
        simulatedUnavailableEngineIds: simulatedUnavailableEngineIds,
      ),
    );
  }
}
