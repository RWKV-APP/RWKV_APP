part of 'p.dart';

const String _modelScopeAcceptancePrompt = 'User: Reply in one short sentence: What is 1+1?\n\nAssistant:';

Future<void> _runModelScopeDebugAcceptance() async {
  final startedAt = DateTime.now().toUtc();
  final modelName = Args.modelScopeDebugAcceptanceModel;
  final outputName = Args.modelScopeDebugAcceptanceOutputName.isEmpty
      ? 'modelscope-debug-acceptance.json'
      : Args.modelScopeDebugAcceptanceOutputName;
  final result = <String, Object?>{
    'schemaVersion': 1,
    'buildMode': 'debug',
    'modelName': modelName,
    'startedAt': startedAt.toIso8601String(),
    'prompt': _modelScopeAcceptancePrompt,
  };
  int exitStatus = 2;

  try {
    if (!kDebugMode) throw StateError('ModelScope acceptance runner requires Debug mode');
    await P.remote.syncAvailableModels();
    final requestedSource = Args.modelScopeDebugAcceptanceSource.trim();
    if (requestedSource.isNotEmpty) {
      P.remote.downloadSource.q = FileDownloadSource.values.byName(requestedSource);
    }
    await P.remote.sync();
    final matches = P.remote.chatWeights.q.where((FileInfo fileInfo) => fileInfo.name == modelName).toList();
    if (matches.length != 1) {
      throw StateError('Expected one model row named "$modelName", found ${matches.length}');
    }
    final fileInfo = matches.single;
    final downloadSource = P.remote.downloadSource.q;
    final resolvedUrl = downloadSource.resolveUrl(fileInfo.raw);
    result.addAll(<String, Object?>{
      'fileName': fileInfo.fileName,
      'rawUrl': fileInfo.raw,
      'downloadSource': downloadSource.name,
      'url': resolvedUrl,
      'expectedBytes': fileInfo.fileSize,
      'expectedSha256': fileInfo.sha256,
      'backend': fileInfo.backend?.asArgument,
      'platforms': fileInfo.supportedPlatforms,
      'socLimitations': fileInfo.socLimitations,
      'device': P.telemetry.benchmarkDeviceInfo.q,
    });

    final downloadStartedAt = DateTime.now().toUtc();
    await P.remote.getFile(fileInfo: fileInfo).timeout(const Duration(hours: 2));
    final downloadDeadline = DateTime.now().add(const Duration(hours: 2));
    final taskLaunchDeadline = DateTime.now().add(const Duration(minutes: 1));
    bool sawDownloadActivity = false;
    while (true) {
      final downloadState = P.remote.locals(fileInfo).q;
      final pendingModelFile = File(downloadState.targetPath);
      final pendingFileExists = await pendingModelFile.exists();
      final pendingBytes = pendingFileExists ? await pendingModelFile.length() : 0;
      if (pendingFileExists && pendingBytes == fileInfo.fileSize) break;

      sawDownloadActivity = sawDownloadActivity || downloadState.downloading || downloadState.progress > 0;
      if (sawDownloadActivity && downloadState.state == TaskState.stopped) {
        throw StateError(
          'Model download stopped before completion at ${downloadState.progress}: ${pendingModelFile.path}',
        );
      }
      if (!sawDownloadActivity && DateTime.now().isAfter(taskLaunchDeadline)) {
        throw StateError('Model download did not start within one minute: ${pendingModelFile.path}');
      }
      if (DateTime.now().isAfter(downloadDeadline)) {
        throw TimeoutException('Model download did not complete within two hours: ${pendingModelFile.path}');
      }
      await 1000.msLater;
    }
    await P.remote.sync();
    final localFile = P.remote.locals(fileInfo).q;
    final modelFile = File(localFile.targetPath);
    if (!await modelFile.exists()) throw StateError('Downloaded model file is absent: ${modelFile.path}');
    final actualBytes = await modelFile.length();
    if (actualBytes != fileInfo.fileSize) {
      throw StateError('Downloaded size mismatch: expected ${fileInfo.fileSize}, got $actualBytes');
    }
    final actualSha256 = (await modelFile.openRead().transform(crypto.sha256).first).toString();
    if (fileInfo.sha256 == null || actualSha256.toLowerCase() != fileInfo.sha256!.toLowerCase()) {
      throw StateError('Downloaded SHA-256 mismatch: expected ${fileInfo.sha256}, got $actualSha256');
    }
    result.addAll(<String, Object?>{
      'downloadStartedAt': downloadStartedAt.toIso8601String(),
      'downloadFinishedAt': DateTime.now().toUtc().toIso8601String(),
      'localPath': modelFile.path,
      'actualBytes': actualBytes,
      'actualSha256': actualSha256,
      'downloadVerified': true,
    });

    final loadStartedAt = DateTime.now().toUtc();
    await P.rwkvModel.startLocalModelForChat(fileInfo);
    final modelId = P.rwkvModel.allLoaded.q[fileInfo];
    if (modelId == null) throw StateError('RWKV Chat did not report a loaded model ID');
    result.addAll(<String, Object?>{
      'loadStartedAt': loadStartedAt.toIso8601String(),
      'loadFinishedAt': DateTime.now().toUtc().toIso8601String(),
      'modelId': modelId,
      'loadVerified': true,
    });

    final generationStartedAt = DateTime.now().toUtc();
    final generationCompleter = Completer<void>();
    String generatedText = '';
    bool eosFound = false;
    final subscription = P.rwkvGeneration
        .completion(
          _modelScopeAcceptancePrompt,
          batchSize: 1,
          maxLength: 96,
          disableCache: true,
          forceRwkvMobile: true,
        )
        .listen(
          (from_rwkv.ResponseBatchBufferContent event) {
            if (event.responseBufferContent.isNotEmpty) {
              generatedText = event.responseBufferContent.first.toString();
            }
            eosFound = event.eosFound.isNotEmpty && event.eosFound.first;
            if ((eosFound || generatedText.length >= 160) && !generationCompleter.isCompleted) {
              generationCompleter.complete();
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!generationCompleter.isCompleted) generationCompleter.completeError(error, stackTrace);
          },
        );
    try {
      await generationCompleter.future.timeout(const Duration(minutes: 20));
    } finally {
      await P.rwkvGeneration.stop(forceRwkvMobile: true);
      await 750.msLater;
      await subscription.cancel();
    }
    P.rwkvGeneration.requestGenerationMetrics();
    await 500.msLater;
    if (generatedText.trim().isEmpty) throw StateError('Generation completed without visible text');
    result.addAll(<String, Object?>{
      'generationStartedAt': generationStartedAt.toIso8601String(),
      'generationFinishedAt': DateTime.now().toUtc().toIso8601String(),
      'generatedText': generatedText,
      'eosFound': eosFound,
      'prefillTokensPerSecond': P.rwkvGeneration.prefillSpeed.q,
      'decodeTokensPerSecond': P.rwkvGeneration.decodeSpeed.q,
      'generationVerified': true,
    });
    await P.rwkvModel._releaseAllModels();
    result['releaseVerified'] = P.rwkvModel.allLoaded.q.isEmpty;
    result['status'] = 'passed';
    exitStatus = 0;
  } catch (error, stackTrace) {
    result['status'] = 'failed';
    result['error'] = error.toString();
    result['stackTrace'] = stackTrace.toString();
    try {
      await P.rwkvModel._releaseAllModels();
    } catch (_) {}
  } finally {
    result['finishedAt'] = DateTime.now().toUtc().toIso8601String();
    final documentsDir = P.app.effectiveDocumentsDir.q;
    if (documentsDir != null) {
      final outputFile = File(join(documentsDir.path, outputName));
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsString(const JsonEncoder.withIndent('  ').convert(result));
      result['outputPath'] = outputFile.path;
    }
    final encoded = jsonEncode(result);
    debugPrint('MODELSCOPE_DEBUG_ACCEPTANCE_RESULT=$encoded');
    await 500.msLater;
    exit(exitStatus);
  }
}
