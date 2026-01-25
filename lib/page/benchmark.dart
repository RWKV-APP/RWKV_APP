import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_mobile_flutter/types.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/model/lambada_test_item.dart';
import 'package:zone/store/p.dart' show P, $Chat, $RWKV, $Lambada;
import 'package:zone/widgets/model_selector.dart';

import 'package:zone/gen/l10n.dart' show S;

class PageBenchmark extends ConsumerStatefulWidget {
  const PageBenchmark({super.key});

  @override
  ConsumerState<PageBenchmark> createState() => _PageBenchmarkState();
}

class _PageBenchmarkState extends ConsumerState<PageBenchmark> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // 当标签页切换完成时（动画结束），停止所有测试
    if (!_tabController.indexIsChanging) {
      _stopAllTests();
    }
  }

  void _stopAllTests() {
    // 停止性能测试
    if (P.rwkv.generating.q) {
      P.chat.stopCompletion();
    }
    // 停止 LAMBADA 测试
    if (P.lambada.autoStartNextTest.q) {
      P.lambada.stopTest();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _stopAllTests();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _stopAllTests();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(S.current.performance_test),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: s.performance_test),
              Tab(text: s.lambada_test),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            SingleChildScrollView(
              padding: const .symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  const SizedBox(height: 12),
                  _Test(),
                ],
              ),
            ),
            const _LambadaTest(),
          ],
        ),
      ),
    );
  }
}

class _Test extends ConsumerStatefulWidget {
  @override
  ConsumerState<_Test> createState() => _TestState();
}

class _TestState extends ConsumerState<_Test> {
  double prefillSpeed = 0;
  double decodeSpeed = 0;
  double flops = 0;
  double bw = 0;

  bool generating = false;
  int numberOfCore = -1;
  Map<String, String> deviceInfo = {};

  double oldMaxLength = 4000;

  int selectedBatchSize = 1;

  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final di = await getDeviceInfo();
      setState(() {
        deviceInfo = di;
      });

      oldMaxLength = P.rwkv.arguments(Argument.maxLength).q;
      P.rwkv.syncMaxLength(maxLength: 200);
    });
  }

  void onStartStopTap() async {
    if (generating) {
      P.chat.stopCompletion();
      setState(() {
        generating = false;
      });
    } else {
      setState(() {
        bw = 0;
        flops = 0;
        prefillSpeed = 0;
        decodeSpeed = 0;
      });
      final prompt =
          "My teacher is Mrs. teacher, he is a woman teacher. She was very young. High on the bridge of the nose has a pair of water Lingling big eyes, short hair, looked even younger. He knows everything very knowledgeable. He taught us the language, we call a stroke of word painting, he wrote the word can be beautiful. Always happy with a smile on his face when the nest. She angry when we are afraid to look at her front, only dare to look at the blackboard. We do not always angry teacher, we have to study hard, ";
      P.rwkv.clearStates();
      subscription?.cancel();
      subscription = P.rwkv.completion(prompt, batchSize: selectedBatchSize).listen((e) {}, onError: (e) {}, onDone: () {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      P.chat.stopCompletion();
      P.rwkv.syncMaxLength(maxLength: oldMaxLength);
    });
  }

  Future<Map<String, String>> getDeviceInfo() async {
    // final mem = await SystemInfoPlus.physicalMemory ?? 0;
    // socInfo += 'Memory: ${mem / 1024 / 1024 / 1024}GB\n';
    DeviceInfoPlugin di = DeviceInfoPlugin();
    final android = Platform.isAndroid ? await di.androidInfo : null;
    final windows = Platform.isWindows ? await di.windowsInfo : null;

    numberOfCore = windows?.numberOfCores ?? -1;

    final lines = {
      "AppVersion": P.app.version.q + " (${P.app.buildNumber.q})",
      // "Kernel": SysInfo.kernelName + ' ' + SysInfo.rawKernelArchitecture + '',
      ..._Utils.getMemInfo(),
      if (android != null) 'DeviceName': android.name,
      if (android != null) 'Hardware': "${android.hardware} ${P.rwkv.socBrand.q.name} ${P.rwkv.socName.q}".replaceAll('Unknown', ''),
      if (windows != null) 'ProductName': windows.productName,
    };
    return lines;
  }

  void listen() {
    ref.listen(P.rwkv.decodeSpeed, (p, r) {
      decodeSpeed = r;
      setState(() {});
    });
    ref.listen(P.rwkv.prefillSpeed, (p, r) {
      prefillSpeed = max(r, prefillSpeed);
      setState(() {});
    });
    ref.listen(P.rwkv.generating, (p, r) {
      if (r != generating) {
        setState(() {
          generating = r;
        });
      }
    });
    ref.listen(P.chat.receivedTokens, (p, r) {
      if (r.length > 1000) {
        P.rwkv.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    listen();
    final model = ref.watch(P.rwkv.latestModel);
    final socName = ref.watch(P.rwkv.socName);
    final socBrand = ref.watch(P.rwkv.socBrand);
    final supportedBatchSizes = ref.watch(P.rwkv.supportedBatchSizes);

    if (model != null) {
      final modelSizeGb = model.fileSize / 1024 / 1024 / 1024;
      final _bw = modelSizeGb * decodeSpeed;
      final _flops = 2 * modelSizeGb * prefillSpeed / 1000;
      bw = max(_bw, bw);
      flops = max(flops, _flops);
    }

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        _KeyValuePairs(
          title: '',
          pairs: {
            ...deviceInfo.map((key, value) => MapEntry(key.codeToName, value)),
            if (socName.isNotEmpty && socName != "Unknown") 'SocName'.codeToName: socName,
            if (socBrand != SocBrand.unknown) 'SocBrand'.codeToName: socBrand.name,
            if (model != null) '---': '',
            if (model != null) 'Model'.codeToName: "${model.name} ${model.quantization}",
            if (model != null) 'FileSize'.codeToName: '${(model.fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
            if (model != null) 'Backend'.codeToName: model.backend?.asArgument ?? '-',
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: null,
                onPressed: () => ModelSelector.show(),
                style: const ButtonStyle(visualDensity: .standard),
                label: Text(S.current.select_model),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: generating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : null,
                onPressed: model == null ? null : () => onStartStopTap(),
                style: const ButtonStyle(visualDensity: .standard),
                label: Text(generating ? S.current.stop : S.current.start),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BatchSizeSelector(
          selectedBatchSize: selectedBatchSize,
          supportedBatchSizes: supportedBatchSizes,
          onChanged: (value) {
            setState(() {
              selectedBatchSize = value;
            });
          },
        ),
        const SizedBox(height: 16),
        if (!generating && flops != 0)
          _KeyValuePairs(
            title: S.current.test_result,
            pairs: {
              'FLOPS': '${flops.toStringAsFixed(2)} T/s',
              'BW': '${bw.toStringAsFixed(2)} GB/s',
              'Prefill': '${prefillSpeed.toStringAsFixed(2)} t/s',
              'Decode': '${decodeSpeed.toStringAsFixed(2)} t/s',
            },
          ),
      ],
    );
  }
}

class _BatchSizeSelector extends ConsumerWidget {
  final int selectedBatchSize;
  final List<int> supportedBatchSizes;
  final ValueChanged<int> onChanged;

  const _BatchSizeSelector({
    required this.selectedBatchSize,
    required this.supportedBatchSizes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = <int>{1, ...supportedBatchSizes}.toList()..sort();
    final s = S.of(context);

    return Material(
      borderRadius: const .all(.circular(8)),
      child: Padding(
        padding: const .symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(
              S.current.batch_inference_count,
              style: const TextStyle(fontSize: 14, fontWeight: .w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: selectedBatchSize,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: .symmetric(horizontal: 12, vertical: 8),
              ),
              items: options.map((size) {
                final label = size == 1 ? '1 (${s.single_thread})' : '$size (${s.multi_thread})';
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyValuePairs extends StatelessWidget {
  final Map<String, String> pairs;
  final String title;

  const _KeyValuePairs({required this.pairs, required this.title});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const .all(.circular(8)),
      child: Padding(
        padding: const .symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: .w500),
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
                const Divider(height: 12, thickness: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _Utils {
  static final int _operates = 10_000_000;

  static Future<double> testFlops(int numberOfCores) async {
    int cores = numberOfCores;
    if (cores <= 0) {
      final out0 = _exec('ls', ['/sys/devices/system/cpu/']);
      final cpus = out0?.split('\n').map((e) => e.trim()).where((e) => e.startsWith('cpu') && e.length == 4) ?? [];
      cores = cpus.length;
    }
    qqq('start test flops, cores=$cores');

    final port = ReceivePort();
    for (var i = 0; i < cores; i++) {
      Isolate.spawn((sp) async {
        try {
          final count = 10;
          final r = [for (var i = 0; i < count; i++) await _testFlops()].reduce((a, b) => a + b) / count;
          sp.send(r);
        } catch (e) {
          qqe(e);
          sp.send(-1);
        }
      }, port.sendPort);
    }
    final r = await port.take(cores).toList();
    port.close();
    final avgMs = (r.reduce((a, b) => a + b) as double) / cores;
    qqq("${r.join('\n')}\navg:${avgMs}ms");
    return (_operates / avgMs * 1000) * cores;
  }

  static Future<double> _testFlops() async {
    final stopwatch = Stopwatch()..start();
    double result = 2.2;
    for (int i = 1; i < _operates; i++) {
      result = result * i;
    }
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds.toDouble();
  }

  static Map<String, String> getMemInfo() {
    final out = _exec('cat', ['/proc/meminfo']);
    final lines = out?.replaceAll('\r\n', '\n').split('\n') ?? [];
    final memInfo = <String, String>{};
    for (final line in lines) {
      final parts = line.split(' ').where((element) => element.isNotEmpty).toList();
      if (parts.length < 2) {
        continue;
      }
      //qqq('${parts[0]} ${(int.parse(parts[1]) / 1024 / 1024).toStringAsFixed(2) + 'GB'}');
      try {
        if (line.contains("MemTotal")) {
          memInfo['MemTotal'] = (int.parse(parts[1]) / 1024 / 1024).toStringAsFixed(2) + 'GB';
        }
        if (Platform.isWindows) {
          if (line.contains("MemFree")) {
            memInfo['MemFree'] = (int.parse(parts[1]) / 1024 / 1024).toStringAsFixed(2) + 'GB';
          }
        } else {
          if (line.contains("MemAvailable")) {
            memInfo['MemAvailable'] = (int.parse(parts[1]) / 1024 / 1024).toStringAsFixed(2) + 'GB';
          }
        }
      } catch (e) {
        //
      }
    }
    return memInfo;
  }

  static String? _exec(String executable, List<String> arguments, {bool runInShell = false}) {
    try {
      final result = Process.runSync(executable, arguments, runInShell: runInShell);
      if (result.exitCode == 0) {
        return result.stdout.toString();
      }
    } catch (e) {
      //
    }
    return null;
  }
}

class _LambadaTest extends ConsumerWidget {
  const _LambadaTest();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testItems = ref.watch(P.lambada.testItems);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final totalFinishCount = ref.watch(P.lambada.totalFinishCount);
    final currentItem = ref.watch(P.lambada.currentItem);
    final testResults = ref.watch(P.lambada.testResults);

    // 计算列表项数量：1个当前项 + 历史项数量
    final historyItemCount = testResults.length;

    return ListView.builder(
      padding: const .only(left: 12, right: 12, top: 12, bottom: 12),
      itemCount: historyItemCount + 1 + 4,
      itemBuilder: (context, index) {
        // 第一个条目是当前正在测试的项
        if (index == 0) {
          return const Padding(
            padding: .only(bottom: 8),
            child: _LambadaTestControlButtons(),
          );
        }
        if (index == 1) {
          return const Padding(
            padding: .only(bottom: 8),
            child: _LambadaModelSelectionButton(),
          );
        }
        if (index == 2) {
          return const _LambadaTestDataCard();
        }
        if (index == 3) {
          return const _LambadaTestResultsCard();
        }
        if (index == 4) {
          return _LambadaTestListItem(
            isCurrentItem: true,
            testItems: testItems,
            totalFinishCount: totalFinishCount - (isRunning ? 0 : 1),
            currentItem: currentItem,
            testResults: testResults,
          );
        }
        // 后续条目是历史项（倒序）
        final historyIndex = (index - (isRunning ? 1 : 0)) - 4;
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
    );
  }
}

class _LambadaTestControlButtons extends ConsumerWidget {
  const _LambadaTestControlButtons();

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

class _LambadaModelSelectionButton extends ConsumerWidget {
  const _LambadaModelSelectionButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final currentModel = ref.watch(P.rwkv.latestModel);

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

class _LambadaTestDataCard extends ConsumerWidget {
  const _LambadaTestDataCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final testItems = ref.watch(P.lambada.testItems);
    final isRunning = ref.watch(P.lambada.autoStartNextTest);
    final totalFinishCount = ref.watch(P.lambada.totalFinishCount);
    final progress = ((totalFinishCount / (testItems.isEmpty ? 1 : testItems.length)).toDouble()).clamp(0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          crossAxisAlignment: .start,
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

class _LambadaTestResultsCard extends ConsumerWidget {
  const _LambadaTestResultsCard();

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
        padding: const .all(16.0),
        child: Column(
          crossAxisAlignment: .start,
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
                    padding: const .symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.q(0.2),
                      borderRadius: .circular(12),
                      border: Border.all(color: Colors.orange.q(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: .min,
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
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _LambadaResultCard(
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
                  child: _LambadaResultCard(
                    title: s.correct_count,
                    value: '$correctCount',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _LambadaResultCard(
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
    final s = S.of(context);

    if (isCurrentItem) {
      // 当前正在测试的项
      if (testItems == null || totalFinishCount == null) {
        return const SizedBox.shrink();
      }

      final currentIndex = totalFinishCount!;
      if (testItems!.isEmpty || currentIndex >= testItems!.length) {
        return const SizedBox.shrink();
      }

      // 查找当前测试项目的结果
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
        child: Padding(
          padding: const .all(16.0),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                s.current_test_item(currentIndex + 1, testItems!.length),
                style: Theme.of(context).textTheme.titleMedium,
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
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        s.target_text(displayTargetText),
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.model_output(displayOutputText),
                        style: TextStyle(
                          fontSize: 12,
                          color: displayIsCorrect ? Colors.green.shade700 : Colors.red.shade700,
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
    } else {
      // 历史项
      if (index == null || sourceText == null || targetText == null || outputText == null || isCorrect == null) {
        return const SizedBox.shrink();
      }

      return Card(
        child: Padding(
          padding: const .all(16.0),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                '#$index',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: .w600,
                  color: Colors.grey,
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
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.model_output(outputText!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isCorrect! ? Colors.green.shade700 : Colors.red.shade700,
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
        border: Border.all(color: color.q(0.3)),
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
