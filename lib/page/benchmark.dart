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
import 'package:zone/store/p.dart' show P, $Chat, $RWKV;
import 'package:zone/widgets/model_selector.dart';

import 'package:zone/gen/l10n.dart' show S;

class PageBenchmark extends ConsumerWidget {
  const PageBenchmark({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(S.current.performance_test),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _Test(),
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
    ref.listen(P.chat.receivingTokens, (p, r) {
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
    final model = ref.watch(P.rwkv.currentModel);
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
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
                style: const ButtonStyle(visualDensity: VisualDensity.standard),
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
                style: const ButtonStyle(visualDensity: VisualDensity.standard),
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

    return Material(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.current.batch_inference_count,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: selectedBatchSize,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: options.map((size) {
                final label = size == 1 ? '1 (单线程)' : '$size (多线程)';
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
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            if (title.isNotEmpty) const SizedBox(height: 6),
            for (final pair in pairs.entries) ...[
              if (pair.key != '---')
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
