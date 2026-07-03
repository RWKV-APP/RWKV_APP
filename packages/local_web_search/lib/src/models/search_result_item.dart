class SearchResultItem {
  final String title;
  final String url;
  final String snippet;

  const SearchResultItem({
    required this.title,
    required this.url,
    required this.snippet,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final url = json['url'];
    final snippet = json['snippet'];

    return SearchResultItem(
      title: title is String ? title.trim() : '',
      url: url is String ? url.trim() : '',
      snippet: snippet is String ? snippet.trim() : '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'title': title, 'url': url, 'snippet': snippet};
  }
}
