class Reference {
  final String url;
  final String summary;
  final String title;
  final String publishedAt;

  Reference({required this.url, required this.summary, required this.title, this.publishedAt = ''});

  Uri? get webUri {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty || uri.userInfo.isNotEmpty) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return uri;
  }

  factory Reference.fromJson(dynamic json) {
    return Reference(
      url: json['url'] ?? '',
      summary: json['summary'] ?? '',
      title: json['title'] ?? '',
      publishedAt: json['publishedAt'] is String ? json['publishedAt'] as String : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'summary': summary,
      'title': title,
      if (publishedAt.isNotEmpty) 'publishedAt': publishedAt,
    };
  }
}
