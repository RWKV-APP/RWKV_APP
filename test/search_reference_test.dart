import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/ref_info.dart';
import 'package:zone/model/reference.dart';
import 'package:zone/model/web_search_trace.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/reference_info.dart';
import 'package:zone/widgets/chat/search_reference_dialog.dart';

void main() {
  test('only original HTTP and HTTPS pages are launchable, including saved references', () {
    for (final url in ['https://rwkv.cn/docs', 'http://example.com/page?q=rwkv']) {
      expect(Reference(url: url, title: '', summary: '').webUri, Uri.parse(url));
    }
    for (final url in ['javascript:alert(1)', 'file:///private/page', 'https://user:secret@example.com', '/relative', 'https://']) {
      expect(Reference(url: url, title: '', summary: '').webUri, isNull);
    }
    final restored = RefInfo.deserialize(_references().serialize());
    expect(restored.list.map((source) => source.url), ['https://rwkv.cn/docs', 'https://example.com/research']);
  });

  testWidgets('source button opens ordered sources, launches the original URL and reopens', (tester) async {
    final semantics = tester.ensureSemantics();
    String? openedUrl;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch') openedUrl = (call.arguments as Map)['url'] as String;
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    await _pumpReferences(tester);
    expect(
      tester.getSemantics(find.text('2 sources')),
      matchesSemantics(
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        label: '2 sources',
      ),
    );
    semantics.dispose();
    expect(find.byType(SearchReferenceDialog), findsNothing);
    await tester.tap(find.text('2 sources'));
    await tester.pumpAndSettle();
    expect(find.text('Search sources · 2'), findsOneWidget);
    final cards = tester.widgetList<SearchReferenceCard>(find.byType(SearchReferenceCard)).toList();
    expect(cards.map((card) => card.number), [1, 2]);
    expect(find.text('rwkv.cn'), findsOneWidget);
    expect(find.text('RWKV documentation'), findsOneWidget);
    expect(find.text('Architecture and inference guides.'), findsOneWidget);
    await tester.tap(find.text('RWKV documentation'));
    await tester.pumpAndSettle();
    expect(openedUrl, 'https://rwkv.cn/docs');
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(SearchReferenceDialog), findsNothing);
    await tester.tap(find.text('2 sources'));
    await tester.pumpAndSettle();
    expect(find.text('rwkv.cn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source sheet scrolls on a narrow phone with large text in both themes', (tester) async {
    for (final brightness in Brightness.values) {
      await _pumpReferences(tester, brightness: brightness, narrow: true);
      await tester.tap(find.text('2 sources'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('failed searches cannot open a sources sheet', (tester) async {
    await _pumpReferences(
      tester,
      info: const RefInfo(list: [], enable: true, error: 'Search unavailable'),
    );
    await tester.tap(find.text(S.current.search_failed));
    await tester.pumpAndSettle();
    expect(find.byType(SearchReferenceDialog), findsNothing);
    expect(find.byTooltip('Search unavailable'), findsOneWidget);
  });

  testWidgets('source and Details actions have the same height at normal and large text sizes', (tester) async {
    final info = _references().copyWith(
      trace: WebSearchTrace.empty().copyWith(searchProvider: 'Fixture', query: 'RWKV'),
    );
    for (final brightness in Brightness.values) {
      for (final narrow in [false, true]) {
        await _pumpReferences(tester, brightness: brightness, narrow: narrow, info: info);
        final sources = find.ancestor(of: find.text('2 sources'), matching: find.byType(InkWell));
        final details = find.ancestor(of: find.text('Details'), matching: find.byType(InkWell));
        expect(tester.getSize(sources).height, tester.getSize(details).height);
        expect(tester.getSize(sources).height, greaterThanOrEqualTo(40));
        if (!narrow) expect(tester.getCenter(sources).dy, tester.getCenter(details).dy);
        expect(tester.takeException(), isNull);
      }
    }
  });
}

RefInfo _references() => RefInfo(
  list: [
    Reference(url: 'https://rwkv.cn/docs', title: 'RWKV documentation', summary: 'Architecture and inference guides.'),
    Reference(
      url: 'https://example.com/research',
      title: 'A long research title about recurrent language models and their inference',
      summary: 'An independent source.',
    ),
  ],
  enable: true,
  error: '',
);

Future<void> _pumpReferences(WidgetTester tester, {Brightness brightness = Brightness.light, bool narrow = false, RefInfo? info}) async {
  tester.view.physicalSize = narrow ? const Size(320, 640) : const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: rc,
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        locale: const Locale('en'),
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
        home: Scaffold(body: ReferenceInfo(refInfo: info ?? RefInfo.deserialize(_references().serialize()), generating: false)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
