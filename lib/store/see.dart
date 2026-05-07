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

  late final waitingText = qs<String?>(null);
  late final waitingImagePath = qs<String?>(null);

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

    for (final chunk in _audioData) {
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

    if (!checkModelSelection(preferredDemoType: .see)) return;

    final imagePath = await showImageSelector();
    if (imagePath == null) return;
    this.imagePath.q = imagePath;

    // TODO: Prefill the chat with the image

    await prefillImage(imagePath);
  }

  Future<void> prefillImage(String imagePath) async {
    if (imagePath.isEmpty) {
      qqe("imagePath is empty");
      return;
    }
    final messages = [
      "<image>$imagePath</image>",
    ];
    P.chat.receiveId.q = Config.seePrefillId;
    await P.rwkvGeneration.sendMessages(messages, maxLength: 0);
  }

  Future<void> autoTest() async {
    await 2000.msLater;
    push(.see);
    await 2000.msLater;
    onSuggestionTap("What is this image?");
    await 100.msLater;
    await selectImage();
    // await Future.delayed(1000.ms);
    // P.chat.onSendButtonPressed(preferredDemoType: .see);
  }

  void onSuggestionTap(String suggestion) {
    P.suggestion.ttsTicker.q += 1;
    final current = P.chat.textEditingController.text;
    if (current.isEmpty) {
      P.chat.textEditingController.text = suggestion;
      return;
    }

    final last = current.characters.last;
    final lastIsChinese = containsChineseCharacters(last);
    final lastIsEnglish = isEnglish(last);
    if (lastIsChinese) {
      P.chat.textEditingController.text = "$current。$suggestion";
    } else if (lastIsEnglish) {
      P.chat.textEditingController.text = "$current. $suggestion";
    } else {
      P.chat.textEditingController.text = "$current$suggestion";
    }
  }
}

/// Private methods
extension _$See on _See {
  Future<void> _init() async {
    switch (P.app.demoType.q) {
      case .fifthteenPuzzle:
      case .othello:
      case .sudoku:
        return;
      case .chat:
      case .tts:
      case .see:
    }
    qq;
    P.rwkvContext.currentWorldType.lv(_onWorldTypeChanged);
    P.talk.audioInteractorShown.lv(_onAudioInteractorShown);
    P.app.demoType.lv(_onWorldTypeChanged);
    _audioPlayer.eventStream.listen(_onPlayerChanged);
    _audioPlayer.onPlayerStateChanged.listen(_onPlayerStateChanged);
    P.app.pageKey.lb(_onPageKeyChanged);
    P.rwkvGeneration.generating.lb(_onGeneratingChanged);
  }

  void _onGeneratingChanged(bool? previous, bool next) async {
    final pageKey = P.app.pageKey.q;
    if (pageKey != .see) return;
    final fromTrueToFalse = previous == true && next == false;
    if (!fromTrueToFalse) return;

    // 如果, 没有正在等待的消息
    final waitingText = P.see.waitingText.q;
    if (waitingText == null) return;

    final waitingImagePath = P.see.waitingImagePath.q;

    final isPureText = waitingImagePath == null;
    final hasAtLeastOneImage = P.msg.hasAtLeastOneImage.q;

    P.see.waitingText.q = null;
    P.see.waitingImagePath.q = null;

    if (isPureText) {
      await P.chat.send(waitingText);
    } else {
      if (hasAtLeastOneImage) {
        P.msg._clear();
        await 10.msLater;
        P.rwkvGeneration.clearStates();
        await 10.msLater;
      }
      await P.chat.send("", type: MessageType.userImage, imageUrl: waitingImagePath);
      await 50.msLater;
      final finalTextToSend = "<image>$waitingImagePath</image>" + waitingText.trim();
      await P.chat.send(finalTextToSend);
    }
  }

  void _onPageKeyChanged(PageKey? previous, PageKey next) async {
    if (previous == .see && next != .see) {
      imagePath.q = null;
      imageHeight.q = null;
      visualFloatHeight.q = null;
      P.app.demoType.q = .chat;
      P.rwkvGeneration.clearStates();
      P.chat.clearMessages();
      // P.rwkvContext.currentWorldType.q = null;
    } else if (previous != .see && next == .see) {
      P.rwkvModel._releaseModelByWeightTypeIfNeeded(weightType: .chat);
      P.rwkvModel._releaseModelByWeightTypeIfNeeded(weightType: .roleplay);
      P.rwkvModel._releaseModelByWeightTypeIfNeeded(weightType: .tts);
      imagePath.q = null;
      imageHeight.q = null;
      visualFloatHeight.q = null;
      P.rwkvGeneration.clearStates();
      P.chat.clearMessages();
      P.app.demoType.q = .see;
      bool isWorldModelLoaded = false;
      final currentModel = P.rwkvModel.latest.q;
      if (currentModel != null) {
        if (currentModel.worldType != null) {
          isWorldModelLoaded = true;
        }
      }

      if (isWorldModelLoaded) {
        // OK
      } else {
        P.rwkvContext.currentGroupInfo.q = null;
        P.rwkvContext.currentWorldType.q = null;
        await P.rwkvModel._releaseModelByWeightTypeIfNeeded(weightType: .see);
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
    final isWorldDemo = demoType == .see;

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
