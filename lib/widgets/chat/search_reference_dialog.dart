import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/model/message.dart' show RefInfo;

class SearchReferenceDialog extends StatelessWidget {
  final RefInfo refInfo;
  final ScrollController scrollController;

  const SearchReferenceDialog({super.key, required this.refInfo, required this.scrollController});

  static void show(BuildContext context, RefInfo ref) async {
    return await showModalBottomSheet(
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
          return SearchReferenceDialog(refInfo: ref, scrollController: scrollController);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 12, vertical: 16),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 6),
              Expanded(child: Text(S.of(context).reference_source, style: theme.textTheme.titleMedium)),
              const CloseButton(),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Material(
              color: theme.scaffoldBackgroundColor,
              child: ListView.builder(
                controller: scrollController,
                shrinkWrap: true,
                itemCount: refInfo.list.length,
                itemBuilder: (BuildContext context, int index) {
                  final ref = refInfo.list[index % refInfo.list.length];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: theme.colorScheme.surfaceContainer,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(ref.title),
                          const SizedBox(height: 4),
                          Text(ref.summary.replaceAll("\n", ' '), maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                        ],
                      ),
                      subtitle: Text(ref.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        launchUrlString(ref.url);
                      },
                    ),
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
