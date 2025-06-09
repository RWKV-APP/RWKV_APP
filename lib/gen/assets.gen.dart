/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $AssetsConfigGen {
  const $AssetsConfigGen();

  /// Directory path: assets/config/chat
  $AssetsConfigChatGen get chat => const $AssetsConfigChatGen();

  /// Directory path: assets/config/othello
  $AssetsConfigOthelloGen get othello => const $AssetsConfigOthelloGen();
}

class $AssetsImgGen {
  const $AssetsImgGen();

  /// Directory path: assets/img/chat
  $AssetsImgChatGen get chat => const $AssetsImgChatGen();

  /// Directory path: assets/img/othello
  $AssetsImgOthelloGen get othello => const $AssetsImgOthelloGen();
}

class $AssetsModelGen {
  const $AssetsModelGen();

  /// Directory path: assets/model/chat
  $AssetsModelChatGen get chat => const $AssetsModelChatGen();

  /// Directory path: assets/model/othello
  $AssetsModelOthelloGen get othello => const $AssetsModelOthelloGen();
}

class $AssetsConfigChatGen {
  const $AssetsConfigChatGen();

  /// File path: assets/config/chat/b_rwkv_vocab_v20230424.txt
  String get bRwkvVocabV20230424 =>
      'assets/config/chat/b_rwkv_vocab_v20230424.txt';

  /// File path: assets/config/chat/prompts.en-US.json
  String get promptsEnUS => 'assets/config/chat/prompts.en-US.json';

  /// File path: assets/config/chat/prompts.zh-hans.json
  String get promptsZhHans => 'assets/config/chat/prompts.zh-hans.json';

  /// File path: assets/config/chat/weights.json
  String get weights => 'assets/config/chat/weights.json';

  /// List of all assets
  List<String> get values =>
      [bRwkvVocabV20230424, promptsEnUS, promptsZhHans, weights];
}

class $AssetsConfigOthelloGen {
  const $AssetsConfigOthelloGen();

  /// File path: assets/config/othello/b_othello_vocab.txt
  String get bOthelloVocab => 'assets/config/othello/b_othello_vocab.txt';

  /// List of all assets
  List<String> get values => [bOthelloVocab];
}

class $AssetsImgChatGen {
  const $AssetsImgChatGen();

  /// File path: assets/img/chat/logo.png
  AssetGenImage get logo => const AssetGenImage('assets/img/chat/logo.png');

  /// File path: assets/img/chat/logo.square.png
  AssetGenImage get logoSquare =>
      const AssetGenImage('assets/img/chat/logo.square.png');

  /// List of all assets
  List<AssetGenImage> get values => [logo, logoSquare];
}

class $AssetsImgOthelloGen {
  const $AssetsImgOthelloGen();

  /// File path: assets/img/othello/logo.png
  AssetGenImage get logo => const AssetGenImage('assets/img/othello/logo.png');

  /// File path: assets/img/othello/logo.square.png
  AssetGenImage get logoSquare =>
      const AssetGenImage('assets/img/othello/logo.square.png');

  /// List of all assets
  List<AssetGenImage> get values => [logo, logoSquare];
}

class $AssetsModelChatGen {
  const $AssetsModelChatGen();

  /// File path: assets/model/chat/q
  String get q => 'assets/model/chat/q';

  /// List of all assets
  List<String> get values => [q];
}

class $AssetsModelOthelloGen {
  const $AssetsModelOthelloGen();

  /// File path: assets/model/othello/rwkv7_othello_26m_L10_D448_extended-ncnn.bin
  String get rwkv7Othello26mL10D448ExtendedNcnnBin =>
      'assets/model/othello/rwkv7_othello_26m_L10_D448_extended-ncnn.bin';

  /// File path: assets/model/othello/rwkv7_othello_26m_L10_D448_extended-ncnn.param
  String get rwkv7Othello26mL10D448ExtendedNcnnParam =>
      'assets/model/othello/rwkv7_othello_26m_L10_D448_extended-ncnn.param';

  /// File path: assets/model/othello/rwkv7_othello_26m_L10_D448_extended.st
  String get rwkv7Othello26mL10D448Extended =>
      'assets/model/othello/rwkv7_othello_26m_L10_D448_extended.st';

  /// File path: assets/model/othello/rwkv7_othello_9m_L10_D256_extended-ncnn.bin
  String get rwkv7Othello9mL10D256ExtendedNcnnBin =>
      'assets/model/othello/rwkv7_othello_9m_L10_D256_extended-ncnn.bin';

  /// File path: assets/model/othello/rwkv7_othello_9m_L10_D256_extended-ncnn.param
  String get rwkv7Othello9mL10D256ExtendedNcnnParam =>
      'assets/model/othello/rwkv7_othello_9m_L10_D256_extended-ncnn.param';

  /// File path: assets/model/othello/rwkv7_othello_9m_L10_D256_extended.st
  String get rwkv7Othello9mL10D256Extended =>
      'assets/model/othello/rwkv7_othello_9m_L10_D256_extended.st';

  /// List of all assets
  List<String> get values => [
        rwkv7Othello26mL10D448ExtendedNcnnBin,
        rwkv7Othello26mL10D448ExtendedNcnnParam,
        rwkv7Othello26mL10D448Extended,
        rwkv7Othello9mL10D256ExtendedNcnnBin,
        rwkv7Othello9mL10D256ExtendedNcnnParam,
        rwkv7Othello9mL10D256Extended
      ];
}

class Assets {
  Assets._();

  static const $AssetsConfigGen config = $AssetsConfigGen();
  static const $AssetsImgGen img = $AssetsImgGen();
  static const $AssetsModelGen model = $AssetsModelGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
