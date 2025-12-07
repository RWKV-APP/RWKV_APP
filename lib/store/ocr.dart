part of 'p.dart';

class _Ocr {
  /// 批量任务的定时器
  Timer? _getResponseTimer;

  late final TextRecognizer _textRecognizer;

  TextRecognizer get textRecognizer => _textRecognizer;

  late final paragraphs = qs<Set<BBox>>({});

  late final onScreenTexts = qp<Set<String>>((ref) {
    final paragraphs = ref.watch(this.paragraphs);
    return paragraphs.map((paragraph) => paragraph.text).toSet();
  });

  late final lines = qs<Set<BBox>>({});

  late final words = qs<Set<BBox>>({});

  late final imageSize = qs<Size>(Size.zero);

  late final image = qs<XFile?>(null);

  /// 批量任务中每一行的翻译结果
  ///
  /// 翻译任务的内存缓存
  ///
  /// 注意, 会同时存储已完成和未完成的 key-value 映射
  late final translations = qs<Map<String, String>>({});

  late final runningTaskKey = qs<String?>(null);
  late final isGenerating = qs(false);

  /// 当前批量任务的原始行列表（用于多行翻译）
  late final runningTasks = qs<List<String>>([]);

  /// 是否是英译中 (true: EN->ZH, false: ZH->EN)
  late final enToZh = qs(true);

  /// 是否显示翻译结果
  late final showTranslation = qs(true);
}

/// Private methods
extension _$Ocr on _Ocr {
  FV _init() async {
    _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    P.rwkv.broadcastStream.listen(
      _onStreamEvent,
      onDone: _onStreamDone,
      onError: _onStreamError,
    );
    P.app.pageKey.l(_onPageKeyChanged);
  }

  void _onPageKeyChanged(PageKey pageKey) {
    switch (pageKey) {
      case PageKey.ocr:
      case PageKey.translator:
        break;
      default:
        _stop();
        break;
    }
  }

  Future<void> _processImage(InputImage inputImage) async {
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    final Set<BBox> newWords = {};
    final Set<BBox> newLines = {};
    final Set<BBox> newParagraphs = {};
    for (TextBlock paragraphBlock in recognizedText.blocks) {
      final paragraphText = paragraphBlock.text.trimCustom();
      if (_isNumeric(paragraphText)) continue;

      final paragraph = BBox(
        x: paragraphBlock.boundingBox.left.toInt(),
        y: paragraphBlock.boundingBox.top.toInt(),
        width: paragraphBlock.boundingBox.width.toInt(),
        height: paragraphBlock.boundingBox.height.toInt(),
        text: paragraphText,
        r: 0,
        p: 1,
      );
      newParagraphs.add(paragraph);
      for (TextLine lineBlock in paragraphBlock.lines) {
        final line = BBox(
          x: lineBlock.boundingBox.left.toInt(),
          y: lineBlock.boundingBox.top.toInt(),
          width: lineBlock.boundingBox.width.toInt(),
          height: lineBlock.boundingBox.height.toInt(),
          text: lineBlock.text.trimCustom(),
          r: 0,
          p: 1,
        );
        newLines.add(line);

        for (TextElement wordBlock in lineBlock.elements) {
          final word = BBox(
            x: wordBlock.boundingBox.left.toInt(),
            y: wordBlock.boundingBox.top.toInt(),
            width: wordBlock.boundingBox.width.toInt(),
            height: wordBlock.boundingBox.height.toInt(),
            text: wordBlock.text.trimCustom(),
            r: 0,
            p: 1,
          );
          newWords.add(word);
        }
      }
    }
    words.q = newWords;
    lines.q = newLines;
    paragraphs.q = newParagraphs;
  }

  void _handleIsGenerating(from_rwkv.IsGenerating res) {
    final pageKey = P.app.pageKey.q;
    if (pageKey != PageKey.ocr) return;
    final generatingStateFromEvent = res.isGenerating;
    final generatingStateInFrontend = isGenerating.q;

    isGenerating.q = generatingStateFromEvent;

    // 状态由生成中变为非生成中, 则认为是结束信号
    final isStopEvent = generatingStateInFrontend && !generatingStateFromEvent;
    if (!isStopEvent) return;

    if (!generatingStateFromEvent) {
      _getResponseTimer?.cancel();
      _getResponseTimer = null;
    }

    // 尝试发送下一批任务
    if (runningTasks.q.isNotEmpty) {
      // 当前批次结束，清空运行中任务
      runningTasks.q = [];
      // 触发下一次检查
      _sendRequest();
    }
  }

  void _handleBatchResponseBufferContent(from_rwkv.ResponseBatchBufferContent res) {
    final responseBufferContents = res.responseBufferContent;

    final batchLines = runningTasks.q;

    if (batchLines.isEmpty) {
      qqw("没有正在运行的任务, 就不应该受到 batch 响应");
      return;
    }

    if (responseBufferContents.length != batchLines.length) {
      qqw("返回的翻译结果的数量应该和发起请求时的 batch count 相等");
      return;
    }

    final updatedTranslations = <int, String>{};
    for (var i = 0; i < responseBufferContents.length && i < batchLines.length; i++) {
      updatedTranslations[i] = responseBufferContents[i];
    }

    final Map<String, String> newTranslations = {};
    for (var i = 0; i < batchLines.length; i++) {
      final line = batchLines[i];
      final translation = updatedTranslations[i];
      if (translation != null) {
        newTranslations[line] = translation;
      }
    }

    translations.q = {...translations.q, ...newTranslations};
  }

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    if (P.app.pageKey.q != PageKey.ocr) return;

    switch (event) {
      case from_rwkv.ResponseBatchBufferContent res:
        _handleBatchResponseBufferContent(res);
      case from_rwkv.ResponseBufferContent res:
        _handleResponseBufferContent(res);
      case from_rwkv.IsGenerating res:
        _handleIsGenerating(res);
      default:
        break;
    }
  }

  void _handleResponseBufferContent(from_rwkv.ResponseBufferContent res) {}

  void _onStreamDone() async {
    if (P.app.pageKey.q != PageKey.ocr) return;
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    if (P.app.pageKey.q != PageKey.ocr) return;
  }

  void _sendTasks(List<String> tasks) {
    P.rwkv.stop();

    if (tasks.isEmpty) return;

    final batchSize = tasks.length;

    // 设置 runningTaskKey 为整个输入文本，用于标识当前任务
    runningTaskKey.q = tasks.join("\n");

    // 为每一行创建消息列表
    final batchMessages = <List<String>>[];
    for (var task in tasks) {
      batchMessages.add([task.trimCustom()]);
    }

    // Set roles based on enToZh
    if (enToZh.q) {
      P.rwkv.send(to_rwkv.SetUserRole("English"));
      P.rwkv.send(to_rwkv.SetResponseRole("Chinese"));
    } else {
      P.rwkv.send(to_rwkv.SetUserRole("Chinese"));
      P.rwkv.send(to_rwkv.SetResponseRole("English"));
    }

    // 使用批量模式发送：每个批次是一条独立的消息列表
    final thinkingMode = P.rwkv.thinkingMode.q;
    final reasoning = thinkingMode.hasThinkTag;
    isGenerating.q = true;
    P.rwkv.send(
      to_rwkv.ChatBatchAsync(
        batchMessages,
        reasoning: reasoning,
        batchSize: batchSize,
      ),
    );

    // 启动定时器获取响应
    _getResponseTimer?.cancel();
    _getResponseTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      _getResponse();
    });
  }

  Future<void> _stop() async {
    P.rwkv.stop();
    _getResponseTimer?.cancel();
    _getResponseTimer = null;
    runningTasks.q = [];
    runningTaskKey.q = null;
    isGenerating.q = false;
    image.q = null;
  }

  void _sendRequest() {
    // 生成中则跳过
    final isGenerating = this.isGenerating.q;
    if (isGenerating) return;

    final onScreenTexts = this.onScreenTexts.q.toList();
    final batchTranslations = translations.q;
    int supportedBatchSize = 1;
    if (P.rwkv.supportedBatchSizes.q.isNotEmpty) {
      supportedBatchSize = P.rwkv.supportedBatchSizes.q.max;
    }

    final runningTasks = this.runningTasks.q;
    if (runningTasks.isNotEmpty) {
      qqe("请求 backend 处理新的 batch 时, 不应该有正在运行的任务");
      this.runningTasks.q = [];
    }

    final List<String> newTasks = [];
    for (var i = 0; i < onScreenTexts.length; i++) {
      final text = onScreenTexts[i];
      final hasDone = batchTranslations.containsKey(text);
      if (!hasDone) newTasks.add(text);
      if (newTasks.length == supportedBatchSize) break;
    }

    if (newTasks.isEmpty) return;

    this.isGenerating.q = true;
    this.runningTasks.q = newTasks;
    _sendTasks(newTasks);
  }

  void _getResponse() {
    P.rwkv.send(to_rwkv.GetBatchResponseBufferContent());
    P.rwkv.send(to_rwkv.GetIsGenerating());
    P.rwkv.send(to_rwkv.GetPrefillAndDecodeSpeed());
  }
}

/// Public methods
extension $Ocr on _Ocr {
  Future<void> takePhoto() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> pickFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    final currentModel = P.rwkv.currentModel.q;
    if (currentModel == null) {
      ModelSelector.show();
      return;
    }

    final picker = ImagePicker();
    final photo = await picker.pickImage(source: source);
    if (photo == null) return;

    image.q = photo;
    translations.q = {};
    runningTasks.q = [];

    // Get image size
    final data = await photo.readAsBytes();
    final decoded = await decodeImageFromList(data);
    imageSize.q = Size(decoded.width.toDouble(), decoded.height.toDouble());

    final inputImage = InputImage.fromFilePath(photo.path);
    await _processImage(inputImage);

    _sendRequest();
  }

  void toggleLanguage() {
    enToZh.q = !enToZh.q;
    // 重置翻译并重新开始
    if (image.q != null) {
      translations.q = {};
      runningTasks.q = [];
      P.rwkv.stop();
      isGenerating.q = false;
      _sendRequest();
    }
  }

  void toggleShowTranslation() {
    showTranslation.q = !showTranslation.q;
  }

  void clearImage() {
    image.q = null;
    translations.q = {};
    runningTasks.q = [];
    P.rwkv.stop();
    isGenerating.q = false;
  }
}

extension _StringTrimCustom on String {
  String trimCustom() {
    return replaceAll(
      RegExp(
        r'^[\s\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E\u2000-\u206F\u3000-\u303F\uFF01-\uFF0F\uFF1A-\uFF20\uFF3B-\uFF40\uFF5B-\uFF65]+|[\s\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E\u2000-\u206F\u3000-\u303F\uFF01-\uFF0F\uFF1A-\uFF20\uFF3B-\uFF40\uFF5B-\uFF65]+$',
      ),
      '',
    );
  }
}

bool _isNumeric(String s) {
  if (s.isEmpty) return false;
  return RegExp(r'^[0-9]+$').hasMatch(s);
}
