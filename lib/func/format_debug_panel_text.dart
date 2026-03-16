// Flutter imports:
import 'package:flutter/material.dart';

const String kDebugSpaceSymbol = '␣';

const List<String> kDebugPanelSymbolFontFallback = [
  'Menlo',
  'Monaco',
  'Courier',
  'SF Pro',
  'Apple Symbols',
  'Segoe UI Symbol',
  'Noto Sans Symbols 2',
  'Noto Sans Symbols',
  'Symbola',
];

TextSpan buildDebugPanelTextSpan({
  required String text,
  required TextStyle baseStyle,
  required bool showEscapeCharacters,
  required bool showSpaceSymbols,
  required Color spaceTextColor,
  required Color spaceBackgroundColor,
  required Color newlineTextColor,
  required Color newlineBackgroundColor,
}) {
  if (!text.contains(r'\n') && !text.contains('\n') && (!showSpaceSymbols || !text.contains(' '))) {
    return TextSpan(text: text, style: baseStyle);
  }

  final spans = <InlineSpan>[];
  final buffer = StringBuffer();
  final newlineStyle = baseStyle.copyWith(
    color: newlineTextColor,
    backgroundColor: newlineBackgroundColor,
    fontWeight: FontWeight.w600,
    fontFamilyFallback: kDebugPanelSymbolFontFallback,
  );
  final spaceStyle = baseStyle.copyWith(
    color: spaceTextColor,
    backgroundColor: spaceBackgroundColor,
    fontWeight: FontWeight.w600,
    fontFamilyFallback: kDebugPanelSymbolFontFallback,
  );

  void flushBuffer() {
    if (buffer.isEmpty) {
      return;
    }

    spans.add(TextSpan(text: buffer.toString()));
    buffer.clear();
  }

  int index = 0;
  while (index < text.length) {
    final current = text[index];
    final next = index + 1 < text.length ? text[index + 1] : null;
    final isEscapedNewline = current == '\\' && next == 'n';

    if (isEscapedNewline) {
      flushBuffer();
      spans.add(
        TextSpan(
          text: showEscapeCharacters ? '\n' : r'\n',
          style: showEscapeCharacters ? null : newlineStyle,
        ),
      );
      index += 2;
      continue;
    }

    if (current == '\n') {
      flushBuffer();
      spans.add(
        TextSpan(
          text: showEscapeCharacters ? '\n' : r'\n',
          style: showEscapeCharacters ? null : newlineStyle,
        ),
      );
      index += 1;
      continue;
    }

    if (current == ' ' && showSpaceSymbols) {
      flushBuffer();
      spans.add(TextSpan(text: kDebugSpaceSymbol, style: spaceStyle));
      index += 1;
      continue;
    }

    buffer.write(current);
    index += 1;
  }

  flushBuffer();
  return TextSpan(style: baseStyle, children: spans);
}
