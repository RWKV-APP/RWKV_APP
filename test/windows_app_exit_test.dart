import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/store/p.dart';

class _ExitingApp extends RawApp {
  final decision = Completer<ui.AppExitResponse>();

  @override
  BuildContext? get context => null;

  @override
  Future<ui.AppExitResponse> didRequestAppExit() => decision.future;
}

void main() {
  testWidgets('Windows close waits for lifecycle cleanup and preserves cancellation', (tester) async {
    const channel = 'com.rwkvzone.chat/lifecycle';
    const codec = StandardMessageCodec();
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMessageHandler(channel, null));
    for (final decision in ui.AppExitResponse.values) {
      final app = _ExitingApp();
      tester.binding.addObserver(app);
      app.registerWindowsExitHandler();
      final reply = Completer<Object?>();
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(channel, codec.encodeMessage('requestAppExit'), (data) {
        reply.complete(codec.decodeMessage(data));
      });
      await tester.pump();
      expect(reply.isCompleted, isFalse);
      app.decision.complete(decision);
      await tester.pump();
      expect(await reply.future, decision.name);
      tester.binding.removeObserver(app);
    }
    final invalidReply = Completer<Object?>();
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(channel, codec.encodeMessage('unrecognized'), (data) {
      invalidReply.complete(codec.decodeMessage(data));
    });
    await tester.pump();
    expect(await invalidReply.future, ui.AppExitResponse.cancel.name);
  });
}
