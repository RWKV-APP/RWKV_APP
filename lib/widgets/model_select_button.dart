// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

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
    final currentModel = ref.watch(P.rwkv.latestModel);
    final currentGroupInfo = ref.watch(P.rwkv.currentGroupInfo);
    final activeLoadingFile = ref.watch(P.rwkv.activeLoadingFile);
    final activeLoadingProgress = ref.watch(P.rwkv.activeLoadingProgress);
    final s = S.of(context);
    final batchEnabled = ref.watch(P.chat.batchEnabled);
    final pageKey = ref.watch(P.app.pageKey);
    final screenWidth = ref.watch(P.app.screenWidth);

    String modelDisplay = activeLoadingFile?.name ?? currentGroupInfo?.displayName ?? currentModel?.name ?? s.click_to_select_model;
    final isLoadingModel = activeLoadingFile != null;
    final hasSelectedModel = isLoadingModel || currentGroupInfo != null || currentModel != null;

    if (screenWidth < 350) {
      modelDisplay = modelDisplay.replaceAll(RegExp(r"\([^)]*\)"), "");
    }

    final qb = ref.watch(P.app.qb);
    final rawMaxButtonWidth = currentModel != null && batchEnabled && preferredDemoType == .chat ? screenWidth * .46 : screenWidth * .62;
    final maxButtonWidth = rawMaxButtonWidth.clamp(180.0, 360.0).toDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxButtonWidth),
      child: C(
        decoration: BD(
          color: qb.q(.05),
          borderRadius: .circular(1000),
          border: .all(color: qb.q(.1)),
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
              if (currentModel != null && batchEnabled && preferredDemoType == .chat) ...[
                Container(
                  width: 0.5,
                  color: qb.q(.1),
                ),
                InkWell(
                  borderRadius: const .horizontal(right: .circular(16)),
                  onTap: P.rwkv.onBatchInferenceTapped,
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
          color: textColor.q(.18),
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
