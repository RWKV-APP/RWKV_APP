// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:local_web_search/local_web_search.dart';

void main() {
  const simulatedUnavailable = String.fromEnvironment(
    'LOCAL_WEB_SEARCH_SIMULATE_UNAVAILABLE',
  );
  runApp(
    SearchBrowserDebugApp(
      simulatedUnavailableEngineIds: _parseEngineIds(simulatedUnavailable),
    ),
  );
}

Set<String> _parseEngineIds(String value) {
  final ids = <String>{};
  final parts = value.split(',');
  for (final part in parts) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    ids.add(trimmed);
  }
  return ids;
}
