// Package imports:
import 'package:path/path.dart' as p;

// Project imports:
import 'package:zone/model/file_info.dart';

Set<String> localChatExcludedConfigFileNamesFromConfig(Map<String, dynamic>? config) {
  if (config == null) return {};

  final result = <String>{};
  for (final demoType in const ["chat", "tts", "world"]) {
    final demoConfig = config[demoType];
    if (demoConfig is! Map) continue;

    final modelConfig = demoConfig["model_config"];
    if (modelConfig is! Iterable) continue;

    for (final entry in modelConfig) {
      if (entry is! Map) continue;
      _addConfigFileName(result, entry);

      final state = entry["state"];
      if (state is! Iterable) continue;

      for (final stateEntry in state) {
        if (stateEntry is! Map) continue;
        _addConfigFileName(result, stateEntry);
      }
    }
  }

  return result;
}

bool shouldShowLocalChatModelFile({
  required FileInfo fileInfo,
  required Set<String> excludedConfigFileNames,
}) {
  if (!fileInfo.fromLocalGgufFile) return true;
  return !excludedConfigFileNames.contains(fileInfo.fileName);
}

void _addConfigFileName(Set<String> result, Map<dynamic, dynamic> entry) {
  final rawFileName = entry["fileName"];
  if (rawFileName is String) {
    final fileName = rawFileName.trim();
    if (fileName.isNotEmpty) {
      result.add(fileName);
      return;
    }
  }

  final rawUrl = entry["url"];
  if (rawUrl is! String) return;

  final uri = Uri.tryParse(rawUrl);
  final fileName = uri == null ? p.basename(rawUrl) : p.url.basename(uri.path);
  if (fileName.isEmpty) return;
  result.add(fileName);
}
