part of 'p.dart';

const int benchmarkDecodeTargetCharsPerBatch = 160;
const int benchmarkPromptTokenCount = 512;
const int benchmarkMaxLength = 100;
const Duration benchmarkBackendIdlePollInterval = Duration(milliseconds: 80);
const Duration benchmarkMetricsPollInterval = Duration(milliseconds: 48);
const Duration benchmarkMetricsSettlePollInterval = Duration(milliseconds: 120);
const Duration benchmarkMetricsSettleTimeout = Duration(seconds: 3);
const String benchmarkPrompt =
    "My teacher is Mrs. teacher, he is a woman teacher. She was very young. High on the bridge of the nose has a pair of water Lingling big eyes, short hair, looked even younger. He knows everything very knowledgeable. He taught us the language, we call a stroke of word painting, he wrote the word can be beautiful. Always happy with a smile on his face when the nest. She angry when we are afraid to look at her front, only dare to look at the blackboard. We do not always angry teacher, we have to study hard.My teacher is Mrs. teacher, he is a woman teacher. She was very young. High on the bridge of the nose has a pair of water Lingling big eyes, short hair, looked even younger. He knows everything very knowledgeable. He taught us the language, we call a stroke of word painting, he wrote the word can be beautiful. Always happy with a smile on his face when the nest. She angry when we are afraid to look at her front, only dare to look at the blackboard. We do not always angry teacher, we have to study hard.My teacher is Mrs. teacher, he is a woman teacher. She was very young. High on the bridge of the nose has a pair of water Lingling big eyes, short hair, looked even younger. He knows everything very knowledgeable. He taught us the language, we call a stroke of word painting, he wrote the word can be beautiful. Always happy with a smile on his face when the nest. She angry when we are afraid to look at her front, only dare to look at the blackboard. We do not always angry teacher, we have to study hard.My teacher is Mrs. teacher, he is a woman teacher. She was very young. High on the bridge of the nose has a pair of water Lingling big eyes, short hair, looked even younger. He knows everything very knowledgeable. He taught us the language, we call a stroke of word painting, he wrote the word can be beautiful. Always happy with a smile on his face when the nest. She angry when we are afraid to look at her front, only dare to look at the blackboard. We do not always angry teacher, we have to study hard.My teacher is Mrs. teacher, he is a woman teacher. She was very young. High on the bridge of the nose has a pair of water Lingling big eyes, short hair, looked even younger. He knows everything very knowledgeable.";

class BenchmarkRunResult {
  final int batchSize;
  final double prefillSpeed;
  final double decodeSpeed;
  final double flops;
  final double bw;

  const BenchmarkRunResult({
    required this.batchSize,
    required this.prefillSpeed,
    required this.decodeSpeed,
    required this.flops,
    required this.bw,
  });

  double get decodeSpeedPerBatch => batchSize <= 0 ? 0 : decodeSpeed / batchSize;
}

class BenchmarkControlSnapshot {
  final bool generating;
  final bool finishing;

  const BenchmarkControlSnapshot({
    this.generating = false,
    this.finishing = false,
  });
}

int benchmarkMaxSupportedBatchSize({
  required FileInfo? model,
  required List<int> supportedBatchSizes,
}) {
  if (!(model?.supportsBatchInference ?? false)) return 1;
  if (supportedBatchSizes.isEmpty) return 1;
  return max(1, supportedBatchSizes.reduce(max));
}

List<int> benchmarkBatchPlanFor({
  required FileInfo? model,
  required List<int> supportedBatchSizes,
}) {
  final maxBatchSize = benchmarkMaxSupportedBatchSize(model: model, supportedBatchSizes: supportedBatchSizes);
  return List<int>.generate(maxBatchSize, (index) => index + 1);
}

class _Benchmark {
  late final prefillSpeed = qs<double>(0);
  late final decodeSpeed = qs<double>(0);
  late final currentPrefillProgress = qs<double>(0);
  late final generating = qs(false);
  late final finishing = qs(false);
  late final currentBatchSize = qs<int>(1);
  late final currentBatchOrdinal = qs<int>(0);
  late final currentGeneratedLength = qs<int>(0);
  late final batchPlan = qs<List<int>>([1]);
  late final results = qs<Map<int, BenchmarkRunResult>>({});

  late final controlSnapshot = qp<BenchmarkControlSnapshot>((ref) {
    final generating = ref.watch(this.generating);
    final finishing = ref.watch(this.finishing);
    return BenchmarkControlSnapshot(generating: generating, finishing: finishing);
  });

  bool _currentBatchSawPrefillActivity = false;
  bool _currentBatchReportSubmitted = false;
  bool _currentBatchFinishing = false;
  bool _benchmarkStopRequested = false;
  bool _pageActive = false;
  double _oldMaxLength = 4000;
  int _benchmarkRunId = 0;
  int _activeBatchRunId = 0;
  int _batchAttemptId = 0;
  int _activeBatchAttemptId = 0;
  StreamSubscription? _subscription;
  Completer<void>? _currentBatchCompleter;
  Timer? _benchmarkMetricsPollTimer;
}

extension _$Benchmark on _Benchmark {
  Future<void> _init() async {
    P.rwkv.decodeSpeed.l(_onDecodeSpeedChanged);
    P.rwkv.prefillSpeed.l(_onPrefillSpeedChanged);
    P.rwkv.prefillProgress.l(_onPrefillProgressChanged);
    P.rwkv.generating.l(_onBackendGeneratingChanged);
  }

  void _onDecodeSpeedChanged(double next) {
    if (next <= 0) return;
    decodeSpeed.q = next;
  }

  void _onPrefillSpeedChanged(double next) {
    if (next <= prefillSpeed.q) return;
    prefillSpeed.q = next;
    final bool decoding = currentGeneratedLength.q > 0 || decodeSpeed.q > 0;
    if (!decoding && next > 0) {
      _currentBatchSawPrefillActivity = true;
    }
  }

  void _onPrefillProgressChanged(double next) {
    final double normalizedProgress = next.clamp(0, 1).toDouble();
    final bool decoding = currentGeneratedLength.q > 0 || decodeSpeed.q > 0;
    if (!decoding && normalizedProgress > 0 && normalizedProgress < 1) {
      _currentBatchSawPrefillActivity = true;
    }
    if (!decoding && !_currentBatchSawPrefillActivity && normalizedProgress >= 1.0 && currentPrefillProgress.q <= 0) {
      return;
    }
    final double nextProgress = max(currentPrefillProgress.q, normalizedProgress);
    if ((nextProgress - currentPrefillProgress.q).abs() < 0.0001) return;
    currentPrefillProgress.q = nextProgress;
  }

  void _onBackendGeneratingChanged(bool next) {
    if (!next && generating.q && _currentBatchCompleter != null) {
      unawaited(
        _finishCurrentBatch(
          runId: _activeBatchRunId,
          attemptId: _activeBatchAttemptId,
          report: true,
          stopBackend: false,
        ),
      );
    }
  }

  void _refreshFinishingState() {
    finishing.q = _currentBatchCompleter != null && !generating.q;
  }

  void _requestBenchmarkMetrics() {
    P.rwkv.requestGenerationMetrics(weightType: .chat);
  }

  void _startBenchmarkMetricsPolling() {
    _stopBenchmarkMetricsPolling();
    _requestBenchmarkMetrics();
    _benchmarkMetricsPollTimer = Timer.periodic(benchmarkMetricsPollInterval, (_) {
      if (_currentBatchCompleter == null || _currentBatchFinishing || _benchmarkStopRequested) return;
      _requestBenchmarkMetrics();
    });
  }

  void _stopBenchmarkMetricsPolling() {
    _benchmarkMetricsPollTimer?.cancel();
    _benchmarkMetricsPollTimer = null;
  }

  Duration _backendIdleTimeoutForBatch(int batchSize) {
    final int seconds = (6 + batchSize * 4).clamp(10, 40);
    return Duration(seconds: seconds);
  }

  Future<void> _waitForFinalBatchMetrics({required bool expectDecode}) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < benchmarkMetricsSettleTimeout) {
      final double settledDecodeSpeed = max(
        max(decodeSpeed.q, P.rwkv.decodeSpeed.q),
        P.telemetry.snapshotPeakDecodeSpeed(),
      );
      if (expectDecode) {
        if (settledDecodeSpeed > 0) return;
      } else {
        final double settledPrefillSpeed = max(prefillSpeed.q, P.rwkv.prefillSpeed.q);
        if (settledPrefillSpeed > 0 || settledDecodeSpeed > 0) return;
      }

      _requestBenchmarkMetrics();
      await Future<void>.delayed(benchmarkMetricsSettlePollInterval);
    }
  }

  Future<bool> _waitForBackendIdle({required Duration timeout}) async {
    final stopwatch = Stopwatch()..start();
    while (P.rwkv.generating.q && stopwatch.elapsed < timeout) {
      await Future<void>.delayed(benchmarkBackendIdlePollInterval);
    }
    return !P.rwkv.generating.q;
  }

  void _resetRunState({required List<int> plan}) {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    currentPrefillProgress.q = 0;
    generating.q = true;
    _benchmarkStopRequested = false;
    _currentBatchReportSubmitted = false;
    _currentBatchSawPrefillActivity = false;
    currentBatchSize.q = plan.first;
    currentBatchOrdinal.q = 0;
    currentGeneratedLength.q = 0;
    batchPlan.q = plan;
    results.q = const <int, BenchmarkRunResult>{};
    _refreshFinishingState();
  }

  void _resetCurrentBatchState({
    required int batchSize,
    required int ordinal,
  }) {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    currentPrefillProgress.q = 0;
    _currentBatchSawPrefillActivity = false;
    currentBatchSize.q = batchSize;
    currentBatchOrdinal.q = ordinal;
    currentGeneratedLength.q = 0;
    _refreshFinishingState();
  }
}

extension $Benchmark on _Benchmark {
  void onPageOpened() {
    if (_pageActive) return;
    _pageActive = true;
    _oldMaxLength = P.rwkv.arguments(Argument.maxLength).q;
    P.rwkv.syncMaxLength(maxLength: benchmarkMaxLength);
  }

  void onPageClosed() {
    if (!_pageActive) return;
    _pageActive = false;
    stopBenchmark(report: true);
    P.rwkv.syncMaxLength(maxLength: _oldMaxLength);
  }

  void onStartStopTap() {
    if (generating.q) {
      stopBenchmark(report: true);
      return;
    }
    unawaited(_startBenchmarkSequence());
  }

  void stopBenchmark({required bool report}) {
    if (_benchmarkStopRequested) return;
    if (!generating.q && _currentBatchCompleter == null) return;
    _benchmarkStopRequested = true;
    unawaited(
      _finishCurrentBatch(
        runId: _activeBatchRunId,
        attemptId: _activeBatchAttemptId,
        report: report,
        stopBackend: true,
      ),
    );
    generating.q = false;
    _refreshFinishingState();
  }

  Future<void> _startBenchmarkSequence() async {
    if (generating.q || _currentBatchCompleter != null || P.rwkv.generating.q) return;

    final runId = ++_benchmarkRunId;
    final model = P.rwkv.latestModel.q;
    final plan = benchmarkBatchPlanFor(model: model, supportedBatchSizes: P.rwkv.supportedBatchSizes.q);
    _resetRunState(plan: plan);

    try {
      for (final entry in plan.indexed) {
        final ordinal = entry.$1 + 1;
        final batchSize = entry.$2;
        if (_benchmarkStopRequested || runId != _benchmarkRunId) break;
        final bool backendIdle = await _waitForBackendIdle(
          timeout: _backendIdleTimeoutForBatch(batchSize),
        );
        if (!backendIdle || _benchmarkStopRequested || runId != _benchmarkRunId) break;
        await _runSingleBatch(runId: runId, batchSize: batchSize, ordinal: ordinal);
      }
    } finally {
      await _subscription?.cancel();
      _subscription = null;
      if (runId == _benchmarkRunId) {
        _currentBatchCompleter = null;
        _activeBatchRunId = 0;
        _activeBatchAttemptId = 0;
      }
      if (runId == _benchmarkRunId) {
        generating.q = false;
        _refreshFinishingState();
      }
    }
  }

  Future<void> _runSingleBatch({
    required int runId,
    required int batchSize,
    required int ordinal,
  }) async {
    final completer = Completer<void>();
    final attemptId = ++_batchAttemptId;
    _currentBatchCompleter = completer;
    _currentBatchReportSubmitted = false;
    _currentBatchFinishing = false;
    _activeBatchRunId = runId;
    _activeBatchAttemptId = attemptId;
    _resetCurrentBatchState(batchSize: batchSize, ordinal: ordinal);

    P.rwkv.prefillProgress.q = 0;
    P.chat.receivedTokens.q = "";
    await P.rwkv.clearStates();

    await _subscription?.cancel();
    _subscription = P.rwkv
        .completion(
          benchmarkPrompt,
          batchSize: batchSize,
          maxLength: benchmarkMaxLength,
          disableCache: true,
        )
        .listen(
          (event) {
            _handleBatchOutputEvent(
              runId: runId,
              attemptId: attemptId,
              response: event,
            );
          },
          onError: (error) {
            _benchmarkStopRequested = true;
            unawaited(
              _finishCurrentBatch(
                runId: runId,
                attemptId: attemptId,
                report: false,
                stopBackend: true,
              ),
            );
          },
          onDone: () {
            unawaited(
              _finishCurrentBatch(
                runId: runId,
                attemptId: attemptId,
                report: true,
                stopBackend: false,
              ),
            );
          },
        );
    _startBenchmarkMetricsPolling();

    await completer.future;
  }

  void _handleBatchOutputEvent({
    required int runId,
    required int attemptId,
    required dynamic response,
  }) {
    if (runId != _benchmarkRunId || attemptId != _activeBatchAttemptId || _currentBatchCompleter == null) return;

    final contents = response.responseBufferContent;
    if (contents is! List) return;
    if (contents.isEmpty) return;
    final textContents = contents.map<String>((content) => content.toString()).toList(growable: false);
    final promptPrefix = benchmarkPrompt.substring(0, min(64, benchmarkPrompt.length));
    final generatedLengths = textContents
        .map((content) {
          final baselineLength = content.startsWith(promptPrefix) ? benchmarkPrompt.length : 0;
          return max(0, content.length - baselineLength);
        })
        .toList(growable: false);
    final dynamic eosValues = response.eosFound;
    final List<bool> eosFound;
    if (eosValues is List) {
      eosFound = eosValues.map<bool>((value) => value == true).toList(growable: false);
    } else {
      eosFound = const <bool>[];
    }
    final List<int> progressLengths = <int>[];
    for (final int index in Iterable<int>.generate(generatedLengths.length)) {
      final bool finished = index < eosFound.length && eosFound[index];
      progressLengths.add(finished ? benchmarkDecodeTargetCharsPerBatch : generatedLengths[index]);
    }
    final generatedLength = progressLengths.reduce(min);
    if (generatedLength > currentGeneratedLength.q) {
      currentGeneratedLength.q = generatedLength;
      if ((_currentBatchSawPrefillActivity || prefillSpeed.q > 0) && currentPrefillProgress.q < 1.0) {
        currentPrefillProgress.q = 1.0;
      }
    } else {
      currentGeneratedLength.q = max(currentGeneratedLength.q, generatedLength);
      if (generatedLength > 0 && (_currentBatchSawPrefillActivity || prefillSpeed.q > 0) && currentPrefillProgress.q < 1.0) {
        currentPrefillProgress.q = 1.0;
      }
    }

    if (generatedLength >= benchmarkDecodeTargetCharsPerBatch) {
      unawaited(
        _finishCurrentBatch(
          runId: runId,
          attemptId: attemptId,
          report: true,
          stopBackend: true,
        ),
      );
    }
  }

  Future<void> _finishCurrentBatch({
    required int runId,
    required int attemptId,
    required bool report,
    required bool stopBackend,
  }) async {
    if (runId == 0 || runId != _activeBatchRunId || runId != _benchmarkRunId) return;
    if (attemptId == 0 || attemptId != _activeBatchAttemptId) return;
    final completer = _currentBatchCompleter;
    if (completer == null || completer.isCompleted) return;
    if (_currentBatchFinishing) return;
    _currentBatchFinishing = true;
    _requestBenchmarkMetrics();
    _stopBenchmarkMetricsPolling();

    if (stopBackend) {
      await P.chat.stopCompletion();
    }

    await _waitForBackendIdle(timeout: _backendIdleTimeoutForBatch(currentBatchSize.q));
    await _waitForFinalBatchMetrics(expectDecode: report);

    final currentSubscription = _subscription;
    _subscription = null;
    await currentSubscription?.cancel();

    if (report && runId == _benchmarkRunId) {
      await _maybeReportCurrentBatch();
    }

    if (!completer.isCompleted) {
      completer.complete();
    }
    _refreshFinishingState();
  }

  Future<void> _maybeReportCurrentBatch() async {
    if (_currentBatchReportSubmitted) return;

    final double snapshotPeakDecodeSpeed = P.telemetry.snapshotPeakDecodeSpeed();
    final double effectivePrefillSpeed = prefillSpeed.q > 0 ? prefillSpeed.q : P.rwkv.prefillSpeed.q;
    final double directDecodeSpeed = decodeSpeed.q > 0 ? decodeSpeed.q : P.rwkv.decodeSpeed.q;
    final double displayDecodeSpeed = directDecodeSpeed > 0 ? directDecodeSpeed : snapshotPeakDecodeSpeed;
    if (effectivePrefillSpeed <= 0 && displayDecodeSpeed <= 0) return;

    _currentBatchReportSubmitted = true;
    _recordBatchResult(
      batchSize: currentBatchSize.q,
      prefillSpeed: max(0, effectivePrefillSpeed),
      decodeSpeed: max(0, displayDecodeSpeed),
      peakDecodeSpeed: snapshotPeakDecodeSpeed,
    );

    if (effectivePrefillSpeed <= 0 || displayDecodeSpeed <= 0) return;

    await P.telemetry.maybeReport(
      prefillSpeed: effectivePrefillSpeed,
      decodeSpeed: displayDecodeSpeed,
      snapshotPeakDecodeSpeed: snapshotPeakDecodeSpeed,
      batchCountOverride: currentBatchSize.q,
      isBatchOverride: currentBatchSize.q > 1,
    );
  }

  void _recordBatchResult({
    required int batchSize,
    required double prefillSpeed,
    required double decodeSpeed,
    required double peakDecodeSpeed,
  }) {
    final model = P.rwkv.latestModel.q;
    final double modelSizeGb = model == null ? 0 : model.fileSize / 1024 / 1024 / 1024;
    final double effectiveDecodeSpeed = batchSize > 1 && peakDecodeSpeed > 0 ? peakDecodeSpeed : decodeSpeed;
    final result = BenchmarkRunResult(
      batchSize: batchSize,
      prefillSpeed: prefillSpeed,
      decodeSpeed: effectiveDecodeSpeed,
      flops: modelSizeGb <= 0 ? 0 : 2 * modelSizeGb * prefillSpeed / 1000,
      bw: modelSizeGb <= 0 ? 0 : modelSizeGb * effectiveDecodeSpeed,
    );
    results.q = {...results.q, batchSize: result};
  }
}
