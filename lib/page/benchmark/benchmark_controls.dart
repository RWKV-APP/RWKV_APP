part of '../benchmark.dart';

class _BenchmarkScaffoldActionBar extends ConsumerWidget {
  final int activeTabIndex;

  const _BenchmarkScaffoldActionBar({
    required this.activeTabIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final benchmarkSnapshot = ref.watch(P.benchmark.controlSnapshot);
    final isLambadaTab = activeTabIndex == 1;
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final loadingModel = ref.watch(P.rwkvModel.loading);
    final activeLoadingFile = ref.watch(P.rwkvModel.activeLoadingFile);
    final activeLoadingProgress = ref.watch(P.rwkvModel.activeLoadingProgress);
    final backendGenerating = ref.watch(P.rwkvGeneration.generating);
    final model = ref.watch(P.rwkvModel.latest);
    final lambadaRunning = ref.watch(P.lambada.autoStartNextTest);
    final running = isLambadaTab ? lambadaRunning : benchmarkSnapshot.generating;
    final finishing = benchmarkSnapshot.finishing;
    final canSelectModel = !running && !finishing && !backendGenerating && !loadingModel;
    final canStartOrStop = model != null && !finishing && !loadingModel && (running || !backendGenerating);
    final selectLabel = s.select_model;
    final primaryLabel = running ? s.stop : s.start;
    final VoidCallback onSelectModel = () {
      if (isLambadaTab) {
        P.lambada.clearTestData();
      }
      ModelSelector.show();
    };
    final VoidCallback onPrimaryTap = isLambadaTab
        ? () {
            if (lambadaRunning) {
              P.lambada.stopTest();
            } else {
              P.lambada.startTest();
            }
          }
        : P.benchmark.onStartStopTap;

    final neutralOutlinedStyle = OutlinedButton.styleFrom(
      foregroundColor: qb,
      backgroundColor: appTheme.settingItem.q(.82),
      disabledBackgroundColor: appTheme.settingItem.q(.48),
      side: BorderSide(color: qb.q(.2), width: .5),
      textStyle: theme.textTheme.bodyMedium,
    );
    final neutralFilledStyle = FilledButton.styleFrom(
      backgroundColor: qb.q(.15),
      foregroundColor: qb,
      disabledBackgroundColor: qb.q(.08),
      disabledForegroundColor: qb.q(.4),
      side: BorderSide(color: qb.q(.18), width: .5),
      textStyle: theme.textTheme.bodyMedium,
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: appTheme.settingBg.withValues(alpha: .78),
            border: Border(top: BorderSide(color: qb.q(.12), width: .5)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loadingModel)
                    _BenchmarkLoadingProgress(
                      loadingFile: activeLoadingFile,
                      progress: activeLoadingProgress,
                    ),
                  if (loadingModel) const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.folder_open),
                          onPressed: canSelectModel ? onSelectModel : null,
                          style: neutralOutlinedStyle.copyWith(visualDensity: VisualDensity.standard),
                          label: Text(selectLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: running ? _RunningActionIcon(color: qb) : const Icon(Icons.play_arrow),
                          onPressed: canStartOrStop ? onPrimaryTap : null,
                          style: neutralFilledStyle.copyWith(visualDensity: VisualDensity.standard),
                          label: Text(primaryLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenchmarkLoadingProgress extends ConsumerWidget {
  final FileInfo? loadingFile;
  final double? progress;

  const _BenchmarkLoadingProgress({
    required this.loadingFile,
    required this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final safeProgress = LoadingProgressButtonContent.normalizeProgress(progress);
    final progressPercent = LoadingProgressButtonContent.progressToPercent(progress);
    final modelLabel = loadingFile?.name ?? s.select_model;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: qb.q(.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: qb.q(.14), width: .5),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  modelLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                s.loading_progress_percent(progressPercent),
                style: theme.textTheme.bodySmall?.copyWith(color: qb.q(.72)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: safeProgress,
            minHeight: 5,
            borderRadius: BorderRadius.circular(3),
            color: qb.q(.62),
            backgroundColor: qb.q(.12),
          ),
        ],
      ),
    );
  }
}

class _RunningActionIcon extends StatelessWidget {
  final Color color;

  const _RunningActionIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color.q(.5),
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: 2.r,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchPlanCard extends ConsumerWidget {
  final bool modelSupportsBatch;
  final bool backendSupportsBatch;
  final int maxSupportedBatchSize;
  final List<int> batchPlan;
  final bool running;
  final int currentBatchSize;
  final int currentBatchOrdinal;

  const _BatchPlanCard({
    required this.modelSupportsBatch,
    required this.backendSupportsBatch,
    required this.maxSupportedBatchSize,
    required this.batchPlan,
    required this.running,
    required this.currentBatchSize,
    required this.currentBatchOrdinal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final status = _batchSupportLabel(s, modelSupportsBatch, backendSupportsBatch, maxSupportedBatchSize);
    final planText = _batchPlanText(s, batchPlan);

    return Material(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: qb.q(.14), width: .5),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Icon(Icons.dynamic_feed, size: 18, color: qb.q(.78)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.batch_inference_count,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InlineInfoRow(label: s.benchmark_support, value: status),
            const SizedBox(height: 4),
            _InlineInfoRow(label: s.benchmark_plan, value: planText),
            if (running) ...[
              const SizedBox(height: 4),
              _InlineInfoRow(
                label: s.benchmark_current,
                value: s.benchmark_current_batch(currentBatchSize, currentBatchOrdinal, batchPlan.length),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineInfoRow extends ConsumerWidget {
  final String label;
  final String value;

  const _InlineInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);

    return Row(
      crossAxisAlignment: .start,
      children: [
        Expanded(flex: 2, child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(color: qb.q(.72)),
          ),
        ),
      ],
    );
  }
}

class _BenchmarkProgressCard extends ConsumerWidget {
  final double prefillSpeed;
  final double decodeSpeed;
  final double prefillProgress;
  final int generatedLength;
  final int targetLength;
  final int batchSize;
  final int batchOrdinal;
  final int batchTotal;

  const _BenchmarkProgressCard({
    required this.prefillSpeed,
    required this.decodeSpeed,
    required this.prefillProgress,
    required this.generatedLength,
    required this.targetLength,
    required this.batchSize,
    required this.batchOrdinal,
    required this.batchTotal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final double normalizedPrefillProgress = prefillProgress.clamp(0, 1).toDouble();
    final double decodeProgress = (generatedLength / targetLength).clamp(0, 1).toDouble();
    final bool decoding = generatedLength > 0 || decodeSpeed > 0;
    final String phase = decoding ? s.decode : s.prefill;

    return Material(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: qb.q(.14), width: .5),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Icon(Icons.speed, size: 18, color: qb.q(.78)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.benchmark_progress,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  s.benchmark_batch(batchSize),
                  style: theme.textTheme.bodyMedium?.copyWith(color: qb.q(.68)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InlineInfoRow(
              label: s.benchmark_run,
              value: s.benchmark_run_status(batchOrdinal, batchTotal, phase),
            ),
            const SizedBox(height: 12),
            _ProgressLine(
              label: s.prefill,
              valueText:
                  "${s.benchmark_progress_speed((normalizedPrefillProgress * 100).toStringAsFixed(0), prefillSpeed.toStringAsFixed(2))} · $benchmarkPromptTokenCount tok",
              value: normalizedPrefillProgress,
            ),
            const SizedBox(height: 10),
            _ProgressLine(
              label: s.decode,
              valueText: s.benchmark_decode_progress_speed(generatedLength, targetLength, decodeSpeed.toStringAsFixed(2)),
              value: decodeProgress,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLine extends ConsumerWidget {
  final String label;
  final String valueText;
  final double value;

  const _ProgressLine({
    required this.label,
    required this.valueText,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Text(
                valueText,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(color: qb.q(.68)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: value,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
          color: qb.q(.5),
          backgroundColor: appTheme.settingBg,
        ),
      ],
    );
  }
}

class _KeyValuePairs extends ConsumerWidget {
  final Map<String, String> pairs;
  final String title;

  const _KeyValuePairs({required this.pairs, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Material(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: qb.q(.14), width: .5),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            if (title.isNotEmpty) const SizedBox(height: 6),
            for (final pair in pairs.entries) ...[
              if (pair.key != '---')
                Row(
                  crossAxisAlignment: .start,
                  children: [
                    Expanded(flex: 2, child: Text(pair.key)),
                    Expanded(flex: 3, child: Text(pair.value)),
                  ],
                )
              else
                Container(
                  margin: const .symmetric(vertical: 6),
                  decoration: BoxDecoration(color: qb.q(.16)),
                  height: .5,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
