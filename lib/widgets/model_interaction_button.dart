import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/store/p.dart';

class ModelInteractionButton extends ConsumerWidget {
  final FileInfo fileInfo;

  final bool overrideIsCurrentModel;

  const ModelInteractionButton({
    super.key,
    required this.fileInfo,
    this.overrideIsCurrentModel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(P.app.theme);
    final startButtonRadius = appTheme.startButtonRadius;
    final s = S.of(context);

    final loadingStatus = ref.watch(P.rwkv.loadingStatus);
    final loading =
        loadingStatus[fileInfo] == .loading ||
        loadingStatus[fileInfo] == .loadModelWithExtra ||
        loadingStatus[fileInfo] == .setQnnLibraryPath;

    final currentModel = ref.watch(P.rwkv.latestModel);
    final isCurrentModel = overrideIsCurrentModel ? overrideIsCurrentModel : currentModel == fileInfo;

    final unzipping = ref.watch(P.rwkv.unzippingStatus(fileInfo));

    final isTranslate = fileInfo.tags.contains("translate");

    Color buttonColor = kG.q(.5);
    String buttonText = s.chatting;

    return Container(
      decoration: BoxDecoration(
        borderRadius: .circular(startButtonRadius),
        color: buttonColor,
      ),
      padding: const .all(8),
    );
  }
}
