import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rxdart/rxdart.dart';
import 'package:system_info2/system_info2.dart';
import 'package:zone/store/p.dart' show P, $Chat;
import 'package:zone/widgets/model_selector.dart';

class PageBenchmark extends ConsumerWidget {
  const PageBenchmark({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Benchmark'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16),
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
  double minSpeed = 99999;
  double maxSpeed = double.minPositive;
  double flops = double.nan;

  bool generating = false;
  bool testingFlops = false;
  Map<String, String> deviceInfo = {};
  final List<double> speed = [];
  final StreamController<double> scSpeed = StreamController<double>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final di = await getDeviceInfo();
      setState(() {
        deviceInfo = di;
      });
    });

    scSpeed.stream.throttleTime(Duration(milliseconds: 100), leading: false, trailing: true).listen((e) {
      if (minSpeed > e) {
        minSpeed = e;
      }
      if (maxSpeed < e) {
        maxSpeed = e;
      }
      speed.add(e);
      setState(() {});
    });
  }

  void onStartStopTap() async {
    if (generating || testingFlops) {
      P.chat.stopCompletion();
      setState(() {
        generating = false;
        testingFlops = false;
      });
    } else {
      setState(() {
        minSpeed = 99999;
        maxSpeed = double.minPositive;
        flops = double.nan;
        speed.clear();
      });
      testingFlops = true;
      final fl = await _Utils.testFlops();
      if (!mounted || !testingFlops) return;
      testingFlops = false;
      setState(() {
        flops = fl;
      });
      P.chat.completion("What is the difference between the two snippets?");
    }
  }

  @override
  void dispose() {
    super.dispose();
    P.chat.stopCompletion();
  }

  Future<Map<String, String>> getDeviceInfo() async {
    // final mem = await SystemInfoPlus.physicalMemory ?? 0;
    // socInfo += 'Memory: ${mem / 1024 / 1024 / 1024}GB\n';
    DeviceInfoPlugin di = DeviceInfoPlugin();
    final android = Platform.isAndroid ? await di.androidInfo : null;
    final windows = Platform.isWindows ? await di.windowsInfo : null;

    final lines = {
      "AppVersion": P.app.version.q + " (${P.app.buildNumber.q})",
      "Kernel": SysInfo.kernelName + ' ' + SysInfo.rawKernelArchitecture + '',
      "Soc": "${P.rwkv.socBrand.q.name} ${P.rwkv.socName.q}",
      ..._Utils.getMemInfo(),
      if (android != null) 'DeviceModel': android.model,
      if (windows != null) 'ProductName': windows.productName,
    };
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final prefill = ref.watch(P.rwkv.prefillSpeed).toStringAsFixed(2);
    final model = ref.watch(P.rwkv.currentModel);
    final speedAvg = (speed.sum / speed.length).toStringAsFixed(2);

    ref.listen(P.chat.receivingTokens, (p, r) {
      if (r != generating) {
        setState(() {
          generating = r;
        });
      }
    });
    ref.listen(P.rwkv.decodeSpeed, (p, r) => scSpeed.add(r));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _KeyValuePairs(
          title: '设备信息',
          pairs: deviceInfo,
        ),
        const SizedBox(height: 16),
        if (model != null)
          _KeyValuePairs(
            pairs: {
              'Model': "${model.name} ${model.quantization}",
              'FileSize': '${(model.fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
              'Backend': model.backend?.asArgument ?? '-',
            },
            title: '模型信息',
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: null,
                onPressed: () => ModelSelector.show(),
                style: ButtonStyle(visualDensity: VisualDensity.standard),
                label: Text('选择模型'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: generating || testingFlops
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : null,
                onPressed: model == null ? null : () => onStartStopTap(),
                style: ButtonStyle(visualDensity: VisualDensity.standard),
                label: Text(generating || testingFlops ? '停止测试' : '开始测试'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _KeyValuePairs(
          title: '测试结果',
          pairs: {
            'Flops': flops.isNaN ? 'NaN' : (flops / 1_000_000).toStringAsFixed(2) + 'M',
            'Prefill Speed': '$prefill t/s',
            'Decode Speed': '${speed.lastOrNull?.toStringAsFixed(2) ?? 'NaN'} t/s',
            'Avg Speed': '$speedAvg t/s',
            'Max Speed': '${maxSpeed == double.minPositive ? 'NaN' : maxSpeed.toStringAsFixed(2)} t/s',
            'Min Speed': '${minSpeed == 99999 ? 'NaN' : minSpeed.toStringAsFixed(2)} t/s',
          },
        ),
      ],
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
      borderRadius: BorderRadius.all(Radius.circular(8)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            for (final pair in pairs.entries) ...[
              Row(
                children: [
                  Expanded(flex: 2, child: Text(pair.key)),
                  Expanded(flex: 3, child: Text(pair.value)),
                ],
              ),
              Divider(height: 6, thickness: 0.5),
            ],
          ],
        ),
      ),
    );
  }
}

class _Utils {
  static Future<double> testFlops() async {
    final port = ReceivePort();
    Isolate.spawn((sp) async {
      final count = 10;
      final r = [for (var i = 0; i < count; i++) await _testFlops()].reduce((a, b) => a + b) / count;
      sp.send(r);
    }, port.sendPort);
    final r = await port.first;
    port.close();
    return r;
  }

  static Future<double> _testFlops() async {
    final stopwatch = Stopwatch()..start();
    double result = 0.0;
    int ops = 100_000_000;
    for (int i = 1; i < ops; i++) {
      result = result * i;
      result = result / i;
    }
    stopwatch.stop();
    return ops / stopwatch.elapsedMilliseconds * 1000;
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
