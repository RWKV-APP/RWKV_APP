import 'package:halo/halo.dart';

(String, String) extrackThoughtAndOutput(String text) {
  // return ("", text);
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
    final thought = text
        .substring(thinkTagStartIndex, thinkTagEndIndex)
        .replaceFirst("<think>", "")
        .replaceFirst("</think>\n", "")
        .replaceFirst("</think>", "");
    int outputStartIndex = thinkTagEndIndex + 9;
    if (outputStartIndex >= text.length) return (thought, "");
    final output = text.substring(outputStartIndex).replaceAll("<EOD>", "");
    return (thought.trim().replaceAll("\n\n", "\n"), output.trim().replaceAll("\n\n", "\n"));
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
