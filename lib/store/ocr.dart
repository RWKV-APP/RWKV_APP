part of 'p.dart';

class _Ocr {
  /// 批量任务的定时器
  Timer? _batchTaskTimer;

  late final CameraController _controller;

  CameraController get controller => _controller;

  late final List<CameraDescription> _cameraDescriptions;

  late final controllerCreated = qs(false);

  late final initialized = qs(false);

  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  late final TextRecognizer _textRecognizer;

  TextRecognizer get textRecognizer => _textRecognizer;

  late final paragraphs = qs<Set<BBox>>({});

  late final onScreenTexts = qp<Set<String>>((ref) {
    final paragraphs = ref.watch(this.paragraphs);
    return paragraphs.map((paragraph) => paragraph.text).toSet();
  });

  late final translations = qs<Map<String, String>>({});

  late final lines = qs<Set<BBox>>({});

  late final words = qs<Set<BBox>>({});

  late final imageSize = qs<Size>(Size.zero);

  late final cameraRect = qs<Rect?>(null);

  late final isRecordingVideo = qs(false);
  late final isStreamingImages = qs(false);
  late final isPreviewPaused = qs(false);
  late final previewPauseOrientation = qs<DeviceOrientation?>(null);
  late final isRecordingPaused = qs(false);

  /// 批量任务中每一行的翻译结果
  late final batchTranslations = qs<Map<int, String>>({});

  late final runningTaskKey = qs<String?>(null);
  late final isGenerating = qs(false);

  /// 当前批量任务的原始行列表（用于多行翻译）
  late final batchTaskLines = qs<List<String>>([]);
}

/// Private methods
extension _$Ocr on _Ocr {
  FV _init() async {
    qr;
    controllerCreated.q = false;
    _cameraDescriptions = await availableCameras();
    _controller = CameraController(
      _cameraDescriptions.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? .nv21 // for Android
          : .bgra8888, // for iOS
    );
    _controller.addListener(_onControllerStateChanged);
    controllerCreated.q = true;
    await Future.delayed(1000.ms);
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
        _controller.stopImageStream();
        isStreamingImages.q = false;
        _controller.pausePreview();
        _controller.stopVideoRecording();
        break;
    }
  }

  void _onControllerStateChanged() {
    qr;
    final CameraValue value = _controller.value;
    if (value.isInitialized) {
      initialized.q = true;
    } else {
      initialized.q = false;
    }
    isRecordingVideo.q = value.isRecordingVideo;
    isStreamingImages.q = value.isStreamingImages;
    isPreviewPaused.q = value.isPreviewPaused;
    previewPauseOrientation.q = value.previewPauseOrientation;
    isRecordingPaused.q = value.isRecordingPaused;
  }

  void _onImageStream(CameraImage image) async {
    if (HF.randomBool(truePercentage: .9)) return;
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    final metadata = inputImage.metadata;

    if (metadata != null) {
      var width = metadata.size.width;
      var height = metadata.size.height;
      final rotation = metadata.rotation;
      if (rotation != InputImageRotation.rotation90deg && rotation != InputImageRotation.rotation270deg) {
        final temp = width;
        width = height;
        height = temp;
      }
      if (Platform.isAndroid) {
        if (rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg) {
          final temp = width;
          width = height;
          height = temp;
        }
      }
      imageSize.q = Size(width, height);
    }

    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    final Set<BBox> newWords = {};
    final Set<BBox> newLines = {};
    final Set<BBox> newParagraphs = {};
    for (TextBlock paragraphBlock in recognizedText.blocks) {
      final paragraph = BBox(
        x: paragraphBlock.boundingBox.left.toInt(),
        y: paragraphBlock.boundingBox.top.toInt(),
        width: paragraphBlock.boundingBox.width.toInt(),
        height: paragraphBlock.boundingBox.height.toInt(),
        text: paragraphBlock.text,
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
          text: lineBlock.text,
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
            text: wordBlock.text,
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

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final camera = _controller.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      // Fix: Force rotation90deg if we are in portrait mode but sensor is landscape
      if (rotation == InputImageRotation.rotation0deg &&
          image.width > image.height &&
          controller.value.deviceOrientation == DeviceOrientation.portraitUp) {
        rotation = InputImageRotation.rotation90deg;
      }
    } else if (Platform.isAndroid) {
      var rotationCompensation = _Ocr._orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    final res = InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
    return res;
  }

  void _handleIsGenerating(from_rwkv.IsGenerating res) {
    final pageKey = P.app.pageKey.q;
    if (pageKey == PageKey.see || pageKey == PageKey.talk || pageKey == PageKey.chat) return;
    final generatingStateFromEvent = res.isGenerating;
    final generatingStateInFrontend = isGenerating.q;

    isGenerating.q = generatingStateFromEvent;

    // 状态由生成中变为非生成中, 则认为是结束信号
    final isStopEvent = generatingStateInFrontend && !generatingStateFromEvent;
    if (!isStopEvent) return;

    // 如果是批量任务，处理批量任务的结束
    if (batchTaskLines.q.isNotEmpty) {
      _appendBatchEndString();
    } else {
      // TODO: 处理串行翻译结果
    }
  }

  void _appendBatchEndString() {
    final batchLines = batchTaskLines.q;
    if (batchLines.isEmpty) return;

    // 清理定时器
    if (_batchTaskTimer != null) {
      _batchTaskTimer!.cancel();
      _batchTaskTimer = null;
    }

    for (var i = 0; i < batchLines.length; i++) {
      final translation = batchTranslations.q[i] ?? "";
      // combinedResult.add(translation);
      // TODO: 更新结果数组
    }
    // final finalResult = combinedResult.join("\n");

    // 更新 result
    // result.q = finalResult;

    // 清空批量任务状态
    batchTaskLines.q = [];
    batchTranslations.q = {};
    runningTaskKey.q = null;
  }

  void _handleBatchResponseBufferContent(from_rwkv.ResponseBatchBufferContent res) {
    qq;
    final responseBufferContents = res.responseBufferContent;
    final batchLines = batchTaskLines.q;

    if (batchLines.isEmpty) return;

    final updatedTranslations = <int, String>{};
    for (var i = 0; i < responseBufferContents.length && i < batchLines.length; i++) {
      updatedTranslations[i] = responseBufferContents[i];
    }

    batchTranslations.q = {...batchTranslations.q, ...updatedTranslations};
  }

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    if (P.app.pageKey.q != PageKey.ocr) return;
    qr;

    switch (event) {
      case from_rwkv.ResponseBatchBufferContent res:
        _handleBatchResponseBufferContent(res);
      case from_rwkv.IsGenerating res:
        _handleIsGenerating(res);
      default:
        break;
    }
  }

  void _onStreamDone() async {
    if (P.app.pageKey.q != PageKey.ocr) return;
    qw;
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    if (P.app.pageKey.q != PageKey.ocr) return;
    qe;
  }

  void _startBatchTask(List<String> paragraphs) {
    qq;
    P.rwkv.stop();

    // 清理之前的定时器
    if (_batchTaskTimer != null) {
      _batchTaskTimer!.cancel();
      _batchTaskTimer = null;
    }

    batchTranslations.q = {};
    final batchSize = paragraphs.length;

    // 设置 runningTaskKey 为整个输入文本，用于标识当前任务
    runningTaskKey.q = paragraphs.join("\n");

    // 为每一行创建消息列表
    final batchMessages = <List<String>>[];
    for (var paragraph in paragraphs) {
      batchMessages.add([paragraph.trim()]);
    }

    // 使用批量模式发送：每个批次是一条独立的消息列表
    final thinkingMode = P.rwkv.thinkingMode.q;
    final reasoning = thinkingMode.hasThinkTag;
    P.rwkv.send(
      to_rwkv.ChatBatchAsync(
        batchMessages,
        reasoning: reasoning,
        batchSize: batchSize,
      ),
    );

    // 启动定时器获取响应
    _batchTaskTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      // 获取批量响应（无参数版本会返回所有批次的响应）
      P.rwkv.send(to_rwkv.GetBatchResponseBufferContent());
      P.rwkv.send(to_rwkv.GetIsGenerating());
      P.rwkv.send(to_rwkv.GetPrefillAndDecodeSpeed());
    });
  }

  Future<void> _stop() async {
    P.rwkv.stop();
    _batchTaskTimer?.cancel();
    _batchTaskTimer = null;
    batchTaskLines.q = [];
    batchTranslations.q = {};
    runningTaskKey.q = null;
    isGenerating.q = false;
    isRecordingVideo.q = false;
    isStreamingImages.q = false;
    isPreviewPaused.q = false;
    previewPauseOrientation.q = null;
    isRecordingPaused.q = false;
    _controller.stopImageStream();
    _controller.pausePreview();
    _controller.stopVideoRecording();
  }
}

/// Public methods
extension $Ocr on _Ocr {
  Future<void> onTapStart() async {
    qr;
    // 1. 检测权限
    // 2. 渲染相机
    // 3. 开始识别
    // 4. 显示识别结果
    // 5. 调整识别结果
    final v = _controller.value;
    // if (!checkModelSelection()) return;
    final currentModel = P.rwkv.currentModel.q;
    if (currentModel == null) {
      ModelSelector.show();
      return;
    }

    await _controller.initialize();
    await _controller.startImageStream(_onImageStream);
    if (_controller.value.isPreviewPaused) await _controller.resumePreview();
    _startBatchTask(onScreenTexts.q.toList().sublist(0, 4));
  }

  Future<void> onTapStop() async {
    qr;
    await _stop();
  }
}
