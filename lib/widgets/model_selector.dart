// ignore: unused_import
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/args.dart';
import 'package:zone/config.dart';
import 'package:zone/func/gb_display.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/route/method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/route/router.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/tts_group_item.dart';
import 'package:zone/widgets/world_group_item.dart';
import 'package:zone/widgets/model_item.dart';

// TODO: move it to pages/panel
class ModelSelector extends ConsumerWidget {
  static FV show() async {
    qq;

    if (P.fileManager.modelSelectorShown.q) return;

    P.fileManager.modelSelectorShown.q = true;

    P.fileManager.checkLocal();

    if (!Args.disableRemoteConfig) {
      P.app.getConfig().then((_) async {
        await P.fileManager.syncAvailableModels();
        await P.fileManager.checkLocal();
      });
    } else {
      P.fileManager.syncAvailableModels().then((_) {
        P.fileManager.checkLocal();
      });
    }

    HF.wait(250).then((_) {
      P.device.sync();
    });
    await showModalBottomSheet(
      isScrollControlled: true,
      context: getContext()!,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: .8,
          maxChildSize: .9,
          expand: false,
          snap: false,

          builder: (BuildContext context, ScrollController scrollController) {
            return ModelSelector(scrollController: scrollController);
          },
        );
      },
    );
    P.fileManager.modelSelectorShown.q = false;
  }

  final ScrollController scrollController;

  const ModelSelector({super.key, required this.scrollController});

  List<Widget> _buildItems(BuildContext context, WidgetRef ref) {
    final demoType = ref.watch(P.app.demoType);
    final availableModels = ref.watch(P.fileManager.availableModels);
    final ttsCores = ref.watch(P.fileManager.ttsCores);

    switch (demoType) {
      case DemoType.world:
        return [
          ...WorldType.values
              .where((e) => e.available)
              .map((e) {
                return e.socPairs
                    .where((pair) {
                      return pair.$1 == "" || pair.$1 == P.rwkv.socName.q;
                    })
                    .map((pair) {
                      return WorldGroupItem(e, socPair: pair);
                    });
              })
              .reduce((v, e) {
                return [...v, ...e];
              }),
        ];
      case DemoType.tts:
        return [
          for (final fileInfo in ttsCores) TTSGroupItem(fileInfo),
        ];
      case DemoType.chat:
      case DemoType.sudoku:
        return [
          for (final fileInfo
              in availableModels
                  .sorted((a, b) {
                    /// 模型尺寸大的在上面
                    return (b.modelSize ?? 0).compareTo(a.modelSize ?? 0);
                  })
                  .sorted((a, b) {
                    return (a.tags.contains("gpu") ? 0 : 1).compareTo(b.tags.contains("gpu") ? 0 : 1);
                  })
                  .sorted((a, b) {
                    return (a.tags.contains("npu") ? 0 : 1).compareTo(b.tags.contains("npu") ? 0 : 1);
                  }))
            ModelItem(fileInfo),
        ];
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
        return [];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final memUsed = ref.watch(P.device.memUsed);
    final memFree = ref.watch(P.device.memFree);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);

    final memUsedString = gbDisplay(memUsed);
    final memFreeString = gbDisplay(memFree);
    final demoType = ref.watch(P.app.demoType);
    final availableModels = ref.watch(P.fileManager.availableModels);
    final ttsCores = ref.watch(P.fileManager.ttsCores);
    final qb = ref.watch(P.app.qb);

    return ClipRRect(
      borderRadius: 16.r,
      child: C(
        margin: const EI.o(t: 12),
        child: ListView(
          padding: const EI.o(l: 12, r: 12),
          controller: scrollController,
          children: [
            Row(
              children: [
                Expanded(
                  child: T(s.chat_welcome_to_use(Config.appTitle), s: const TS(s: 18, w: FW.w600)),
                ),
                IconButton(
                  onPressed: () {
                    pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (demoType == DemoType.world) T(s.please_select_a_world_type, s: const TS(s: 16, w: FW.w500)),
            // T(s.memory_used(memUsedString, memFreeString), s: TS(c: qb.q(.7), s: 12)),
            const _DownloadSource(),
            if (demoType == DemoType.chat)
              T(
                "👉${s.size_recommendation}👈",
                s: TS(c: qb.q(.7), s: 12, w: FW.w500),
              ),
            ..._buildItems(context, ref),
            16.h,
            paddingBottom.h,
          ],
        ),
      ),
    );
  }
}

class _DownloadSource extends ConsumerWidget {
  const _DownloadSource();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSource = ref.watch(P.fileManager.downloadSource);
    final primary = Theme.of(context).colorScheme.primary;
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        4.h,
        T(
          S.current.download_server_,
          s: TS(c: qb.q(.7), s: 12, w: FW.w600),
        ),
        4.h,
        Wrap(
          runSpacing: 4,
          spacing: 4,
          children: FileDownloadSource.values.where((e) => kDebugMode || !e.isDebug).map((e) {
            return GD(
              onTap: () {
                P.fileManager.downloadSource.q = e;
              },
              child: C(
                decoration: BD(
                  color: e == currentSource ? primary : kC,
                  borderRadius: 4.r,
                  border: Border.all(
                    color: primary,
                  ),
                ),
                padding: const EI.s(h: 6, v: 2),
                child: T(
                  e.name + (e == FileDownloadSource.huggingface ? S.current.overseas : ""),
                  s: TS(c: e == currentSource ? qw : qb.q(.7), s: 14),
                ),
              ),
            );
          }).toList(),
        ),
        8.h,
      ],
    );
  }
}
