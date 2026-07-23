// Dart imports:
import 'dart:convert';

// Project imports:
import 'package:zone/model/agent.dart';

enum G1hAgentOutputKind {
  finalAnswer,
  toolCall,
  incompleteToolCall,
  malformedToolCall,
}

final class G1hAgentOutput {
  final G1hAgentOutputKind kind;
  final String finalAnswer;
  final AgentToolCall? toolCall;
  final String error;
  final List<AgentInterventionKind> interventions;

  const G1hAgentOutput({
    required this.kind,
    this.finalAnswer = "",
    this.toolCall,
    this.error = "",
    this.interventions = const <AgentInterventionKind>[],
  });
}

final class G1hAgentProtocol {
  static const String toolCallOpen = "<tool_call>";
  static const String toolCallClose = "</tool_call>";
  static const String thinkClose = "</think>";

  const G1hAgentProtocol();

  String buildPrompt({
    required String system,
    required String user,
    required List<AgentToolDefinition> tools,
  }) {
    final buffer = StringBuffer("<s>");
    if (system.trim().isNotEmpty) {
      buffer
        ..write("System: ")
        ..write(system.trim())
        ..write("\n\n");
    }

    if (tools.isNotEmpty) {
      buffer.write(
        "System: You may call tools to help answer the user. "
        "Available tools are listed as JSON inside <tools></tools>. "
        "If a tool is needed, return exactly one tool call as JSON inside "
        "<tool_call></tool_call>. Do not invent tool names or arguments.\n\n",
      );
      buffer.write("<tools>\n");
      for (final tool in tools) {
        buffer
          ..write(jsonEncode(tool.toJson()))
          ..write("\n");
      }
      buffer.write("</tools>\n\n");
      buffer.write(
        "Tool call format:\n"
        "<tool_call>\n"
        '{"name": "tool_name", "arguments": {"arg": "value"}}\n'
        "</tool_call>\n\n",
      );
    }

    buffer
      ..write("User: ")
      ..write(user.trim())
      ..write("\n\nAssistant: <think>");
    return buffer.toString();
  }

  G1hAgentOutput parse(
    String output, {
    required int callOrdinal,
    AgentEvaluationMode mode = .assisted,
  }) {
    final openIndex = output.indexOf(toolCallOpen);
    if (openIndex < 0) {
      return G1hAgentOutput(
        kind: .finalAnswer,
        finalAnswer: finalAnswerFromOutput(output),
      );
    }

    final jsonStart = openIndex + toolCallOpen.length;
    final closeIndex = output.indexOf(toolCallClose, jsonStart);
    final rawEnvelope = closeIndex < 0 ? output.substring(jsonStart).trim() : output.substring(jsonStart, closeIndex).trim();
    if (rawEnvelope.isEmpty) {
      return const G1hAgentOutput(kind: .incompleteToolCall);
    }

    final hasForeignBoundary = _hasForeignBoundary(rawEnvelope);
    if (mode == .strict && closeIndex < 0) {
      if (!hasForeignBoundary) {
        return const G1hAgentOutput(kind: .incompleteToolCall);
      }
      return const G1hAgentOutput(
        kind: .malformedToolCall,
        error: "Strict tool calls must end with </tool_call>",
      );
    }

    final interventions = <AgentInterventionKind>[];
    final boundedEnvelope = hasForeignBoundary ? _beforeForeignBoundary(rawEnvelope) : rawEnvelope;
    final extracted = mode == .strict
        ? (
            json: boundedEnvelope.trim(),
            complete: true,
            interventions: const <AgentInterventionKind>[],
          )
        : _extractToolJsonText(boundedEnvelope);
    interventions.addAll(extracted.interventions);
    final rawJson = extracted.json;
    AgentJson? decoded = _decodeStrictObject(rawJson);
    if (decoded == null && mode == .assisted) {
      final repaired = _repairJson(rawJson);
      decoded = _decodeStrictObject(repaired);
      if (decoded != null) {
        interventions.add(.jsonRepair);
      } else if (closeIndex >= 0 || hasForeignBoundary) {
        decoded = _decodeStrictObject(_completeJsonContainers(repaired));
        if (decoded != null) {
          interventions.add(.jsonContainerCompletion);
        }
      }
    }
    if (decoded == null) {
      if (closeIndex < 0 && !extracted.complete) {
        return const G1hAgentOutput(kind: .incompleteToolCall);
      }
      return G1hAgentOutput(
        kind: .malformedToolCall,
        error: "Tool call must contain one valid JSON object",
        interventions: List<AgentInterventionKind>.unmodifiable(interventions),
      );
    }

    final normalized = mode == .strict
        ? (value: decoded, changed: false)
        : _normalizeToolEnvelope(
            decoded,
            rawEnvelope: boundedEnvelope,
          );
    if (normalized.changed) {
      interventions.add(.envelopeNormalization);
    }
    final normalizedEnvelope = normalized.value;
    if (mode == .strict) {
      final keys = normalizedEnvelope.keys.toSet();
      if (keys.length != 2 || !keys.contains("name") || !keys.contains("arguments")) {
        return const G1hAgentOutput(
          kind: .malformedToolCall,
          error: "Strict tool calls must contain only name and arguments",
        );
      }
    }
    final name = normalizedEnvelope["name"];
    final arguments = normalizedEnvelope["arguments"];
    if (name is! String || name.trim().isEmpty) {
      return const G1hAgentOutput(
        kind: .malformedToolCall,
        error: "Tool call name must be a non-empty string",
      );
    }
    if (arguments is! Map) {
      return const G1hAgentOutput(
        kind: .malformedToolCall,
        error: "Tool call arguments must be an object",
      );
    }

    final normalizedArguments = <String, Object?>{};
    for (final entry in arguments.entries) {
      if (entry.key is! String) {
        return const G1hAgentOutput(
          kind: .malformedToolCall,
          error: "Tool call argument keys must be strings",
        );
      }
      normalizedArguments[entry.key as String] = entry.value;
    }

    return G1hAgentOutput(
      kind: .toolCall,
      toolCall: AgentToolCall(
        id: "call_$callOrdinal",
        name: name,
        arguments: normalizedArguments,
        raw: rawJson,
        interventions: List<AgentInterventionKind>.unmodifiable(interventions),
      ),
      interventions: List<AgentInterventionKind>.unmodifiable(interventions),
    );
  }

  String appendToolExchange({
    required String prompt,
    required String modelOutput,
    required AgentToolResult result,
  }) {
    final buffer = StringBuffer(prompt);
    buffer.write(modelOutput);
    if (!modelOutput.contains(toolCallClose)) {
      buffer.write("\n$toolCallClose");
    }
    buffer
      ..write("\n\nUser: <tool_response>\n")
      ..write(result.content)
      ..write("\n</tool_response>\n\nAssistant: <think>");
    return buffer.toString();
  }

  String finalAnswerFromOutput(String output) {
    String result = output;
    final thinkEndIndex = result.lastIndexOf(thinkClose);
    if (thinkEndIndex >= 0) {
      result = result.substring(thinkEndIndex + thinkClose.length);
    }
    result = result.replaceAll("<think>", "").replaceAll("<EOD>", "").replaceAll("</s>", "");
    return result.trim();
  }

  String? truncateAtRepeatedThinkClose(String output) {
    final firstIndex = output.indexOf(thinkClose);
    if (firstIndex < 0) return null;
    final secondIndex = output.indexOf(
      thinkClose,
      firstIndex + thinkClose.length,
    );
    if (secondIndex < 0) return null;
    return output.substring(0, secondIndex).trimRight();
  }

  String? truncateAtRepeatedText(
    String output, {
    int minimumLength = 800,
    int comparisonLength = 160,
    int requiredOccurrences = 3,
  }) {
    if (output.length < minimumLength || comparisonLength <= 0) return null;
    if (requiredOccurrences < 2 || output.length < comparisonLength) return null;

    final suffixStart = output.length - comparisonLength;
    final suffix = output.substring(suffixStart);
    int searchBefore = suffixStart;
    int occurrences = 1;
    int earliestMatch = suffixStart;
    while (searchBefore > 0) {
      final match = output.lastIndexOf(suffix, searchBefore - 1);
      if (match < 0) break;
      occurrences += 1;
      earliestMatch = match;
      if (occurrences >= requiredOccurrences) {
        return output.substring(0, earliestMatch + comparisonLength).trimRight();
      }
      searchBefore = match;
    }
    return null;
  }

  AgentJson? _decodeStrictObject(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final result = <String, Object?>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String) return null;
        result[entry.key as String] = entry.value;
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  String _repairJson(String raw) {
    final buffer = StringBuffer();
    bool inString = false;
    bool escaped = false;
    for (int index = 0; index < raw.length; index += 1) {
      final character = raw[index];
      if (!inString) {
        if (character == '"') {
          inString = true;
          buffer.write(character);
          continue;
        }
        if (character == ",") {
          final next = _nextNonWhitespace(raw, index + 1);
          if (next?.character == "}" || next?.character == "]") {
            continue;
          }
        }
        buffer.write(character);
        continue;
      }

      if (escaped) {
        escaped = false;
        buffer.write(character);
        continue;
      }
      if (character == "\\") {
        final next = index + 1 < raw.length ? raw[index + 1] : "";
        if (<String>{'"', "\\", "/", "b", "f", "n", "r", "t", "u"}.contains(next)) {
          escaped = true;
          buffer.write(character);
          continue;
        }
        buffer.write("\\\\");
        continue;
      }
      if (character == '"') {
        if (_quoteClosesJsonString(raw, index)) {
          inString = false;
          buffer.write(character);
          continue;
        }
        buffer.write('\\"');
        continue;
      }
      switch (character) {
        case "\n":
          buffer.write(r"\n");
        case "\r":
          buffer.write(r"\r");
        case "\t":
          buffer.write(r"\t");
        default:
          if (character.codeUnitAt(0) < 0x20) {
            buffer.write("\\u${character.codeUnitAt(0).toRadixString(16).padLeft(4, "0")}");
          } else {
            buffer.write(character);
          }
      }
    }
    return buffer.toString();
  }

  ({AgentJson value, bool changed}) _normalizeToolEnvelope(
    AgentJson decoded, {
    required String rawEnvelope,
  }) {
    if (decoded["name"] is String && decoded["arguments"] is Map) {
      return (value: decoded, changed: false);
    }
    if (decoded.length == 1) {
      final entry = decoded.entries.first;
      if (entry.value is Map) {
        return (
          value: <String, Object?>{
            "name": entry.key,
            "arguments": entry.value,
          },
          changed: true,
        );
      }
    }

    final objectStart = rawEnvelope.indexOf("{");
    if (objectStart < 0) return (value: decoded, changed: false);
    final prefix = rawEnvelope.substring(0, objectStart).trim();
    if (!RegExp(r"^[A-Za-z_][A-Za-z0-9_]*$").hasMatch(prefix)) {
      return (value: decoded, changed: false);
    }
    return (
      value: <String, Object?>{
        "name": prefix,
        "arguments": decoded,
      },
      changed: true,
    );
  }

  bool _hasForeignBoundary(String raw) {
    return raw.contains("</tool_response>") ||
        raw.contains("\n\nUser:") ||
        raw.contains("\nUser:") ||
        raw.contains("<EOD>") ||
        raw.contains("</s>");
  }

  String _beforeForeignBoundary(String raw) {
    int? boundary;
    for (final marker in <String>[
      "</tool_response>",
      "\n\nUser:",
      "\nUser:",
      "<EOD>",
      "</s>",
    ]) {
      final index = raw.indexOf(marker);
      if (index < 0) continue;
      if (boundary == null || index < boundary) {
        boundary = index;
      }
    }
    if (boundary == null) return raw;
    return raw.substring(0, boundary).replaceFirst(RegExp(r'</?[^<>]*$'), '').trimRight();
  }

  String _completeJsonContainers(String raw) {
    final stack = <String>[];
    bool inString = false;
    bool escaped = false;
    for (int index = 0; index < raw.length; index += 1) {
      final character = raw[index];
      if (inString) {
        if (escaped) {
          escaped = false;
          continue;
        }
        if (character == "\\") {
          escaped = true;
          continue;
        }
        if (character != '"') continue;
        inString = false;
        continue;
      }
      if (character == '"') {
        inString = true;
        continue;
      }
      if (character == "{") {
        stack.add("}");
        continue;
      }
      if (character == "[") {
        stack.add("]");
        continue;
      }
      if (character != "}" && character != "]") continue;
      if (stack.isEmpty || stack.last != character) return raw;
      stack.removeLast();
    }

    final buffer = StringBuffer(raw);
    if (inString) {
      buffer.write('"');
    }
    for (final closer in stack.reversed) {
      buffer.write(closer);
    }
    return buffer.toString();
  }

  bool _quoteClosesJsonString(String raw, int quoteIndex) {
    final next = _nextNonWhitespace(raw, quoteIndex + 1);
    if (next == null) return true;
    if (next.character == ":") return true;
    if (next.character == "}" || next.character == "]") {
      return _hasValidStructuralTail(raw, next.index);
    }
    if (next.character != ",") return false;
    final afterComma = _nextNonWhitespace(raw, next.index + 1);
    if (afterComma == null) return true;
    return <String>{'"', "}", "]"}.contains(afterComma.character);
  }

  bool _hasValidStructuralTail(String raw, int start) {
    for (int index = start; index < raw.length; index += 1) {
      final character = raw[index];
      if (character.trim().isEmpty) continue;
      if (character == "}" || character == "]") continue;
      if (character != ",") return false;
      final afterComma = _nextNonWhitespace(raw, index + 1);
      if (afterComma == null) return true;
      return <String>{'"', "}", "]"}.contains(afterComma.character);
    }
    return true;
  }

  ({int index, String character})? _nextNonWhitespace(
    String value,
    int start,
  ) {
    for (int index = start; index < value.length; index += 1) {
      final character = value[index];
      if (character.trim().isEmpty) continue;
      return (index: index, character: character);
    }
    return null;
  }

  ({
    String json,
    bool complete,
    List<AgentInterventionKind> interventions,
  })
  _extractToolJsonText(String raw) {
    String candidate = raw.trim();
    final interventions = <AgentInterventionKind>[];
    final repeatedOpenIndex = candidate.lastIndexOf(toolCallOpen);
    if (repeatedOpenIndex >= 0) {
      candidate = candidate.substring(repeatedOpenIndex + toolCallOpen.length).trim();
      interventions.add(.trailingTextExtraction);
    }
    if (candidate.startsWith("```")) {
      interventions.add(.fencedJsonExtraction);
      final firstNewline = candidate.indexOf("\n");
      if (firstNewline >= 0) {
        candidate = candidate.substring(firstNewline + 1);
      }
      final fenceEnd = candidate.indexOf("```");
      if (fenceEnd >= 0) {
        candidate = candidate.substring(0, fenceEnd);
      }
      candidate = candidate.trim();
    }

    final objectStart = candidate.indexOf("{");
    if (objectStart < 0) {
      return (
        json: candidate,
        complete: false,
        interventions: List<AgentInterventionKind>.unmodifiable(interventions),
      );
    }
    if (objectStart > 0) {
      interventions.add(.trailingTextExtraction);
    }
    final objectEnd = _jsonObjectEnd(candidate, objectStart);
    if (objectEnd == null) {
      return (
        json: candidate.substring(objectStart).trim(),
        complete: false,
        interventions: List<AgentInterventionKind>.unmodifiable(interventions),
      );
    }
    if (candidate.substring(objectEnd + 1).trim().isNotEmpty) {
      interventions.add(.trailingTextExtraction);
    }
    return (
      json: candidate.substring(objectStart, objectEnd + 1).trim(),
      complete: true,
      interventions: List<AgentInterventionKind>.unmodifiable(interventions),
    );
  }

  int? _jsonObjectEnd(String value, int start) {
    int depth = 0;
    bool inString = false;
    bool escaped = false;
    for (int index = start; index < value.length; index += 1) {
      final character = value[index];
      if (inString) {
        if (escaped) {
          escaped = false;
          continue;
        }
        if (character == "\\") {
          escaped = true;
          continue;
        }
        if (character == '"') {
          inString = false;
        }
        continue;
      }
      if (character == '"') {
        inString = true;
        continue;
      }
      if (character == "{") {
        depth += 1;
        continue;
      }
      if (character != "}") continue;
      depth -= 1;
      if (depth == 0) return index;
    }
    return null;
  }
}
