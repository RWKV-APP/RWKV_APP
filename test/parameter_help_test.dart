import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/string_utils.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/argument_value.dart';
import 'package:zone/widgets/parameter_help_button.dart';

const _arguments = [
  Argument.temperature,
  Argument.topP,
  Argument.presencePenalty,
  Argument.frequencyPenalty,
  Argument.penaltyDecay,
  Argument.maxLength,
];

void main() {
  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux]) {
    testWidgets('$platform help opens by keyboard and click, dismisses without changing a value', (tester) async {
      int changes = 0;
      await _pumpHelp(tester, platform: platform, onChanged: (_, _) => changes++);
      final description = S.current.parameter_help_temperature;
      final semantics = tester.ensureSemantics();
      try {
        expect(find.text(description), findsNothing);
        expect(find.bySemanticsLabel(RegExp('About Temperature')), findsOneWidget);
      } finally {
        semantics.dispose();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text(description), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(description), findsNothing);
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.text(description), findsOneWidget);
      await tester.tapAt(const Offset(10, 700));
      await tester.pumpAndSettle();
      expect(find.text(description), findsNothing);
      expect(changes, 0);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('desktop help opens on hover and closes when pointer leaves', (tester) async {
    await _pumpHelp(tester, platform: TargetPlatform.macOS);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(tester.getCenter(find.byIcon(Icons.info_outline)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text(S.current.parameter_help_temperature), findsOneWidget);
    await mouse.moveTo(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(find.text(S.current.parameter_help_temperature), findsNothing);
    await mouse.removePointer();
  });

  testWidgets('a desktop click gives Escape a way to close help', (tester) async {
    await _pumpHelp(tester, platform: TargetPlatform.macOS);
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(find.text(S.current.parameter_help_temperature), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(S.current.parameter_help_temperature), findsNothing);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform help closes back to the settings sheet without changing its value', (tester) async {
      int changes = 0;
      await _pumpHelp(tester, platform: platform, nestedSheet: true, onChanged: (_, _) => changes++);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(IconButton)).height, greaterThanOrEqualTo(48));
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text(S.current.parameter_help_temperature), findsOneWidget);
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(find.text(S.current.parameter_help_temperature), findsNothing);
      expect(find.byType(ArgumentValue), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 1);
      expect(changes, 0);

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 50));
      await tester.pumpAndSettle();
      expect(find.text(S.current.parameter_help_temperature), findsNothing);
      expect(find.byType(ArgumentValue), findsOneWidget);
      expect(changes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in S.delegate.supportedLocales) {
    testWidgets('$locale explanations fit a narrow phone with large text', (tester) async {
      for (final argument in _arguments) {
        await _pumpHelp(
          tester,
          platform: TargetPlatform.android,
          locale: locale,
          argument: argument,
          size: const Size(320, 568),
          textScale: 2,
        );
        final description = argument.helpDescription(S.current)!;
        expect(description.trim(), isNotEmpty);
        expect(find.byType(ParameterHelpButton), findsOneWidget);
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();
        expect(find.text(description), findsOneWidget);
        expect(find.text(codeToName(argument.name)), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -160));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.text(description))).pop();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('title-free batch controls do not acquire an unrelated help button', (tester) async {
    await _pumpHelp(tester, platform: TargetPlatform.android, argument: Argument.batchCount, showTitle: false);
    expect(find.byType(ParameterHelpButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHelp(
  WidgetTester tester, {
  required TargetPlatform platform,
  Locale locale = const Locale('en'),
  Argument argument = Argument.temperature,
  Size size = const Size(800, 800),
  double textScale = 1,
  bool nestedSheet = false,
  bool showTitle = true,
  void Function(Argument, double)? onChanged,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await S.load(locale);
  P.app.qb.q = Colors.black;
  P.rwkvParams.supportedBatchSizes.q = [];
  P.rwkvParams.arguments(argument).q = argument.defaults;
  final value = ArgumentValue(argument, onChanged ?? (_, _) {}, showTitle: showTitle);
  await tester.pumpWidget(
    StateWrapper(
      child: MaterialApp(
        locale: locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(platform: platform),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => nestedSheet
                ? TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (context) => SizedBox(height: 500, child: value),
                    ),
                    child: const Text('Settings'),
                  )
                : Align(alignment: .topCenter, child: value),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
