import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Exercise the pinned Windows implementation, including its native channel.
// ignore: depend_on_referenced_packages, implementation_imports
import 'package:flutter_inappwebview_windows/src/in_app_webview/custom_platform_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a WebView disposed during native creation releases the late view', (tester) async {
    final created = Completer<int>();
    final messenger = tester.binding.defaultBinaryMessenger;
    const manager = MethodChannel('com.pichillilorenzo/flutter_inappwebview_manager');
    const events = MethodChannel('com.pichillilorenzo/custom_platform_view_42_events');
    int callbacks = 0;
    final released = <int>[];
    messenger.setMockMethodCallHandler(manager, (call) async {
      if (call.method == 'createInAppWebView') return created.future;
      if (call.method == 'dispose') {
        released.add((call.arguments as Map)['id'] as int);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(events, (_) async => null);
    addTearDown(() {
      messenger.setMockMethodCallHandler(manager, null);
      messenger.setMockMethodCallHandler(events, null);
    });

    await tester.pumpWidget(MaterialApp(home: CustomPlatformView(onPlatformViewCreated: (_) => callbacks++)));
    await tester.pumpWidget(const SizedBox.shrink());
    created.complete(42);
    await tester.pumpAndSettle();
    // EventChannel cancellation acknowledges on the real platform-message queue.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(callbacks, 0);
    expect(released, [42]);
  });
}
