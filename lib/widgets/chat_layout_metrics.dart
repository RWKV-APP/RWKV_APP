const double chatInputBarMaxWidth = 900.0;
const double chatNonBatchMessageMaxWidth = chatInputBarMaxWidth + 80.0;
const double chatBatchListPaddingBreakpoint = 1280.0;

double resolveChatMessageMaxWidth({
  required double viewportWidth,
  required bool isBatch,
}) {
  if (isBatch) return viewportWidth;
  return chatNonBatchMessageMaxWidth;
}

double resolveChatBatchListHorizontalPadding({
  required double viewportWidth,
}) {
  if (viewportWidth < chatBatchListPaddingBreakpoint) return 0.0;

  final padding = (viewportWidth - chatNonBatchMessageMaxWidth) / 2;
  if (padding <= 0) return 0.0;
  return padding;
}
