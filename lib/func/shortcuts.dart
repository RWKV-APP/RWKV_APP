import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef FV = Future<void>;
typedef JSON = Map<String, dynamic>;

typedef AO = AnimatedOpacity;
typedef AP = AnimatedPositioned;
typedef BD = BoxDecoration;
typedef BR = BorderRadius;
typedef C = Container;
typedef CAA = CrossAxisAlignment;
typedef FW = FontWeight;
typedef GD = GestureDetector;
typedef ID = InputDecoration;
typedef MAA = MainAxisAlignment;
typedef SB = SizedBox;

const kW = Colors.white;
const kB = Colors.black;
const kG = Color(0xFF808080);
const kC = Colors.transparent;
const kCR = Colors.red;
const kCB = Colors.blue;
const kCG = Colors.green;
const kCY = Colors.yellow;

void _logTrace({
  String header = "💬",
  Object? message,
  int i = 2,
}) {
  if (!kDebugMode) return;
  final frames = StackTrace.current.toString().trimRight().split("\n");
  final rawFrame = frames.length > i ? frames[i] : frames.last;
  final memberMatch = RegExp(r'^\s*#\d+\s+(.+?)(?: \(|$)').firstMatch(rawFrame);
  final member = memberMatch?.group(1)?.trim() ?? rawFrame.trim();
  if (message == null) {
    debugPrint("$header $member");
    return;
  }
  debugPrint("$header $member $message");
}

void get qq {
  _logTrace(header: "💬");
}

void get qw {
  _logTrace(header: "🚧");
}

void get qe {
  _logTrace(header: "😡");
}

void get qr {
  _logTrace(header: "✅");
}

void qqq(Object? message) {
  _logTrace(header: "💬", message: message);
}

void qqw(Object? message) {
  _logTrace(header: "🚧", message: message);
}

void qqe(Object? message) {
  _logTrace(header: "😡", message: message);
}

void qqr(Object? message) {
  _logTrace(header: "✅", message: message);
}

abstract class HF {
  static late final int _initTimeS;
  static late final int _initTimeMS;
  static late final int _initTimeUS;

  static final _rnd = math.Random();
  static const _chars = "AaBbCcDdEeeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890";
  static final _codeSpacing = " ".codeUnits[0];

  static final number = _Number();
  static final random = _Random();

  static void init() {
    _initTimeS = HF.seconds;
    _initTimeMS = HF.milliseconds;
    _initTimeUS = HF.microseconds;
  }

  static Future<void> wait(int ms) {
    return Future.delayed(Duration(milliseconds: ms));
  }

  static List<Map<dynamic, dynamic>> listMap(Object? object) {
    try {
      return list(object).mv;
    } catch (e) {
      throw "shortcuts: element in list is not Map";
    }
  }

  static List<JSON> listJSON(Object? object) {
    try {
      return list(object).jv;
    } catch (e) {
      throw "shortcuts: element in list is not JSON";
    }
  }

  static JSON json(Map<dynamic, dynamic> object) {
    try {
      final result = object.map((k, v) => MapEntry(k.toString(), v));
      return result;
    } catch (e) {
      throw "shortcuts: target is not JSON:\n$e\n$object";
    }
  }

  static List<JSON> jsonArray(Object? object) {
    try {
      final result = listMap(object).map((e) => json(e));
      return result.toList();
    } catch (e) {
      throw "shortcuts: target is not JSON Array:\n$e\n$object";
    }
  }

  static List<dynamic> list(Object? object) {
    try {
      return object as List<dynamic>;
    } catch (e) {
      throw "shortcuts: target is not List:\n$e\n$object";
    }
  }

  static int randomInt({
    int min = 1,
    int max = 9999999,
  }) {
    return _rnd.nextInt(max - min + 1) + min;
  }

  static int randomMax(int max) {
    return _rnd.nextInt(max + 1);
  }

  static String randomString({
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
    final length = fixed ? effectiveMin : _rnd.nextInt(effectiveMax - effectiveMin) + effectiveMin;
    final enableSpaceTrimming = length >= 2;
    bool previousUseSpace = false;
    final codes = Iterable.generate(length, (index) {
      final isHead = index == 0;
      final isTail = index == length - 1;
      final useSpace = !previousUseSpace && _rnd.nextDouble() < effectiveSpacingRate;
      previousUseSpace = useSpace;
      if (useSpace && enableSpaceTrimming && !isHead && !isTail) return _codeSpacing;
      if (useSpace && !enableSpaceTrimming) return _codeSpacing;
      return _chars.codeUnitAt(_rnd.nextInt(_chars.length));
    });

    return String.fromCharCodes(codes);
  }

  static bool randomBool({double truePercentage = 0.5}) {
    if (truePercentage == 0.5) return _rnd.nextBool();
    final percentage = math.max(0.0, math.min(1.0, truePercentage));
    return _rnd.nextDouble() < percentage;
  }

  static int get microseconds => DateTime.now().microsecondsSinceEpoch;

  static int get milliseconds => DateTime.now().millisecondsSinceEpoch;

  static int get seconds => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  static int get shorterUS => microseconds - _initTimeUS;

  static int get shorterMS => milliseconds - _initTimeMS;

  static int get shorterS => seconds - _initTimeS;

  static int get debugShorterUS => kDebugMode ? shorterUS : microseconds;

  static int get debugShorterMS => kDebugMode ? shorterMS : milliseconds;

  static int get debugShorterS => kDebugMode ? shorterS : seconds;
}

class _Number {
  num? from(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    throw "shortcuts: target is not Number:\n$value";
  }
}

class _Random {
  final color = _RandomColor();
}

class _RandomColor {
  static final _rnd = math.Random();

  Color get q => Color.fromARGB(
    _rnd.nextInt(0xFF),
    _rnd.nextInt(0xFF),
    _rnd.nextInt(0xFF),
    _rnd.nextInt(0xFF),
  );

  Color get vivid {
    final channel = _rnd.nextInt(3);
    final dim = _rnd.nextInt(2);
    late final int r;
    late final int g;
    late final int b;
    final dynamicValue = _rnd.nextInt(0xFF);

    if (channel == 0) {
      if (dim == 0) {
        r = 0xFF;
        g = 0x00;
        b = dynamicValue;
      } else {
        r = 0xFF;
        g = dynamicValue;
        b = 0x00;
      }
    } else if (channel == 1) {
      if (dim == 0) {
        r = 0x00;
        g = 0xFF;
        b = dynamicValue;
      } else {
        r = dynamicValue;
        g = 0xFF;
        b = 0x00;
      }
    } else {
      if (dim == 0) {
        r = 0x00;
        g = dynamicValue;
        b = 0xFF;
      } else {
        r = dynamicValue;
        g = 0x00;
        b = 0xFF;
      }
    }

    return Color.fromARGB(0xFF, r, g, b);
  }
}

class Debouncer {
  final int milliseconds;
  void Function()? _action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void call(void Function() action) {
    final duration = Duration(milliseconds: milliseconds);
    _timer?.cancel();
    _action = action;
    _timer = Timer(duration, () {
      _action?.call();
    });
  }
}

class Throttler {
  final int milliseconds;
  final bool trailing;
  Function? _pendingCall;
  Timer? _timer;
  bool _isReady = true;

  Throttler({required this.milliseconds, this.trailing = false});

  Throttler.ms(this.milliseconds, {this.trailing = false});

  Throttler.duration(Duration duration, {this.trailing = false}) : milliseconds = duration.inMilliseconds;

  void call(Function action) {
    if (_isReady) {
      _isReady = false;
      action();
      _timer = Timer(Duration(milliseconds: milliseconds), _onTimerComplete);
      return;
    }
    if (!trailing) return;
    _pendingCall = action;
  }

  void _onTimerComplete() {
    _isReady = true;
    if (!trailing) return;
    if (_pendingCall == null) return;
    final pendingCall = _pendingCall;
    _pendingCall = null;
    _isReady = false;
    pendingCall!();
    _timer = Timer(Duration(milliseconds: milliseconds), _onTimerComplete);
  }

  void cancel() {
    _timer?.cancel();
    _pendingCall = null;
    _isReady = true;
  }
}

extension ShortcutDartNumT<T extends num> on T {
  T squeeze(T min, T max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

extension ShortcutDartNum on num {
  String get withoutZero => toString().withoutZero;

  Duration get ms => Duration(milliseconds: toInt());
}

extension ShortcutDartInt on int {
  int get withoutNegative => math.max(0, this);
}

extension ShortcutDartDouble on double {
  double get withoutNegative => math.max(0.0, this);
}

extension ShortcutDartIterable<T> on Iterable<T> {
  List<R> indexMap<R>(
    R Function(int index, T value) convert, {
    bool growable = false,
  }) => toList(growable: growable).indexMap(convert, growable: growable);

  List<R> m<R>(
    R Function(T value) convert, {
    bool growable = false,
  }) => toList(growable: growable).m(convert, growable: growable);

  T? get(int? index) {
    if (index == null) return null;
    if (isEmpty) return null;
    if (length <= index) return null;
    if (this is List<T>) return (this as List<T>)[index];
    return toList(growable: false)[index];
  }

  T? get random {
    if (isEmpty) return null;
    if (length == 1) return first;
    final index = HF.randomInt(min: 0, max: length - 1);
    return get(index);
  }

  Iterable<T> randomCount(int count) {
    final copy = List<T>.from(this)..shuffle();
    return copy.take(count);
  }
}

extension ShortcutDartList<T> on List<T> {
  List<R> indexMap<R>(
    R Function(int index, T value) convert, {
    bool growable = false,
  }) {
    final result = <R>[];
    for (int index = 0; index < length; index++) {
      result.add(convert(index, this[index]));
    }
    if (growable) return result;
    return List<R>.of(result, growable: false);
  }

  List<R> m<R>(
    R Function(T value) convert, {
    bool growable = false,
  }) {
    final result = <R>[];
    for (final value in this) {
      result.add(convert(value));
    }
    if (growable) return result;
    return List<R>.of(result, growable: false);
  }

  void removeFirstWhere(bool Function(T element) test) {
    for (final element in this) {
      if (!test(element)) continue;
      remove(element);
      return;
    }
  }

  List<Map<dynamic, dynamic>> get mv {
    try {
      return map((e) => e as Map<dynamic, dynamic>).toList();
    } catch (e) {
      throw "shortcuts: element is not Map";
    }
  }

  List<JSON> get jv {
    try {
      return mv.m((e) => e.map((k, v) => MapEntry(k.toString(), v)));
    } catch (e) {
      throw "shortcuts: element is not Map";
    }
  }

  String get formatedJSONString {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(this);
  }

  List<T> get shuffled => [...(this..shuffle())];

  List<T> withoutIndex(int index) {
    final result = [...this];
    if (index < 0 || index >= length) return result;
    result.removeAt(index);
    return result;
  }
}

extension ShortcutDartListNull<T> on List<T?> {
  List<T> get withoutNull {
    final values = where((e) => e != null).m((e) => e!);
    return [...values];
  }
}

extension ShortcutDartListString on List<String> {
  List<String> get longestParentString {
    final wantedKeys = [...this];
    for (int i = 0; i < length; i++) {
      final keyInTotal = this[i];
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
}

extension ShortcutDartMap<K, V> on Map<K, V> {
  List<V> get v => values.toList();

  List<K> get k => keys.toList();

  List<R> indexMap<R>(
    R Function(K key, V value) convert, {
    bool growable = false,
  }) {
    final result = <R>[];
    for (final entry in entries) {
      result.add(convert(entry.key, entry.value));
    }
    if (growable) return result;
    return List<R>.of(result, growable: false);
  }

  Map<String, String> get allString {
    final result = <String, String>{};
    for (final entry in entries) {
      result[entry.key.toString()] = entry.value.toString();
    }
    return result;
  }

  Map<K, V> get withoutNull {
    final result = <K, V>{};
    for (final key in keys) {
      if (this[key] == null) continue;
      result[key] = this[key] as V;
    }
    return result;
  }

  Map<K, V> get trim {
    final result = <K, V>{};
    for (final key in keys) {
      final value = this[key] as V;
      if (value is String) {
        result[key] = value.trim() as V;
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  Map<K, V> get sorted {
    final sorted = SplayTreeMap<K, V>.from(this);
    final result = Map<K, V>.fromEntries(sorted.entries);
    final deepResult = <K, V>{};
    for (final entry in result.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map) {
        deepResult[key] = value.debugSorted as V;
      } else if (value is List) {
        final deepList = <dynamic>[];
        for (final element in value) {
          if (element is Map) {
            deepList.add(element.debugSorted);
          } else {
            deepList.add(element);
          }
        }
        deepResult[key] = deepList as V;
      } else {
        deepResult[key] = value;
      }
    }
    return deepResult;
  }

  Map<K, V> get debugSorted {
    if (!kDebugMode) return this;
    return sorted;
  }

  String get formatedJSONString {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(this);
  }
}

extension ShortcutDartString on String {
  String get withoutZero {
    if (endsWith(".0")) return substring(0, length - 2);
    if (endsWith(".00")) return substring(0, length - 3);
    return this;
  }

  String get withoutNonAlphabets {
    final regExp = RegExp("[^a-zA-Z0-9]");
    return replaceAll(regExp, "");
  }

  String get withoutAlphabets {
    final regExp = RegExp("[a-zA-Z0-9]");
    return replaceAll(regExp, "");
  }

  List<String> scatter({int minLength = 1}) {
    final subSequence = <String>[];
    if (length <= minLength) return [this];
    final iBias = minLength - 1;
    for (int i = 0; i < length; i++) {
      for (int j = length; j > i + iBias; j--) {
        final sub = substring(i, j);
        subSequence.add(sub);
      }
    }
    return subSequence;
  }

  String get codeToName {
    if (isEmpty) return "";

    String formatted = this;
    while (formatted.contains("__")) {
      formatted = formatted.replaceAll("__", "_");
    }

    formatted = formatted.replaceAllMapped(RegExp(r'_([a-z])'), (match) {
      return ' ${match[1]!.toUpperCase()}';
    });

    formatted = formatted.replaceAllMapped(RegExp(r'([A-z])_'), (match) {
      return '${match[1]} ';
    });

    formatted = formatted.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
      return '${match[1]} ${match[2]}';
    });

    formatted = formatted.replaceAllMapped(RegExp(r'([A-Z])([A-Z])([a-z])'), (match) {
      return '${match[1]} ${match[2]}${match[3]}';
    });

    formatted = formatted
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');

    return formatted;
  }

  List<String> get allCaseCombinations {
    final result = <String>[];

    void backtrack(String current, int index) {
      if (index == length) {
        result.add(current);
        return;
      }

      backtrack(current + this[index].toLowerCase(), index + 1);
      backtrack(current + this[index].toUpperCase(), index + 1);
    }

    backtrack('', 0);
    return result;
  }

  bool get containChinese {
    final chineseRegex = RegExp(r'[\u4E00-\u9FFF]');
    return chineseRegex.hasMatch(this);
  }

  bool get isEng {
    if (isEmpty) return false;
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  Set<String> get allIsolatedChars {
    final result = <String>{};
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
    }
    return result;
  }
}

extension ShortcutNumT<T extends num> on T {
  BorderRadius get r => BorderRadius.circular(toDouble());

  Radius get rr => Radius.circular(toDouble());

  SB get h => SB(height: toDouble());

  SB get w => SB(width: toDouble());

  double get dv => toDouble();
}

extension ShortcutColor on Color {
  Color q(double alpha) => withValues(alpha: alpha);
}

extension ShortcutListWidget on List<Widget> {
  List<Widget> widgetJoin(Widget Function(int previousIndex) convert) {
    final result = <Widget>[];
    final itemCount = length;
    for (int i = 0; i < itemCount; i++) {
      result.add(this[i]);
      if (i >= itemCount - 1) continue;
      result.add(convert(i));
    }
    return result;
  }
}

extension ShortcutListSpan on List<InlineSpan> {
  List<InlineSpan> spanJoin(InlineSpan Function(int previousIndex) convert) {
    final result = <InlineSpan>[];
    final itemCount = length;
    for (int i = 0; i < itemCount; i++) {
      result.add(this[i]);
      if (i >= itemCount - 1) continue;
      result.add(convert(i));
    }
    return result;
  }
}

class EI extends EdgeInsets {
  static const EI zero = EI.a(0);

  const EI.s({
    double? h,
    double? v,
    double l = 0.0,
    double t = 0.0,
  }) : super.symmetric(vertical: v ?? l, horizontal: h ?? t);

  const EI.o({
    double? l,
    double? t,
    double? r,
    double? b,
    double h = 0.0,
    double v = 0.0,
  }) : super.only(
         left: l ?? h,
         right: r ?? h,
         top: t ?? v,
         bottom: b ?? v,
       );

  const EI.f(
    super.l,
    super.t,
    super.r,
    super.b,
  ) : super.fromLTRB();

  const EI.a(super.value) : super.all();
}

class T extends Text {
  static const String kNullText = kDebugMode ? "debug:null" : "";

  const T(
    String? data, {
    super.key,
    TextStyle? s,
    super.textAlign,
    super.softWrap,
    super.maxLines,
    super.overflow,
    super.strutStyle,
    super.textDirection,
    super.locale,
    super.textScaler,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  }) : super(
         data ?? kNullText,
         style: s,
       );
}

class TS extends TextStyle {
  const TS({
    double? s,
    Color? c,
    FontWeight? w,
    String? ff,
    TextBaseline? baseline,
    super.background,
    super.decoration,
    super.fontFeatures,
    super.fontStyle,
    super.foreground,
    super.height,
    super.letterSpacing,
    super.shadows,
    super.wordSpacing,
  }) : super(
         color: c,
         fontFamily: ff,
         fontSize: s,
         fontWeight: w,
         textBaseline: baseline,
       );
}

class MeasureSize extends SingleChildRenderObjectWidget {
  final void Function(Size size) onChange;

  const MeasureSize({
    super.key,
    required this.onChange,
    required Widget super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  Size? oldSize;
  void Function(Size size) onChange;

  _MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child!.size;
    if (oldSize == newSize) return;
    oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}
