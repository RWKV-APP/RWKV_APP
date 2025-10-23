import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/store/p.dart';

class PageLambada extends ConsumerWidget {
  const PageLambada({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LAMBADA 测试'),
        actions: [
          _AppBarActions(),
        ],
      ),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
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
            label: Text(isRunning ? '测试中...' : '开始测试'),
          ),
        ),
        const SizedBox(width: 8),
        if (isRunning)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => P.lambada.stopTest(),
              icon: const Icon(Icons.stop),
              label: const Text('停止测试'),
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
            label: const Text('加载数据'),
          ),
      ],
    );
  }
}

class _ModelSelectionButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final currentModel = ref.watch(P.rwkv.currentModel);

    return Row(
      children: [
        if (currentModel != null) Expanded(child: T("当前模型: ${currentModel.name}")),
        if (currentModel == null) Expanded(child: T("请选择模型")),
        ElevatedButton.icon(
          onPressed: isRunning ? null : () => P.lambada.reselectModel(),
          icon: const Icon(Icons.model_training),
          label: currentModel == null ? Text("请选择模型") : Text('重新选择模型'),
        ),
      ],
    );
  }
}

class _TestDataCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              '测试数据',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('总测试项: ${testItems.length}'),
            if (isRunning) ...[
              const SizedBox(height: 8),
              Text('当前进度: $totalFinishCount / ${testItems.length}'),
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
                  '测试结果',
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
                          '实时更新',
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
                    title: '准确率',
                    value: '${(acc * 100).toStringAsFixed(2)}%',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResultCard(
                    title: '困惑度',
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
                    title: '正确数',
                    value: '$correctCount',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResultCard(
                    title: '总数',
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
              '当前测试项 (${currentIndex + 1}/${testItems.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '源文本: ${testItems[currentIndex].sourceText}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '目标文本: ${testItems[currentIndex].targetText}',
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
