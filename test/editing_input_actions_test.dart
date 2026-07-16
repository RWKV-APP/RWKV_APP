import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/page/chat.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/input_text_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clear text and exit editing remain distinct actions', (tester) async {
    await S.load(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
    P.app.theme.q = .light;
    P.app.qb.q = Colors.black;
    P.app.qw.q = Colors.white;
    P.app.demoType.q = .chat;
    P.msg.editingOrRegeneratingIndex.q = 0;
    P.chat.textEditingController.value = const TextEditingValue(
      text: '需要修改的问题',
      selection: TextSelection.collapsed(offset: 7),
    );
    P.chat.textInInput.q = '需要修改的问题';
    addTearDown(() {
      P.msg.editingOrRegeneratingIndex.q = null;
      P.chat.textEditingController.clear();
      P.chat.textInInput.q = '';
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
          home: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: InputTextField(preferredDemoType: .chat),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('清除文本'), findsOneWidget);
    expect(find.byTooltip('退出编辑'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('clear-editing-input')));
    await tester.pumpAndSettle();

    expect(P.chat.textEditingController.text, isEmpty);
    expect(P.chat.textInInput.q, isEmpty);
    expect(P.msg.editingOrRegeneratingIndex.q, 0);
    final clearButton = tester.widget<IconButton>(find.byKey(const ValueKey('clear-editing-input')));
    expect(clearButton.onPressed, isNull);

    P.chat.textEditingController.value = const TextEditingValue(
      text: '另一个问题',
      selection: TextSelection.collapsed(offset: 5),
    );
    P.chat.textInInput.q = '另一个问题';
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exit-editing')));
    await tester.pumpAndSettle();

    expect(P.msg.editingOrRegeneratingIndex.q, isNull);
    expect(P.chat.textEditingController.text, isEmpty);
    expect(find.byKey(const ValueKey('editing-message-banner')), findsNothing);
  });

  testWidgets('popping the chat page clears editing state before re-entry', (tester) async {
    await S.load(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    P.app.theme.q = .light;
    P.app.qb.q = Colors.black;
    P.app.qw.q = Colors.white;
    P.app.demoType.q = .chat;
    P.msg.ids.q = const <int>[];
    P.msg.pool.q = const {};
    P.msg.editingOrRegeneratingIndex.q = 0;
    P.chat.textEditingController.value = const TextEditingValue(
      text: '离开页面前的编辑内容',
      selection: TextSelection.collapsed(offset: 10),
    );
    P.chat.textInInput.q = '离开页面前的编辑内容';
    addTearDown(() {
      P.msg.editingOrRegeneratingIndex.q = null;
      P.chat.textEditingController.clear();
      P.chat.textInInput.q = '';
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
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    key: const ValueKey('open-chat'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const PageChat()),
                      );
                    },
                    child: const Text('打开聊天'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('editing-message-banner')), findsOneWidget);

    Navigator.of(tester.element(find.byType(PageChat))).pop();
    await tester.pumpAndSettle();

    expect(P.msg.editingOrRegeneratingIndex.q, isNull);
    expect(P.chat.textEditingController.text, isEmpty);
    expect(P.chat.textInInput.q, isEmpty);

    await tester.tap(find.byKey(const ValueKey('open-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('editing-message-banner')), findsNothing);
  });
}
