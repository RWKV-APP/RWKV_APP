import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/page/completion/_completion_state.dart';

import '_completion_controller.dart';

class CompletionListItem extends ConsumerWidget {
  final CompletionItemState item;
  final Widget? footer;

  CompletionListItem({super.key, required this.item, this.footer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final content = Container(
      margin: footer != null ? null : EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: item.isUser ? null : theme.primaryColor.withAlpha(12),
        border: Border(
          left: BorderSide(
            color: item.isUser ? Colors.black : theme.primaryColor,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 16),
      child: SelectableText(
        item.chooses[item.index].content, //
        style: TextStyle(fontSize: 14, height: 2, letterSpacing: 1),
      ),
    );
    if (footer == null) return content;
    return Column(
      children: [
        content,
        footer!,
        const SizedBox(height: 20),
      ],
    );
  }
}

class CompletionListItemFooter extends ConsumerWidget {
  final CompletionItemState item;

  CompletionListItemFooter({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasChooses = item.chooses.length > 1;

    final speed = Text(
      "Prefill：0.0t/s  Decode:0.0t/s",
      style: TextStyle(fontSize: 8),
      textAlign: TextAlign.end,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.translate(
          offset: Offset(-8, 0),
          child: IconButton(
            onPressed: () {
              CompletionController.current.onRegenerateTap(item);
            },
            icon: Icon(Icons.refresh_rounded, size: 18),
          ),
        ),
        if (!hasChooses) Expanded(child: speed),
        if (hasChooses)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: item.index == 0 ? null : () => CompletionController.current.onPrevChooseTap(item),
                  icon: Icon(
                    Icons.arrow_circle_left_outlined,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.index + 1}/${item.chooses.length}',
                  style: TextStyle(fontSize: 10, color: theme.primaryColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: item.index == item.chooses.length - 1 ? null : () => CompletionController.current.onNextChooseTap(item),
                  icon: Icon(Icons.arrow_circle_right_outlined, size: 18),
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Flexible(child: speed),
              ],
            ),
          ),
      ],
    );
  }
}
