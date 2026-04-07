// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

class CompletionSuggestionDialog extends StatelessWidget {
  final ScrollController scrollController;
  final List<String> items;

  const CompletionSuggestionDialog({
    super.key,
    required this.scrollController,
    required this.items,
  });

  static Future<String?> show(BuildContext context) {
    final theme = Theme.of(context);
    final items = P.suggestion.config.q.completion;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      builder: (context) {
        return DraggableScrollableSheet(
          maxChildSize: .9,
          minChildSize: .25,
          expand: false,
          snap: false,
          builder: (context, scrollController) {
            return CompletionSuggestionDialog(
              scrollController: scrollController,
              items: items,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.suggest,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const CloseButton(),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  for (final (index, item) in items.indexed)
                    _SuggestionItem(
                      text: item,
                      showDivider: index != items.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final String text;
  final bool showDivider;

  const _SuggestionItem({
    required this.text,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(text);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 16, right: 16),
            color: theme.dividerColor,
          ),
      ],
    );
  }
}
