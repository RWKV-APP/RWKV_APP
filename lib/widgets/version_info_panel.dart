import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/markdown_render.dart';

class VersionInfoPanel extends ConsumerWidget {
  static final _shown = qs(false);

  static Future<void> show() async {
    qq;
    if (_shown.q) return;
    _shown.q = true;
    final context = getContext();
    if (context == null || !context.mounted) {
      _shown.q = false;
      return;
    }
    final isMobile = P.app.isMobile.q;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: isMobile ? .6 : .75,
          maxChildSize: isMobile ? .65 : .8,
          minChildSize: isMobile ? .45 : .6,
          expand: false,
          snap: false,
          builder: (context, scrollController) {
            return VersionInfoPanel(scrollController: scrollController);
          },
        );
      },
    );
    _shown.q = false;
  }

  final ScrollController? scrollController;

  const VersionInfoPanel({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final latestVersionInfo = ref.watch(P.app.latestVersionInfo);
    double paddingBottom = ref.watch(P.app.paddingBottom);
    paddingBottom = max(paddingBottom, 16);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.found_new_version_available),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                pop();
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                s.latest_version + s.colon + (latestVersionInfo?.version ?? "") + "(" + (latestVersionInfo?.build.toString() ?? "") + ")",
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(s.current_version + s.colon + (P.app.version.q) + "(" + (P.app.buildNumber.q) + ")"),
            ),
            Expanded(
              child: _ReleaseNotesContent(scrollController: scrollController),
            ),
            8.h,
            Row(
              children: [
                Expanded(
                  child: IconButton(
                    onPressed: P.app.onDownloadNowClicked,
                    icon: Container(
                      height: 44,
                      padding: const .symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14b8a6),
                        borderRadius: 100.r,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.download, color: Colors.white),
                          Text(
                            s.download_now,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: IconButton(
                    onPressed: P.app.skipThisVersion,
                    icon: Container(
                      height: 44,
                      padding: const .symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0d9488),
                        borderRadius: 100.r,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.skip_next, color: Colors.white),
                          Text(
                            s.skip_this_version,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    onPressed: pop,
                    icon: Container(
                      height: 44,
                      padding: const .symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0d9488),
                        borderRadius: 100.r,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel, color: Colors.white),
                          Text(
                            s.cancel,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            paddingBottom.h,
          ],
        ),
      ),
    );
  }
}

class _ReleaseNotesContent extends ConsumerWidget {
  final ScrollController? scrollController;

  const _ReleaseNotesContent({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestVersionInfo = ref.watch(P.app.latestVersionInfo);
    final releaseNotesData = ref.watch(P.app.releaseNotesContent);
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);

    if (latestVersionInfo == null) {
      return Center(
        child: Text(
          S.of(context).no_latest_version_info,
          style: theme.textTheme.bodyMedium?.copyWith(color: qb.q(.5)),
        ),
      );
    }

    // Trigger fetch if not already loaded
    if (releaseNotesData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        P.app.getReleaseNotes(
          build: latestVersionInfo.build,
          version: latestVersionInfo.version,
        );
      });
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    // Type check and extract content
    final content = (releaseNotesData as ({String? content, String? version})?)?.content;

    if (content == null || content.isEmpty) {
      return Center(
        child: Padding(
          padding: const .all(16),
          child: Text(
            S.of(context).no_latest_version_info,
            style: theme.textTheme.bodyMedium?.copyWith(color: qb.q(.5)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const .all(16),
      children: [
        MarkdownRender(raw: content),
      ],
    );
  }
}
