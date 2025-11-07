part of 'p.dart';

class _World {
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
  late final _recorder = ar.AudioRecorder();
  late final _audioPlayer = ap.AudioPlayer();

  /// TODO: Use it!
  late final streaming = qs(false);
  late final audioFileStreamController = StreamController<(File file, int length)>.broadcast();
  final List<Uint8List> _audioData = [];
  Stream<Uint8List>? _currentRecorderStream;
  StreamController<Uint8List>? _currentStreamController;
}

/// Public methods
extension $World on _World {
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
    P.tts.audioStream?.resetStat();
    P.tts.audioStream?.uninit();
  }

  Future<void> stopPlaying() async {
    playing.q = false;
    await _audioPlayer.stop();
    P.tts.audioStream?.resetStat();
    P.tts.audioStream?.uninit();
  }
}

/// Private methods
extension _$World on _World {
  Future<void> _init() async {
    switch (P.app.demoType.q) {
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
        return;
      case DemoType.chat:
      case DemoType.tts:
      case DemoType.world:
    }
    qq;
    P.rwkv.currentWorldType.lv(_onWorldTypeChanged);
    P.tts.audioInteractorShown.lv(_onAudioInteractorShown);
    P.app.demoType.lv(_onWorldTypeChanged);
    _audioPlayer.eventStream.listen(_onPlayerChanged);
    _audioPlayer.onPlayerStateChanged.listen(_onPlayerStateChanged);
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

    if (!P.tts.audioInteractorShown.q) {
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
    final isWorldDemo = demoType == DemoType.world;

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
