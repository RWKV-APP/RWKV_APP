import 'package:zone/store/rag.dart';

enum ReferenceType { web, document, unknown }

class Reference {
  final String url;
  final String summary;
  final String title;
  final ReferenceType type;

  Reference({required this.url, required this.summary, required this.title, required this.type});

  factory Reference.fromJson(dynamic json) {
    return Reference(
      url: json['url'] ?? '',
      summary: json['summary'] ?? '',
      title: json['title'] ?? '',
      type: ReferenceType.values[json['type'] ?? 0],
    );
  }

  factory Reference.fromDocSearch(ChunkQueryResult result) {
    return Reference(
      url: '',
      summary: result.text,
      title: result.documentName,
      type: ReferenceType.document,
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'summary': summary, 'title': title, 'type': type.index};
  }
}
