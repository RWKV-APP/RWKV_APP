// Dart imports:
import 'dart:math';
import 'dart:ui' as ui;

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/func/format_bytes.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/lambada_test_item.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/loading_progress_button_content.dart';
import 'package:zone/widgets/model_selector.dart';

part 'benchmark/benchmark_controls.dart';
part 'benchmark/benchmark_results.dart';
part 'benchmark/benchmark_lambada.dart';

class PageBenchmark extends ConsumerStatefulWidget {
  const PageBenchmark({super.key});

  @override
  ConsumerState<PageBenchmark> createState() => _PageBenchmarkState();
}

class _PageBenchmarkState extends ConsumerState<PageBenchmark> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _lastSettledTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    P.benchmark.onPageOpened();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (index == _lastSettledTabIndex) return;
    _lastSettledTabIndex = index;
    _stopAllTests();
  }

  void _stopAllTests() {
    P.benchmark.stopBenchmark(report: true);
    if (P.lambada.autoStartNextTest.q) {
      P.lambada.stopTest();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _stopAllTests();
    P.benchmark.onPageClosed();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final s = S.of(context);
    final benchmarkTheme = theme.copyWith(
      tabBarTheme: theme.tabBarTheme.copyWith(
        dividerColor: qb.q(.16),
        indicatorColor: qb.q(.5),
        labelColor: qb,
        unselectedLabelColor: qb.q(.68),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: qb.q(.62),
        linearTrackColor: appTheme.settingBg,
      ),
      splashColor: qb.q(.06),
      highlightColor: qb.q(.04),
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _stopAllTests();
        }
      },
      child: Theme(
        data: benchmarkTheme,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(s.performance_test),
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
            children: const [
              _Test(),
              _LambadaTest(),
            ],
          ),
          extendBody: true,
          bottomNavigationBar: _BenchmarkScaffoldActionBar(
            activeTabIndex: _tabController.index,
          ),
        ),
      ),
    );
  }
}

class _Test extends ConsumerWidget {
  const _Test();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final model = ref.watch(P.rwkv.latestModel);
    final supportedBatchSizes = ref.watch(P.rwkv.supportedBatchSizes);
    final maxSupportedBatchSize = benchmarkMaxSupportedBatchSize(model: model, supportedBatchSizes: supportedBatchSizes);
    final generating = ref.watch(P.benchmark.generating);
    final currentBatchSize = ref.watch(P.benchmark.currentBatchSize);
    final currentBatchOrdinal = ref.watch(P.benchmark.currentBatchOrdinal);
    final currentGeneratedLength = ref.watch(P.benchmark.currentGeneratedLength);
    final currentPrefillProgress = ref.watch(P.benchmark.currentPrefillProgress);
    final prefillSpeed = ref.watch(P.benchmark.prefillSpeed);
    final decodeSpeed = ref.watch(P.benchmark.decodeSpeed);
    final batchPlan = ref.watch(P.benchmark.batchPlan);
    final batchResults = ref.watch(P.benchmark.results);
    final visibleBatchPlan = generating ? batchPlan : benchmarkBatchPlanFor(model: model, supportedBatchSizes: supportedBatchSizes);
    final modelSupportsBatch = model?.supportsBatchInference ?? false;
    final backendSupportsBatch = maxSupportedBatchSize > 1;
    final telemetryDeviceInfo = ref.watch(P.telemetry.benchmarkDeviceInfo);
    final List<MapEntry<int, BenchmarkRunResult>> completedResults = batchResults.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final BenchmarkRunResult? latestCompletedResult = completedResults.isEmpty ? null : completedResults.last.value;
    final bool showBenchmarkProgress = generating || latestCompletedResult != null;
    final int displayBatchSize = generating ? currentBatchSize : (latestCompletedResult?.batchSize ?? currentBatchSize);
    final int displayBatchOrdinal = generating
        ? currentBatchOrdinal
        : (latestCompletedResult == null ? currentBatchOrdinal : completedResults.length);
    final int displayBatchTotal = max(visibleBatchPlan.length, displayBatchOrdinal);
    final double displayPrefillSpeed = generating ? prefillSpeed : (latestCompletedResult?.prefillSpeed ?? prefillSpeed);
    final double displayDecodeSpeed = generating ? decodeSpeed : (latestCompletedResult?.decodeSpeed ?? decodeSpeed);
    final double displayPrefillProgress = generating ? currentPrefillProgress : (latestCompletedResult == null ? 0 : 1);
    final int generatedLength = generating
        ? min(currentGeneratedLength, benchmarkDecodeTargetCharsPerBatch)
        : (latestCompletedResult == null ? 0 : benchmarkDecodeTargetCharsPerBatch);

    return Theme(
      data: theme,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 112 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: .stretch,
          mainAxisSize: .min,
          children: [
            _KeyValuePairs(
              title: '',
              pairs: {
                ...telemetryDeviceInfo.map((key, value) => MapEntry(_localizedBenchmarkInfoKey(s, key), value)),
                if (model != null) '---': '',
                if (model != null) s.model: model.name,
                if (model != null) s.quantization: model.quantization ?? '-',
                if (model != null) s.benchmark_info_file_size: formatBytes(model.fileSize),
                if (model != null) s.benchmark_info_backend: model.backend?.asArgument ?? '-',
                if (model != null)
                  s.batch_inference: _batchSupportLabel(s, modelSupportsBatch, backendSupportsBatch, maxSupportedBatchSize),
              },
            ),
            const SizedBox(height: 12),
            _BatchPlanCard(
              modelSupportsBatch: modelSupportsBatch,
              backendSupportsBatch: backendSupportsBatch,
              maxSupportedBatchSize: maxSupportedBatchSize,
              batchPlan: visibleBatchPlan,
              running: generating,
              currentBatchSize: currentBatchSize,
              currentBatchOrdinal: currentBatchOrdinal,
            ),
            if (showBenchmarkProgress) ...[
              const SizedBox(height: 12),
              _BenchmarkProgressCard(
                prefillSpeed: displayPrefillSpeed,
                decodeSpeed: displayDecodeSpeed,
                prefillProgress: displayPrefillProgress,
                generatedLength: generatedLength,
                targetLength: benchmarkDecodeTargetCharsPerBatch,
                batchSize: displayBatchSize,
                batchOrdinal: displayBatchOrdinal,
                batchTotal: displayBatchTotal,
              ),
            ],
            const SizedBox(height: 16),
            if (batchResults.isNotEmpty) _BenchmarkResultsCard(results: batchResults.values.toList()),
          ],
        ),
      ),
    );
  }
}

String _batchSupportLabel(S s, bool modelSupportsBatch, bool backendSupportsBatch, int maxSupportedBatchSize) {
  if (!modelSupportsBatch) return s.benchmark_batch_not_supported_by_model;
  if (!backendSupportsBatch) return s.benchmark_batch_waiting_for_backend;
  return s.benchmark_batch_supported_up_to(maxSupportedBatchSize);
}

String _batchPlanText(S s, List<int> batchPlan) {
  if (batchPlan.length == 1) return s.benchmark_batch_plan_single;
  return s.benchmark_batch_plan_range(batchPlan.first, batchPlan.last, batchPlan.length);
}

String _localizedBenchmarkInfoKey(S s, String key) {
  return switch (key) {
    "AppVersion" => s.benchmark_info_app_version,
    "BuildMode" => s.benchmark_info_build_mode,
    "OS" => s.benchmark_info_os,
    "OSVersion" => s.benchmark_info_os_version,
    "DeviceModel" => s.benchmark_info_device_model,
    "SocName" => s.benchmark_info_soc_name,
    "SocBrand" => s.benchmark_info_soc_brand,
    "CPUName" => s.benchmark_info_cpu_name,
    "GPUName" => s.benchmark_info_gpu_name,
    "TotalMemory" => s.benchmark_info_total_memory,
    "TotalVRAM" => s.benchmark_info_total_vram,
    _ => key.codeToName,
  };
}
