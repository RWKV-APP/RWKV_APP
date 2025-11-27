part of 'p.dart';

class _Ocr {
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

  late final lines = qs<Set<BBox>>({});

  late final words = qs<Set<BBox>>({});

  late final cameraRect = qs<Rect?>(null);
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
          ? ImageFormatGroup
                .nv21 // for Android
          : ImageFormatGroup.bgra8888, // for iOS
    );
    _controller.addListener(_onControllerStateChanged);
    controllerCreated.q = true;
    await Future.delayed(1000.ms);
    await prepareController();
    _controller.startImageStream(_onImageStream);
    _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
  }

  void _onControllerStateChanged() {
    qr;
    final CameraValue value = _controller.value;
    if (value.isInitialized) {
      initialized.q = true;
    } else {
      initialized.q = false;
    }
  }

  void _onImageStream(CameraImage image) async {
    if (HF.randomBool(truePercentage: .9)) return;
    qr;
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    String text = recognizedText.text;
    for (TextBlock block in recognizedText.blocks) {
      final Rect rect = block.boundingBox;
      final List<Point<int>> cornerPoints = block.cornerPoints;
      final String text = block.text;
      final List<String> languages = block.recognizedLanguages;

      for (TextLine line in block.lines) {
        // Same getters as TextBlock
        for (TextElement element in line.elements) {
          // Same getters as TextBlock
          qqr(element.text);
        }
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final camera = _cameraDescriptions[1];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
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
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }
}

/// Public methods
extension $Ocr on _Ocr {
  Future<void> prepareController() async {
    qr;
    await _controller.initialize();
  }
}
