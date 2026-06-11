// Dart imports:
import 'dart:convert';

class AlbatrossSseChoice {
  final int index;
  final String content;
  final String? finishReason;

  const AlbatrossSseChoice({
    required this.index,
    required this.content,
    required this.finishReason,
  });
}

class AlbatrossSseEvent {
  final bool done;
  final List<AlbatrossSseChoice> choices;

  const AlbatrossSseEvent({
    required this.done,
    required this.choices,
  });

  const AlbatrossSseEvent.done() : done = true, choices = const <AlbatrossSseChoice>[];
}

class AlbatrossSseParser {
  String _pending = "";

  List<AlbatrossSseEvent> add(String chunk) {
    _pending = _pending + chunk;
    final events = <AlbatrossSseEvent>[];

    while (true) {
      final separatorIndex = _pending.indexOf("\n\n");
      if (separatorIndex < 0) break;

      final rawEvent = _pending.substring(0, separatorIndex);
      _pending = _pending.substring(separatorIndex + 2);
      final event = _parseEvent(rawEvent);
      if (event == null) continue;
      events.add(event);
    }

    return events;
  }

  AlbatrossSseEvent? _parseEvent(String rawEvent) {
    final lines = rawEvent.split(RegExp(r'\r?\n'));
    final dataLines = <String>[];
    for (final line in lines) {
      if (!line.startsWith("data:")) continue;
      dataLines.add(line.substring(5).trimLeft());
    }
    if (dataLines.isEmpty) return null;

    final data = dataLines.join("\n").trim();
    if (data.isEmpty) return null;
    if (data == "[DONE]") return const AlbatrossSseEvent.done();

    final decoded = jsonDecode(data);
    if (decoded is! Map) return null;

    final rawChoices = decoded["choices"];
    if (rawChoices is! List) {
      return const AlbatrossSseEvent(done: false, choices: <AlbatrossSseChoice>[]);
    }

    final choices = <AlbatrossSseChoice>[];
    for (final rawChoice in rawChoices) {
      if (rawChoice is! Map) continue;
      final rawIndex = rawChoice["index"];
      final index = rawIndex is int ? rawIndex : 0;
      final delta = rawChoice["delta"];
      final String content;
      if (delta is Map) {
        content = delta["content"] as String? ?? "";
      } else {
        content = rawChoice["text"] as String? ?? "";
      }
      choices.add(
        AlbatrossSseChoice(
          index: index,
          content: content,
          finishReason: rawChoice["finish_reason"] as String?,
        ),
      );
    }

    return AlbatrossSseEvent(done: false, choices: choices);
  }
}

bool shouldShowAlbatrossEntry({
  required bool isWindows,
  required bool isWindowsX64,
  required String gpuName,
}) {
  if (!isWindows) return false;
  if (!isWindowsX64) return false;
  return gpuName.toLowerCase().contains("nvidia");
}

String buildAlbatrossCompletionPrompt(List<String> messages) {
  final buffer = StringBuffer();
  for (int i = 0; i < messages.length; i++) {
    final role = i.isEven ? "User" : "Assistant";
    final content = i.isEven ? messages[i].trim() : stripAlbatrossThinking(messages[i]).trim();
    if (content.isEmpty) continue;
    buffer.writeln("$role: $content");
    buffer.writeln();
  }
  buffer.write("Assistant:");
  return buffer.toString();
}

String stripAlbatrossThinking(String value) {
  return value.replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '').trim();
}
