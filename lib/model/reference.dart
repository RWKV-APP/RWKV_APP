class Reference {
  final String url;
  final String summary;
  final String title;

  Reference({required this.url, required this.summary, required this.title});

  factory Reference.fromJson(dynamic json) {
    return Reference(
      url: json['url'] ?? '',
      summary: json['summary'] ?? '',
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'summary': summary,
      'title': title,
    };
  }
}
