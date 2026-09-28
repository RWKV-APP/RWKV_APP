import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/widgets/force_import_model_dialog.dart';

void main() {
  testWidgets('shows complete filename and warning; each file needs its own decision', (tester) async {
    const names = ['rwkv7-g1d-0.1b-20260129-ctx4096-q4_k_m.gguf', 'another-rwkv.gguf'];
    final decisions = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                for (final name in names) {
                  decisions.add(await showForceImportModelDialog(context, name));
                }
              },
              child: const Text('Import'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(find.text('强制导入未收录模型？'), findsOneWidget);
    expect(find.textContaining(names.first), findsOneWidget);
    expect(find.textContaining('应用不保证其可用性'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(decisions, [false]);
    expect(find.textContaining(names.last), findsOneWidget);
    await tester.tap(find.text('强制导入'));
    await tester.pumpAndSettle();
    expect(decisions, [false, true]);
    expect(find.text('强制导入未收录模型？'), findsNothing);
  });
}
