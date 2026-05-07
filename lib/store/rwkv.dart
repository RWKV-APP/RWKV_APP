part of 'p.dart';

class _RWKVBridge {
  @Deprecated("Use _broadcastStream instead")
  static Stream<LLMEvent>? _oldBroadcastStream;

  static Stream<from_rwkv.FromRWKV>? _broadcastStream;

  /// We use it to send message to rwkv_mobile_flutter isolate
  ///
  /// This sendPort is created rwkv_mobile_flutter isolate
  SendPort? _sendPort;

  SendPort? get sendPort => _sendPort;

  /// Receive message from RWKV isolate
  late final _receivePort = ReceivePort();

  ReceivePort get receivePort => _receivePort;

  @Deprecated("Use _streamController instead")
  late final _oldMessagesController = StreamController<LLMEvent>();

  late final _messagesController = StreamController<from_rwkv.FromRWKV>();

  /// 我们等着这个的主要目的是等着 rwkv_mobile_flutter isolate 把 sendPort 发过来, 我们好用 sendport 来让 rwkv_mobile_flutter isolate 加载模型, 并执行后继操作
  Completer<void>? _createRWKVIsolateCompleter;

  @Deprecated("Use broadcastStream instead")
  Stream<LLMEvent> get oldBroadcastStream {
    _oldBroadcastStream ??= _oldMessagesController.stream.asBroadcastStream();
    return _oldBroadcastStream!;
  }

  Stream<from_rwkv.FromRWKV> get broadcastStream {
    _broadcastStream ??= _messagesController.stream.asBroadcastStream();
    return _broadcastStream!;
  }

  void emitFromRWKV(from_rwkv.FromRWKV event) {
    _messagesController.add(event);
  }

  void emitOldEvent(LLMEvent event) {
    _oldMessagesController.add(event);
  }

  void send(to_rwkv.ToRWKV toRwkv) {
    final sendPort = _sendPort;
    if (sendPort == null) {
      qqw("sendPort is null");
      return;
    }
    sendPort.send(toRwkv);
  }
}

extension _$RWKVBridge on _RWKVBridge {
  Future<void> _init() async {
    P.app.pageKey.lv(_onPageKeyChanged);
    _receivePort.listen(_onMessage);
    await P.rwkvBackend._init();
    P.rwkvModel.latest.lb(P.rwkvModel._onCurrentModelChanged);
    Albatross.instance.init();
    P.rwkvGeneration.generating.l(P.rwkvGeneration._onGeneratingChanged);
  }

  Future<void> _createRWKVIsolateIfNeeded() async {
    if (P.rwkvBackend.backendStatus.q != .none) {
      final msg = "Backend is not in none status, so isolate should be created before, current status: ${P.rwkvBackend.backendStatus.q}";
      qqw(msg);
      return;
    }

    P.rwkvBackend.backendStatus.q = .creatingIsolate;
    _createRWKVIsolateCompleter = Completer<void>();
    final options = StartOptions(
      sendPort: _receivePort.sendPort,
      rootIsolateToken: RootIsolateToken.instance!,
    );
    await RWKVMobile().runIsolate(options);
    await _createRWKVIsolateCompleter!.future;
    P.rwkvBackend.backendStatus.q = .ready;
  }

  Future<void> _onPageKeyChanged() async {
    final pageKey = P.app.pageKey.q;
    switch (pageKey) {
      case .othello:
        await P.rwkvModel.loadOthello();
        break;
      case .chat:
        qq;
        final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .chat);
        if (modelID != null) P.rwkvBridge.send(to_rwkv.GetSupportedBatchSizes(modelID: modelID));
        break;
      default:
        break;
    }
  }

  void _onMessage(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
      _createRWKVIsolateCompleter?.complete();
      _createRWKVIsolateCompleter = null;
      return;
    }

    if (RoleplayManage.isRolePlayMessage) {
      RoleplayManage.operationMessage(message);
    }

    if (message is from_rwkv.FromRWKV) {
      _handleFromRWKV(message);
      return;
    }

    if (message["responseBufferIds"] != null) {
      final responseBufferIdsList = message["responseBufferIds"];
      emitOldEvent(
        LLMEvent(
          responseBufferIds: (responseBufferIdsList as List).map((e) => e as int).toList(),
          type: _RWKVMessageType.responseBufferIds,
        ),
      );
      return;
    }

    if (message["isGenerating"] != null) {
      final isGenerating = message["isGenerating"];
      emitOldEvent(
        LLMEvent(
          content: isGenerating.toString(),
          type: _RWKVMessageType.isGenerating,
        ),
      );
      if (!isGenerating) {
        P.rwkvGeneration._cancelTokensTimer();
      }
      return;
    }

    if (message["sudokuOthelloResponse"] != null) {
      final responseText = message["sudokuOthelloResponse"].toString();
      emitOldEvent(
        LLMEvent(
          content: responseText,
          type: _RWKVMessageType.sudokuOthelloResponse,
        ),
      );
      return;
    }

    if (message["streamResponse"] != null) {
      final responseText = message["streamResponse"].toString();
      emitOldEvent(
        LLMEvent(
          content: responseText,
          token: message["streamResponseToken"],
          type: _RWKVMessageType.streamResponse,
        ),
      );
      if (message["prefillSpeed"] != null && message["prefillSpeed"] != -1.0) {
        P.rwkvGeneration.prefillSpeed.q = message["prefillSpeed"];
      }
      if (message["decodeSpeed"] != null && message["decodeSpeed"] != -1.0) {
        P.rwkvGeneration.decodeSpeed.q = message["decodeSpeed"];
        P.telemetry.trackDecodeSpeed(message["decodeSpeed"] as double);
      }
      return;
    }

    qqe("unknown message: $message");
    if (!kDebugMode) Sentry.captureException(Exception("unknown message: $message"), stackTrace: StackTrace.current);
  }

  void _handleFromRWKV(from_rwkv.FromRWKV message) {
    emitFromRWKV(message);
    switch (message) {
      case from_rwkv.LoadModelSteps res:
        P.rwkvModel._handleLoadModelSteps(res);

      case from_rwkv.SamplerAndPenaltyParams res:
        final temperatures = res.temperatures;
        final topPs = res.topPs;
        final presencePenalties = res.presencePenalties;
        final frequencyPenalties = res.frequencyPenalties;
        final penaltyDecays = res.penaltyDecays;
        final backendValues = <SamplerAndPenaltyParam>[];
        for (int i = 0; i < temperatures.length; i++) {
          backendValues.add(
            SamplerAndPenaltyParam(
              temperature: temperatures[i].toDouble(),
              topP: topPs[i].toDouble(),
              presencePenalty: presencePenalties[i].toDouble(),
              frequencyPenalty: frequencyPenalties[i].toDouble(),
              penaltyDecay: penaltyDecays[i].toDouble(),
            ),
          );
        }
        P.rwkvParams.backendBatchParams.q = backendValues;

      case from_rwkv.EvaluationResults res:
        P.lambada._onResultsReceived(res);

      case from_rwkv.IsGenerating res:
        P.rwkvGeneration.generating.q = res.isGenerating;

      case from_rwkv.StateInfo response:
        final stateInfo = response.stateInfo.trim();
        if (stateInfo.isEmpty) return;
        final stateLogList = stateInfo.split("text =").where((e) => e.isNotEmpty).map((e) {
          final raw = e.split(", remaining lifespan = ");
          final text = raw[0];
          final lifeSpan = int.tryParse(raw[1]) ?? 0;
          return StateLog(text: text, lifeSpan: lifeSpan);
        }).toList();
        P.rwkvDebug.stateLogList.q = stateLogList;

      case from_rwkv.Error response:
        if (kDebugMode) {
          String errorLog = "error: ${response.message}";
          if (message.to != null) errorLog += " in ${message.to.runtimeType}";
          if (message.to?.requestId != null) errorLog += " requestId: ${message.to?.requestId}";
          qqe(errorLog);
        }
        qqe;
        Alert.error(response.message);

      case from_rwkv.Speed response:
        P.rwkvGeneration.prefillSpeed.q = response.prefillSpeed;
        P.rwkvGeneration.decodeSpeed.q = response.decodeSpeed;
        P.telemetry.trackDecodeSpeed(response.decodeSpeed);
        P.rwkvGeneration.prefillProgress.q = response.prefillProgress.clamp(0, 1).toDouble();

      case from_rwkv.StreamResponse response:
        final decodeSpeed = response.decodeSpeed;
        final prefillSpeed = response.prefillSpeed;
        if (decodeSpeed != -1.0) {
          P.rwkvGeneration.decodeSpeed.q = decodeSpeed;
          P.telemetry.trackDecodeSpeed(decodeSpeed);
        }
        if (prefillSpeed != -1.0) P.rwkvGeneration.prefillSpeed.q = prefillSpeed;

      case from_rwkv.SupportedBatchSizes response:
        P.rwkvParams.supportedBatchSizes.q = response.supportedBatchSizes;

      case from_rwkv.RuntimeLog response:
        P.rwkvDebug.runtimeLog.q = P.rwkvDebug._parseRuntimeLog(response.runtimeLog);

      default:
        break;
    }
  }
}

@Deprecated("Use FromRWKV instead")
enum _RWKVMessageType {
  /// 模型吐完 token 了会被调用, 调用内容该次 generate 吐出的总文本
  @Deprecated("Use FromRWKV instead")
  sudokuOthelloResponse,

  /// 模型每吐一个token，调用一次, 调用内容为该次 generate 已经吐出的文本
  @Deprecated("Use FromRWKV instead")
  streamResponse,

  /// 模型是否正在生成
  @Deprecated("Use FromRWKV instead")
  isGenerating,
  @Deprecated("Use FromRWKV instead")
  responseBufferIds,
}

@Deprecated("Use FromRWKV instead")
@immutable
final class LLMEvent {
  final _RWKVMessageType type;
  final String content;
  final List<int>? responseBufferIds;
  final int? token;

  const LLMEvent({
    required this.type,
    this.content = "",
    this.responseBufferIds,
    this.token,
  });

  @override
  String toString() {
    return "LLMEvent.type: $type";
  }
}
