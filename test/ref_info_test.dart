// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/model/ref_info.dart';
import 'package:zone/model/reference.dart';
import 'package:zone/model/web_search_trace.dart';

void main() {
  test('RefInfo preserves web search trace through serialization', () {
    const trace = WebSearchTrace(
      searchProvider: 'Local Web Search',
      searchEngineId: 'bing',
      searchEngineLabel: 'Bing',
      userQuery: '给我讲讲中国',
      query: '中国',
      searchUrl: 'https://www.bing.com/search?q=%E4%B8%AD%E5%9B%BD',
      pageUrl: 'https://www.bing.com/search?q=%E4%B8%AD%E5%9B%BD',
      pageTitle: 'China - Bing',
      extractedItemCount: 8,
      sourceLimit: 8,
      sources: <WebSearchTraceSource>[
        WebSearchTraceSource(
          rank: 1,
          title: 'China',
          url: 'https://example.com/china',
          summary: 'China overview.',
        ),
      ],
      steps: <WebSearchTraceStep>[
        WebSearchTraceStep(title: 'Query generated', detail: '中国'),
      ],
      promptContext: '[1] China',
      finalPrompt: '[1] China\n请根据以上信息回答:\n中国',
      error: '',
    );
    final ref = RefInfo(
      list: <Reference>[
        Reference(
          url: 'https://example.com/china',
          title: 'China',
          summary: 'China overview.',
        ),
      ],
      enable: true,
      error: '',
      trace: trace,
    );

    final decoded = RefInfo.deserialize(ref.serialize());

    expect(decoded.trace?.searchEngineLabel, 'Bing');
    expect(decoded.trace?.sources.single.url, 'https://example.com/china');
    expect(decoded.trace?.steps.single.title, 'Query generated');
    expect(decoded.trace?.finalPrompt, contains('请根据以上信息回答'));
  });

  test('RefInfo keeps legacy reference JSON valid without trace', () {
    const legacyJson = '{"list":[{"url":"https://example.com","summary":"Example","title":"Example"}],"enable":true,"error":""}';

    final decoded = RefInfo.deserialize(legacyJson);

    expect(decoded.enable, true);
    expect(decoded.list.single.title, 'Example');
    expect(decoded.trace, null);
  });
}
