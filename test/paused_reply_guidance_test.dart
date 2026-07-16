import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/paused_reply_guidance.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart';
import 'package:zone/model/msg_node.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/input_bar.dart';
import 'package:zone/widgets/input_interactions.dart';
import 'package:zone/widgets/paused_reply_guidance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('paused reply guidance', () {
    test('shows only for the latest paused assistant message', () {
      const pausedReply = Message(
        id: 2,
        content: 'Partial answer',
        isMine: false,
        paused: true,
      );

      expect(
        resolvePausedReplyGuidanceMessageId(
          messages: const <Message>[
            Message(id: 1, content: 'Question', isMine: true, paused: false),
            pausedReply,
          ],
          dismissedMessageId: null,
        ),
        pausedReply.id,
      );
      expect(
        resolvePausedReplyGuidanceMessageId(
          messages: const <Message>[
            Message(id: 1, content: 'Question', isMine: true, paused: false),
            pausedReply,
          ],
          dismissedMessageId: pausedReply.id,
        ),
        isNull,
      );
    });

    test('hides after the conversation continues', () {
      expect(
        resolvePausedReplyGuidanceMessageId(
          messages: const <Message>[
            Message(id: 1, content: 'Question', isMine: true, paused: false),
            Message(id: 2, content: 'Partial answer', isMine: false, paused: true),
            Message(id: 3, content: 'Follow-up', isMine: true, paused: false),
          ],
          dismissedMessageId: null,
        ),
        isNull,
      );
    });

    test('finds the original question through the active message tree', () {
      final root = MsgNode(0);
      final questionNode = root.add(MsgNode(10));
      questionNode.add(MsgNode(11));
      const messages = <Message>[
        Message(id: 10, content: 'Original question', isMine: true, paused: false),
        Message(id: 11, content: 'Partial answer', isMine: false, paused: true),
      ];

      expect(
        originalQuestionIndexForPausedReply(
          messages: messages,
          rootNode: root,
          pausedReplyId: 11,
        ),
        0,
      );
    });

    test('stays hidden while the experimental feature is disabled', () {
      final root = MsgNode(0);
      final questionNode = root.add(MsgNode(20));
      questionNode.add(MsgNode(21));
      P.preference.pausedReplyGuidanceEnabled.q = false;
      P.msg.msgNode.q = root;
      P.msg.ids.q = const <int>[20, 21];
      P.msg.pool.q = const <int, Message>{
        20: Message(id: 20, content: 'Question', isMine: true, paused: false),
        21: Message(id: 21, content: 'Partial answer', isMine: false, paused: true),
      };

      expect(P.chat.pausedReplyGuidanceMessageId.q, isNull);
    });

    testWidgets('renders without overflow on a narrow input bar and can be dismissed', (tester) async {
      await S.load(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final root = MsgNode(0);
      final questionNode = root.add(MsgNode(100));
      questionNode.add(MsgNode(101));
      P.app.theme.q = .light;
      P.app.qb.q = Colors.black;
      P.app.qw.q = Colors.white;
      P.app.demoType.q = .chat;
      P.preference.pausedReplyGuidanceEnabled.q = true;
      P.msg.editingOrRegeneratingIndex.q = null;
      P.msg.msgNode.q = root;
      P.msg.ids.q = const <int>[100, 101];
      P.msg.pool.q = const <int, Message>{
        100: Message(id: 100, content: '原问题', isMine: true, paused: false),
        101: Message(id: 101, content: '回答到一半', isMine: false, paused: true),
      };
      P.ui.useBackdropFilterForInputOptions.q = true;
      P.ui.backdropFilterBgAlphaForInputOptions.q = .75;
      P.ui.sigmaForBackdropFilterForInputOptions.q = 8;
      P.rwkvGeneration.generating.q = false;
      expect(P.chat.pausedReplyGuidanceMessageId.q, 101);

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
                child: PausedReplyGuidance(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('paused-reply-guidance-101')), findsOneWidget);
      expect(find.text('回答已暂停。如果刚才的问题需要调整，修改原问题后重新生成会更准确。'), findsOneWidget);
      expect(find.text('修改原问题'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('paused-reply-guidance-101')),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('paused-reply-guidance-101')),
          matching: find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final decoration = widget.decoration;
            if (decoration is! BoxDecoration) return false;
            return decoration.borderRadius == BorderRadius.circular(16) && decoration.border != null;
          }),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();

      expect(find.text('修改原问题'), findsNothing);
    });

    testWidgets('adds the floating guidance height to the measured input bar space', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final root = MsgNode(0);
      final questionNode = root.add(MsgNode(200));
      questionNode.add(MsgNode(201));
      P.app.theme.q = .light;
      P.app.qb.q = Colors.black;
      P.app.qw.q = Colors.white;
      P.app.demoType.q = .chat;
      P.preference.pausedReplyGuidanceEnabled.q = true;
      P.msg.editingOrRegeneratingIndex.q = null;
      P.msg.msgNode.q = root;
      P.msg.ids.q = const <int>[200, 201];
      P.msg.pool.q = const <int, Message>{
        200: Message(id: 200, content: 'Original question', isMine: true, paused: false),
        201: Message(id: 201, content: 'Complete answer', isMine: false, paused: false),
      };
      P.chat.inputHeight.q = 0;
      P.rwkvGeneration.generating.q = false;

      await tester.pumpWidget(
        StateWrapper(
          child: MaterialApp(
            supportedLocales: S.delegate.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const Scaffold(
              body: Stack(
                children: [
                  InputBar(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final heightWithoutGuidance = P.chat.inputHeight.q;

      P.msg.pool.q = const <int, Message>{
        200: Message(id: 200, content: 'Original question', isMine: true, paused: false),
        201: Message(id: 201, content: 'Partial answer', isMine: false, paused: true),
      };
      await tester.pumpAndSettle();
      final heightWithGuidance = P.chat.inputHeight.q;
      final guidanceTop = tester.getTopLeft(find.byType(PausedReplyGuidance)).dy;
      final shortcutsTop = tester.getTopLeft(find.byType(InputInteractions)).dy;

      expect(find.byKey(const ValueKey('paused-reply-guidance-201')), findsOneWidget);
      expect(heightWithGuidance, greaterThan(heightWithoutGuidance));
      expect(guidanceTop, lessThan(shortcutsTop));
      expect(tester.takeException(), isNull);
    });
  });
}
