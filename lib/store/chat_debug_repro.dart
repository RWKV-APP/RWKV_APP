part of 'p.dart';

const String _fakeBatchInferenceBenchmarkCharacterPool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ     .,!?;:-";
const String _markdownFlickerReproTrigger = "3OHseuuRnX+m+BrJ28/oVYhxXWShsMwHHKSZBkUNzQJZq6P6";
const String _markdownFlickerReproModelName = "Markdown Flicker Repro";
const Duration _markdownFlickerReproInterval = Duration(milliseconds: 70);
const double _markdownFlickerReproDecodeSpeed = 18.0;
const List<int> _fakeBatchInferenceBenchmarkFixedTargetLengths = <int>[500, 1000, 1500];
const String _markdownFlickerReproOutput = """
请把它改写成一个更完整、更适合画图模型理解的英文 Prompt。下面是我建议补充的细节：

- 具体建筑元素：
  - `a charming old church with a steeple` / `an ancient stone church with a tall spire`
  - 教堂矗立在小镇尽头，尖塔直指天空。
  - 教堂周围有修剪整齐的绿色草坪和几棵树。
  - 可以有一座古老的钟楼。
  - `quaint cottages` / `small wooden houses`
  - 许多房子是传统的木屋，外墙覆盖着青苔或爬山虎。
  - 窗户里透出温暖的灯光，表示家庭正在享受晚餐或休息。
  - `colorful flower boxes` / `vibrant window boxes`
  - 很多窗台前都摆放着色彩斑斓的花盆，种植着薰衣草、三叶草等。
  - `rustic fences and gates` / `weathered wooden fences`
  - 栅栏和铁门都显得陈旧而亲切，涂有暗红色或褐色的油漆。
  - `old weathered boats in the harbor` / `vintage fishing boats in the harbor`
  - 码头上停靠着一些老旧的渔船，船身覆盖着厚厚的盐渍和岁月痕迹。
  - `windmill or wind turbine` / `small windmill on the hill`
  - 远处或附近有一座古老的风车，缓缓转动着巨大的叶片。

3. 环境与氛围细节 (Environmental & Atmospheric Details)
- 海洋 (Ocean):
  - `calm turquoise sea` / `peaceful turquoise ocean`
  - 海水呈现出宁静的青绿色，波浪轻柔地拍打着海岸。
  - 海面上漂浮着零星的白色泡沫。
  - `sunset reflecting on water` / `golden reflection of sunset on water`
  - 夕阳的倒影清晰可见，将整个海面染成一片金色。
- 自然元素 (Natural Elements):
  - `seagulls flying gracefully` / `graceful seagulls soaring in the sky`
  - 几只海鸥在空中优雅地盘旋。
  - `blooming flowers along the path` / `wildflowers blooming by the roadside`
  - 路旁盛开着各种野花，增添了生机。
  - `lush green grass fields` / `luxuriant green grassy hillsides`
  - 小镇周围是茂密的绿草地，随风摇曳。
  - `distant silhouette of mountains` / `faraway mountain range silhouette`
  - 在视野尽头，隐约可见一排低矮的、轮廓模糊的群山。

4. 人物与活动细节 (Character & Activity Details)
- 居民 (Residents):
  - `simple wooden benches` / `comfortable wooden benches`
  - 沿着街道和海滩有几张简单的木制长椅。
  - `people sitting and chatting` / `locals sitting and talking on benches`
  - 有几对夫妇或朋友坐在长椅上闲聊，手里拿着咖啡杯或饮料。
  - `children playing nearby` / `kids playing close by`
  - 孩子们在不远处玩耍，他们的笑声融入了整个场景的宁静之中。
  - `cyclist passing by` / `cyclist riding past`
  - 一位骑自行车的人正穿过小镇，消失在画面边缘。
  - `old fisherman repairing nets` / `elderly fisherman fixing fishing nets`
  - 老渔夫坐在码头边修补渔网，旁边放着木桶和绳索。
  - `woman watering flowers` / `villager watering colorful flowers`
  - 一位居民正在给窗台花盆浇水，水珠在夕阳下闪光。
  - `cat sleeping on warm stone steps` / `lazy cat resting on old steps`
  - 一只猫蜷缩在教堂前的石阶上，显得非常安静。
  - `small dog following a child` / `little dog trotting behind a kid`
  - 一只小狗跟在孩子身后，尾巴轻轻摇动。
  - `shopkeeper arranging baskets` / `vendor arranging handmade baskets`
  - 小店老板正在门口整理手工篮子和鲜花。
  - `tourist holding a folded map` / `visitor looking at a paper map`
  - 一个游客拿着折叠地图，站在路牌旁寻找方向。
""";

class _FakeBatchInferenceBenchmarkSlotState {
  final String content;
  final int targetLength;
  final int intervalMultiplier;
  final bool completed;

  const _FakeBatchInferenceBenchmarkSlotState({
    required this.content,
    required this.targetLength,
    required this.intervalMultiplier,
    required this.completed,
  });

  _FakeBatchInferenceBenchmarkSlotState copyWith({
    String? content,
    int? targetLength,
    int? intervalMultiplier,
    bool? completed,
  }) {
    return _FakeBatchInferenceBenchmarkSlotState(
      content: content ?? this.content,
      targetLength: targetLength ?? this.targetLength,
      intervalMultiplier: intervalMultiplier ?? this.intervalMultiplier,
      completed: completed ?? this.completed,
    );
  }
}

extension $ChatDebugRepro on _Chat {
  void _startFakeBatchInferenceBenchmark({
    required int messageId,
    required int batchSize,
  }) {
    _cancelFakeBatchInferenceBenchmark();

    final int effectiveBatchSize = math.max(1, batchSize);
    final int updatesPerSecond = math.max(1, effectiveBatchSize * 20);
    final int intervalInMilliseconds = math.max(1, 1000 ~/ updatesPerSecond);

    _fakeBatchInferenceBenchmarkMessageId = messageId;
    _fakeBatchInferenceBenchmarkFixedTargetsBySlot = _buildFakeBatchInferenceBenchmarkFixedTargets(
      effectiveBatchSize,
    );
    _fakeBatchInferenceBenchmarkSlotStates = List<_FakeBatchInferenceBenchmarkSlotState>.generate(
      effectiveBatchSize,
      _createFakeBatchInferenceBenchmarkSlotState,
    );
    _fakeBatchInferenceBenchmarkSlotIndex = 0;
    _fakeBatchInferenceBenchmarkTick = 0;
    _setReceivedTokens(_buildFakeBatchInferenceBenchmarkContent(), immediateUi: true);

    _fakeBatchInferenceBenchmarkTimer = Timer.periodic(
      Duration(milliseconds: intervalInMilliseconds),
      (Timer timer) {
        final int? activeMessageId = _fakeBatchInferenceBenchmarkMessageId;
        if (activeMessageId != messageId) {
          timer.cancel();
          return;
        }

        final message = P.msg.pool.q[messageId];
        if (message == null || !message.changing || !P.rwkvGeneration.generating.q) {
          _cancelFakeBatchInferenceBenchmark(updateGenerating: true);
          return;
        }

        final int activeBatchSize = _fakeBatchInferenceBenchmarkSlotStates.length;
        if (activeBatchSize <= 0) {
          _cancelFakeBatchInferenceBenchmark(updateGenerating: true);
          return;
        }

        final int slotIndex = _findNextFakeBatchInferenceBenchmarkSlotIndex(activeBatchSize);
        if (slotIndex < 0) {
          _cancelFakeBatchInferenceBenchmark(updateGenerating: true);
          return;
        }

        _advanceFakeBatchInferenceBenchmarkSlot(slotIndex);
        _fakeBatchInferenceBenchmarkTick++;
        _fakeBatchInferenceBenchmarkSlotIndex = (slotIndex + 1) % activeBatchSize;
        _setReceivedTokens(_buildFakeBatchInferenceBenchmarkContent());
      },
    );
  }

  bool _shouldStartMarkdownFlickerRepro(String raw) {
    return raw.trim() == _markdownFlickerReproTrigger;
  }

  void _startMarkdownFlickerRepro({
    required int messageId,
    required int batchSize,
  }) {
    _cancelMarkdownFlickerRepro();
    final effectiveBatchSize = math.max(1, batchSize);
    _markdownFlickerReproMessageId = messageId;
    _markdownFlickerReproCursors = List<int>.filled(effectiveBatchSize, 0);
    P.rwkvGeneration.prefillSpeed.q = 0.0;
    P.rwkvGeneration.decodeSpeed.q = _markdownFlickerReproDecodeSpeed;
    _setReceivedTokens(_buildMarkdownFlickerReproContent(), immediateUi: true);

    _markdownFlickerReproTimer = Timer.periodic(
      _markdownFlickerReproInterval,
      (Timer timer) {
        final int? activeMessageId = _markdownFlickerReproMessageId;
        if (activeMessageId != messageId) {
          timer.cancel();
          return;
        }

        final message = P.msg.pool.q[messageId];
        if (message == null || !message.changing || !P.rwkvGeneration.generating.q) {
          _cancelMarkdownFlickerRepro(updateGenerating: true);
          return;
        }

        if (_markdownFlickerReproCursors.isEmpty) {
          _cancelMarkdownFlickerRepro(updateGenerating: true);
          return;
        }

        if (_markdownFlickerReproCursors.every((int cursor) => cursor >= _markdownFlickerReproOutput.length)) {
          _finishMarkdownFlickerRepro(messageId: messageId);
          return;
        }

        _markdownFlickerReproCursors = _markdownFlickerReproCursors
            .map((int cursor) => _nextMarkdownFlickerReproCursor(cursor))
            .toList(growable: false);
        _setReceivedTokens(_buildMarkdownFlickerReproContent());
      },
    );
  }

  int _nextMarkdownFlickerReproCursor(int cursor) {
    if (cursor >= _markdownFlickerReproOutput.length) return cursor;
    return math.min(
      _markdownFlickerReproOutput.length,
      cursor + _nextMarkdownFlickerReproChunkSize(cursor),
    );
  }

  String _buildMarkdownFlickerReproContent() {
    if (_markdownFlickerReproCursors.isEmpty) return "";

    final slotOutputs = <String>[];
    for (final int cursor in _markdownFlickerReproCursors) {
      final safeCursor = cursor.clamp(0, _markdownFlickerReproOutput.length);
      slotOutputs.add(_markdownFlickerReproOutput.substring(0, safeCursor));
    }

    if (slotOutputs.length == 1) return slotOutputs.first;
    return buildBatchContent(slotOutputs);
  }

  int _nextMarkdownFlickerReproChunkSize(int cursor) {
    if (cursor < 0) return 1;
    if (cursor >= _markdownFlickerReproOutput.length) return 1;

    final current = _markdownFlickerReproOutput.codeUnitAt(cursor);
    if (current == 0x0A) return 1;
    if (current == 0x20 && _isMarkdownFlickerReproListIndent(cursor)) return 1;
    if (_isMarkdownFlickerReproListMarker(current)) return 1;
    if (cursor > 0 && _isMarkdownFlickerReproListMarker(_markdownFlickerReproOutput.codeUnitAt(cursor - 1))) return 1;
    if (cursor > 1 && _isMarkdownFlickerReproListMarker(_markdownFlickerReproOutput.codeUnitAt(cursor - 2))) return 3;
    return 9;
  }

  bool _isMarkdownFlickerReproListIndent(int cursor) {
    final previousIndex = cursor <= 0 ? 0 : cursor - 1;
    final lineStart = _markdownFlickerReproOutput.lastIndexOf("\n", previousIndex) + 1;
    final prefix = _markdownFlickerReproOutput.substring(lineStart, cursor);
    if (prefix.trim().isNotEmpty) return false;

    int index = cursor;
    while (index < _markdownFlickerReproOutput.length && _markdownFlickerReproOutput.codeUnitAt(index) == 0x20) {
      index++;
    }
    if (index >= _markdownFlickerReproOutput.length) return false;
    return _isMarkdownFlickerReproListMarker(_markdownFlickerReproOutput.codeUnitAt(index));
  }

  bool _isMarkdownFlickerReproListMarker(int codeUnit) {
    if (codeUnit == 0x2A) return true;
    if (codeUnit == 0x2D) return true;
    return codeUnit == 0x2B;
  }

  void _finishMarkdownFlickerRepro({required int messageId}) {
    final bufferedContent = _buildMarkdownFlickerReproContent();
    final finalContent = receivedTokens.q.isNotEmpty
        ? receivedTokens.q
        : bufferedContent.isNotEmpty
        ? bufferedContent
        : _markdownFlickerReproOutput;
    _cancelMarkdownFlickerRepro(updateGenerating: true);
    _updateMessageById(
      id: messageId,
      content: finalContent,
      changing: false,
      prefillSpeed: 0.0,
      decodeSpeed: _markdownFlickerReproDecodeSpeed,
      callingFunction: "_finishMarkdownFlickerRepro",
    );
    _setReceivedTokens("", immediateUi: true);
    if (receiveId.q == messageId) {
      receiveId.q = null;
    }
  }

  Future<bool> _pauseMarkdownFlickerReproMessage({
    required int id,
    required Message msg,
    required bool isSensitive,
  }) async {
    if (_markdownFlickerReproMessageId != id) {
      return false;
    }

    final currentGeneratedContent = receivedTokens.q;
    final finalizedContent = currentGeneratedContent.isNotEmpty ? currentGeneratedContent : msg.content;
    _cancelMarkdownFlickerRepro(updateGenerating: true);

    final newMsg = msg.copyWith(
      content: finalizedContent,
      paused: true,
      changing: false,
      isSensitive: isSensitive,
      prefillSpeed: 0.0,
      decodeSpeed: _markdownFlickerReproDecodeSpeed,
    );
    await P.msg._syncMsg(id, newMsg);
    _setReceivedTokens("", immediateUi: true);
    if (receiveId.q == id) {
      receiveId.q = null;
    }
    return true;
  }

  void _cancelMarkdownFlickerRepro({bool updateGenerating = false}) {
    final timer = _markdownFlickerReproTimer;
    final active = timer != null || _markdownFlickerReproMessageId != null;
    timer?.cancel();
    _markdownFlickerReproTimer = null;
    _markdownFlickerReproMessageId = null;
    _markdownFlickerReproCursors = const <int>[];
    if (active && updateGenerating) {
      P.rwkvGeneration.generating.q = false;
    }
  }

  String _buildFakeBatchInferenceBenchmarkContent() {
    if (_fakeBatchInferenceBenchmarkSlotStates.isEmpty) {
      return "";
    }
    final List<String> slotOutputs = _fakeBatchInferenceBenchmarkSlotStates.map((e) => e.content).toList();
    if (slotOutputs.length == 1) {
      return slotOutputs.first;
    }
    return buildBatchContent(slotOutputs);
  }

  String _nextFakeBatchInferenceBenchmarkChunk() {
    final int length = 3 + _fakeBatchInferenceBenchmarkRandom.nextInt(3);
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final int index = _fakeBatchInferenceBenchmarkRandom.nextInt(_fakeBatchInferenceBenchmarkCharacterPool.length);
      buffer.write(_fakeBatchInferenceBenchmarkCharacterPool[index]);
    }
    return buffer.toString();
  }

  _FakeBatchInferenceBenchmarkSlotState _createFakeBatchInferenceBenchmarkSlotState(int index) {
    final int targetLength = _fakeBatchInferenceBenchmarkFixedTargetsBySlot[index] ?? 1 << 30;
    final int intervalMultiplier = 1 + _fakeBatchInferenceBenchmarkRandom.nextInt(4);
    return _FakeBatchInferenceBenchmarkSlotState(
      content: "",
      targetLength: targetLength,
      intervalMultiplier: intervalMultiplier,
      completed: false,
    );
  }

  Map<int, int> _buildFakeBatchInferenceBenchmarkFixedTargets(int batchSize) {
    if (batchSize <= 0) {
      return const <int, int>{};
    }

    final List<int> slotIndexes = List<int>.generate(batchSize, (index) => index);
    slotIndexes.shuffle(_fakeBatchInferenceBenchmarkRandom);

    final Map<int, int> result = <int, int>{};
    final int fixedCount = math.min(batchSize, _fakeBatchInferenceBenchmarkFixedTargetLengths.length);
    for (int i = 0; i < fixedCount; i++) {
      result[slotIndexes[i]] = _fakeBatchInferenceBenchmarkFixedTargetLengths[i];
    }
    return result;
  }

  int _findNextFakeBatchInferenceBenchmarkSlotIndex(int activeBatchSize) {
    for (int offset = 0; offset < activeBatchSize; offset++) {
      final int candidate = (_fakeBatchInferenceBenchmarkSlotIndex + offset) % activeBatchSize;
      final slotState = _fakeBatchInferenceBenchmarkSlotStates[candidate];
      if (slotState.completed) {
        continue;
      }
      if (_fakeBatchInferenceBenchmarkTick % slotState.intervalMultiplier != 0) {
        continue;
      }
      return candidate;
    }

    for (int offset = 0; offset < activeBatchSize; offset++) {
      final int candidate = (_fakeBatchInferenceBenchmarkSlotIndex + offset) % activeBatchSize;
      final slotState = _fakeBatchInferenceBenchmarkSlotStates[candidate];
      if (!slotState.completed) {
        return candidate;
      }
    }
    return -1;
  }

  void _advanceFakeBatchInferenceBenchmarkSlot(int slotIndex) {
    final slotState = _fakeBatchInferenceBenchmarkSlotStates[slotIndex];
    if (slotState.completed) {
      return;
    }

    final String nextChunk = _nextFakeBatchInferenceBenchmarkChunk();
    final int remaining = slotState.targetLength - slotState.content.length;
    if (remaining <= 0) {
      _fakeBatchInferenceBenchmarkSlotStates[slotIndex] = slotState.copyWith(completed: true);
      return;
    }

    final String appended = nextChunk.length <= remaining ? nextChunk : nextChunk.substring(0, remaining);
    final String newContent = slotState.content + appended;
    final bool completed = newContent.length >= slotState.targetLength;
    _fakeBatchInferenceBenchmarkSlotStates[slotIndex] = slotState.copyWith(
      content: newContent,
      completed: completed,
    );
  }

  Future<bool> _pauseFakeBatchInferenceBenchmarkMessage({
    required int id,
    required Message msg,
    required bool isSensitive,
  }) async {
    if (_fakeBatchInferenceBenchmarkMessageId != id) {
      return false;
    }

    final currentGeneratedContent = receivedTokens.q;
    final finalizedContent = currentGeneratedContent.isNotEmpty ? currentGeneratedContent : msg.content;
    _cancelFakeBatchInferenceBenchmark(updateGenerating: true);

    final newMsg = msg.copyWith(
      content: finalizedContent,
      paused: true,
      changing: false,
      isSensitive: isSensitive,
    );
    await P.msg._syncMsg(id, newMsg);
    return true;
  }

  void _cancelFakeBatchInferenceBenchmark({bool updateGenerating = false}) {
    final timer = _fakeBatchInferenceBenchmarkTimer;
    final active = timer != null || _fakeBatchInferenceBenchmarkMessageId != null;
    timer?.cancel();
    _fakeBatchInferenceBenchmarkTimer = null;
    _fakeBatchInferenceBenchmarkMessageId = null;
    _fakeBatchInferenceBenchmarkSlotStates = const <_FakeBatchInferenceBenchmarkSlotState>[];
    _fakeBatchInferenceBenchmarkSlotIndex = 0;
    _fakeBatchInferenceBenchmarkTick = 0;
    _fakeBatchInferenceBenchmarkFixedTargetsBySlot = const <int, int>{};
    if (active && updateGenerating) {
      P.rwkvGeneration.generating.q = false;
    }
  }
}
