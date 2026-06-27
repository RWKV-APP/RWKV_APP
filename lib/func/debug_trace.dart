// Flutter imports:
import 'package:flutter/foundation.dart';

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
