// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// Package imports:

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/store/p.dart';
import 'package:zone/widgets/message.dart';
import 'package:zone/widgets/thinking_content_panel.dart';

const _thinkingPanelKey = ValueKey<String>("thinking-content-panel");
const _thinkingScrollKey = ValueKey<String>("thinking-content-scroll");
const _thinkingHeaderKey = ValueKey<String>("thinking-header");
const _thinkingScrollToBottomButtonKey = ValueKey<String>("thinking-scroll-to-bottom-button");
const _batchThinkingPanelKey = ValueKey<String>("batch-thinking-content-panel-6-0");
const _batchThinkingHeaderKey = ValueKey<String>("batch-thinking-header-6-0");
const _batchQuickThinkingPanelKey = ValueKey<String>("batch-thinking-content-panel-7-0");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    for (int messageId = 1; messageId <= 9; messageId++) {
      _resetMessageUiState(messageId: messageId);
    }
  });

  testWidgets('long thinking content defaults to a five line preview', (tester) async {
    final msg = model.Message(
      id: 1,
      content: _thinkingResponse(lineCount: 24),
      isMine: false,
      paused: false,
    );

    await _pumpMessage(tester: tester, msg: msg);

    final panelHeight = tester.getSize(find.byKey(_thinkingPanelKey)).height;
    expect(panelHeight, lessThanOrEqualTo(_expectedPreviewMaxHeight() + 20));

    final listView = tester.widget<ListView>(find.byKey(_thinkingScrollKey));
    final controller = listView.controller!;
    expect(controller.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('preview fade uses the opaque thinking panel gray', (tester) async {
    final msg = model.Message(
      id: 5,
      content: _thinkingResponse(lineCount: 24),
      isMine: false,
      paused: false,
    );

    await _pumpMessage(tester: tester, msg: msg);
    final expectedFadeColor = Color.alphaBlend(Colors.black.withValues(alpha: .025), Colors.white);
    final matchingFadeGradients = _findLinearGradients(tester)
        .where(
          (gradient) =>
              gradient.colors.length == 2 &&
              gradient.colors.first == expectedFadeColor &&
              gradient.colors.last == expectedFadeColor.withValues(alpha: 0),
        )
        .toList();

    expect(matchingFadeGradients, hasLength(2));
  });

  testWidgets('tapping the thinking header expands the full content', (tester) async {
    final msg = model.Message(
      id: 2,
      content: _thinkingResponse(lineCount: 24),
      isMine: false,
      paused: false,
    );

    await _pumpMessage(tester: tester, msg: msg);
    final previewHeight = _visiblePanelHeight(tester, _thinkingPanelKey);
    final previewWidth = tester.getSize(find.byKey(_thinkingPanelKey)).width;

    final header = tester.widget<GestureDetector>(find.byKey(_thinkingHeaderKey));
    expect(header.behavior, HitTestBehavior.opaque);
    header.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final animatingHeight = _visiblePanelHeight(tester, _thinkingPanelKey);
    expect(animatingHeight, greaterThan(previewHeight));

    await tester.pumpAndSettle();

    final expandedHeight = _visiblePanelHeight(tester, _thinkingPanelKey);
    final expandedWidth = tester.getSize(find.byKey(_thinkingPanelKey)).width;
    expect(expandedHeight, greaterThan(animatingHeight));
    expect(expandedWidth, previewWidth);

    final expandedHeader = tester.widget<GestureDetector>(find.byKey(_thinkingHeaderKey));
    expandedHeader.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final collapsingHeight = _visiblePanelHeight(tester, _thinkingPanelKey);
    expect(collapsingHeight, lessThan(expandedHeight));
    expect(collapsingHeight, greaterThan(previewHeight));
  });

  testWidgets('disabled thinking preview renders full non-batch thought content', (tester) async {
    final msg = model.Message(
      id: 8,
      content: _thinkingResponse(lineCount: 24),
      isMine: false,
      paused: false,
    );

    await _pumpMessage(
      tester: tester,
      msg: msg,
      renderThinkingTagAsPreview: false,
    );

    expect(find.byKey(_thinkingPanelKey), findsNothing);
    expect(find.byKey(_thinkingScrollKey), findsNothing);
    expect(find.textContaining("Thought Result"), findsOneWidget);
    expect(find.textContaining("line 24"), findsOneWidget);
    expect(find.textContaining("answer"), findsOneWidget);

    final animatorFinder = find.byType(ThinkingFullContentAnimator);
    expect(animatorFinder, findsOneWidget);
    final expandedAnimatorWidth = tester.getSize(animatorFinder).width;

    final header = tester.widget<GestureDetector>(find.byKey(_thinkingHeaderKey));
    header.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getSize(animatorFinder).width, expandedAnimatorWidth);
    await tester.pumpAndSettle();

    expect(find.textContaining("line 24"), findsNothing);
    expect(find.textContaining("answer"), findsOneWidget);

    final collapsedHeader = tester.widget<GestureDetector>(find.byKey(_thinkingHeaderKey));
    collapsedHeader.onTap!();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining("line 24"), findsOneWidget);
  });

  testWidgets('tapping the thinking preview panel expands it', (tester) async {
    final msg = model.Message(
      id: 1,
      content: _thinkingResponse(lineCount: 24),
      isMine: false,
      paused: false,
    );

    await _pumpMessage(tester: tester, msg: msg);
    final previewHeight = _visiblePanelHeight(tester, _thinkingPanelKey);

    await tester.tap(find.byKey(_thinkingPanelKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final animatingHeight = _visiblePanelHeight(tester, _thinkingPanelKey);
    expect(animatingHeight, greaterThan(previewHeight));
  });

  testWidgets('quick thinking stays hidden and still renders the answer', (tester) async {
    const msg = model.Message(
      id: 3,
      content: "<think>\n</think>\nanswer",
      isMine: false,
      paused: false,
    );

    await _pumpMessage(tester: tester, msg: msg);

    expect(find.byKey(_thinkingPanelKey), findsNothing);
    expect(find.text("Thought Result"), findsNothing);
    expect(find.textContaining("answer"), findsOneWidget);
  });

  testWidgets('streaming preview scrolls to the latest thinking content', (tester) async {
    const messageId = 4;
    const msg = model.Message(
      id: messageId,
      content: "<think>\nline 01",
      isMine: false,
      paused: false,
      changing: true,
    );

    await _pumpMessage(tester: tester, msg: msg);
    P.chat.receiveId.q = messageId;
    P.rwkvGeneration.generating.q = true;
    P.chat.visibleReceivedTokens.q = _openThinkingResponse(lineCount: 12);
    await tester.pump();
    await tester.pump();

    P.chat.visibleReceivedTokens.q = _openThinkingResponse(lineCount: 32);
    await tester.pump();
    await tester.pump();

    final listView = tester.widget<ListView>(find.byKey(_thinkingScrollKey));
    final controller = listView.controller!;
    expect(controller.offset, controller.position.maxScrollExtent);
  });

  testWidgets('manual scroll pauses auto scroll and the bottom button resumes it', (tester) async {
    const messageId = 4;
    const msg = model.Message(
      id: messageId,
      content: "<think>\nline 01",
      isMine: false,
      paused: false,
      changing: true,
    );

    await _pumpMessage(tester: tester, msg: msg);
    P.chat.receiveId.q = messageId;
    P.rwkvGeneration.generating.q = true;
    P.chat.visibleReceivedTokens.q = _openThinkingResponse(lineCount: 40);
    await tester.pump();
    await tester.pump();

    final listView = tester.widget<ListView>(find.byKey(_thinkingScrollKey));
    final controller = listView.controller!;
    expect(controller.offset, controller.position.maxScrollExtent);

    await tester.drag(find.byKey(_thinkingScrollKey), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(controller.offset, lessThan(controller.position.maxScrollExtent));
    expect(_visiblePanelHeight(tester, _thinkingPanelKey), lessThanOrEqualTo(_expectedPreviewMaxHeight() + 20));

    final button = tester.widget<AnimatedOpacity>(find.byKey(_thinkingScrollToBottomButtonKey));
    expect(button.opacity, 1);

    P.chat.visibleReceivedTokens.q = _openThinkingResponse(lineCount: 52);
    await tester.pump();
    await tester.pump();
    expect(controller.offset, lessThan(controller.position.maxScrollExtent));

    final buttonTapTarget = find.descendant(
      of: find.byKey(_thinkingScrollToBottomButtonKey),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(buttonTapTarget);
    await tester.pumpAndSettle();
    expect(controller.offset, controller.position.maxScrollExtent);

    P.chat.visibleReceivedTokens.q = _openThinkingResponse(lineCount: 60);
    await tester.pump();
    await tester.pump();
    expect(controller.offset, controller.position.maxScrollExtent);
  });

  testWidgets('batch slot thinking defaults to preview and expands from the header', (tester) async {
    final msg = model.Message(
      id: 6,
      content: buildBatchContent([
        _thinkingResponse(lineCount: 24),
        "plain batch answer",
      ]),
      isMine: false,
      paused: false,
    );

    await _pumpMessage(tester: tester, msg: msg);
    final previewHeight = _visiblePanelHeight(tester, _batchThinkingPanelKey);
    final previewWidth = tester.getSize(find.byKey(_batchThinkingPanelKey)).width;
    expect(previewHeight, lessThanOrEqualTo(_expectedPreviewMaxHeight() + 20));

    final header = tester.widget<GestureDetector>(find.byKey(_batchThinkingHeaderKey));
    expect(header.behavior, HitTestBehavior.opaque);
    header.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final animatingHeight = _visiblePanelHeight(tester, _batchThinkingPanelKey);
    expect(animatingHeight, greaterThan(previewHeight));

    await tester.pumpAndSettle();

    final expandedHeight = _visiblePanelHeight(tester, _batchThinkingPanelKey);
    final expandedWidth = tester.getSize(find.byKey(_batchThinkingPanelKey)).width;
    expect(expandedHeight, greaterThan(animatingHeight));
    expect(expandedWidth, previewWidth);
  });

  testWidgets('batch slot thinking preview panel tap expands it', (tester) async {
    final msg = model.Message(
      id: 6,
      content: buildBatchContent([
        _thinkingResponse(lineCount: 24),
        "plain batch answer",
      ]),
      isMine: false,
      paused: false,
    );

    await _pumpMessage(tester: tester, msg: msg);
    final previewHeight = _visiblePanelHeight(tester, _batchThinkingPanelKey);

    await tester.tap(find.byKey(_batchThinkingPanelKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final animatingHeight = _visiblePanelHeight(tester, _batchThinkingPanelKey);
    expect(animatingHeight, greaterThan(previewHeight));
  });

  testWidgets('batch quick thinking stays hidden and still renders the answer', (tester) async {
    final msg = model.Message(
      id: 7,
      content: buildBatchContent([
        "<think>\n</think>\nanswer",
        "plain batch answer",
      ]),
      isMine: false,
      paused: false,
    );

    await _pumpMessage(tester: tester, msg: msg);

    expect(find.byKey(_batchQuickThinkingPanelKey), findsNothing);
    expect(find.textContaining("answer"), findsWidgets);
  });

  testWidgets('disabled thinking preview renders full batch thought content', (tester) async {
    final msg = model.Message(
      id: 6,
      content: buildBatchContent([
        _thinkingResponse(lineCount: 24),
        "plain batch answer",
      ]),
      isMine: false,
      paused: false,
    );

    await _pumpMessage(
      tester: tester,
      msg: msg,
      renderThinkingTagAsPreview: false,
    );

    expect(find.byKey(_batchThinkingPanelKey), findsNothing);
    expect(find.byKey(_batchThinkingHeaderKey), findsOneWidget);
    expect(find.textContaining("line 24"), findsOneWidget);
    expect(find.textContaining("plain batch answer"), findsOneWidget);

    final animatorFinder = find.byType(ThinkingFullContentAnimator);
    expect(animatorFinder, findsOneWidget);
    final expandedAnimatorWidth = tester.getSize(animatorFinder).width;

    final header = tester.widget<GestureDetector>(find.byKey(_batchThinkingHeaderKey));
    header.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getSize(animatorFinder).width, expandedAnimatorWidth);
    await tester.pumpAndSettle();

    expect(find.textContaining("line 24"), findsNothing);
    expect(find.textContaining("plain batch answer"), findsOneWidget);

    final collapsedHeader = tester.widget<GestureDetector>(find.byKey(_batchThinkingHeaderKey));
    collapsedHeader.onTap!();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining("line 24"), findsOneWidget);
  });
}

Future<void> _pumpMessage({
  required WidgetTester tester,
  required model.Message msg,
  bool renderThinkingTagAsPreview = true,
}) async {
  _resetMessageUiState(messageId: msg.id);
  P.preference.renderThinkingTagAsPreviewEnabled.q = renderThinkingTagAsPreview;
  await tester.pumpWidget(
    StateWrapper(
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800, 2000)),
        child: Localizations(
          locale: const Locale("en"),
          delegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Theme(
              data: ThemeData.light(),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) {
                      return Material(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: 800,
                            child: Message(msg, 0, selectMode: true),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _resetMessageUiState({required int messageId}) {
  P.app.screenWidth.q = 800;
  P.app.screenHeight.q = 2000;
  P.app.qb.q = Colors.black;
  P.app.qw.q = Colors.white;
  P.app.theme.q = .light;
  P.app.demoType.q = .chat;
  P.chat.isSharing.q = false;
  P.chat.receiveId.q = null;
  P.chat.visibleReceivedTokens.q = "";
  P.msg.editingOrRegeneratingIndex.q = null;
  P.msg.cotDisplayState(messageId).q = .previewCotContent;
  P.ui.batchViewportWidth.q = 45;
  P.ui.clearBatchMessageUi(messageId: messageId);
  P.preference.preferredMessageLineHeight.q = 1.2;
  P.preference.renderMarkdownAndLatexEnabled.q = false;
  P.preference.renderThinkingTagAsPreview = true;
  P.preference.renderThinkingTagAsPreviewEnabled.q = true;
  P.rwkvContext.currentWorldType.q = null;
  P.rwkvGeneration.generating.q = false;
}

String _thinkingResponse({required int lineCount}) {
  return "${_openThinkingResponse(lineCount: lineCount)}\n</think>\nanswer";
}

String _openThinkingResponse({required int lineCount}) {
  final lines = List.generate(lineCount, (index) => "line ${(index + 1).toString().padLeft(2, "0")}");
  return "<think>\n${lines.join("\n")}";
}

double _expectedPreviewMaxHeight() {
  final textStyle = const TextStyle(
    fontSize: Config.markdownBodyFontSize * Config.msgFontScale,
    height: 1.2,
  );
  final textPainter = TextPainter(
    text: TextSpan(text: "M", style: textStyle),
    textDirection: TextDirection.ltr,
    textScaler: .noScaling,
  )..layout();
  return textPainter.preferredLineHeight * 5;
}

List<LinearGradient> _findLinearGradients(WidgetTester tester) {
  final gradients = <LinearGradient>[];
  final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
  for (final decoratedBox in decoratedBoxes) {
    final decoration = decoratedBox.decoration;
    if (decoration is! BoxDecoration) continue;
    final gradient = decoration.gradient;
    if (gradient is! LinearGradient) continue;
    gradients.add(gradient);
  }
  return gradients;
}

double _visiblePanelHeight(WidgetTester tester, Key panelKey) {
  final animatedSize = find.ancestor(
    of: find.byKey(panelKey),
    matching: find.byType(AnimatedSize),
  );
  return tester.getSize(animatedSize.first).height;
}
