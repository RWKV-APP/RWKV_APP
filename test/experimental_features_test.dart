import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/experimental_features.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('paused reply guidance is disabled by default and persists when enabled', (tester) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await S.load(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
    P.app.theme.q = .light;
    P.app.qb.q = Colors.black;
    P.app.qw.q = Colors.white;
    P.preference.pausedReplyGuidanceEnabled.q = false;
    addTearDown(() {
      P.preference.pausedReplyGuidanceEnabled.q = false;
    });

    await tester.pumpWidget(
      StateWrapper(
        child: MaterialApp(
          locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const ExperimentalFeatures(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('实验性功能'), findsOneWidget);
    expect(find.text('暂停回答后的提问修正提示'), findsOneWidget);
    expect(P.preference.pausedReplyGuidanceEnabled.q, isFalse);

    await tester.tap(find.byKey(const ValueKey('paused-reply-guidance-experimental-switch')));
    await tester.pumpAndSettle();

    final sp = await SharedPreferences.getInstance();
    expect(P.preference.pausedReplyGuidanceEnabled.q, isTrue);
    expect(sp.getBool('halo_state.experimental.pausedReplyGuidanceEnabled'), isTrue);
  });
}
