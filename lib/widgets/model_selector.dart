// ignore: unused_import
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/user_type.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/model_item.dart';
import 'package:zone/widgets/role_play_item.dart';
import 'package:zone/widgets/tts_group_item.dart';
import 'package:zone/widgets/world_group_item.dart';

class ModelSelector extends ConsumerWidget {
  final bool nekoOnly;
  final bool rolePlayOnly;
  final ScrollController scrollController;
  static DemoType? _preferredDemoType;

  static Future<void> show({
    bool nekoOnly = false,
    bool rolePlayOnly = false,
    DemoType? preferredDemoType,
  }) async {
    if (P.fileManager.modelSelectorShown.q) return;
    P.fileManager.modelSelectorShown.q = true;

    final context = getContext();
    if (context == null) {
      P.fileManager.modelSelectorShown.q = false;
      return;
    }

    // Fire and forget model updates
    (() async {
      P.fileManager.checkLocal();
      await P.app.syncConfig();
      await P.fileManager.syncAvailableModels();
      P.fileManager.checkLocal();
    })();

    if (P.app.pageKey.q == PageKey.talk) {
      _preferredDemoType = DemoType.tts;
    }

    if (preferredDemoType != null) {
      _preferredDemoType = preferredDemoType;
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: .8,
          maxChildSize: .9,
          expand: false,
          snap: false,

          builder: (BuildContext context, ScrollController scrollController) {
            return ModelSelector(scrollController: scrollController, nekoOnly: nekoOnly, rolePlayOnly: rolePlayOnly);
          },
        );
      },
    );

    _preferredDemoType = null;

    P.fileManager.modelSelectorShown.q = false;
  }

  const ModelSelector({super.key, required this.scrollController, required this.nekoOnly, required this.rolePlayOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final isDesktop = ref.watch(P.app.isDesktop);

    return ClipRRect(
      borderRadius: 16.r,
      child: Container(
        margin: const EI.o(t: 12),
        child: ListView(
          padding: EI.o(l: isDesktop ? 12 : 8, r: isDesktop ? 12 : 8),
          controller: scrollController,
          children: [
            const _Header(),
            const _Hints(),
            _ModelList(nekoOnly: nekoOnly, rolePlayOnly: rolePlayOnly),
            16.h,
            paddingBottom.h,
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        Expanded(
          child: T(s.chat_welcome_to_use(Config.appTitle), s: const TS(s: 18, w: FontWeight.w600)),
        ),
        const IconButton(
          onPressed: pop,
          icon: Icon(Icons.close),
        ),
      ],
    );
  }
}

class _Hints extends ConsumerWidget {
  const _Hints();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final demoType = ModelSelector._preferredDemoType ?? ref.watch(P.app.demoType);
    final qb = ref.watch(P.app.qb);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (demoType == DemoType.world) ...[
          T(s.please_select_a_world_type, s: const TS(s: 16, w: FontWeight.w500)),
          4.h,
        ],
        const _DownloadSource(),
        if (demoType == DemoType.chat)
          T(
            "👉${s.str_model_selection_dialog_hint}👈",
            s: TS(c: qb.q(.7), s: 12, w: FontWeight.w500),
          ),
      ],
    );
  }
}

class _ModelList extends ConsumerWidget {
  final bool nekoOnly;
  final bool rolePlayOnly;

  const _ModelList({required this.nekoOnly, required this.rolePlayOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoType = ref.watch(P.app.demoType);
    final preferredDemoType = ModelSelector._preferredDemoType ?? demoType;

    Set<FileInfo> availableModels = switch (preferredDemoType) {
      DemoType.world => ref.watch(P.fileManager.worldWeights),
      DemoType.tts => ref.watch(P.fileManager.ttsWeights),
      DemoType.chat => ref.watch(P.fileManager.chatWeights),
      DemoType.sudoku => ref.watch(P.fileManager.sudokuWeights),
      DemoType.othello => ref.watch(P.fileManager.othelloWeights),
      DemoType.fifthteenPuzzle => ref.watch(P.fileManager.sudokuWeights),
    };

    final ttsCores = ref.watch(P.fileManager.ttsCores);
    final userType = ref.watch(P.preference.userType);
    final pageKey = ref.watch(P.app.pageKey);

    if (rolePlayOnly) {
      availableModels = availableModels.where((e) => e.state.isNotEmpty).toSet();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: availableModels.map((e) => RolePlayItem(file: e)).toList(),
      );
    }

    if (pageKey == PageKey.translator) {
      availableModels = availableModels.where((e) => e.tags.contains("translate")).toSet();
    } else {
      availableModels = availableModels.where((e) => !e.tags.contains("translate")).toSet();
    }

    if (pageKey == PageKey.benchmark) {
      availableModels = availableModels.whereNot((e) => e.tags.contains('DeepEmbedding')).toSet();
    }

    List<Widget> items = switch (preferredDemoType) {
      DemoType.world =>
        WorldType.values
            .where((e) => e.available)
            .expand(
              (e) => e.socPairs
                  .where((pair) => pair.$1.isEmpty || pair.$1 == P.rwkv.socName.q)
                  .sortedBy<num>((pair) => -pair.$1.length)
                  .map((pair) => WorldGroupItem(e, socPair: pair)),
            )
            .toList(),
      DemoType.tts => ttsCores.map((fileInfo) => TTSGroupItem(fileInfo)).toList(),
      DemoType.chat || DemoType.sudoku =>
        availableModels
            .where((e) => !nekoOnly || e.isNeko)
            .sorted((a, b) {
              final aHasNpu = a.tags.contains("npu");
              final bHasNpu = b.tags.contains("npu");
              if (aHasNpu != bHasNpu) return aHasNpu ? -1 : 1;

              final aHasGpu = a.tags.contains("gpu");
              final bHasGpu = b.tags.contains("gpu");
              if (aHasGpu != bHasGpu) return aHasGpu ? -1 : 1;

              return (b.modelSize ?? 0).compareTo(a.modelSize ?? 0);
            })
            .map(
              (fileInfo) =>
                  ModelItem(fileInfo, userType.isGreaterThan(UserType.user), loadButtonTextShowLoad: pageKey == PageKey.benchmark),
            )
            .toList(),
      DemoType.fifthteenPuzzle || DemoType.othello => [],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
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
          s: TS(c: qb.q(.7), s: 12, w: FontWeight.w600),
        ),
        4.h,
        Wrap(
          runSpacing: 4,
          spacing: 4,
          children: FileDownloadSource.values.where((e) => (kDebugMode || !e.isDebug) && !e.hidden).map((e) {
            return GestureDetector(
              onTap: () {
                P.fileManager.downloadSource.q = e;
              },
              child: Container(
                decoration: BoxDecoration(
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
