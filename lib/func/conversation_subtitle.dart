import 'package:zone/func/get_batch_info.dart';

const int conversationSubtitleMaxLength = 200;

String buildConversationSubtitleFromResponseContent(String content, {int? selectedBatch}) {
  final responseContent = _resolveResponseContent(content, selectedBatch: selectedBatch);
  final normalized = responseContent
      .replaceAll('\n', ' ')
      .replaceAll('<EOD>', '')
      .replaceAll('</think>', '')
      .replaceAll('<think>', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.length <= conversationSubtitleMaxLength) return normalized;
  return normalized.substring(0, conversationSubtitleMaxLength);
}

String _resolveResponseContent(String content, {int? selectedBatch}) {
  final (batch, isBatch, batchCount, storedSelectedBatch) = getBatchInfo(content);
  if (!isBatch) return content;
  if (batchCount <= 0) return "";

  final storedIndex = _validBatchIndex(storedSelectedBatch, batchCount);
  final selectedIndex = _validBatchIndex(selectedBatch, batchCount);
  return batch[selectedIndex ?? storedIndex ?? 0];
}

int? _validBatchIndex(int? index, int batchCount) {
  if (index == null) return null;
  if (index < 0) return null;
  if (index >= batchCount) return null;
  return index;
}
