import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/store/p.dart';

class PageLambada extends ConsumerWidget {
  const PageLambada({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.lambada_test),
        actions: [
          _AppBarActions(),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TestControlButtons(),
            const SizedBox(height: 8),
            _ModelSelectionButton(),
            const SizedBox(height: 16),
            _TestDataCard(),
            const SizedBox(height: 16),
            _TestResultsCard(),
            const SizedBox(height: 16),
            _CurrentTestPreview(),
          ],
        ),
      ),
    );
  }
}

class _AppBarActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(P.lambada.autoStartNextTest);

    if (isRunning) {
      return IconButton(
        icon: const Icon(Icons.stop),
        onPressed: () {
          P.lambada.reset();
        },
      );
    }

    return const SizedBox.shrink();
  }
}

class _TestControlButtons extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isRunning ? null : () => P.lambada.startTest(),
            icon: isRunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(isRunning ? s.testing : s.start_test),
          ),
        ),
        const SizedBox(width: 8),
        if (isRunning)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => P.lambada.stopTest(),
              icon: const Icon(Icons.stop),
              label: Text(s.stop_test),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () => P.lambada.loadTestData(),
            icon: const Icon(Icons.refresh),
            label: Text(s.load_data),
          ),
      ],
    );
  }
}

class _ModelSelectionButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final currentModel = ref.watch(P.rwkv.currentModel);

    return Row(
      children: [
        if (currentModel != null) Expanded(child: Text(s.current_model(currentModel.name))),
        if (currentModel == null) Expanded(child: Text(s.please_select_model)),
        ElevatedButton.icon(
          onPressed: isRunning ? null : () => P.lambada.reselectModel(),
          icon: const Icon(Icons.model_training),
          label: currentModel == null ? Text(s.please_select_model) : Text(s.reselect_model),
        ),
      ],
    );
  }
}

class _TestDataCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final testItems = ref.watch(P.lambada.testItems);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final totalFinishCount = ref.watch(P.lambada.totalFinishCount);
    final progress = ((totalFinishCount / testItems.length).toDouble()).clamp(0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.test_data,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(s.total_test_items(testItems.length)),
            if (isRunning) ...[
              const SizedBox(height: 8),
              Text(s.current_progress(totalFinishCount, testItems.length)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
            ],
          ],
        ),
      ),
    );
  }
}

class _TestResultsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final ppl = ref.watch(P.lambada.ppl);
    final acc = ref.watch(P.lambada.acc);
    final totalFinishCount = ref.watch(P.lambada.totalFinishCount);
    final correctCount = ref.watch(P.lambada.correctCount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.test_results,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (isRunning) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.q(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.q(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.real_time_update,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
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
                  child: _ResultCard(
                    title: s.accuracy,
                    value: '${(acc * 100).toStringAsFixed(2)}%',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResultCard(
                    title: s.perplexity,
                    value: ppl.toStringAsFixed(2),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ResultCard(
                    title: s.correct_count,
                    value: '$correctCount',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResultCard(
                    title: s.total_count,
                    value: '$totalFinishCount',
                    color: Colors.grey,
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

class _CurrentTestPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final testItems = ref.watch(P.lambada.testItems);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final totalFinishCount = ref.watch(P.lambada.totalFinishCount);
    final currentIndex = totalFinishCount;

    if (!isRunning || testItems.isEmpty || currentIndex >= testItems.length) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.current_test_item(currentIndex + 1, testItems.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              s.source_text(testItems[currentIndex].sourceText),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              s.target_text(testItems[currentIndex].targetText),
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _ResultCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EI.a(12),
      decoration: BoxDecoration(
        color: color.q(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.q(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
