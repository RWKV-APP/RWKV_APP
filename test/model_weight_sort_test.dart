// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/model/file_info.dart';
import 'package:zone/model/model_weight_sort.dart';
import 'package:zone/model/world_type.dart';

void main() {
  test('orders weights by the shared acceleration priority', () {
    final models = [
      _fileInfo(name: 'CPU', tags: const ['cpu'], modelSize: 13.3),
      _fileInfo(name: 'WebRWKV', tags: const ['webRwkv'], modelSize: 7.2),
      _fileInfo(name: 'GPU', tags: const ['gpu'], modelSize: 2.9),
      _fileInfo(name: 'NPU', tags: const ['npu'], modelSize: 1.5),
      _fileInfo(name: 'MLX', tags: const ['mlx'], modelSize: 0.4),
      _fileInfo(name: 'Core ML', tags: const ['coreml'], modelSize: 0.1),
    ]..sort(compareModelWeights);

    expect(models.map((model) => model.name), ['Core ML', 'MLX', 'NPU', 'GPU', 'WebRWKV', 'CPU']);
  });

  test('orders weights by descending size within the same acceleration tier', () {
    final models = [
      _fileInfo(name: 'GPU 0.4B', tags: const ['gpu'], modelSize: 0.4),
      _fileInfo(name: 'GPU 2.9B', tags: const ['gpu'], modelSize: 2.9),
      _fileInfo(name: 'GPU 1.5B', tags: const ['gpu'], modelSize: 1.5),
    ]..sort(compareModelWeights);

    expect(models.map((model) => model.name), ['GPU 2.9B', 'GPU 1.5B', 'GPU 0.4B']);
  });

  test('applies the Chat ordering to VL selections after SoC filtering', () {
    const socName = '8 Gen 3';
    final availableModels = [
      _worldFileInfo(WorldType.modrwkvV3, '', tags: const ['gpu'], modelSize: 0.4),
      _worldFileInfo(WorldType.modrwkvV3, socName, tags: const ['npu'], modelSize: 0.4),
      _worldFileInfo(WorldType.fineVisionMax, '', tags: const ['gpu'], modelSize: 1.5),
      _worldFileInfo(WorldType.fineVisionMax, socName, tags: const ['npu'], modelSize: 1.5),
      _worldFileInfo(WorldType.fineVisionMaxThinkingPreview, '', tags: const ['gpu'], modelSize: 1.5),
      _worldFileInfo(WorldType.fineVisionMaxThinkingPreview, socName, tags: const ['npu'], modelSize: 1.5),
    ];

    final selections = sortedWorldModelSelections(
      availableModels: availableModels,
      socName: socName,
    );

    expect(
      selections.map((selection) => '${selection.worldType.name}:${selection.socPair.$1}'),
      [
        'fineVisionMax:8 Gen 3',
        'fineVisionMaxThinkingPreview:8 Gen 3',
        'modrwkvV3:8 Gen 3',
        'fineVisionMax:',
        'fineVisionMaxThinkingPreview:',
        'modrwkvV3:',
      ],
    );
  });
}

FileInfo _worldFileInfo(
  WorldType worldType,
  String socName, {
  required List<String> tags,
  required double modelSize,
}) {
  final socPair = worldType.socPairs.singleWhere((pair) => pair.$1 == socName);
  return _fileInfo(
    name: '${worldType.name}:${socName.isEmpty ? 'generic' : socName}',
    fileName: socPair.$2,
    tags: tags,
    modelSize: modelSize,
  );
}

FileInfo _fileInfo({
  required String name,
  String? fileName,
  required List<String> tags,
  required double modelSize,
}) {
  return FileInfo.fromJSON({
    'name': name,
    'url': 'test/${fileName ?? '$name.gguf'}',
    'fileSize': 1,
    'platforms': const ['macos'],
    'backends': const ['llamacpp'],
    'modelSize': modelSize,
    'tags': tags,
  });
}
