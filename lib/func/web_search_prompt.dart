typedef WebSearchPromptParts = ({String query, String footer});

WebSearchPromptParts splitWebSearchPrompt({
  required String prompt,
  required String userMsgFooter,
}) {
  if (userMsgFooter.isEmpty) {
    return (query: prompt, footer: '');
  }
  if (!prompt.endsWith(userMsgFooter)) {
    return (query: prompt, footer: '');
  }

  final query = prompt.substring(0, prompt.length - userMsgFooter.length).trimRight();
  return (query: query, footer: userMsgFooter);
}
