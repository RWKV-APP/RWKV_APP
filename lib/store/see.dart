part of 'p.dart';

class _See {
  // ===========================================================================
  // Instance
  // ===========================================================================

  late final _recorder = ar.AudioRecorder();
  late final _audioPlayer = ap.AudioPlayer();

  late final audioFileStreamController = StreamController<(File file, int length)>.broadcast();
  final List<Uint8List> _audioData = [];
  Stream<Uint8List>? _currentRecorderStream;
  StreamController<Uint8List>? _currentStreamController;

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  // 🔥 Vision

  late final imagePath = qs<String?>(null);
  late final imageHeight = qs<double?>(null);
  late final visualFloatHeight = qs<double?>(null);

  // 🔥 Audio

  /// in milliseconds
  late final startTime = qs(0);

  /// in milliseconds
  late final endTime = qs(0);
  late final audioPath = qs("");
  late final audioDuration = qs(0);
  late final recording = qs(false);
  late final playing = qs(false);

  /// TODO: Use it!
  late final streaming = qs(false);
}

/// Public methods
extension $See on _See {
  Future<void> startRecord() async {
    qq;
    await stopPlaying();
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      Alert.warning(S.current.please_grant_permission_to_use_microphone);
      return;
    }

    final t = HF.milliseconds;
    startTime.q = t;
    recording.q = true;
    _currentStreamController = StreamController<Uint8List>();
    final rawAudioStream = _currentStreamController!.stream;
    final audioStream = rawAudioStream.asBroadcastStream();

    _audioData.clear();
    audioStream.listen(
      (data) {
        _audioData.add(data);
      },
      onDone: () {
        qqq("AudioStream Done");
      },
      onError: (error, stackTrace) {
        qqe("AudioStream Error: $error");
        qqe("AudioStream StackTrace: $stackTrace");
      },
    );
  }

  Future<bool> stopRecord({bool isCancel = false}) async {
    if (!recording.q) return false;
    qq;
    recording.q = false;

    final cc = _currentStreamController;
    cc?.close();
    _currentStreamController = null;

    if (isCancel) {
      _audioData.clear();
      return false;
    }

    final t = HF.milliseconds;
    endTime.q = t;

    final audioLengthInMilliseconds = endTime.q - startTime.q;

    if (audioLengthInMilliseconds < 1000) {
      Alert.warning(S.current.your_voice_is_too_short);
      qqw("audioLengthInMilliseconds: $audioLengthInMilliseconds");
      return false;
    }

    if (_audioData.isEmpty) {
      Alert.warning(S.current.your_voice_is_empty);
      throw Exception("😡 audioData is empty");
    }

    final cacheDir = P.app.cacheDir.q;
    if (cacheDir == null) throw Exception("😡 cacheDir is null");

    final path = "${cacheDir.path}/${HF.seconds}.${S.current.my_voice}.wav";
    final file = File(path);

    List<int> wavHeader = _createWavHeader(
      dataSize: _audioData.expand((x) => x).length,
      sampleRate: 16000,
      numChannels: 1,
      bitsPerSample: 16,
    );

    await file.writeAsBytes(wavHeader);

    for (var chunk in _audioData) {
      await file.writeAsBytes(chunk, mode: FileMode.append);
    }

    audioFileStreamController.add((file, audioLengthInMilliseconds));

    _audioData.clear();

    return true;
  }

  Future<void> play({required String path}) async {
    qq;
    if (path.isEmpty) return;
    await stopPlaying();
    ap.Source source = ap.DeviceFileSource(path);
    playing.q = true;
    P.app.hapticLight();

    await _audioPlayer.play(source);
    P.talk.audioStream?.resetStat();
    P.talk.audioStream?.uninit();
  }

  Future<void> stopPlaying() async {
    playing.q = false;
    await _audioPlayer.stop();
    P.talk.audioStream?.resetStat();
    P.talk.audioStream?.uninit();
  }

  Future<void> selectImage() async {
    if (P.chat.focusNode.hasFocus) {
      P.chat.focusNode.unfocus();
      return;
    }

    if (!checkModelSelection(preferredDemoType: DemoType.see)) return;

    final imagePath = await showImageSelector();
    if (imagePath == null) return;
    this.imagePath.q = imagePath;

    // TODO: Prefill the chat with the image
  }

  Future<void> _tryLoadLastWorldModel() async {
    if (P.app.pageKey.q != PageKey.see) return;

    await Future.delayed(500.ms);

    final last = P.preference.lastWorldModel.q;
    if (last == null) {
      if (P.app.pageKey.q == PageKey.see) {
        ModelSelector.show(preferredDemoType: .see);
      }
      return;
    }

    try {
      final worldTypeString = last["worldType"];
      final modelFileName = last["modelFileName"];
      final worldType = WorldType.values.byName(worldTypeString);

      final availableModels = P.fileManager.seeWeights.q;
      final fileInfos = availableModels.where((e) => e.worldType == worldType).toList();

      final encoderFileKey = fileInfos.firstWhere((e) => e.isEncoder);
      final modelFileKey = fileInfos.firstWhere((e) => !e.isEncoder && e.fileName == modelFileName);
      final adapterFileKey = fileInfos.firstWhereOrNull((e) => e.isAdapter);

      final encoderLocalFile = P.fileManager.locals(encoderFileKey).q;
      final modelLocalFile = P.fileManager.locals(modelFileKey).q;
      final adapterLocalFile = adapterFileKey != null ? P.fileManager.locals(adapterFileKey).q : null;

      if (!encoderLocalFile.hasFile || !modelLocalFile.hasFile || (adapterLocalFile != null && !adapterLocalFile.hasFile)) {
        if (P.app.pageKey.q == PageKey.see) {
          ModelSelector.show(preferredDemoType: DemoType.see);
        }
        return;
      }

      P.rwkv.currentWorldType.q = worldType;
      P.rwkv.clearStates();
      P.chat.clearMessages();

      switch (worldType) {
        case WorldType.reasoningQA:
        case WorldType.ocr:
          await P.rwkv.loadSee(
            modelPath: modelLocalFile.targetPath,
            encoderPath: encoderLocalFile.targetPath,
            backend: modelFileKey.backend!,
            enableReasoning: worldType.isReasoning,
            adapterPath: null,
            fileInfo: modelFileKey,
          );
        case WorldType.modrwkvV2:
        case WorldType.modrwkvV3:
          final modelID = await P.rwkv.loadSee(
            modelPath: modelLocalFile.targetPath,
            encoderPath: encoderLocalFile.targetPath,
            backend: modelFileKey.backend!,
            enableReasoning: worldType.isReasoning,
            adapterPath: adapterLocalFile?.targetPath,
            fileInfo: modelFileKey,
          );
          if (modelID != null) P.rwkv.send(SetImageUniqueIdentifier("image"));
          if (modelID != null) P.rwkv.send(SetSpaceAfterRoles(false, modelID: modelID));
      }

      if (P.app.pageKey.q != PageKey.see) return;
    } catch (e) {
      qqe("Failed to auto load world model: $e");
      if (P.app.pageKey.q == PageKey.see) {
        ModelSelector.show(preferredDemoType: DemoType.see);
      }
    }
  }
}

/// Private methods
extension _$See on _See {
  Future<void> _init() async {
    switch (P.app.demoType.q) {
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
        return;
      case DemoType.chat:
      case DemoType.tts:
      case DemoType.see:
    }
    qq;
    P.rwkv.currentWorldType.lv(_onWorldTypeChanged);
    P.talk.audioInteractorShown.lv(_onAudioInteractorShown);
    P.app.demoType.lv(_onWorldTypeChanged);
    _audioPlayer.eventStream.listen(_onPlayerChanged);
    _audioPlayer.onPlayerStateChanged.listen(_onPlayerStateChanged);
    P.app.pageKey.lb(_onPageKeyChanged);
  }

  void _onPageKeyChanged(PageKey? previous, PageKey next) async {
    if (previous == PageKey.see && next != PageKey.see) {
      imagePath.q = null;
      imageHeight.q = null;
      visualFloatHeight.q = null;
      P.rwkv.clearStates();
      P.chat.clearMessages();
      // P.rwkv.currentWorldType.q = null;
      // P.rwkv.currentModel.q = null;
    } else if (previous != PageKey.see && next == PageKey.see) {
      P.rwkv._releaseModelByWeightTypeIfNeeded(weightType: .chat);
      P.rwkv._releaseModelByWeightTypeIfNeeded(weightType: .tts);
      imagePath.q = null;
      imageHeight.q = null;
      visualFloatHeight.q = null;
      P.rwkv.clearStates();
      P.chat.clearMessages();
      P.app.demoType.q = DemoType.see;
      bool isWorldModelLoaded = false;
      final currentModel = P.rwkv.latestModel.q;
      if (currentModel != null) {
        if (currentModel.worldType != null) {
          isWorldModelLoaded = true;
        }
      }

      if (isWorldModelLoaded) {
        // OK
      } else {
        P.rwkv.currentWorldType.q = null;
        await P.rwkv._releaseModelByWeightTypeIfNeeded(weightType: .see);
        _tryLoadLastWorldModel();
      }
    } else {}
  }

  void _onPlayerChanged(ap.AudioEvent event) {
    qqq("🔊 AudioPlayerEvent: $event");
    final eventType = event.eventType;
    switch (eventType) {
      case ap.AudioEventType.complete:
        playing.q = false;
      case ap.AudioEventType.log:
        break;
      case ap.AudioEventType.prepared:
      case ap.AudioEventType.duration:
      case ap.AudioEventType.seekComplete:
        break;
    }
  }

  void _onPlayerStateChanged(ap.PlayerState state) {
    qqq("🔊 AudioPlayerState: $state");
    switch (state) {
      case ap.PlayerState.playing:
        playing.q = true;
      case ap.PlayerState.paused:
        playing.q = false;
      case ap.PlayerState.stopped:
        playing.q = false;
      case ap.PlayerState.completed:
        playing.q = false;
      case ap.PlayerState.disposed:
        playing.q = false;
    }
  }

  void _onAudioInteractorShown() async {
    qq;

    imagePath.q = null;
    imageHeight.q = null;
    visualFloatHeight.q = null;
    startTime.q = 0;
    endTime.q = 0;
    audioDuration.q = 0;
    recording.q = false;
    playing.q = false;
    audioPath.q = "";

    if (!P.talk.audioInteractorShown.q) {
      await _recorder.pause();
      await _recorder.stop();
      await _audioPlayer.stop();
      _currentRecorderStream = null;
      streaming.q = false;
      return;
    }

    await _startStream();
  }

  Future<void> _startStream() async {
    qr;
    final hasPermission = await _recorder.hasPermission();

    qqq("hasPermission: $hasPermission");

    if (!hasPermission) {
      Alert.warning(S.current.please_grant_permission_to_use_microphone);
      await _recorder.pause();
      await _recorder.stop();
      await _audioPlayer.stop();
      _currentRecorderStream = null;
      streaming.q = false;
      return;
    }

    final config = const ar.RecordConfig(
      encoder: ar.AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );

    streaming.q = true;
    try {
      _currentRecorderStream = await _recorder.startStream(config);
    } catch (e) {
      streaming.q = false;
      qqe("Failed to start recording stream");
      qqq(e);
    }

    _currentRecorderStream!.listen((data) {
      final cc = _currentStreamController;
      if (cc == null) return;
      cc.add(data);
    });
  }

  void _onWorldTypeChanged() async {
    qq;

    final demoType = P.app.demoType.q;
    final isWorldDemo = demoType == DemoType.see;

    P.chat.clearMessages();
    imagePath.q = null;
    imageHeight.q = null;
    visualFloatHeight.q = null;
    startTime.q = 0;
    endTime.q = 0;
    audioDuration.q = 0;
    recording.q = false;
    playing.q = false;
    audioPath.q = "";

    if (!isWorldDemo) {
      await _recorder.pause();
      await _recorder.stop();
      await _audioPlayer.stop();
      _currentRecorderStream = null;
      streaming.q = false;
      return;
    }
  }

  List<int> _createWavHeader({
    required int dataSize,
    required int sampleRate,
    required int numChannels,
    required int bitsPerSample,
  }) {
    final bytesPerSample = bitsPerSample ~/ 8;
    final blockAlign = numChannels * bytesPerSample;
    final byteRate = sampleRate * blockAlign;
    final chunkSize = 36 + dataSize;

    List<int> header = [];

    header.addAll('RIFF'.codeUnits);
    header.addAll(_intToBytes(chunkSize, 4));
    header.addAll('WAVE'.codeUnits);

    header.addAll('fmt '.codeUnits);
    header.addAll(_intToBytes(16, 4));
    header.addAll(_intToBytes(1, 2));
    header.addAll(_intToBytes(numChannels, 2));
    header.addAll(_intToBytes(sampleRate, 4));
    header.addAll(_intToBytes(byteRate, 4));
    header.addAll(_intToBytes(blockAlign, 2));
    header.addAll(_intToBytes(bitsPerSample, 2));

    header.addAll('data'.codeUnits);
    header.addAll(_intToBytes(dataSize, 4));

    return header;
  }

  List<int> _intToBytes(int value, int byteCount) {
    List<int> bytes = [];
    for (int i = 0; i < byteCount; i++) {
      bytes.add((value >> (i * 8)) & 0xFF);
    }
    return bytes;
  }
}
