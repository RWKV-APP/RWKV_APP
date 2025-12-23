import 'package:flutter/material.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

class CompletionSuggestionDialog extends StatefulWidget {
  final ScrollController scrollController;

  const CompletionSuggestionDialog(this.scrollController, {super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (c) => DraggableScrollableSheet(
        maxChildSize: .9,
        minChildSize: .25,
        expand: false,
        snap: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return CompletionSuggestionDialog(scrollController);
        },
      ),
    );
  }

  @override
  State<CompletionSuggestionDialog> createState() => _CompletionSuggestionDialogState();
}

class _CompletionSuggestionDialogState extends State<CompletionSuggestionDialog> {
  List<String> items = [];

  @override
  void initState() {
    super.initState();
    items = P.suggestion.config.q.completion;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const .symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Expanded(child: Text(s.suggest, style: theme.textTheme.titleMedium)),
                const CloseButton(),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  for (final item in items) ...[
                    ListTile(
                      title: Text(item, maxLines: 3, overflow: .ellipsis),
                      onTap: () {
                        Navigator.pop(context, item);
                      },
                    ),
                    const Divider(indent: 16, endIndent: 16, height: 6, thickness: 0.5),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
