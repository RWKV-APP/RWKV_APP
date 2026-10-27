import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/model/app_theme.dart';
import 'package:zone/widgets/model_name.dart';

void main() {
  for (final appTheme in AppTheme.values) {
    testWidgets('generation stands out in the ' + appTheme.name + ' theme', (tester) async {
      const name = 'RWKV7-G1k 2.9B (MLX)';
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: appTheme.colorScheme),
          home: const Scaffold(body: ModelName(name)),
        ),
      );
      final text = tester.widget<Text>(find.byType(Text));
      final span = text.textSpan! as TextSpan;
      final parts = span.children!.cast<TextSpan>();
      expect(span.toPlainText(), name);
      expect(parts.map((part) => part.text).toList(), ['RWKV7-', 'G1k', ' 2.9B (MLX)']);
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(parts[1].style?.fontWeight, FontWeight.w900);
      expect(parts[1].style?.color, appTheme.isLight ? Colors.black : Colors.white);
      expect(parts.first.style, isNull);
      expect(parts.last.style, isNull);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel(name), findsOneWidget);
      semantics.dispose();
    });
  }

  testWidgets('recognizes generations in names and imported filenames without changing text', (tester) async {
    for (final (name, generations) in [
      ('RWKV7-G1j 1.5B', ['G1j']),
      ('rwkv7_g1K_2.9B_Q4_K_M.gguf', ['g1K']),
      ('RWKV7-G1k / RWKV7-G1j', ['G1k', 'G1j']),
      ('RWKV7-G1aa 1.5B', ['G1aa']),
      ('RWKV-VL 0.4B', <String>[]),
      ('G10 RG1k G1k2 G1', <String>[]),
    ]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ModelName(name))));
      final span = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
      expect(span.toPlainText(), name);
      expect(
        span.children!.cast<TextSpan>().where((part) => part.style?.fontWeight == FontWeight.w900).map((part) => part.text).toList(),
        generations,
      );
    }
  });

  testWidgets('keeps custom style and wraps on a narrow screen with large text', (tester) async {
    const style = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const SizedBox(width: 180, child: ModelName('RWKV7-G1k 13.3B (Palm CPU, W4)', style: style)),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style, style);
    expect(text.maxLines, isNull);
    expect(tester.getSize(find.byType(ModelName)).height, greaterThan(50));
    expect(tester.takeException(), isNull);
  });
}
