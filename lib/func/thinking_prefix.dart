// Project imports:
import 'package:zone/model/file_info.dart';
import 'package:zone/model/thinking_mode.dart';

const String compactFastThinkingPrefix = '<think></think';

final DateTime compactFastThinkingPrefixCutoff = DateTime.utc(2026, 7, 10);

bool usesCompactFastThinkingPrefix(FileInfo fileInfo) {
  final identity = '${fileInfo.name} ${fileInfo.fileName} ${fileInfo.raw}'.toLowerCase();
  final familyMatch = RegExp(r'(?:^|[-_\s])g1([a-z])(?:$|[-_\s])').firstMatch(identity);
  final familySuffix = familyMatch?.group(1);
  if (familySuffix != null) {
    return familySuffix.codeUnitAt(0) >= 'h'.codeUnitAt(0);
  }

  final weightDate = _weightDateFromFileName(fileInfo.fileName) ?? fileInfo.date?.toUtc();
  if (weightDate == null) return false;
  return !weightDate.isBefore(compactFastThinkingPrefixCutoff);
}

String thinkingTokenForModel({
  required ThinkingMode thinkingMode,
  required String configuredThinkingToken,
  required FileInfo fileInfo,
}) {
  if (thinkingMode != ThinkingMode.fast) return configuredThinkingToken;
  if (configuredThinkingToken != ThinkingMode.fast.header) return configuredThinkingToken;
  if (!usesCompactFastThinkingPrefix(fileInfo)) return configuredThinkingToken;
  return compactFastThinkingPrefix;
}

DateTime? _weightDateFromFileName(String fileName) {
  final match = RegExp(r'(20\d{2})(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])').firstMatch(fileName);
  if (match == null) return null;

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final result = DateTime.utc(year, month, day);
  if (result.year != year || result.month != month || result.day != day) return null;
  return result;
}
