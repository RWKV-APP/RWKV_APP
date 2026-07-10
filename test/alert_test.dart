// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/model/app_theme.dart';
import 'package:zone/widgets/alert.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Alert exposes its message as a live region', (tester) async {
    final semanticsHandle = tester.ensureSemantics();

    const message = 'Model loaded';
    await _pumpAlertHost(tester, ThemeData.light());

    final completion = Alert.success(message);
    await _showAlert(tester);

    expect(find.bySemanticsLabel(message), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(message)),
      matchesSemantics(label: message, isLiveRegion: true),
    );

    await _finishAlert(tester, completion);
    semanticsHandle.dispose();
  });

  testWidgets('Alert uses theme surface colors and keeps status color on its icon', (tester) async {
    const message = 'Could not load model';
    const surfaceColor = Color(0xFF102030);
    const textColor = Color(0xFFF4F7FA);
    const statusColor = Color(0xFFFF8A80);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ).copyWith(
          surface: surfaceColor,
          onSurface: textColor,
        );
    final theme = ThemeData(brightness: Brightness.dark, colorScheme: colorScheme);
    await _pumpAlertHost(tester, theme);

    final completion = Alert.error(message, color: statusColor);
    await _showAlert(tester);

    final messageWidget = tester.widget<Text>(find.text(message));
    final statusIcon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
    final hasThemeSurface = tester.widgetList<Container>(find.byType(Container)).any((container) {
      final decoration = container.decoration;
      return decoration is BoxDecoration && decoration.color == surfaceColor;
    });

    expect(messageWidget.style?.color, textColor);
    expect(messageWidget.style?.color, isNot(statusColor));
    expect(statusIcon.color, statusColor);
    expect(hasThemeSurface, isTrue);

    await _finishAlert(tester, completion);
  });

  test('App theme alert text colors meet WCAG AA contrast', () {
    for (final appTheme in AppTheme.values) {
      final colorScheme = appTheme.colorScheme;
      final contrastRatio = _contrastRatio(colorScheme.onSurface, colorScheme.surface);

      expect(
        contrastRatio,
        greaterThanOrEqualTo(4.5),
        reason: '$appTheme onSurface should be readable on surface',
      );
    }
  });
}

Future<void> _pumpAlertHost(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: Stack(
          children: [
            SizedBox.expand(),
            Alert(),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showAlert(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 11));
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _finishAlert(WidgetTester tester, Future<void> completion) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pump(const Duration(milliseconds: 300));
  await completion;
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance ? foregroundLuminance : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance ? backgroundLuminance : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
