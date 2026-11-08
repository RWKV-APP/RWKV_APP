import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/web_search_report.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart';
import 'package:zone/model/ref_info.dart';
import 'package:zone/model/web_search_trace.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/reference_info.dart';
import 'package:zone/widgets/chat/web_search_trace_panel.dart';

void main() {
  tearDown(() {
    P.msg.pool.q = {};
    P.chat.webSearchApiKeys.q = {};
    P.app.theme.q = .light;
  });

  testWidgets('Details renders the four shared report sections and copies each or all', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final message = _message();
    P.msg.pool.q = {message.id: message};
    await _pumpPanel(tester, trace: message.reference.trace!);
    final sections = webSearchReportSections(trace: message.reference.trace!, strings: S.current, modelOutput: message.content);

    for (int index = 0; index < sections.length; index++) {
      final copy = find.byTooltip('${S.current.copy_text}: ${sections[index].title}');
      await tester.scrollUntilVisible(copy, 250, scrollable: _panelScrollable());
      expect(find.text(sections[index].title), findsOneWidget);
      await tester.tap(copy);
      await _settleCopy(tester);
      expect(
        copied,
        formatWebSearchReport(trace: message.reference.trace!, strings: S.current, modelOutput: message.content, section: index),
      );
    }
    await tester.tap(find.byTooltip(S.current.web_search_report_copy_all));
    await _settleCopy(tester);
    expect(copied, formatWebSearchReport(trace: message.reference.trace!, strings: S.current, modelOutput: message.content));
    expect(copied, contains('  原始 🐕 输出\n\n\t保留空白\n'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('open Details follows live output and shows unavailable after message removal', (tester) async {
    final message = _message().copyWith(content: 'partial  🐕', changing: true);
    P.msg.pool.q = {message.id: message};
    P.chat.webSearchApiKeys.q = {'fixture': 'fixture-secret-key'};
    await _pumpPanel(tester, trace: message.reference.trace!);
    await tester.scrollUntilVisible(find.text(S.current.web_search_report_output), 250, scrollable: _panelScrollable());
    expect(find.textContaining('partial  🐕'), findsOneWidget);
    expect(find.textContaining(S.current.web_search_report_output_generating), findsOneWidget);

    P.msg.pool.q = {message.id: message.copyWith(content: 'final  🐕 fixture-secret-key\n', changing: false, paused: true)};
    await tester.pump();
    expect(find.textContaining('final  🐕 [REDACTED]\n'), findsOneWidget);
    expect(find.textContaining(S.current.web_search_report_output_paused), findsOneWidget);
    expect(find.textContaining('fixture-secret-key'), findsNothing);

    P.msg.pool.q = {};
    await tester.pump();
    expect(find.text(S.current.web_search_report_output_unavailable), findsOneWidget);
    final copyAll = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .singleWhere((button) => button.tooltip == S.current.web_search_report_copy_all);
    expect(copyAll.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('request frame contains only query and full-response mode copies beyond preview', (tester) async {
    final body = '{\n${List.generate(40, (index) => '  "field$index": "$index"').join(',\n')}\n}';
    final trace = _message().reference.trace!.copyWith(
      request: 'POST https://example.com/search\nContent-Type: application/json\n\n{"query":"深圳 犬只 数量"}',
      responses: [WebSearchTraceResponse(query: '深圳 犬只 数量', statusCode: 200, body: body)],
    );
    final message = _message().copyWith(reference: _message().reference.copyWith(trace: trace));
    P.msg.pool.q = {message.id: message};
    await _pumpPanel(tester, trace: trace);
    expect(find.byWidgetPredicate((widget) => widget is SelectableText && widget.data == trace.query), findsOneWidget);
    final preview = tester.widget<SelectableText>(find.byWidgetPredicate((widget) => widget is SelectableText && widget.data == body));
    expect(preview.maxLines, 12);
    expect(find.text(S.current.web_search_report_full_response), findsOneWidget);
    await _pumpPanel(tester, trace: trace, responseOnly: true);
    expect(find.text(S.current.web_search_report_request), findsNothing);
    final complete = tester.widget<SelectableText>(find.byWidgetPredicate((widget) => widget is SelectableText && widget.data == body));
    expect(complete.maxLines, isNull);
    expect(complete.data, endsWith('"field39": "39"\n}'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved references without a trace retain Details and copy only recorded data', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final message = _message().copyWith(
      reference: RefInfo.deserialize(
        '{"list":[{"title":"Saved source","url":"https://example.com/saved","summary":"Saved  🐕 excerpt"}],"enable":true,"error":""}',
      ),
    );
    expect(message.reference.trace, isNull);
    P.msg.pool.q = {message.id: message};
    final trace = webSearchTraceForReport(message.reference);
    expect(trace.request, isEmpty);
    expect(trace.query, isEmpty);
    expect(trace.userQuery, isEmpty);
    expect(trace.finalPrompt, isEmpty);
    expect(trace.modelInput, isEmpty);
    await _pumpPanel(
      tester,
      trace: trace,
      child: ReferenceInfo(refInfo: message.reference, generating: false, messageId: message.id),
    );
    final details = find.ancestor(of: find.text(S.current.web_search_report_details_action), matching: find.byType(InkWell));
    expect(tester.widget<InkWell>(details).onTap, isNotNull);

    await _pumpPanel(tester, trace: trace);
    await tester.tap(find.byTooltip(S.current.web_search_report_copy_all));
    await _settleCopy(tester);
    expect(copied, formatWebSearchReport(trace: trace, strings: S.current, modelOutput: message.content));
    expect(copied, contains('Saved  🐕 excerpt'));
    expect(copied, contains('https://example.com/saved'));
    expect(copied, contains(S.current.web_search_report_request_missing));
    expect(copied, contains(S.current.web_search_report_input_missing));
    expect(copied, contains(message.content));
    expect(message.reference.trace, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('four numbered sections remain readable on narrow screens with large text in both themes', (tester) async {
    for (final brightness in Brightness.values) {
      for (final locale in [const Locale('en'), const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')]) {
        final message = _message();
        P.msg.pool.q = {message.id: message};
        await _pumpPanel(tester, trace: message.reference.trace!, brightness: brightness, locale: locale, narrow: true);
        final titles = [
          S.current.web_search_report_request,
          S.current.web_search_report_results,
          S.current.web_search_report_input,
          S.current.web_search_report_output,
        ];
        for (final title in titles) {
          await tester.scrollUntilVisible(find.text(title), 250, scrollable: _panelScrollable());
          expect(find.text(title), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        expect(find.byTooltip(S.current.web_search_report_copy_all), findsOneWidget);
      }
    }
  });
}

Finder _panelScrollable() => find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;

Future<void> _settleCopy(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(seconds: 8));
  await tester.pump(const Duration(milliseconds: 300));
}

Message _message() => Message(
  id: 71,
  content: '  原始 🐕 输出\n\n\t保留空白\n',
  isMine: false,
  paused: false,
  reference: RefInfo(
    list: const [],
    enable: true,
    error: '',
    trace: WebSearchTrace.empty().copyWith(
      searchProvider: 'AnySearch',
      userQuery: '深圳有多少条狗？',
      query: '深圳 犬只 数量',
      request: 'POST https://example.com/search\n{"query":"深圳 犬只 数量"}',
      sources: const [WebSearchTraceSource(rank: 1, title: 'Source', url: 'https://example.com/dogs', summary: 'Registered dogs.')],
      modelInput: {
        'messages': ['context  🐕\n深圳有多少条狗？'],
        'addGenerationPrompt': true,
      },
      finalPrompt: 'context  🐕\n深圳有多少条狗？',
    ),
  ),
);

Future<void> _pumpPanel(
  WidgetTester tester, {
  required WebSearchTrace trace,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  bool narrow = false,
  Widget? child,
  bool responseOnly = false,
}) async {
  P.app.theme.q = brightness == Brightness.dark ? .dim : .light;
  tester.view.physicalSize = narrow ? const Size(320, 720) : const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = ScrollController(keepScrollOffset: false);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: rc,
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        locale: locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(narrow ? 2 : 1)),
          child: child!,
        ),
        home: Scaffold(
          body:
              child ??
              WebSearchTracePanel(
                key: ValueKey((brightness, locale, narrow, responseOnly)),
                messageId: 71,
                trace: trace,
                scrollController: controller,
                responseOnly: responseOnly,
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
