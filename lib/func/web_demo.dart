// Dart imports:
import 'dart:io';

// Package imports:
import 'package:path/path.dart' as path;

// Project imports:
import 'package:zone/config.dart';

const String webDemoPromptPlaceholder = "{{prompt}}";
const String webDemoDefaultPromptTemplate = "User: Write HTML: {{prompt}}\n\nAssistant: <think></think";

class WebDemoHtmlDocument {
  final String html;
  final int start;
  final int end;
  final bool complete;

  const WebDemoHtmlDocument({
    required this.html,
    required this.start,
    required this.end,
    required this.complete,
  });
}

class WebDemoCloudChoice {
  final int index;
  final String content;

  const WebDemoCloudChoice({
    required this.index,
    required this.content,
  });
}

String buildWebDemoPrompt({
  required String template,
  required String request,
}) {
  final normalizedTemplate = template.trim().isEmpty ? webDemoDefaultPromptTemplate : template.trim();
  if (normalizedTemplate.contains(webDemoPromptPlaceholder)) {
    return normalizedTemplate.replaceAll(webDemoPromptPlaceholder, request.trim());
  }
  if (normalizedTemplate.contains("{prompt}")) {
    return normalizedTemplate.replaceAll("{prompt}", request.trim());
  }
  return "$normalizedTemplate\n\nUser request:\n${request.trim()}";
}

String buildWebDemoEditPrompt({
  required String html,
  required String instruction,
}) {
  return """User: Modify the HTML below according to this request:
${instruction.trim()}

Return a complete HTML document.

HTML:
```html
${html.trim()}
```

Assistant: <think></think""";
}

WebDemoHtmlDocument? extractFirstWebDemoHtml(String text) {
  final documents = extractWebDemoHtmlDocuments(text);
  if (documents.isEmpty) return null;
  return documents.first;
}

List<WebDemoHtmlDocument> extractWebDemoHtmlDocuments(String text) {
  if (text.trim().isEmpty) return const <WebDemoHtmlDocument>[];

  final visibleStart = _visibleStartIndex(text);
  final visible = _stripHtmlCodeFence(text.substring(visibleStart));
  final lower = visible.toLowerCase();
  final documents = _extractDocumentsByStartToken(
    visible: visible,
    visibleStart: visibleStart,
    lower: lower,
    startToken: "<!doctype html",
  );
  if (documents.isNotEmpty) return documents;

  return _extractDocumentsByStartToken(
    visible: visible,
    visibleStart: visibleStart,
    lower: lower,
    startToken: "<html",
  );
}

List<String> splitWebDemoBatchContent(String content) {
  if (!content.contains(Config.batchMarker)) return <String>[content];
  final parts = content.split(Config.batchMarker);
  return parts.where((part) => part.trim().isNotEmpty).toList();
}

List<WebDemoCloudChoice> extractWebDemoCloudChoiceContents(Map<String, Object?> response) {
  final rawChoices = response["choices"];
  if (rawChoices is! List) return const <WebDemoCloudChoice>[];

  final choices = <WebDemoCloudChoice>[];
  for (int order = 0; order < rawChoices.length; order++) {
    final rawChoice = rawChoices[order];
    if (rawChoice is! Map) continue;

    final index = rawChoice["index"];
    final content = _extractCloudChoiceContent(rawChoice);
    if (content == null) continue;
    choices.add(
      WebDemoCloudChoice(
        index: index is int ? index : order,
        content: content,
      ),
    );
  }

  return choices;
}

List<String> buildWebDemoCloudChoiceOutputs({
  required List<WebDemoCloudChoice> choices,
  required int batchSize,
  required String prompt,
}) {
  if (batchSize <= 0) return const <String>[];

  final outputs = List<String>.filled(batchSize, "");
  int nextFallbackIndex = 0;
  for (final choice in choices) {
    final targetIndex = choice.index >= 0 && choice.index < batchSize ? choice.index : nextFallbackIndex;
    nextFallbackIndex++;
    if (targetIndex < 0 || targetIndex >= outputs.length) continue;
    outputs[targetIndex] = stripWebDemoPromptPrefix(content: choice.content, prompt: prompt);
  }
  return outputs;
}

String stripWebDemoPromptPrefix({
  required String content,
  required String prompt,
}) {
  if (content.isEmpty) return "";
  if (!content.startsWith(prompt)) return content;
  return content.substring(prompt.length);
}

Future<File> writeWebDemoHtmlFile({
  required Directory root,
  required String html,
  required String label,
}) async {
  final dir = Directory(path.join(root.path, "web_demo"));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final fileName = _safeFileName(label);
  final file = File(path.join(dir.path, "$fileName.html"));
  await file.writeAsString(html);
  return file;
}

List<WebDemoHtmlDocument> _extractDocumentsByStartToken({
  required String visible,
  required int visibleStart,
  required String lower,
  required String startToken,
}) {
  final documents = <WebDemoHtmlDocument>[];
  int cursor = 0;

  while (cursor < visible.length) {
    final start = lower.indexOf(startToken, cursor);
    if (start < 0) break;

    final bodyStart = lower.indexOf("<body", start);
    if (bodyStart < 0) {
      cursor = start + 1;
      continue;
    }

    final nextStart = lower.indexOf("<!doctype html", start + 1);
    final htmlEnd = lower.indexOf("</html>", start);
    final hasCompleteEnd = htmlEnd >= 0 && (nextStart < 0 || htmlEnd < nextStart);
    final end = hasCompleteEnd
        ? htmlEnd + "</html>".length
        : nextStart > start
        ? nextStart
        : visible.length;
    final html = visible.substring(start, end).trim();
    if (html.isNotEmpty) {
      documents.add(
        WebDemoHtmlDocument(
          html: html,
          start: visibleStart + start,
          end: visibleStart + end,
          complete: hasCompleteEnd,
        ),
      );
    }
    cursor = end;
  }

  return documents;
}

int _visibleStartIndex(String text) {
  final lower = text.toLowerCase();
  final marker = lower.indexOf("</think>");
  if (marker < 0) return 0;
  return marker + "</think>".length;
}

String _stripHtmlCodeFence(String text) {
  final trimmed = text.trim();
  if (!trimmed.startsWith("```")) return text;

  final firstBreak = trimmed.indexOf("\n");
  if (firstBreak < 0) return text;
  final firstLine = trimmed.substring(0, firstBreak).toLowerCase();
  if (firstLine != "```html" && firstLine != "```") return text;

  final fenceEnd = trimmed.lastIndexOf("```");
  if (fenceEnd <= firstBreak) return trimmed.substring(firstBreak + 1);
  return trimmed.substring(firstBreak + 1, fenceEnd).trim();
}

String? _extractCloudChoiceContent(Map rawChoice) {
  final message = rawChoice["message"];
  if (message is Map) {
    final content = message["content"];
    if (content is String) return content;
  }

  final delta = rawChoice["delta"];
  if (delta is Map) {
    final content = delta["content"];
    if (content is String) return content;
  }

  final text = rawChoice["text"];
  if (text is String) return text;

  final content = rawChoice["content"];
  if (content is String) return content;

  return null;
}

String _safeFileName(String label) {
  final trimmed = label.trim().isEmpty ? "web-demo" : label.trim();
  final normalized = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), "-");
  final clipped = normalized.length > 64 ? normalized.substring(0, 64) : normalized;
  final suffix = DateTime.now().millisecondsSinceEpoch;
  return "$clipped-$suffix";
}
