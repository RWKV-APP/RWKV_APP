part of '../benchmark.dart';

class _LambadaTest extends ConsumerWidget {
  const _LambadaTest();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final testItems = ref.watch(P.lambada.testItems);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final totalFinishCount = ref.watch(P.lambada.totalFinishCount);
    final currentItem = ref.watch(P.lambada.currentItem);
    final testResults = ref.watch(P.lambada.testResults);

    final historyItemCount = testResults.length;

    return Theme(
      data: theme,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 112 + MediaQuery.paddingOf(context).bottom),
        itemCount: historyItemCount + 3,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _LambadaTestDataCard();
          }
          if (index == 1) {
            return const _LambadaTestResultsCard();
          }
          if (index == 2) {
            return _LambadaTestListItem(
              isCurrentItem: true,
              testItems: testItems,
              totalFinishCount: totalFinishCount - (isRunning ? 0 : 1),
              currentItem: currentItem,
              testResults: testResults,
            );
          }
          final historyIndex = (index - (isRunning ? 1 : 0)) - 2;
          final reversedIndex = historyItemCount - 1 - historyIndex;
          if (reversedIndex >= 0 && reversedIndex < testResults.length) {
            final result = testResults[reversedIndex];
            final targetText = result['targetText'] ?? '';
            final outputText = result['outputText'] ?? '';
            final isCorrect = targetText == outputText;
            return _LambadaTestListItem(
              isCurrentItem: false,
              index: reversedIndex + (isRunning ? 0 : 1),
              sourceText: result['sourceText'] ?? '',
              targetText: targetText,
              outputText: outputText,
              isCorrect: isCorrect,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LambadaTestDataCard extends ConsumerWidget {
  const _LambadaTestDataCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final testItems = ref.watch(P.lambada.testItems);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final totalFinishCount = ref.watch(P.lambada.totalFinishCount);
    final progress = ((totalFinishCount / (testItems.isEmpty ? 1 : testItems.length)).toDouble()).clamp(0, 1.0).toDouble();
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Card(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: qb.q(.14), width: .5),
      ),
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              s.test_data,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(s.total_test_items(testItems.length)),
            if (isRunning) ...[
              const SizedBox(height: 8),
              Text(s.current_progress(totalFinishCount, testItems.length)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                color: qb.q(.62),
                backgroundColor: qb.q(.1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LambadaTestResultsCard extends ConsumerWidget {
  const _LambadaTestResultsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final ppl = ref.watch(P.lambada.ppl);
    final acc = ref.watch(P.lambada.acc);
    final totalFinishCount = ref.watch(P.lambada.totalFinishCount);
    final correctCount = ref.watch(P.lambada.correctCount);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Card(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: qb.q(.14), width: .5),
      ),
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Text(
                  s.test_results,
                  style: theme.textTheme.titleMedium,
                ),
                if (isRunning) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const .symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: qb.q(.16),
                      borderRadius: .circular(12),
                      border: .all(color: qb.q(.35)),
                    ),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: qb,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.real_time_update,
                          style: TextStyle(
                            fontSize: 12,
                            color: qb.q(.75),
                            fontWeight: .w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LambadaResultCard(
                    title: s.accuracy,
                    value: '${(acc * 100).toStringAsFixed(2)}%',
                    color: qb.q(.95),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _LambadaResultCard(
                    title: s.perplexity,
                    value: ppl.toStringAsFixed(2),
                    color: qb.q(.85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _LambadaResultCard(
                    title: s.correct_count,
                    value: '$correctCount',
                    color: qb.q(.75),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _LambadaResultCard(
                    title: s.total_count,
                    value: '$totalFinishCount',
                    color: qb.q(.65),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LambadaTestListItem extends ConsumerWidget {
  final bool isCurrentItem;
  final List<LambadaTestItem>? testItems;
  final int? totalFinishCount;
  final LambadaTestItem? currentItem;
  final List<Map<String, String>>? testResults;
  final int? index;
  final String? sourceText;
  final String? targetText;
  final String? outputText;
  final bool? isCorrect;

  const _LambadaTestListItem({
    required this.isCurrentItem,
    this.testItems,
    this.totalFinishCount,
    this.currentItem,
    this.testResults,
    this.index,
    this.sourceText,
    this.targetText,
    this.outputText,
    this.isCorrect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    if (isCurrentItem) {
      if (testItems == null || totalFinishCount == null) {
        return const SizedBox.shrink();
      }

      final currentIndex = totalFinishCount!;
      if (testItems!.isEmpty || currentIndex >= testItems!.length) {
        return const SizedBox.shrink();
      }

      Map<String, String>? currentResult;
      if (currentItem != null && testResults != null) {
        for (final result in testResults!) {
          if (result['sourceText'] == currentItem!.sourceText && result['targetText'] == currentItem!.targetText) {
            currentResult = result;
            break;
          }
        }
      }

      final displayTargetText = currentItem?.targetText ?? testItems![currentIndex].targetText;
      final displaySourceText = currentItem?.sourceText ?? testItems![currentIndex].sourceText;
      final displayOutputText = currentResult?['outputText'] ?? '';
      final displayIsCorrect = displayOutputText.isNotEmpty && displayTargetText == displayOutputText;

      return Card(
        color: appTheme.settingItem,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: qb.q(.14), width: .5),
        ),
        child: Padding(
          padding: const .all(16.0),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                s.current_test_item(currentIndex + 1, testItems!.length),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                s.source_text(displaySourceText),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              if (displayOutputText.isEmpty)
                Text(
                  s.target_text(displayTargetText),
                  style: TextStyle(fontSize: 12, color: qb.q(.78)),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        s.target_text(displayTargetText),
                        style: TextStyle(fontSize: 12, color: qb.q(.78)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.model_output(displayOutputText),
                        style: TextStyle(
                          fontSize: 12,
                          color: displayIsCorrect ? qb.q(.92) : qb.q(.62),
                          fontWeight: displayIsCorrect ? FontWeight.w500 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    if (index == null || sourceText == null || targetText == null || outputText == null || isCorrect == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: qb.q(.14), width: .5),
      ),
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              '#$index',
              style: TextStyle(
                fontSize: 14,
                fontWeight: .w600,
                color: qb.q(.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.source_text(sourceText!),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    s.target_text(targetText!),
                    style: TextStyle(fontSize: 12, color: qb.q(.78)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.model_output(outputText!),
                    style: TextStyle(
                      fontSize: 12,
                      color: isCorrect! ? qb.q(.92) : qb.q(.62),
                      fontWeight: isCorrect! ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LambadaResultCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _LambadaResultCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: color.q(0.1),
        borderRadius: .circular(8),
        border: .all(color: color.q(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: .w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: .bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
