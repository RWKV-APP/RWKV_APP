(String, String) extrackThoughtAndOutput(String text) {
  final startIndex = text.indexOf("<think>");
  final isThinkingMessage = startIndex == 0;
  if (!isThinkingMessage) return ("", text);
  final endIndex = text.indexOf("</think>");
  if (endIndex == -1) return (text.replaceFirst("<think>\n", ""), "");
  final thought = text.substring(startIndex, endIndex);
  final output = text.substring(endIndex + 9);
  return (thought, output);
}
