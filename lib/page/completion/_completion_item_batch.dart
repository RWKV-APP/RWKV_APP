// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:zone/page/completion/_completion_controller.dart';
import 'package:zone/page/completion/_completion_list_item.dart';
import 'package:zone/page/completion/_completion_state.dart';

class CompletionItemBatch extends StatelessWidget {
  final CompletionItemNode item;
  final Widget? footer;
  final bool isLast;
  final TextStyle textStyle;

  const CompletionItemBatch({
    super.key,
    required this.item,
    this.footer,
    required this.isLast,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        for (final node in item.siblings)
          _BatchChoice(
            node: node,
            textStyle: textStyle,
          ),
        ?footer,
        if (isLast) const SizedBox(height: 12),
      ],
    );
  }
}

class _BatchChoice extends StatelessWidget {
  final CompletionItemNode node;
  final TextStyle textStyle;

  const _BatchChoice({
    required this.node,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () {
        CompletionController.current.switchChooseTo(node);
      },
      child: _BatchChoiceContent(
        node: node,
        textStyle: textStyle,
      ),
    );
  }
}

class _BatchChoiceContent extends StatelessWidget {
  final CompletionItemNode node;
  final TextStyle textStyle;

  const _BatchChoiceContent({
    required this.node,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width - 100;
        final lineHeight = _measureHeight(
          content: 'A',
          style: textStyle,
          maxWidth: maxWidth,
        );
        final lineCount = _measureLineCount(
          content: node.content,
          style: textStyle,
          maxWidth: maxWidth,
        );
        final collapsed = !node.selected && node.parent.switched;
        final expanded = node.selected && node.parent.switched;
        final showLines = collapsed ? 1 : lineCount.clamp(1, 3);
        final content = SelectableText(
          node.content,
          style: textStyle.copyWith(
            color: collapsed ? Colors.grey : theme.textTheme.bodyMedium?.color,
          ),
          onTap: () {
            CompletionController.current.switchChooseTo(node);
          },
        );

        return Container(
          margin: EdgeInsets.only(top: node.index == 0 ? 0 : 12),
          child: CompletionItemDecoration(
            isUser: false,
            gray: collapsed,
            child: expanded
                ? content
                : ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: lineHeight * showLines),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: content,
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

double _measureHeight({
  required String content,
  required TextStyle style,
  required double maxWidth,
}) {
  final textPainter = TextPainter(
    text: TextSpan(text: content, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);

  return textPainter.height;
}

int _measureLineCount({
  required String content,
  required TextStyle style,
  required double maxWidth,
}) {
  final textPainter = TextPainter(
    text: TextSpan(text: content, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);

  return textPainter.computeLineMetrics().length;
}
