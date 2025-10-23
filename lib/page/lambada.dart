import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/store/p.dart';

class PageLambada extends ConsumerWidget {
  const PageLambada({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testItems = ref.watch(P.lambada.testItems);
    final currentIndex = ref.watch(P.lambada.currentIndex);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final progress = ref.watch(P.lambada.progress);
    final screenHeight = ref.watch(P.app.screenHeight);
    final ppl = ref.watch(P.lambada.ppl);
    final acc = ref.watch(P.lambada.acc);
    final totalCount = ref.watch(P.lambada.totalCount);
    final correctCount = ref.watch(P.lambada.correctCount);
    final totalLogits = ref.watch(P.lambada.totalLogits);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LAMBADA 测试'),
        actions: [
          if (isRunning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                P.lambada.reset();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: SizedBox(
          height: screenHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 测试控制按钮
              Row(
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
              ),

              const SizedBox(height: 8),

              // 模型选择按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isRunning ? null : () => P.lambada.reselectModel(),
                      icon: const Icon(Icons.model_training),
                      label: const Text('重新选择模型'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 测试数据信息
              Card(
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
                        Text('当前进度: $currentIndex / ${testItems.length}'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 测试结果
              ...[
                Card(
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
                                value: '$totalCount',
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 当前测试项预览
              if (isRunning && testItems.isNotEmpty && currentIndex < testItems.length) ...[
                Card(
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
                ),
              ],
            ],
          ),
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
