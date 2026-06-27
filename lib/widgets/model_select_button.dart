// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/loading_progress_button_content.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/widgets/triangle_painter.dart';

class ModelSelectButton extends ConsumerWidget {
  final DemoType preferredDemoType;

  const ModelSelectButton({
    required this.preferredDemoType,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rawCurrentModel = ref.watch(P.rwkvModel.latest);
    final rawCurrentGroupInfo = ref.watch(P.rwkvContext.currentGroupInfo);
    final rawActiveLoadingFile = ref.watch(P.rwkvModel.activeLoadingFile);
    final activeLoadingProgress = ref.watch(P.rwkvModel.activeLoadingProgress);
    final s = S.of(context);
    final batchEnabled = ref.watch(P.chat.effectiveBatchEnabled);
    final pageKey = ref.watch(P.app.pageKey);
    final screenWidth = ref.watch(P.app.screenWidth);
    final albatrossCanUse = preferredDemoType == .chat && ref.watch(P.albatrossRuntime.canUse);
    final currentModel = P.rwkvAutoLoad.visibleCurrentModelForPage(
      fileInfo: rawCurrentModel,
      pageKey: pageKey,
      preferredDemoType: preferredDemoType,
    );
    final currentGroupInfo = P.rwkvAutoLoad.visibleGroupInfoForPage(
      groupInfo: rawCurrentGroupInfo,
      pageKey: pageKey,
      preferredDemoType: preferredDemoType,
    );
    final activeLoadingFile = P.rwkvAutoLoad.visibleActiveLoadingFileForPage(
      fileInfo: rawActiveLoadingFile,
      pageKey: pageKey,
      preferredDemoType: preferredDemoType,
    );

    String modelDisplay =
        activeLoadingFile?.name ??
        currentGroupInfo?.displayName ??
        currentModel?.name ??
        (albatrossCanUse ? "Albatross" : s.click_to_select_model);
    final isLoadingModel = activeLoadingFile != null;
    final hasSelectedModel = isLoadingModel || currentGroupInfo != null || currentModel != null || albatrossCanUse;

    if (screenWidth < 350) {
      modelDisplay = modelDisplay.replaceAll(RegExp(r"\([^)]*\)"), "");
    }

    final qb = ref.watch(P.app.qb);
    final showBatchShortcut = (currentModel != null || albatrossCanUse) && batchEnabled && preferredDemoType == .chat;
    final rawMaxButtonWidth = showBatchShortcut ? screenWidth * .46 : screenWidth * .62;
    final maxButtonWidth = rawMaxButtonWidth.clamp(180.0, 360.0).toDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxButtonWidth),
      child: Container(
        decoration: BoxDecoration(
          color: qb.withValues(alpha: .05),
          borderRadius: .circular(1000),
          border: .all(color: qb.withValues(alpha: .1)),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: .center,
            mainAxisSize: .min,
            children: [
              Flexible(
                child: InkWell(
                  borderRadius: const .horizontal(left: .circular(16)),
                  onTap: () {
                    ModelSelector.show(
                      showNeko: pageKey == .neko,
                      preferredDemoType: preferredDemoType,
                    );
                  },
                  child: Padding(
                    padding: const .symmetric(horizontal: 8, vertical: 4),
                    child: isLoadingModel
                        ? _ActiveLoadingModelContent(
                            progress: activeLoadingProgress,
                            modelDisplay: modelDisplay,
                            textColor: qb,
                          )
                        : Text(
                            modelDisplay,
                            maxLines: 1,
                            overflow: .ellipsis,
                            style: const TextStyle(fontSize: 10, height: 1, fontWeight: .w500),
                          ),
                  ),
                ),
              ),
              if (!hasSelectedModel) ...[
                SizedBox(
                  height: 5,
                  width: 8,
                  child: CustomPaint(
                    painter: TrianglePainter(color: theme.disabledColor),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (showBatchShortcut) ...[
                Container(
                  width: 0.5,
                  color: qb.withValues(alpha: .1),
                ),
                InkWell(
                  borderRadius: const .horizontal(right: .circular(16)),
                  onTap: P.rwkvParams.onBatchInferenceTapped,
                  child: Padding(
                    padding: const .symmetric(horizontal: 8, vertical: 4),
                    child: Text("  " + s.batch_inference_short + "  ", style: const TextStyle(fontSize: 10, height: 1, fontWeight: .w500)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveLoadingModelContent extends StatelessWidget {
  final double? progress;
  final String modelDisplay;
  final Color textColor;

  const _ActiveLoadingModelContent({
    required this.progress,
    required this.modelDisplay,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: .min,
      children: [
        LoadingProgressButtonContent(
          progress: progress,
          textStyle: const TextStyle(fontSize: 10, height: 1, fontWeight: .w600),
          indicatorColor: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Container(
          width: 0.5,
          height: 12,
          color: textColor.withValues(alpha: .18),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            modelDisplay,
            maxLines: 1,
            overflow: .ellipsis,
            style: const TextStyle(fontSize: 10, height: 1, fontWeight: .w500),
          ),
        ),
      ],
    );
  }
}
