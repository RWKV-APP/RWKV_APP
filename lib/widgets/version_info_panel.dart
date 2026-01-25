import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';

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
    double paddingBottom = ref.watch(P.app.paddingBottom);
    paddingBottom = max(paddingBottom, 16);
    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: T(s.found_new_version_available),
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
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Container(
                    height: 100,
                    color: Colors.red,
                  );
                },
              ),
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
                        color: Colors.red,
                        borderRadius: 100.r,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.download),
                          Text("Download Now"),
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
                        color: Colors.red,
                        borderRadius: 100.r,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.skip_next),
                          Text("Skip this version"),
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
                        color: Colors.red,
                        borderRadius: 100.r,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel),
                          Text(s.cancel),
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
