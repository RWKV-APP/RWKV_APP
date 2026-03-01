// Package imports:
import 'package:halo/halo.dart';

(String, String) extractThoughtAndOutputForBatchInference(String text) {
  final lengthOfThinkEndTag = "</think>".length;

  try {
    final thinkTagStartIndex = text.indexOf("<think>");
    final isThinkingMessage = thinkTagStartIndex == 0;
    if (!isThinkingMessage) return ("", text);
    final thinkTagEndIndex = text.indexOf("</think>");
    if (thinkTagEndIndex == -1) {
      if (text.contains("<think>\n")) {
        return (text.replaceFirst("<think>\n", "").trim(), "");
      }
      return (text.replaceFirst("<think>", "").trim(), "");
    }

    int offsetAfterThinkingTag = lengthOfThinkEndTag;
    offsetAfterThinkingTag = lengthOfThinkEndTag;

    String thought = text
        .substring(thinkTagStartIndex, thinkTagEndIndex)
        .replaceFirst("<think>", "")
        .replaceFirst("</think>\n", "")
        .replaceFirst("</think>", "");
    thought = thought.trim();

    int outputStartIndex = thinkTagEndIndex + offsetAfterThinkingTag;
    if (outputStartIndex >= text.length) return (thought, "");

    String output = text.substring(outputStartIndex).replaceAll("<EOD>", "");
    output = output.replaceAll("\n\n", "\n");
    output = output.trim();

    return (thought, output);
  } catch (e) {
    final startIndex = text.indexOf("<think>");
    final isThinkingMessage = startIndex == 0;
    if (!isThinkingMessage) return ("", text);
    final endIndex = text.indexOf("</think>");
    qqe(e);
    qqe("text: $text");
    qqe("startIndex: $startIndex");
    qqe("endIndex: $endIndex");
    qqe("text.length: ${text.length}");
    return ("", text.trim());
  }
}
