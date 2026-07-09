import 'dart:convert';

import 'package:local_web_search/src/models/search_reference_source.dart';

class SearchDeepResult {
  static final RegExp _whitespacePattern = RegExp(r'[ \t\r\f\v]+');
  static final RegExp _blankLinePattern = RegExp(r'\n{3,}');

  final int rank;
  final String title;
  final String url;
  final String markdown;
  final int rawTextLength;
  final int markdownLength;
  final String? error;

  const SearchDeepResult({
    required this.rank,
    required this.title,
    required this.url,
    required this.markdown,
    required this.rawTextLength,
    required this.markdownLength,
    this.error,
  });

  factory SearchDeepResult.failure({
    required SearchReferenceSource source,
    required String message,
  }) {
    return SearchDeepResult(
      rank: source.rank,
      title: source.title,
      url: source.url,
      markdown: '',
      rawTextLength: 0,
      markdownLength: 0,
      error: message,
    );
  }

  factory SearchDeepResult.fromJavaScriptResult({
    required SearchReferenceSource source,
    required Object? result,
    required int maxCharacters,
  }) {
    if (result == null) {
      return SearchDeepResult.failure(
        source: source,
        message: 'Deep extraction returned no result.',
      );
    }

    final raw = result is String ? result : jsonEncode(result);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return SearchDeepResult.failure(
          source: source,
          message: 'Deep extraction result is not a JSON object.',
        );
      }

      final error = decoded['error']?.toString() ?? '';
      final pageTitle = _cleanInline(decoded['title']?.toString() ?? '');
      final pageUrl = _cleanInline(decoded['href']?.toString() ?? '');
      final markdown = _fitMarkdown(
        decoded['markdown']?.toString() ?? '',
        maxCharacters,
      );
      final rawTextLength = _intValue(decoded['rawTextLength']);
      final markdownLength = _intValue(decoded['markdownLength']);
      final title = pageTitle.isEmpty ? source.title : pageTitle;
      final url = pageUrl.isEmpty ? source.url : pageUrl;

      return SearchDeepResult(
        rank: source.rank,
        title: title,
        url: url,
        markdown: markdown,
        rawTextLength: rawTextLength,
        markdownLength: markdownLength,
        error: error.isEmpty ? null : error,
      );
    } catch (error) {
      return SearchDeepResult.failure(
        source: source,
        message: error.toString(),
      );
    }
  }

  bool get hasError => error != null && error!.isNotEmpty;

  bool get hasContent => markdown.trim().isNotEmpty && !hasError;

  String toPromptBlock() {
    final buffer = StringBuffer();
    buffer.writeln('[Deep $rank] $title');
    buffer.writeln('URL: $url');
    buffer.writeln('Extracted page content:');
    buffer.write(markdown.trim());
    return buffer.toString().trimRight();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rank': rank,
      'title': title,
      'url': url,
      'markdown': markdown,
      'rawTextLength': rawTextLength,
      'markdownLength': markdownLength,
      'error': error,
    };
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static String _cleanInline(String text) {
    return text.replaceAll(_whitespacePattern, ' ').trim();
  }

  static String _fitMarkdown(String text, int maxCharacters) {
    if (maxCharacters <= 0) return '';
    final compact = text
        .replaceAll('\u00a0', ' ')
        .replaceAll(_whitespacePattern, ' ')
        .replaceAll(_blankLinePattern, '\n\n')
        .trim();
    if (compact.length <= maxCharacters) return compact;
    return compact.substring(0, maxCharacters).trimRight();
  }
}
