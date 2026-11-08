import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/model/reference.dart';
import 'package:zone/model/ref_info.dart';
import 'package:zone/model/web_search_trace.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/markdown_render.dart';

void main() {
  test('batch citations keep their own source order across persistence', () {
    final combined = RefInfo.empty().copyWith(
      trace: WebSearchTrace.empty().copyWith(
        sourceGroups: const [
          [WebSearchTraceSource(rank: 1, title: 'A', url: 'https://example.com/a', summary: '')],
          [WebSearchTraceSource(rank: 1, title: 'B', url: 'https://example.com/b', summary: '')],
        ],
      ),
    );
    final restored = RefInfo.deserialize(combined.serialize());
    expect(restored.sourcesForBatch(0).single.url, 'https://example.com/a');
    expect(restored.sourcesForBatch(1).single.url, 'https://example.com/b');
    expect(restored.sourcesForBatch(2), isEmpty);
    expect(RefInfo.empty().sourcesForBatch(0), isEmpty);
  });
  testWidgets('saved and streaming source tags open the corresponding source and reject invalid numbers', (tester) async {
    String? opened;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch') opened = (call.arguments as Map)['url'] as String;
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    P.preference.renderMarkdownAndLatexEnabled.q = true;
    final references = [
      Reference(title: 'First', url: 'https://example.com/1', summary: ''),
      Reference(title: 'Unsafe', url: 'javascript:alert(1)', summary: ''),
      Reference(title: 'Metro source', url: 'https://example.com/metro', summary: ''),
    ];
    const raw = '根据参考资料[3]，深圳有18条地铁线。[0] [2] [9]\n\n`array[1]`';
    for (final streaming in [false, true]) {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: rc,
          child: MaterialApp(
            home: Scaffold(
              body: StreamingMarkdownRender(raw: raw, references: references, streaming: streaming),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byTooltip('Metro source\nhttps://example.com/metro'), findsOneWidget);
      expect(find.byTooltip('First\nhttps://example.com/1'), findsNothing);
      expect(find.byTooltip('Unsafe\njavascript:alert(1)'), findsNothing);
      await tester.tap(find.byTooltip('Metro source\nhttps://example.com/metro'));
      await tester.pump();
      expect(opened, 'https://example.com/metro');
      expect(tester.takeException(), isNull);
    }
  });
}
