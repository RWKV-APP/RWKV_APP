// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/model/app_theme.dart' as app_theme;
import 'package:zone/model/debug_space_symbol.dart';

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

Color defaultDebugSpaceTextColor({
  required app_theme.AppTheme appTheme,
  required Color qb,
}) {
  return appTheme.primary;
}

Color defaultDebugSpaceBackgroundColor({
  required app_theme.AppTheme appTheme,
}) {
  return appTheme.primary.q(appTheme.isLight ? .18 : .24);
}

Color defaultDebugNewlineTextColor({
  required app_theme.AppTheme appTheme,
  required Color qb,
}) {
  return qb.q(appTheme.isLight ? .9 : .94);
}

Color defaultDebugNewlineBackgroundColor({
  required app_theme.AppTheme appTheme,
  required Color qb,
}) {
  return qb.q(appTheme.isLight ? .14 : .2);
}

TextSpan buildDebugPanelTextSpan({
  required String text,
  required TextStyle baseStyle,
  required bool showEscapeCharacters,
  required bool showSpaceSymbols,
  required DebugSpaceSymbol spaceSymbol,
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
      spans.add(TextSpan(text: spaceSymbol.symbol, style: spaceStyle));
      index += 1;
      continue;
    }

    buffer.write(current);
    index += 1;
  }

  flushBuffer();
  return TextSpan(style: baseStyle, children: spans);
}
