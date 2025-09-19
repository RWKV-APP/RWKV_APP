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
