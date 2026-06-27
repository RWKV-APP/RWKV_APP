import 'dart:math' as math;

import 'package:flutter/material.dart';

final math.Random _random = math.Random();
const String _randomChars = "AaBbCcDdEeeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890";
final int _randomCodeSpacing = " ".codeUnits[0];

int randomInt({
  int min = 1,
  int max = 9999999,
}) {
  return _random.nextInt(max - min + 1) + min;
}

bool randomBool({double truePercentage = 0.5}) {
  if (truePercentage == 0.5) return _random.nextBool();
  final percentage = math.max(0.0, math.min(1.0, truePercentage));
  return _random.nextDouble() < percentage;
}

String randomString({
  int min = 1,
  int max = 2000,
  double spacingRate = 0.20,
  String? template,
}) {
  int effectiveMin = min;
  int effectiveMax = max;
  double effectiveSpacingRate = spacingRate;
  if (template != null && template.isNotEmpty) {
    effectiveMin = template.length;
    effectiveMax = template.length;
    final spaceCount = template.split(" ").length;
    effectiveSpacingRate = spaceCount / template.length;
  }
  final fixed = effectiveMax <= effectiveMin;
  final length = fixed ? effectiveMin : _random.nextInt(effectiveMax - effectiveMin) + effectiveMin;
  final enableSpaceTrimming = length >= 2;
  bool previousUseSpace = false;
  final codes = Iterable.generate(length, (index) {
    final isHead = index == 0;
    final isTail = index == length - 1;
    final useSpace = !previousUseSpace && _random.nextDouble() < effectiveSpacingRate;
    previousUseSpace = useSpace;
    if (useSpace && enableSpaceTrimming && !isHead && !isTail) return _randomCodeSpacing;
    if (useSpace && !enableSpaceTrimming) return _randomCodeSpacing;
    return _randomChars.codeUnitAt(_random.nextInt(_randomChars.length));
  });

  return String.fromCharCodes(codes);
}

T? randomElement<T>(Iterable<T> values) {
  if (values.isEmpty) return null;
  if (values.length == 1) return values.first;
  final index = randomInt(min: 0, max: values.length - 1);
  return values.elementAt(index);
}

Iterable<T> randomItems<T>(Iterable<T> values, int count) {
  final copy = List<T>.from(values)..shuffle();
  return copy.take(count);
}

Color randomColor() {
  return Color.fromARGB(
    _random.nextInt(0xFF),
    _random.nextInt(0xFF),
    _random.nextInt(0xFF),
    _random.nextInt(0xFF),
  );
}

Color vividRandomColor() {
  final channel = _random.nextInt(3);
  final dim = _random.nextInt(2);
  late final int r;
  late final int g;
  late final int b;
  final dynamicValue = _random.nextInt(0xFF);

  if (channel == 0) {
    if (dim == 0) {
      r = 0xFF;
      g = 0x00;
      b = dynamicValue;
      return Color.fromARGB(0xFF, r, g, b);
    }
    r = 0xFF;
    g = dynamicValue;
    b = 0x00;
    return Color.fromARGB(0xFF, r, g, b);
  }

  if (channel == 1) {
    if (dim == 0) {
      r = 0x00;
      g = 0xFF;
      b = dynamicValue;
      return Color.fromARGB(0xFF, r, g, b);
    }
    r = dynamicValue;
    g = 0xFF;
    b = 0x00;
    return Color.fromARGB(0xFF, r, g, b);
  }

  if (dim == 0) {
    r = 0x00;
    g = dynamicValue;
    b = 0xFF;
    return Color.fromARGB(0xFF, r, g, b);
  }
  r = dynamicValue;
  g = 0x00;
  b = 0xFF;
  return Color.fromARGB(0xFF, r, g, b);
}
