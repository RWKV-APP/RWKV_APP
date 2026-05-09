import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rwkv_mobile_flutter/from_rwkv.dart' as from_rwkv;
import 'package:rwkv_mobile_flutter/rwkv_mobile_flutter.dart';
import 'package:rwkv_mobile_flutter/to_rwkv.dart' as to_rwkv;
import 'package:rwkv_mobile_flutter/types.dart';

const String _modelUrl = String.fromEnvironment('RWKV_TEST_MODEL_URL');
const String _modelPath = String.fromEnvironment('RWKV_TEST_MODEL_PATH');
const String _modelFileName = String.fromEnvironment('RWKV_TEST_MODEL_FILE_NAME');
const String _modelSha256 = String.fromEnvironment('RWKV_TEST_MODEL_SHA256');
const String _backendName = String.fromEnvironment('RWKV_TEST_BACKEND', defaultValue: 'llamacpp');
const String _prompt = String.fromEnvironment('RWKV_TEST_PROMPT', defaultValue: 'Hello, RWKV');
const int _maxTokens = int.fromEnvironment('RWKV_TEST_MAX_TOKENS', defaultValue: 4);
const int _downloadTimeoutMinutes = int.fromEnvironment('RWKV_TEST_DOWNLOAD_TIMEOUT_MINUTES', defaultValue: 35);
const int _downloadRetryCount = int.fromEnvironment('RWKV_TEST_DOWNLOAD_RETRY_COUNT', defaultValue: 8);
const int _loadTimeoutMinutes = int.fromEnvironment('RWKV_TEST_LOAD_TIMEOUT_MINUTES', defaultValue: 20);
const int _generationTimeoutSeconds = int.fromEnvironment('RWKV_TEST_GENERATION_TIMEOUT_SECONDS', defaultValue: 90);
const bool _skipDownloadIfExists = bool.fromEnvironment('RWKV_TEST_SKIP_DOWNLOAD_IF_EXISTS', defaultValue: true);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Test Lab engine smoke', () {
    testWidgets('loads model and generates tokens', (WidgetTester tester) async {
      final backend = Backend.fromString(_backendName);
      final modelPath = await _resolveModelPath();
      final tokenizerPath = await _copyAssetToTemp('assets/config/chat/rwkv_vocab_v20230424.txt');
      final harness = _RwkvHarness();

      await harness.start();
      try {
        final modelID = await harness.loadModel(
          modelPath: modelPath,
          tokenizerPath: tokenizerPath,
          backend: backend,
          timeout: Duration(minutes: _loadTimeoutMinutes),
        );
        expect(modelID, greaterThanOrEqualTo(0));

        final result = await harness.generate(
          modelID: modelID,
          prompt: _prompt,
          maxTokens: _maxTokens,
          timeout: Duration(seconds: _generationTimeoutSeconds),
        );

        debugPrint('RWKV smoke result: modelID=$modelID tokens=${result.tokensCount} text="${result.text}"');
        expect(result.tokensCount, greaterThan(0));
      } finally {
        await harness.close();
      }
    });
  });
}

Future<String> _resolveModelPath() async {
  if (_modelPath.isNotEmpty) {
    final file = File(_modelPath);
    if (await file.exists()) {
      debugPrint('Using existing model path: $_modelPath');
      return _modelPath;
    }
    throw TestFailure('RWKV_TEST_MODEL_PATH does not exist: $_modelPath');
  }

  if (_modelUrl.isEmpty) {
    throw TestFailure('Set RWKV_TEST_MODEL_URL or RWKV_TEST_MODEL_PATH before running the smoke test.');
  }

  final uri = Uri.parse(_modelUrl);
  final fileName = _modelFileName.isNotEmpty ? _modelFileName : path.basename(uri.path);
  if (fileName.isEmpty) {
    throw TestFailure('Cannot infer a model file name from RWKV_TEST_MODEL_URL. Set RWKV_TEST_MODEL_FILE_NAME.');
  }

  final dir = await getApplicationSupportDirectory();
  final modelDir = Directory(path.join(dir.path, 'firebase_test_lab_models'));
  await modelDir.create(recursive: true);
  final file = File(path.join(modelDir.path, fileName));

  if (_skipDownloadIfExists && await file.exists()) {
    debugPrint('Using cached model file: ${file.path}');
    await _verifySha256IfNeeded(file);
    return file.path;
  }

  await _downloadFile(
    uri: uri,
    target: file,
    timeout: Duration(minutes: _downloadTimeoutMinutes),
  );
  await _verifySha256IfNeeded(file);
  return file.path;
}

Future<void> _downloadFile({
  required Uri uri,
  required File target,
  required Duration timeout,
}) async {
  final tempFile = File('${target.path}.part');
  if (await tempFile.exists()) {
    await tempFile.delete();
  }

  debugPrint('Downloading model from $uri');
  final startedAt = DateTime.now();
  DateTime lastLoggedAt = startedAt;
  int receivedBytes = 0;
  int totalBytes = -1;

  for (int attempt = 1; attempt <= _downloadRetryCount + 1; attempt++) {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);

    try {
      final offset = await tempFile.exists() ? await tempFile.length() : 0;
      receivedBytes = offset;

      final request = await client.getUrl(uri).timeout(const Duration(seconds: 30));
      if (offset > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
        debugPrint('Resuming model download from ${_formatBytes(offset)}.');
      }

      final response = await request.close().timeout(const Duration(seconds: 60));
      if (offset > 0 && response.statusCode == HttpStatus.ok) {
        await tempFile.delete();
        throw const _DownloadRestartException();
      }

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      if (!isSuccess) {
        throw TestFailure('Model download failed with HTTP ${response.statusCode}: $uri');
      }

      totalBytes = response.contentLength >= 0 ? offset + response.contentLength : -1;
      final sink = tempFile.openWrite(mode: FileMode.append);

      try {
        await for (final chunk in response.timeout(const Duration(seconds: 90))) {
          sink.add(chunk);
          receivedBytes += chunk.length;

          final now = DateTime.now();
          if (now.difference(startedAt) > timeout) {
            throw TimeoutException('Timed out downloading model after ${timeout.inMinutes} minutes.');
          }

          if (now.difference(lastLoggedAt).inSeconds < 10) {
            continue;
          }
          lastLoggedAt = now;
          debugPrint('Downloaded ${_formatBytes(receivedBytes)} / ${_formatBytes(totalBytes)}');
        }
      } finally {
        await sink.close();
      }

      if (await target.exists()) {
        await target.delete();
      }
      await tempFile.rename(target.path);
      final elapsed = DateTime.now().difference(startedAt);
      debugPrint('Model downloaded to ${target.path}, size=${_formatBytes(receivedBytes)}, elapsed=${elapsed.inSeconds}s');
      return;
    } on Object catch (error, stackTrace) {
      client.close(force: true);

      if (error is _DownloadRestartException) {
        debugPrint('Range download was not accepted; restarting from byte 0.');
        continue;
      }

      final canRetry = attempt <= _downloadRetryCount && DateTime.now().difference(startedAt) <= timeout;
      if (!canRetry) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      final delay = Duration(seconds: attempt * 3);
      debugPrint(
        'Model download interrupted after ${_formatBytes(receivedBytes)} / ${_formatBytes(totalBytes)}. '
        'Retry ${attempt + 1}/${_downloadRetryCount + 1} in ${delay.inSeconds}s: $error',
      );
      await Future<void>.delayed(delay);
    } finally {
      client.close(force: true);
    }
  }
}

class _DownloadRestartException implements Exception {
  const _DownloadRestartException();
}

Future<void> _verifySha256IfNeeded(File file) async {
  if (_modelSha256.isEmpty) {
    return;
  }

  final digest = await sha256.bind(file.openRead()).first;
  final actual = digest.toString().toLowerCase();
  final expected = _modelSha256.toLowerCase();
  if (actual == expected) {
    debugPrint('Model sha256 verified: $actual');
    return;
  }

  throw TestFailure('Model sha256 mismatch. expected=$expected actual=$actual path=${file.path}');
}

Future<String> _copyAssetToTemp(String assetPath) async {
  final tempDir = await getTemporaryDirectory();
  final target = File(path.join(tempDir.path, assetPath));
  await target.parent.create(recursive: true);
  final data = await rootBundle.load(assetPath);
  await target.writeAsBytes(data.buffer.asUint8List(), flush: true);
  return target.path;
}

String _formatBytes(int value) {
  if (value < 0) {
    return 'unknown';
  }

  const units = <String>['B', 'KB', 'MB', 'GB'];
  double size = value.toDouble();
  int unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size = size / 1024;
    unitIndex += 1;
  }
  return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
}

final class _GenerationResult {
  final String text;
  final int tokensCount;

  const _GenerationResult({
    required this.text,
    required this.tokensCount,
  });
}

final class _RwkvHarness {
  final ReceivePort _receivePort = ReceivePort();
  final StreamController<from_rwkv.FromRWKV> _events = StreamController<from_rwkv.FromRWKV>.broadcast();
  final Completer<SendPort> _sendPortCompleter = Completer<SendPort>();
  final List<String> _errors = <String>[];

  StreamSubscription<dynamic>? _subscription;
  RWKVMobile? _rwkvMobile;
  SendPort? _sendPort;

  Future<void> start() async {
    _subscription = _receivePort.listen(_onMessage);
    _rwkvMobile = RWKVMobile();
    final token = RootIsolateToken.instance;
    if (token == null) {
      throw TestFailure('RootIsolateToken is null. This test must run on a Flutter device target.');
    }

    await _rwkvMobile!.runIsolate(StartOptions(sendPort: _receivePort.sendPort, rootIsolateToken: token));
    _sendPort = await _sendPortCompleter.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw TimeoutException('Timed out waiting for RWKV isolate SendPort.');
      },
    );
    debugPrint('RWKV isolate started.');
  }

  Future<int> loadModel({
    required String modelPath,
    required String tokenizerPath,
    required Backend backend,
    required Duration timeout,
  }) async {
    final request = to_rwkv.LoadRWKVModel(
      modelPath: modelPath,
      backend: backend,
      tokenizerPath: tokenizerPath,
    );

    final completer = Completer<int>();
    late final StreamSubscription<from_rwkv.FromRWKV> subscription;
    subscription = _events.stream.listen((from_rwkv.FromRWKV event) {
      if (event is from_rwkv.Error && event.req == request && !completer.isCompleted) {
        completer.completeError(TestFailure(event.message));
        return;
      }

      if (event is! from_rwkv.LoadModelSteps || event.req != request) {
        return;
      }

      if (event.progress != null) {
        debugPrint('RWKV loading progress: ${(event.progress! * 100).toStringAsFixed(1)}%');
      } else {
        debugPrint('RWKV loading status: ${event.status}');
      }

      if (event.status == LoadingStatus.loaded) {
        final modelID = event.modelID;
        if (modelID == null) {
          completer.completeError(TestFailure('LoadModelSteps.loaded returned null modelID.'));
          return;
        }
        completer.complete(modelID);
        return;
      }

      if (event.status == LoadingStatus.failedInLoading && !completer.isCompleted) {
        completer.completeError(TestFailure(event.info ?? 'RWKV model loading failed.'));
      }
    });

    _send(request);
    try {
      return await completer.future.timeout(timeout);
    } finally {
      await subscription.cancel();
    }
  }

  Future<_GenerationResult> generate({
    required int modelID,
    required String prompt,
    required int maxTokens,
    required Duration timeout,
  }) async {
    _send(to_rwkv.SetMaxLength(maxTokens, modelID: modelID));
    _send(
      to_rwkv.SetSamplerParams(
        temperature: 0.8,
        topK: 40,
        topP: 0.9,
        presencePenalty: 0,
        frequencyPenalty: 0,
        penaltyDecay: 0,
        modelID: modelID,
      ),
    );
    _send(to_rwkv.SetSeed(42, modelID: modelID));

    final request = to_rwkv.GenerateAsync(prompt, modelID: modelID, maxLength: maxTokens);
    _send(request);
    await _waitForGenerateStart(request, timeout: const Duration(seconds: 10));
    await _waitForGenerationToStop(modelID: modelID, timeout: timeout);

    final text = await _requestResponseText(modelID);
    final tokensCount = await _requestTokensCount(modelID);
    return _GenerationResult(text: text, tokensCount: tokensCount);
  }

  Future<void> close() async {
    final modelIDs = await _requestLoadedModelIDs(timeout: const Duration(seconds: 5));
    for (final modelID in modelIDs) {
      _send(to_rwkv.ReleaseRWKVModel(modelID: modelID));
    }
    await _subscription?.cancel();
    await _events.close();
    _receivePort.close();
  }

  void _onMessage(dynamic message) {
    if (message is SendPort) {
      if (!_sendPortCompleter.isCompleted) {
        _sendPortCompleter.complete(message);
      }
      return;
    }

    if (message is from_rwkv.FromRWKV) {
      if (message is from_rwkv.Error) {
        _errors.add(message.message);
        debugPrint('RWKV error: ${message.message}');
      }
      _events.add(message);
      return;
    }

    debugPrint('RWKV raw message: $message');
  }

  void _send(to_rwkv.ToRWKV request) {
    final sendPort = _sendPort;
    if (sendPort == null) {
      throw TestFailure('RWKV isolate has not started.');
    }
    sendPort.send(request);
  }

  Future<void> _waitForGenerateStart(to_rwkv.GenerateAsync request, {required Duration timeout}) async {
    final completer = Completer<void>();
    late final StreamSubscription<from_rwkv.FromRWKV> subscription;
    subscription = _events.stream.listen((from_rwkv.FromRWKV event) {
      if (event is from_rwkv.Error && event.req == request && !completer.isCompleted) {
        completer.completeError(TestFailure(event.message));
        return;
      }

      if (event is from_rwkv.GenerateStop && event.req == request && event.error != null && !completer.isCompleted) {
        completer.completeError(TestFailure(event.error!));
        return;
      }

      if (event is from_rwkv.GenerateStart && event.req == request && !completer.isCompleted) {
        completer.complete();
      }
    });

    try {
      await completer.future.timeout(timeout);
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> _waitForGenerationToStop({
    required int modelID,
    required Duration timeout,
  }) async {
    final startedAt = DateTime.now();
    while (DateTime.now().difference(startedAt) < timeout) {
      final isGenerating = await _requestIsGenerating(modelID);
      if (!isGenerating) {
        return;
      }
      if (_errors.isNotEmpty) {
        throw TestFailure('RWKV emitted error while generating: ${_errors.last}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    throw TimeoutException('Timed out waiting for RWKV generation to finish.');
  }

  Future<bool> _requestIsGenerating(int modelID) async {
    final request = to_rwkv.GetIsGenerating(modelID: modelID);
    final completer = Completer<bool>();
    late final StreamSubscription<from_rwkv.FromRWKV> subscription;
    subscription = _events.stream.listen((from_rwkv.FromRWKV event) {
      if (event is from_rwkv.IsGenerating && event.req == request && !completer.isCompleted) {
        completer.complete(event.isGenerating);
      }
    });

    _send(request);
    try {
      return await completer.future.timeout(const Duration(seconds: 5));
    } finally {
      await subscription.cancel();
    }
  }

  Future<String> _requestResponseText(int modelID) async {
    final request = to_rwkv.GetResponseBufferContent(messages: const <String>[], modelID: modelID);
    final completer = Completer<String>();
    late final StreamSubscription<from_rwkv.FromRWKV> subscription;
    subscription = _events.stream.listen((from_rwkv.FromRWKV event) {
      if (event is from_rwkv.ResponseBufferContent && event.req == request && !completer.isCompleted) {
        completer.complete(event.responseBufferContent);
      }
    });

    _send(request);
    try {
      return await completer.future.timeout(const Duration(seconds: 5));
    } finally {
      await subscription.cancel();
    }
  }

  Future<int> _requestTokensCount(int modelID) async {
    final request = to_rwkv.GetResponseBufferTokensCount(modelID: modelID);
    final completer = Completer<int>();
    late final StreamSubscription<from_rwkv.FromRWKV> subscription;
    subscription = _events.stream.listen((from_rwkv.FromRWKV event) {
      if (event is from_rwkv.TokensCount && event.req == request && !completer.isCompleted) {
        completer.complete(event.tokensCount);
      }
    });

    _send(request);
    try {
      return await completer.future.timeout(const Duration(seconds: 5));
    } finally {
      await subscription.cancel();
    }
  }

  Future<List<int>> _requestLoadedModelIDs({required Duration timeout}) async {
    final request = to_rwkv.GetLoadedModelIDs();
    final completer = Completer<List<int>>();
    late final StreamSubscription<from_rwkv.FromRWKV> subscription;
    subscription = _events.stream.listen((from_rwkv.FromRWKV event) {
      if (event is from_rwkv.LoadedModelIDs && event.req == request && !completer.isCompleted) {
        completer.complete(event.loadedModelIDs);
      }
    });

    _send(request);
    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      return const <int>[];
    } finally {
      await subscription.cancel();
    }
  }
}
