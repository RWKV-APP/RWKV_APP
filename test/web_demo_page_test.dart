import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/model/msg_node.dart';
import 'package:zone/page/web_demo.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/web_demo_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Web Demo opens as an independent grid tool', (tester) async {
    await _pumpWebDemoPage(tester);

    expect(find.text("RWKV Web Demo"), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text("Generate HTML Grid"), findsOneWidget);
    expect(find.text("Concurrency"), findsOneWidget);
    expect(find.text("Cloud"), findsOneWidget);
    expect(find.text("Albatross"), findsOneWidget);
    expect(find.text("RWKV Mobile"), findsOneWidget);
    expect(find.text("7.2B"), findsOneWidget);
    expect(find.text("13.3B"), findsOneWidget);
    expect(find.text("30"), findsWidgets);
    expect(find.text("Generate an HTML grid to compare candidates."), findsOneWidget);

    final presenceFrame = find.ancestor(
      of: find.text("Presence Penalty"),
      matching: find.byWidgetPredicate((widget) => widget.runtimeType.toString() == "_ControlFrame"),
    );
    final countFrame = find.ancestor(
      of: find.text("Count Penalty"),
      matching: find.byWidgetPredicate((widget) => widget.runtimeType.toString() == "_ControlFrame"),
    );
    expect(find.descendant(of: presenceFrame, matching: find.text("1.0")), findsOneWidget);
    expect(find.descendant(of: countFrame, matching: find.text("0.1")), findsOneWidget);
    expect(P.rwkvParams.arguments(Argument.presencePenalty).q, 2);
    expect(P.rwkvParams.arguments(Argument.frequencyPenalty).q, .2);
  });

  testWidgets('Web Demo preset picker and backend selectors update state', (tester) async {
    await _pumpWebDemoPage(tester);

    await tester.tap(find.text("Custom prompt"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("SaaS dashboard").last);
    await tester.pump();

    expect(P.webDemo.promptInput.q, contains("SaaS analytics dashboard"));
    expect(P.webDemo.promptController.text, P.webDemo.promptInput.q);

    await tester.tap(find.text("Albatross"));
    await tester.pump();
    expect(P.webDemo.backendMode.q, WebDemoBackendMode.localAlbatross);
    expect(P.webDemo.batchSizeMax.q, 10);

    await tester.tap(find.text("RWKV Mobile"));
    await tester.pump();
    expect(P.webDemo.backendMode.q, WebDemoBackendMode.localRwkvMobile);

    await tester.tap(find.text("Cloud"));
    await tester.pump();
    await tester.tap(find.text("13.3B"));
    await tester.pump();
    expect(P.webDemo.backendMode.q, WebDemoBackendMode.cloud13b);
  });

  testWidgets('Web Demo generate and stop buttons reflect prompt and active state', (tester) async {
    await _pumpWebDemoPage(tester);

    FilledButton generateButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, "Generate HTML Grid"),
    );
    OutlinedButton stopButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, "Stop"),
    );
    expect(generateButton.onPressed, isNull);
    expect(stopButton.onPressed, isNull);

    P.webDemo.promptInput.q = "Create a tiny clock page.";
    P.webDemo.promptController.text = P.webDemo.promptInput.q;
    await tester.pump();

    generateButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, "Generate HTML Grid"),
    );
    expect(generateButton.onPressed, isNotNull);

    P.webDemo.active.q = true;
    P.webDemo.currentRun.q = WebDemoRun(
      prompt: P.webDemo.promptInput.q,
      createdAt: DateTime(2026),
      backendMode: WebDemoBackendMode.cloud7b,
      batchSize: 3,
      rawDecodeParams: "{}",
    );
    await tester.pump();

    generateButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, "Generate HTML Grid"),
    );
    stopButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, "Stop"),
    );
    expect(find.text("Generating"), findsOneWidget);
    expect(generateButton.onPressed, isNull);
    expect(stopButton.onPressed, isNotNull);

    P.webDemo.active.q = false;
    P.webDemo.currentRun.q = null;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('Web Demo controls reset visible values', (tester) async {
    await _pumpWebDemoPage(tester);

    P.webDemo.batchSize.q = 7;
    P.webDemo.previewScalePercent.q = 80;
    P.webDemo.arguments(Argument.temperature).q = .2;
    await tester.pump();

    await _tapResetFor(tester, "Concurrency");
    await _tapResetFor(tester, "Preview Scale %");
    await _tapResetFor(tester, "Temperature");
    await tester.pump();

    expect(P.webDemo.batchSize.q, 30);
    expect(P.webDemo.previewScalePercent.q, 35);
    expect(P.webDemo.arguments(Argument.temperature).q, 1);
  });

  testWidgets('Web Demo result grid shows streaming source and copy action', (tester) async {
    await _pumpWebDemoPage(tester);
    final copiedTexts = <String>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method != 'Clipboard.setData') return null;
      final arguments = Map<String, dynamic>.from(call.arguments as Map);
      copiedTexts.add(arguments['text'] as String);
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    P.webDemo.active.q = true;
    P.webDemo.results.q = const <WebDemoResult>[
      WebDemoResult(index: 0, raw: '', streaming: true),
    ];
    await tester.pump();

    expect(find.text('#1'), findsOneWidget);
    expect(find.text('Waiting for first tokens...'), findsOneWidget);
    expect(find.byIcon(Icons.content_copy_rounded), findsOneWidget);

    P.webDemo.results.q = const <WebDemoResult>[
      WebDemoResult(index: 0, raw: 'streaming source', streaming: true),
    ];
    await tester.pump();

    await tester.tap(find.byIcon(Icons.content_copy_rounded));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(copiedTexts, ['streaming source']);
  });

  testWidgets('Web Demo preview panel exposes loading, source, and continuation states', (tester) async {
    debugWebDemoInlinePreviewSupported = false;
    addTearDown(() {
      debugWebDemoInlinePreviewSupported = null;
    });
    await _pumpPreviewPanel(tester, raw: '', label: 'Preview');

    expect(find.text('Waiting · 0 B'), findsOneWidget);
    expect(find.text('Waiting for first tokens'), findsOneWidget);

    await _pumpPreviewPanel(tester, raw: 'partial stream without html yet', label: 'Preview');
    expect(find.textContaining('Parsing'), findsOneWidget);
    expect(find.text('Waiting for HTML document'), findsOneWidget);

    const html = '<!doctype html><html><body><h1>Ready</h1></body></html>';
    await _pumpPreviewPanel(tester, raw: html, label: 'Preview');
    expect(find.textContaining('Complete'), findsOneWidget);
    expect(find.text('Inline preview is unavailable on this platform.'), findsOneWidget);

    await tester.tap(find.byTooltip('View source'));
    await tester.pumpAndSettle();
    expect(find.text('Preview source'), findsOneWidget);
    expect(find.text(html), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Continue editing'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(seconds: 3));

    expect(P.webDemo.pendingHtmlContext.q, html);
    expect(P.webDemo.promptInput.q, 'Modify this page: ');
    expect(find.text('Inline preview is unavailable on this platform.'), findsOneWidget);
  });
}

Future<void> _pumpWebDemoPage(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 900);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  P.app.theme.q = .light;
  P.app.qb.q = Colors.black;
  P.app.qw.q = Colors.white;
  P.msg.ids.q = [];
  P.msg.msgNode.q = MsgNode(0);
  P.msg.pool.q = {};
  P.rwkvParams.arguments(Argument.presencePenalty).q = 2;
  P.rwkvParams.arguments(Argument.frequencyPenalty).q = .2;
  P.webDemo.arguments(Argument.maxLength).q = 10000;
  P.webDemo.arguments(Argument.temperature).q = 1;
  P.webDemo.arguments(Argument.topP).q = .5;
  P.webDemo.arguments(Argument.presencePenalty).q = 1;
  P.webDemo.arguments(Argument.frequencyPenalty).q = .1;
  P.webDemo.arguments(Argument.penaltyDecay).q = .99;
  P.webDemo.batchSize.q = 30;
  P.webDemo.previewScalePercent.q = 35;
  P.webDemo.previewAutoScrollSeconds.q = 5;
  P.webDemo.backendMode.q = WebDemoBackendMode.cloud7b;
  P.webDemo.pendingHtmlContext.q = null;
  P.webDemo.promptInput.q = "";
  P.webDemo.promptController.text = "";
  P.webDemo.results.q = const <WebDemoResult>[];
  P.webDemo.currentRun.q = null;
  P.webDemo.active.q = false;

  await tester.pumpWidget(
    const StateWrapper(
      child: MaterialApp(
        home: PageWebDemo(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpPreviewPanel(
  WidgetTester tester, {
  required String raw,
  required String label,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(760, 620);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  P.app.theme.q = .light;
  P.app.qb.q = Colors.black;
  P.app.qw.q = Colors.white;
  P.webDemo.pendingHtmlContext.q = null;
  P.webDemo.promptInput.q = '';
  P.webDemo.promptController.text = '';

  await tester.pumpWidget(
    StateWrapper(
      child: MaterialApp(
        home: Scaffold(
          body: WebDemoPreviewPanel(raw: raw, label: label, height: 260),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tapResetFor(WidgetTester tester, String label) async {
  final frame = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((widget) => widget.runtimeType.toString() == "_ControlFrame"),
  );
  final icon = find.descendant(
    of: frame,
    matching: find.byIcon(Icons.restart_alt_rounded),
  );
  await tester.ensureVisible(icon);
  await tester.tap(
    icon,
  );
}
