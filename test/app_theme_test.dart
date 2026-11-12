import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/app_presentation.dart';
import 'package:zone/model/app_style.dart';
import 'package:zone/model/app_theme.dart';
import 'package:zone/page/layout/themed_launcher.dart';
import 'package:zone/page/layout/themed_shell.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/empty.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/theme_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme IDs round trip and preserve legacy preferences', () {
    expect(AppTheme.fromString('Light'), AppTheme.light);
    expect(AppTheme.fromString('Dim'), AppTheme.dim);
    expect(AppTheme.fromString('LightsOut'), AppTheme.lightsOut);
    expect(AppTheme.fromString('unknown'), isNull);

    final ids = {for (final theme in AppTheme.values) theme.storageId};
    expect(ids.length, AppTheme.values.length);
    for (final theme in AppTheme.values) {
      expect(AppTheme.fromString(theme.storageId), theme);
    }
  });

  test('all nine designs have distinct visual profiles and a stable preference ID', () {
    final designs = AppStyle.values.where((style) => !style.isClassic);
    expect(designs.map((style) => style.name), [
      'anthropic',
      'proMax',
      'taste',
      'impeccable',
      'emil',
      'hallmark',
      'vercel',
      'uiSkills',
      'smartisan',
    ]);
    expect({for (final style in designs) (style.layout, style.surface, style.radius, style.headingSize)}.length, 9);
    expect({for (final style in designs) AppPresentation.forStyle(style)}, AppPresentation.values.toSet());
    expect(AppPresentation.forStyle(AppStyle.classic), isNull);
    for (final style in designs) {
      expect(AppStyle.fromId(style.name), style);
      expect(style.light.isLight, isTrue);
      expect(style.dark.isLight, isFalse);
    }
    expect(AppStyle.fromId(null), AppStyle.classic);
    expect(AppStyle.fromId('removed-style'), AppStyle.classic);
    expect(AppStyle.anthropic.headingFont(TargetPlatform.windows), 'Georgia');
    expect(AppStyle.anthropic.headingFont(TargetPlatform.android), 'serif');
  });

  test('custom palettes and both variants of each design keep text and accents legible', () {
    for (final theme in [
      AppTheme.paper,
      AppTheme.glacier,
      AppTheme.midnight,
      AppTheme.forest,
      for (final style in AppStyle.values.where((style) => !style.isClassic)) ...[style.light, style.dark],
    ]) {
      final scheme = theme.colorScheme;
      for (final (foreground, background) in [
        (scheme.onPrimary, scheme.primary),
        (scheme.onSurface, theme.scaffoldBg),
        (scheme.onSurface, theme.userMsgBg),
        (theme.qb6, theme.settingItem),
        (scheme.primary, theme.settingBg),
        (scheme.primary, theme.userMsgBg),
      ]) {
        final a = foreground.computeLuminance();
        final b = background.computeLuminance();
        expect((math.max(a, b) + .05) / (math.min(a, b) + .05), greaterThanOrEqualTo(4.5), reason: theme.storageId);
      }
    }
  });

  test('rapid theme selection persists the last mode and both palettes', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await Future.wait([
      P.preference.setAppearance(AppTheme.paper),
      P.preference.setAppearance(AppTheme.midnight),
      P.preference.setAppStyle(.emil),
      P.preference.setAppearance(AppTheme.forest),
      P.preference.setAppStyle(.hallmark),
      P.preference.setAppearanceMode(.system),
    ]);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('halo_state.appearance'), ['system', 'Paper', 'Forest']);
    expect(P.app.preferredThemeMode.q, ThemeMode.system);
    expect(preferences.getString('halo_state.themeStyle'), 'hallmark');
    await P.preference.setAppStyle(.classic);
    expect(preferences.getStringList('halo_state.appearance'), ['system', 'Paper', 'Forest']);
  });

  test('alternate chat controls use their theme surface and readable foreground', () {
    for (final style in AppStyle.values.where((style) => !style.isClassic)) {
      for (final palette in [style.light, style.dark]) {
        for (final state in [InteractionVisualState.available, InteractionVisualState.idleInteractive, InteractionVisualState.enabled]) {
          final colors = interactionVisualColors(appTheme: palette, state: state, themed: true);
          expect(colors.background, state == .enabled ? palette.userMsgBg : palette.settingItem);
          final a = colors.foreground.computeLuminance();
          final b = colors.background.computeLuminance();
          expect((math.max(a, b) + .05) / (math.min(a, b) + .05), greaterThanOrEqualTo(4.5), reason: palette.storageId);
        }
      }
    }
  });

  testWidgets('the theme picker can apply a design at narrow width with large text', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 650);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(() => P.preference.appStyle.q = .classic);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: rc,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: ThemeSelector(null, styles: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final option = find.widgetWithText(OutlinedButton, 'Smartisan UI');
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(P.preference.appStyle.q, AppStyle.smartisan);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait launcher cards in the same row share top and bottom edges', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(397, 715);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const short = ValueKey('short feature');
    const tall = ValueKey('tall feature');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: rc,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: ThemedLauncher(
            presentation: AppPresentation.device,
            style: AppStyle.smartisan,
            chat: SizedBox(height: 40),
            features: [
              SizedBox(key: short, height: 30),
              SizedBox(key: tall, height: 75),
            ],
            utilities: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final shortRect = tester.getRect(find.byKey(short));
    final tallRect = tester.getRect(find.byKey(tall));
    expect(shortRect.left, lessThan(tallRect.left));
    expect(shortRect.top, tallRect.top);
    expect(shortRect.bottom, tallRect.bottom);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait chat prompts with different text lengths align', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(397, 715);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final previous = P.suggestion.chatSuggestions.q;
    addTearDown(() => P.suggestion.chatSuggestions.q = previous);
    const short = 'Short question';
    const long = 'A longer question that needs several lines of text in a narrow prompt card';
    P.suggestion.chatSuggestions.q = [Suggestion(display: short, prompt: short), Suggestion(display: long, prompt: long)];
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: rc,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: Stack(children: [Empty(presentation: AppPresentation.dashboard)]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Rect card(String text) => tester.getRect(find.ancestor(of: find.text(text), matching: find.byType(InkWell)));
    expect(card(short).left, lessThan(card(long).left));
    expect(card(short).top, card(long).top);
    expect(card(short).bottom, card(long).bottom);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow navigation keeps its full label on one line at 140 percent', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(397, 715);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: rc,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: ThemedAppShell(
            presentation: AppPresentation.device,
            style: AppStyle.smartisan,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final label = find.text('Conversations');
    final fit = find.ancestor(of: label, matching: find.byType(FittedBox));
    expect(tester.widget<Text>(label).maxLines, 1);
    expect(tester.widget<FittedBox>(fit).fit, BoxFit.scaleDown);
    expect(tester.takeException(), isNull);
  });
}
