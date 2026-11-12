import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/model/app_theme.dart';
import 'package:zone/widgets/model_name.dart';

void main() {
  for (final appTheme in AppTheme.values) {
    testWidgets('generation stands out in the ' + appTheme.storageId + ' theme', (tester) async {
      const name = 'RWKV7-G1l 2.9B (MLX)';
      const displayName = 'RWKV7-G1L 2.9B (MLX)';
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: appTheme.colorScheme),
          home: const Scaffold(body: ModelName(name)),
        ),
      );
      final text = tester.widget<Text>(find.byType(Text));
      final span = text.textSpan! as TextSpan;
      final parts = span.children!.cast<TextSpan>();
      expect(span.toPlainText(), displayName);
      expect(parts.map((part) => part.text).toList(), ['RWKV7-', 'G1L', ' 2.9B (MLX)']);
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(parts[1].style?.fontWeight, FontWeight.w900);
      expect(parts[1].style?.color, appTheme.isLight ? Colors.black : Colors.white);
      expect(parts.first.style, isNull);
      expect(parts.last.style, isNull);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel(displayName), findsOneWidget);
      semantics.dispose();
    });
  }

  testWidgets('uppercases only generation tokens in catalog and imported model labels', (tester) async {
    for (final (name, displayName) in [
      ('RWKV7-G1j 1.5B', 'RWKV7-G1J 1.5B'),
      ('rwkv7_g1K_2.9B_Q4_K_M.gguf', 'rwkv7_G1K_2.9B_Q4_K_M.gguf'),
      ('RWKV7-G1K / RWKV7-G1m', 'RWKV7-G1K / RWKV7-G1M'),
      ('RWKV7-G1aa 1.5B', 'RWKV7-G1AA 1.5B'),
      ('RWKV-VL 0.4B', 'RWKV-VL 0.4B'),
      ('G10 RG1k G1k2 G1', 'G10 RG1k G1k2 G1'),
    ]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ModelName(name))));
      final span = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
      expect(span.toPlainText(), displayName);
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
