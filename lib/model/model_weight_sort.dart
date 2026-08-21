import 'package:zone/model/file_info.dart';
import 'package:zone/model/world_type.dart';

typedef WorldModelSelection = ({WorldType worldType, (String, String) socPair});

/// Orders model weights by the shared selector priority.
///
/// Accelerated backends are preferred first, then larger models within the
/// same backend tier.
int compareModelWeights(FileInfo a, FileInfo b) {
  final aHasCoreML = a.hasEffectiveTag('coreml');
  final bHasCoreML = b.hasEffectiveTag('coreml');
  if (aHasCoreML != bHasCoreML) return aHasCoreML ? -1 : 1;

  final aHasMLX = a.hasEffectiveTag('mlx');
  final bHasMLX = b.hasEffectiveTag('mlx');
  if (aHasMLX != bHasMLX) return aHasMLX ? -1 : 1;

  final aHasNpu = a.hasEffectiveTag('npu');
  final bHasNpu = b.hasEffectiveTag('npu');
  if (aHasNpu != bHasNpu) return aHasNpu ? -1 : 1;

  final aHasGpu = a.hasEffectiveTag('gpu');
  final bHasGpu = b.hasEffectiveTag('gpu');
  if (aHasGpu != bHasGpu) return aHasGpu ? -1 : 1;

  final aHasWebRWKV = a.hasEffectiveTag('webRwkv');
  final bHasWebRWKV = b.hasEffectiveTag('webRwkv');
  if (aHasWebRWKV != bHasWebRWKV) return aHasWebRWKV ? -1 : 1;

  return (b.modelSize ?? 0).compareTo(a.modelSize ?? 0);
}

/// Builds the visible VL selections for [socName] and applies the same model
/// priority used by the Chat selector.
List<WorldModelSelection> sortedWorldModelSelections({
  required Iterable<FileInfo> availableModels,
  required String socName,
}) {
  final modelsByFileName = <String, FileInfo>{
    for (final model in availableModels)
      if (!model.isEncoder && !model.isAdapter) model.fileName: model,
  };

  final indexedSelections = <({int index, WorldModelSelection selection, FileInfo? model})>[];
  int index = 0;

  for (final worldType in WorldType.values.where((value) => value.available)) {
    for (final socPair in worldType.socPairs.where((pair) => pair.$1.isEmpty || pair.$1 == socName)) {
      indexedSelections.add((
        index: index++,
        selection: (worldType: worldType, socPair: socPair),
        model: modelsByFileName[socPair.$2],
      ));
    }
  }

  indexedSelections.sort((a, b) {
    final aModel = a.model;
    final bModel = b.model;

    if (aModel == null && bModel == null) return a.index.compareTo(b.index);
    if (aModel == null) return 1;
    if (bModel == null) return -1;

    final priority = compareModelWeights(aModel, bModel);
    if (priority != 0) return priority;
    return a.index.compareTo(b.index);
  });

  return indexedSelections.map((entry) => entry.selection).toList(growable: false);
}
