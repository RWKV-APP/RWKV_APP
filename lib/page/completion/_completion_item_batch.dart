import 'package:flutter/material.dart';
import 'package:zone/page/completion/_completion_controller.dart';
import 'package:zone/page/completion/_completion_list_item.dart';

import '_completion_state.dart' show CompletionItemNode;

class CompletionItemBatch extends StatefulWidget {
  final CompletionItemNode item;
  final Widget? footer;
  final bool isLast;

  CompletionItemBatch({super.key, required this.item, this.footer, required this.isLast});

  @override
  State<CompletionItemBatch> createState() => _CompletionItemBatchState();
}

class _CompletionItemBatchState extends State<CompletionItemBatch> {
  final style = const TextStyle(fontSize: 14, height: 2, letterSpacing: 1, overflow: TextOverflow.ellipsis);
  late final double lineHeight = _measureHeight('A');
  late final maxWidth = MediaQuery.of(context).size.width - 100;
  final node2lines = <int, int>{};

  @override
  void initState() {
    super.initState();
  }

  double _measureHeight(String content) {
    final tp = TextPainter(
      text: TextSpan(text: content, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return tp.height;
  }

  int _measureLineCount(String content) {
    final tp = TextPainter(
      text: TextSpan(text: content, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return tp.computeLineMetrics().length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final node in widget.item.siblings)
          GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            child: _selection(node),
            onTap: () {
              CompletionController.current.switchChooseTo(node);
            },
          ),
        if (widget.footer != null) widget.footer!,
        if (widget.isLast) const SizedBox(height: 12),
      ],
    );
  }

  Widget _selection(CompletionItemNode node) {
    int lines = node2lines[node.id] ?? 1;
    if (lines < 3) {
      lines = _measureLineCount(node.content);
      node2lines[node.id] = lines;
    }
    final selected = node.selected;
    final collapsed = !selected && node.parent.switched;
    final expanded = node.selected && node.parent.switched;
    final content = SelectableText(
      node.content,
      style: style.copyWith(color: collapsed ? Colors.grey : null),
      onTap: () {
        CompletionController.current.switchChooseTo(node);
      },
    );
    final showLines = collapsed ? 1 : lines.clamp(1, 3);
    return Container(
      margin: node.index == 0 ? null : const EdgeInsets.only(top: 12),
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
                      right: 0,
                      left: 0,
                      bottom: 0,
                      child: content,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
