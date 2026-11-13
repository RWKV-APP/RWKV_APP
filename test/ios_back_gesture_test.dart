import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';

void main() {
  testWidgets('Pushed iOS page tracks the edge drag, cancels, and returns', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push<void>(PageKey.advancedSettings.path),
              child: const Text('Open settings'),
            ),
          ),
        ),
        PageKey.advancedSettings.route,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: rc,
        child: MaterialApp.router(routerConfig: router, localizationsDelegates: const [S.delegate]),
      ),
    );
    await tester.pumpAndSettle();

    final openSettings = find.text('Open settings');
    final title = find.text(S.current.advance_settings);
    await tester.tap(openSettings);
    await tester.pumpAndSettle();

    final initialX = tester.getTopLeft(title).dx;
    final shortDrag = await tester.startGesture(const Offset(5, 400));
    await shortDrag.moveBy(const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(title).dx, greaterThan(initialX));
    await shortDrag.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(title).dx, initialX);

    await tester.dragFrom(const Offset(5, 400), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(title, findsNothing);
    expect(openSettings, findsOneWidget);

    await tester.tap(openSettings);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(openSettings, findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
