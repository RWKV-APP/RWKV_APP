// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/ref_info.dart';
import 'package:zone/model/reference.dart';

class SearchReferenceDialog extends StatelessWidget {
  final RefInfo refInfo;
  final ScrollController scrollController;

  const SearchReferenceDialog({super.key, required this.refInfo, required this.scrollController});

  static Future<void> show(BuildContext context, RefInfo ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 720),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (c) => DraggableScrollableSheet(
        initialChildSize: .6,
        maxChildSize: .9,
        minChildSize: .25,
        expand: false,
        snap: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return SearchReferenceDialog(refInfo: ref, scrollController: scrollController);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final provider = refInfo.trace?.searchEngineLabel ?? '';
    return Container(
      padding: const .fromLTRB(16, 0, 16, 16),
      width: double.infinity,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${s.reference_source} · ${refInfo.list.length}', style: theme.textTheme.titleMedium),
              ),
              const CloseButton(),
            ],
          ),
          if (provider.isNotEmpty)
            Padding(
              padding: const .only(bottom: 12),
              child: Text(provider, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          Expanded(
            child: Material(
              color: theme.scaffoldBackgroundColor,
              child: ListView.builder(
                controller: scrollController,
                itemCount: refInfo.list.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const .only(bottom: 10),
                    child: SearchReferenceCard(reference: refInfo.list[index], number: index + 1),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchReferenceCard extends StatelessWidget {
  final Reference reference;
  final int number;

  const SearchReferenceCard({super.key, required this.reference, required this.number});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uri = reference.webUri;
    final secondary = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Semantics(
      link: uri != null,
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: .circular(12),
        child: InkWell(
          borderRadius: .circular(12),
          onTap: uri == null ? null : () => launchUrl(uri),
          child: Padding(
            padding: const .all(14),
            child: Row(
              crossAxisAlignment: .start,
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  alignment: .center,
                  padding: const .all(4),
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: .circular(6)),
                  child: Text('$number', style: theme.textTheme.labelMedium),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      if (uri != null) ...[
                        Text(uri.host, textDirection: .ltr, style: secondary, maxLines: 1, overflow: .ellipsis),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        reference.title.isEmpty ? reference.url : reference.title,
                        maxLines: 3,
                        overflow: .ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (reference.summary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(reference.summary.replaceAll('\n', ' '), style: theme.textTheme.bodySmall, maxLines: 3, overflow: .ellipsis),
                      ],
                      const SizedBox(height: 6),
                      Tooltip(
                        message: reference.url,
                        child: Text(reference.url, textDirection: .ltr, style: secondary, maxLines: 1, overflow: .ellipsis),
                      ),
                    ],
                  ),
                ),
                if (uri != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.open_in_new, size: 16, color: theme.colorScheme.onSurfaceVariant),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
