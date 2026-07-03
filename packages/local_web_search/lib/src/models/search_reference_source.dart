import 'package:local_web_search/src/models/search_result_item.dart';

class SearchReferenceSource {
  final int rank;
  final String title;
  final String url;
  final String summary;

  const SearchReferenceSource({
    required this.rank,
    required this.title,
    required this.url,
    required this.summary,
  });

  factory SearchReferenceSource.fromSearchResultItem({
    required int rank,
    required SearchResultItem item,
  }) {
    return SearchReferenceSource(
      rank: rank,
      title: item.title,
      url: item.url,
      summary: item.snippet,
    );
  }

  String toPromptBlock() {
    final buffer = StringBuffer();
    buffer.writeln('[$rank] $title');
    buffer.writeln('URL: $url');
    if (summary.isNotEmpty) {
      buffer.writeln('Summary: $summary');
    }
    return buffer.toString().trimRight();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rank': rank,
      'title': title,
      'url': url,
      'summary': summary,
    };
  }
}
