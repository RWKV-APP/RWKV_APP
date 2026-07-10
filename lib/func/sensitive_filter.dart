typedef SensitiveFilterRules = ({
  List<List<String>> compoundRules,
  SensitiveFilterPatternIndex index,
  int maxLength,
  List<List<String>> orderedCompoundRules,
  Set<String> plainWords,
  List<List<String>> unorderedCompoundRules,
});

typedef SensitiveFilterMatchPayload = ({SensitiveFilterPatternIndex index, String text});
typedef SensitiveFilterWindowMatchPayload = ({
  SensitiveFilterPatternIndex index,
  int maxLength,
  String text,
});
typedef SensitiveBatchFilterResult = ({
  List<String> contents,
  Set<int> sensitiveIndexes,
});

const String sensitiveFilterCompoundSeparator = '|';
const SensitiveFilterPatternIndex emptySensitiveFilterPatternIndex = SensitiveFilterPatternIndex(
  nodes: <SensitiveFilterPatternNode>[],
  orderedRules: <SensitiveFilterCompiledRule>[],
  patternLengths: <int>[],
  patterns: <String>[],
  plainPatternIds: <int>[],
  unorderedRules: <SensitiveFilterCompiledRule>[],
);
const SensitiveFilterRules emptySensitiveFilterRules = (
  compoundRules: <List<String>>[],
  index: emptySensitiveFilterPatternIndex,
  maxLength: 0,
  orderedCompoundRules: <List<String>>[],
  plainWords: <String>{},
  unorderedCompoundRules: <List<String>>[],
);

class SensitiveFilterCompiledRule {
  const SensitiveFilterCompiledRule({required this.patternIds, required this.text});

  final List<int> patternIds;
  final String text;
}

class SensitiveFilterPatternIndex {
  const SensitiveFilterPatternIndex({
    required this.nodes,
    required this.orderedRules,
    required this.patternLengths,
    required this.patterns,
    required this.plainPatternIds,
    required this.unorderedRules,
  });

  final List<SensitiveFilterPatternNode> nodes;
  final List<SensitiveFilterCompiledRule> orderedRules;
  final List<int> patternLengths;
  final List<String> patterns;
  final List<int> plainPatternIds;
  final List<SensitiveFilterCompiledRule> unorderedRules;

  bool get isEmpty => patterns.isEmpty;
}

class SensitiveFilterPatternNode {
  const SensitiveFilterPatternNode({
    required this.failure,
    required this.outputs,
    required this.transitions,
  });

  final int failure;
  final List<int> outputs;
  final Map<int, int> transitions;
}

class _SensitiveFilterOccurrence {
  const _SensitiveFilterOccurrence({required this.end, required this.partIndex, required this.start});

  final int end;
  final int partIndex;
  final int start;
}

class _SensitiveFilterPatternNodeBuilder {
  final outputs = <int>[];
  final transitions = <int, int>{};
  int failure = 0;
}

class _SensitiveFilterScanResult {
  const _SensitiveFilterScanResult({required this.occurrencesByPattern});

  final List<List<_SensitiveFilterTextOccurrence>?> occurrencesByPattern;

  bool hasPattern(int patternId) {
    final occurrences = occurrencesByPattern[patternId];
    if (occurrences == null) return false;
    return occurrences.isNotEmpty;
  }
}

class _SensitiveFilterTextOccurrence {
  const _SensitiveFilterTextOccurrence({required this.end, required this.start});

  final int end;
  final int start;
}

SensitiveFilterRules parseSensitiveFilterRules(String filter) {
  final plainWords = <String>{};
  final compoundRuleKeys = <String>{};
  final compoundRules = <List<String>>[];
  final orderedCompoundRules = <List<String>>[];
  final unorderedCompoundRules = <List<String>>[];
  int maxLength = 0;

  final lines = filter.split('\n');
  for (final line in lines) {
    final raw = line.trim();
    if (raw.isEmpty) continue;
    if (raw.length > maxLength) maxLength = raw.length;
    if (!raw.contains(sensitiveFilterCompoundSeparator)) {
      plainWords.add(raw);
      continue;
    }

    final parts = raw.split(sensitiveFilterCompoundSeparator).map((e) => e.trim()).toList(growable: false);
    if (parts.any((e) => e.isEmpty)) {
      plainWords.add(raw);
      continue;
    }

    final uniqueParts = <String>[];
    final seenParts = <String>{};
    for (final part in parts) {
      if (!seenParts.add(part)) continue;
      uniqueParts.add(part);
    }
    if (uniqueParts.length < 2) {
      plainWords.add(raw);
      continue;
    }

    final key = uniqueParts.join(sensitiveFilterCompoundSeparator);
    if (!compoundRuleKeys.add(key)) continue;
    final rule = List<String>.unmodifiable(uniqueParts);
    compoundRules.add(rule);
    if (_shouldCompoundRuleBeOrdered(uniqueParts)) {
      orderedCompoundRules.add(rule);
      continue;
    }
    unorderedCompoundRules.add(rule);
  }

  final index = _buildSensitiveFilterPatternIndex(
    orderedCompoundRules: orderedCompoundRules,
    plainWords: plainWords.toList(growable: false),
    unorderedCompoundRules: unorderedCompoundRules,
  );

  return (
    compoundRules: List<List<String>>.unmodifiable(compoundRules),
    index: index,
    maxLength: maxLength,
    orderedCompoundRules: List<List<String>>.unmodifiable(orderedCompoundRules),
    plainWords: Set<String>.unmodifiable(plainWords),
    unorderedCompoundRules: List<List<String>>.unmodifiable(unorderedCompoundRules),
  );
}

bool isSensitiveFilterRulesEmpty(SensitiveFilterRules rules) {
  if (rules.plainWords.isNotEmpty) return false;
  return rules.compoundRules.isEmpty;
}

SensitiveBatchFilterResult filterSensitiveBatchContents({
  required List<String> contents,
  required bool Function(int index, String content) isSensitive,
  required String replacement,
  required Set<int> sensitiveIndexes,
}) {
  if (contents.isEmpty) {
    return (
      contents: const <String>[],
      sensitiveIndexes: Set<int>.unmodifiable(sensitiveIndexes),
    );
  }

  final nextSensitiveIndexes = <int>{...sensitiveIndexes};
  final filteredContents = <String>[];
  for (int index = 0; index < contents.length; index++) {
    final content = contents[index];
    if (!nextSensitiveIndexes.contains(index) && content.isNotEmpty && isSensitive(index, content)) {
      nextSensitiveIndexes.add(index);
    }
    filteredContents.add(nextSensitiveIndexes.contains(index) ? replacement : content);
  }

  return (
    contents: List<String>.unmodifiable(filteredContents),
    sensitiveIndexes: Set<int>.unmodifiable(nextSensitiveIndexes),
  );
}

String? findSensitiveFilterMatch(SensitiveFilterMatchPayload payload) {
  if (payload.index.isEmpty) return null;

  final scanResult = _scanTextWithPatternIndex(
    index: payload.index,
    text: payload.text,
  );
  final plainMatch = _findPlainWordMatch(
    index: payload.index,
    scanResult: scanResult,
  );
  if (plainMatch != null) return plainMatch;

  final unorderedMatch = _findUnorderedCompoundMatch(
    index: payload.index,
    scanResult: scanResult,
  );
  if (unorderedMatch != null) return unorderedMatch;

  return _findOrderedCompoundMatch(
    index: payload.index,
    scanResult: scanResult,
  );
}

String? findSensitiveFilterMatchInWindows(SensitiveFilterWindowMatchPayload payload) {
  if (payload.maxLength <= 0) return null;
  if (payload.index.isEmpty) return null;

  final scanResult = _scanTextWithPatternIndex(
    index: payload.index,
    text: payload.text,
  );
  final plainMatch = _findPlainWordMatch(
    index: payload.index,
    scanResult: scanResult,
  );
  if (plainMatch != null) return plainMatch;

  if (payload.text.length <= payload.maxLength) {
    final unorderedMatch = _findUnorderedCompoundMatch(
      index: payload.index,
      scanResult: scanResult,
    );
    if (unorderedMatch != null) return unorderedMatch;

    return _findOrderedCompoundMatch(
      index: payload.index,
      scanResult: scanResult,
    );
  }

  final unorderedWindowMatch = _findUnorderedCompoundWindowMatch(
    index: payload.index,
    maxLength: payload.maxLength,
    scanResult: scanResult,
  );
  if (unorderedWindowMatch != null) return unorderedWindowMatch;

  return _findOrderedCompoundWindowMatch(
    index: payload.index,
    maxLength: payload.maxLength,
    scanResult: scanResult,
  );
}

SensitiveFilterPatternIndex _buildSensitiveFilterPatternIndex({
  required List<List<String>> orderedCompoundRules,
  required List<String> plainWords,
  required List<List<String>> unorderedCompoundRules,
}) {
  final nodeBuilders = <_SensitiveFilterPatternNodeBuilder>[_SensitiveFilterPatternNodeBuilder()];
  final patternIdsByText = <String, int>{};
  final patternLengths = <int>[];
  final patterns = <String>[];

  int ensurePattern(String pattern) {
    final existing = patternIdsByText[pattern];
    if (existing != null) return existing;

    final patternId = patterns.length;
    patterns.add(pattern);
    patternLengths.add(pattern.length);
    patternIdsByText[pattern] = patternId;

    int nodeIndex = 0;
    for (int index = 0; index < pattern.length; index++) {
      final codeUnit = pattern.codeUnitAt(index);
      final nextNodeIndex = nodeBuilders[nodeIndex].transitions[codeUnit];
      if (nextNodeIndex != null) {
        nodeIndex = nextNodeIndex;
        continue;
      }

      final createdNodeIndex = nodeBuilders.length;
      nodeBuilders.add(_SensitiveFilterPatternNodeBuilder());
      nodeBuilders[nodeIndex].transitions[codeUnit] = createdNodeIndex;
      nodeIndex = createdNodeIndex;
    }
    nodeBuilders[nodeIndex].outputs.add(patternId);
    return patternId;
  }

  final plainPatternIds = <int>[];
  for (final plainWord in plainWords) {
    plainPatternIds.add(ensurePattern(plainWord));
  }

  final unorderedRules = <SensitiveFilterCompiledRule>[];
  for (final rule in unorderedCompoundRules) {
    final patternIds = <int>[];
    for (final part in rule) {
      patternIds.add(ensurePattern(part));
    }
    unorderedRules.add(
      SensitiveFilterCompiledRule(
        patternIds: List<int>.unmodifiable(patternIds),
        text: rule.join(sensitiveFilterCompoundSeparator),
      ),
    );
  }

  final orderedRules = <SensitiveFilterCompiledRule>[];
  for (final rule in orderedCompoundRules) {
    final patternIds = <int>[];
    for (final part in rule) {
      patternIds.add(ensurePattern(part));
    }
    orderedRules.add(
      SensitiveFilterCompiledRule(
        patternIds: List<int>.unmodifiable(patternIds),
        text: rule.join(sensitiveFilterCompoundSeparator),
      ),
    );
  }

  _buildFailureLinks(nodeBuilders);

  final nodes = <SensitiveFilterPatternNode>[];
  for (final node in nodeBuilders) {
    nodes.add(
      SensitiveFilterPatternNode(
        failure: node.failure,
        outputs: List<int>.unmodifiable(node.outputs),
        transitions: Map<int, int>.unmodifiable(node.transitions),
      ),
    );
  }

  return SensitiveFilterPatternIndex(
    nodes: List<SensitiveFilterPatternNode>.unmodifiable(nodes),
    orderedRules: List<SensitiveFilterCompiledRule>.unmodifiable(orderedRules),
    patternLengths: List<int>.unmodifiable(patternLengths),
    patterns: List<String>.unmodifiable(patterns),
    plainPatternIds: List<int>.unmodifiable(plainPatternIds),
    unorderedRules: List<SensitiveFilterCompiledRule>.unmodifiable(unorderedRules),
  );
}

void _buildFailureLinks(List<_SensitiveFilterPatternNodeBuilder> nodes) {
  final queue = <int>[];
  for (final childIndex in nodes.first.transitions.values) {
    nodes[childIndex].failure = 0;
    queue.add(childIndex);
  }

  int head = 0;
  while (head < queue.length) {
    final currentIndex = queue[head];
    head++;

    final transitions = nodes[currentIndex].transitions.entries.toList(growable: false);
    for (final transition in transitions) {
      final codeUnit = transition.key;
      final targetIndex = transition.value;
      int failureIndex = nodes[currentIndex].failure;
      while (failureIndex != 0 && !nodes[failureIndex].transitions.containsKey(codeUnit)) {
        failureIndex = nodes[failureIndex].failure;
      }

      nodes[targetIndex].failure = nodes[failureIndex].transitions[codeUnit] ?? 0;
      nodes[targetIndex].outputs.addAll(nodes[nodes[targetIndex].failure].outputs);
      queue.add(targetIndex);
    }
  }
}

_SensitiveFilterScanResult _scanTextWithPatternIndex({
  required SensitiveFilterPatternIndex index,
  required String text,
}) {
  final occurrencesByPattern = List<List<_SensitiveFilterTextOccurrence>?>.filled(
    index.patterns.length,
    null,
  );
  if (index.nodes.isEmpty) {
    return _SensitiveFilterScanResult(occurrencesByPattern: occurrencesByPattern);
  }

  int nodeIndex = 0;
  for (int cursor = 0; cursor < text.length; cursor++) {
    final codeUnit = text.codeUnitAt(cursor);
    while (nodeIndex != 0 && !index.nodes[nodeIndex].transitions.containsKey(codeUnit)) {
      nodeIndex = index.nodes[nodeIndex].failure;
    }

    nodeIndex = index.nodes[nodeIndex].transitions[codeUnit] ?? 0;
    final outputs = index.nodes[nodeIndex].outputs;
    if (outputs.isEmpty) continue;

    final end = cursor + 1;
    for (final patternId in outputs) {
      final start = end - index.patternLengths[patternId];
      final occurrences = occurrencesByPattern[patternId] ?? <_SensitiveFilterTextOccurrence>[];
      occurrences.add(_SensitiveFilterTextOccurrence(end: end, start: start));
      occurrencesByPattern[patternId] = occurrences;
    }
  }

  return _SensitiveFilterScanResult(occurrencesByPattern: occurrencesByPattern);
}

String? _findPlainWordMatch({
  required SensitiveFilterPatternIndex index,
  required _SensitiveFilterScanResult scanResult,
}) {
  for (final patternId in index.plainPatternIds) {
    if (!scanResult.hasPattern(patternId)) continue;
    return index.patterns[patternId];
  }
  return null;
}

String? _findUnorderedCompoundMatch({
  required SensitiveFilterPatternIndex index,
  required _SensitiveFilterScanResult scanResult,
}) {
  for (final rule in index.unorderedRules) {
    if (!_doesRuleContainEveryPattern(rule: rule, scanResult: scanResult)) continue;
    return rule.text;
  }
  return null;
}

String? _findOrderedCompoundMatch({
  required SensitiveFilterPatternIndex index,
  required _SensitiveFilterScanResult scanResult,
}) {
  for (final rule in index.orderedRules) {
    if (!_doesOrderedRuleMatch(rule: rule, scanResult: scanResult)) continue;
    return rule.text;
  }
  return null;
}

String? _findUnorderedCompoundWindowMatch({
  required SensitiveFilterPatternIndex index,
  required int maxLength,
  required _SensitiveFilterScanResult scanResult,
}) {
  for (final rule in index.unorderedRules) {
    if (!_doesUnorderedRuleMatchInWindow(maxLength: maxLength, rule: rule, scanResult: scanResult)) continue;
    return rule.text;
  }
  return null;
}

String? _findOrderedCompoundWindowMatch({
  required SensitiveFilterPatternIndex index,
  required int maxLength,
  required _SensitiveFilterScanResult scanResult,
}) {
  for (final rule in index.orderedRules) {
    if (!_doesOrderedRuleMatch(maxLength: maxLength, rule: rule, scanResult: scanResult)) continue;
    return rule.text;
  }
  return null;
}

bool _shouldCompoundRuleBeOrdered(List<String> rule) {
  for (final part in rule) {
    if (part.length == 1) continue;
    return false;
  }
  return true;
}

bool _doesRuleContainEveryPattern({
  required SensitiveFilterCompiledRule rule,
  required _SensitiveFilterScanResult scanResult,
}) {
  for (final patternId in rule.patternIds) {
    if (scanResult.hasPattern(patternId)) continue;
    return false;
  }
  return true;
}

bool _doesUnorderedRuleMatchInWindow({
  required int maxLength,
  required SensitiveFilterCompiledRule rule,
  required _SensitiveFilterScanResult scanResult,
}) {
  final occurrenceLists = <List<_SensitiveFilterTextOccurrence>>[];
  for (final patternId in rule.patternIds) {
    final occurrences = scanResult.occurrencesByPattern[patternId];
    if (occurrences == null || occurrences.isEmpty) return false;
    occurrenceLists.add(occurrences);
  }

  if (occurrenceLists.length == 2) {
    return _doesTwoPartUnorderedRuleMatchInWindow(
      firstOccurrences: occurrenceLists[0],
      maxLength: maxLength,
      secondOccurrences: occurrenceLists[1],
    );
  }

  final occurrences = <_SensitiveFilterOccurrence>[];
  for (int partIndex = 0; partIndex < occurrenceLists.length; partIndex++) {
    for (final occurrence in occurrenceLists[partIndex]) {
      occurrences.add(
        _SensitiveFilterOccurrence(
          end: occurrence.end,
          partIndex: partIndex,
          start: occurrence.start,
        ),
      );
    }
  }
  occurrences.sort((a, b) => a.start.compareTo(b.start));
  return _doesMergedOccurrenceMatchInWindow(
    maxLength: maxLength,
    occurrences: occurrences,
    partCount: occurrenceLists.length,
  );
}

bool _doesTwoPartUnorderedRuleMatchInWindow({
  required List<_SensitiveFilterTextOccurrence> firstOccurrences,
  required int maxLength,
  required List<_SensitiveFilterTextOccurrence> secondOccurrences,
}) {
  int firstIndex = 0;
  int secondIndex = 0;
  while (firstIndex < firstOccurrences.length && secondIndex < secondOccurrences.length) {
    final first = firstOccurrences[firstIndex];
    final second = secondOccurrences[secondIndex];
    final windowStart = first.start <= second.start ? first.start : second.start;
    final windowEnd = first.end >= second.end ? first.end : second.end;
    if (windowEnd - windowStart <= maxLength) return true;

    if (first.start <= second.start) {
      firstIndex++;
      continue;
    }
    secondIndex++;
  }
  return false;
}

bool _doesMergedOccurrenceMatchInWindow({
  required int maxLength,
  required List<_SensitiveFilterOccurrence> occurrences,
  required int partCount,
}) {
  final counts = List<int>.filled(partCount, 0);
  final maxEndQueue = <int>[];
  int maxEndQueueHead = 0;
  int coveredParts = 0;
  int left = 0;

  for (int right = 0; right < occurrences.length; right++) {
    final rightOccurrence = occurrences[right];
    if (counts[rightOccurrence.partIndex] == 0) coveredParts++;
    counts[rightOccurrence.partIndex]++;

    while (maxEndQueue.length > maxEndQueueHead && occurrences[maxEndQueue.last].end <= rightOccurrence.end) {
      maxEndQueue.removeLast();
    }
    maxEndQueue.add(right);

    while (coveredParts == partCount && left <= right) {
      while (maxEndQueue.length > maxEndQueueHead && maxEndQueue[maxEndQueueHead] < left) {
        maxEndQueueHead++;
      }
      final windowStart = occurrences[left].start;
      final windowEnd = occurrences[maxEndQueue[maxEndQueueHead]].end;
      if (windowEnd - windowStart <= maxLength) return true;

      final leftOccurrence = occurrences[left];
      counts[leftOccurrence.partIndex]--;
      if (counts[leftOccurrence.partIndex] == 0) coveredParts--;
      left++;
    }
  }

  return false;
}

bool _doesOrderedRuleMatch({
  int? maxLength,
  required SensitiveFilterCompiledRule rule,
  required _SensitiveFilterScanResult scanResult,
}) {
  final firstOccurrences = scanResult.occurrencesByPattern[rule.patternIds.first];
  if (firstOccurrences == null || firstOccurrences.isEmpty) return false;

  for (final firstOccurrence in firstOccurrences) {
    int searchStart = firstOccurrence.end;
    int windowEnd = firstOccurrence.end;
    bool matched = true;

    for (int index = 1; index < rule.patternIds.length; index++) {
      final occurrences = scanResult.occurrencesByPattern[rule.patternIds[index]];
      if (occurrences == null || occurrences.isEmpty) {
        matched = false;
        break;
      }

      final occurrence = _firstOccurrenceStartingAtOrAfter(
        occurrences: occurrences,
        start: searchStart,
      );
      if (occurrence == null) {
        matched = false;
        break;
      }

      windowEnd = occurrence.end;
      searchStart = occurrence.end;
    }

    if (!matched) continue;
    if (maxLength == null) return true;
    if (windowEnd - firstOccurrence.start <= maxLength) return true;
  }

  return false;
}

_SensitiveFilterTextOccurrence? _firstOccurrenceStartingAtOrAfter({
  required List<_SensitiveFilterTextOccurrence> occurrences,
  required int start,
}) {
  int left = 0;
  int right = occurrences.length;
  while (left < right) {
    final middle = (left + right) ~/ 2;
    if (occurrences[middle].start < start) {
      left = middle + 1;
      continue;
    }
    right = middle;
  }
  if (left >= occurrences.length) return null;
  return occurrences[left];
}
