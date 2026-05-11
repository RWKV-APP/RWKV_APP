// Project imports:
import 'package:zone/config.dart';

(List<String> batch, bool isBatch, int batchCount, int? selectedBatch) getBatchInfo(String content) {
  final decodedInfo = content.split(Config.batchMarker);
  if (decodedInfo.length == 1) {
    return ([content], false, 0, 0);
  }
  final dataCount = decodedInfo.length;
  final batch = decodedInfo.sublist(0, dataCount);
  int? selectedBatch = int.tryParse(decodedInfo.last);
  if (selectedBatch != null && selectedBatch < 0) selectedBatch = null;
  return (batch, true, dataCount - 1, selectedBatch);
}

bool getIsBatch(String content) {
  final decodedInfo = content.split(Config.batchMarker);
  return decodedInfo.length > 1;
}

String buildBatchContent(List<String> batch, {int selectedBatch = -1}) {
  if (batch.isEmpty) return "";
  return batch.join(Config.batchMarker) + Config.batchMarker + selectedBatch.toString();
}

List<String> normalizeBatchResponseBufferContent({
  required List<String> responseBufferContent,
  required int expectedBatchCount,
  int? maxBatchSlotCount,
}) {
  if (responseBufferContent.isEmpty) return const <String>[];
  final int? effectiveMaxBatchSlotCount = maxBatchSlotCount == null || maxBatchSlotCount <= 0 ? null : maxBatchSlotCount;
  if (expectedBatchCount <= 0) {
    if (effectiveMaxBatchSlotCount == null) return responseBufferContent;
    if (responseBufferContent.length <= effectiveMaxBatchSlotCount) return responseBufferContent;
    return responseBufferContent.take(effectiveMaxBatchSlotCount).toList();
  }
  if (effectiveMaxBatchSlotCount != null && expectedBatchCount > effectiveMaxBatchSlotCount) {
    return responseBufferContent.take(effectiveMaxBatchSlotCount).toList();
  }
  if (responseBufferContent.length == expectedBatchCount) return responseBufferContent;

  final latestSnapshot = _findLatestCompleteBatchSnapshot(
    responseBufferContent: responseBufferContent,
    expectedBatchCount: expectedBatchCount,
  );
  if (latestSnapshot != null) return latestSnapshot;
  if (responseBufferContent.length < expectedBatchCount) return responseBufferContent;
  return responseBufferContent.take(expectedBatchCount).toList();
}

List<String>? _findLatestCompleteBatchSnapshot({
  required List<String> responseBufferContent,
  required int expectedBatchCount,
}) {
  List<String>? latestSnapshot;
  final current = <String>[];

  for (final content in responseBufferContent) {
    if (content == "-1") {
      if (current.length == expectedBatchCount) {
        latestSnapshot = <String>[...current];
      }
      current.clear();
      continue;
    }

    current.add(content);
    if (current.length <= expectedBatchCount) continue;
    current.clear();
  }

  if (current.length == expectedBatchCount) {
    latestSnapshot = <String>[...current];
  }

  return latestSnapshot;
}
