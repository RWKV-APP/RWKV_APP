import 'dart:collection';
import 'dart:convert';

T clampComparable<T extends num>(T value, T min, T max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

List<R> mapIndexed<T, R>(
  Iterable<T> values,
  R Function(int index, T value) convert, {
  bool growable = false,
}) {
  final result = <R>[];
  int index = 0;
  for (final value in values) {
    result.add(convert(index, value));
    index++;
  }
  if (growable) return result;
  return List<R>.of(result, growable: false);
}

List<R> mapFixed<T, R>(
  Iterable<T> values,
  R Function(T value) convert, {
  bool growable = false,
}) {
  final result = <R>[];
  for (final value in values) {
    result.add(convert(value));
  }
  if (growable) return result;
  return List<R>.of(result, growable: false);
}

T? elementAtOrNull<T>(Iterable<T> values, int? index) {
  if (index == null) return null;
  if (values.isEmpty) return null;
  if (values.length <= index) return null;
  return values.elementAt(index);
}

void removeFirstMatching<T>(List<T> values, bool Function(T element) test) {
  for (final element in values) {
    if (!test(element)) continue;
    values.remove(element);
    return;
  }
}

String prettyJson(Object? value) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(value);
}

List<T> shuffledList<T>(Iterable<T> values) {
  return List<T>.of(values)..shuffle();
}

List<T> listWithoutIndex<T>(List<T> values, int index) {
  final result = [...values];
  if (index < 0 || index >= values.length) return result;
  result.removeAt(index);
  return result;
}

List<T> nonNullList<T>(Iterable<T?> values) {
  return values.whereType<T>().toList();
}

List<String> longestParentStrings(List<String> values) {
  final wantedKeys = [...values];
  for (int i = 0; i < values.length; i++) {
    final keyInTotal = values[i];
    if (!wantedKeys.contains(keyInTotal)) continue;
    if (keyInTotal.length < 2) continue;
    final needToRemove = <String>[];
    for (int j = 0; j < wantedKeys.length; j++) {
      final keyInWanted = wantedKeys[j];
      if (!keyInTotal.contains(keyInWanted)) continue;
      if (keyInTotal == keyInWanted) continue;
      needToRemove.add(keyInWanted);
    }
    for (final element in needToRemove) {
      wantedKeys.remove(element);
    }
  }

  return wantedKeys;
}

Map<String, String> stringifyMapValues(Map<dynamic, dynamic> values) {
  final result = <String, String>{};
  for (final entry in values.entries) {
    result[entry.key.toString()] = entry.value.toString();
  }
  return result;
}

Map<K, V> withoutNullValues<K, V>(Map<K, V?> values) {
  final result = <K, V>{};
  for (final entry in values.entries) {
    final value = entry.value;
    if (value == null) continue;
    result[entry.key] = value;
  }
  return result;
}

Map<K, V> trimStringValues<K, V>(Map<K, V> values) {
  final result = <K, V>{};
  for (final entry in values.entries) {
    final value = entry.value;
    if (value is String) {
      result[entry.key] = value.trim() as V;
      continue;
    }
    result[entry.key] = value;
  }
  return result;
}

Map<K, V> deepSortedMap<K, V>(Map<K, V> values) {
  final sorted = SplayTreeMap<K, V>.from(values);
  final result = Map<K, V>.fromEntries(sorted.entries);
  final deepResult = <K, V>{};
  for (final entry in result.entries) {
    final key = entry.key;
    final value = entry.value;
    if (value is Map) {
      deepResult[key] = deepSortedMap(value) as V;
      continue;
    }
    if (value is List) {
      final deepList = <dynamic>[];
      for (final element in value) {
        if (element is Map) {
          deepList.add(deepSortedMap(element));
          continue;
        }
        deepList.add(element);
      }
      deepResult[key] = deepList as V;
      continue;
    }
    deepResult[key] = value;
  }
  return deepResult;
}
