import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_mobile_flutter/rwkv.dart';
import 'package:zone/config.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/state/p.dart';

@immutable
class FileInfo extends Equatable {
  /// e.g.
  ///
  /// RWKV v7 World 0.4B
  final String name;

  /// e.g.
  ///
  /// rwkv7-world-2.9B-Q4_K_M.gguf
  final String fileName;

  final FileType fileType;

  /// In bytes
  ///
  /// e.g.
  ///
  /// 179794688, 501496768
  final int fileSize;

  /// e.g.
  ///
  /// mollysama/rwkv-mobile-models/resolve/main/gguf/rwkv7-world-1.5B-Q5_K_M.gguf
  final String raw;

  /// This file info is for download debugging purpose
  final bool isDebug;

  /// e.g.
  ///
  /// ["aifasthub", "huggingface", ...]
  final List<FileDownloadSource> availableIn;

  /// e.g.
  ///
  /// ['linux', 'macos', 'windows', ...]
  ///
  /// TODO: Should move it to backends?
  final List<String> supportedPlatforms;

  final Backend? backend;

  final String? sha256;

  /// e.g.
  ///
  /// 1.5, 2.9, 7, 14, 32 ...
  final double? modelSize;

  /// e.g.
  ///
  /// gguf, safetensors, ...
  final String? ext;

  /// e.g.
  ///
  /// q4_0, q4_1, q4_2, q4_3, q4_4, q5_0, q5_1, q5_2, q5_3, q5_4, q8_0, q8_1, q8_2, q8_3, q8_4, ...
  final String? quantization;

  /// e.g.
  ///
  /// ["encoder", ...]
  final List<String> tags;

  /// e.g.
  ///
  /// ["8 Gen 3", ...]
  final List<String> socLimitations;

  final Set<SocBrand> unsupportedSocBrand;

  const FileInfo({
    required this.name,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.raw,
    required this.isDebug,
    required this.availableIn,
    required this.supportedPlatforms,
    required this.backend,
    required this.sha256,
    required this.modelSize,
    required this.ext,
    required this.quantization,
    required this.tags,
    required this.socLimitations,
    required this.unsupportedSocBrand,
  });

  factory FileInfo.fromJSON(Map<String, dynamic> json) {
    final firstBackend = HF.list(json['backends'] ?? []).firstOrNull;
    final backend = firstBackend == null ? null : Backend.fromString(firstBackend);
    final rawFileType = json['fileType'];
    final fileType = rawFileType == null ? FileType.weights : FileType.values.byName(rawFileType);
    final socLimitations = HF.list(json['socLimitations'] ?? []).map((e) => e.toString()).toList();
    final unsupportedSocBrand = HF.list(json['unsupportedSocBrand'] ?? []).map((e) => SocBrand.values.byName(e.toString())).toSet();
    return FileInfo(
      name: json['name'],
      fileName: json['fileName'],
      fileType: fileType,
      fileSize: json['fileSize'],
      raw: json['url'],
      isDebug: json['isDebug'] as bool? ?? false,
      availableIn: HF.list(json['availableIn'] ?? []).map((e) => FileDownloadSource.values.byName(e.toString())).toList(),
      supportedPlatforms: HF.list(json['platforms']).map((e) => e.toString()).toList(),
      backend: backend,
      sha256: json['sha256'] as String?,
      modelSize: json['modelSize'] as double?,
      ext: json['type'] as String?,
      quantization: json['quantization'] as String?,
      tags: HF.list(json['tags'] ?? []).map((e) => e.toString()).toList(),
      socLimitations: socLimitations,
      unsupportedSocBrand: unsupportedSocBrand,
    );
  }

  bool get platformSupported {
    final platforms = supportedPlatforms;
    if (Platform.isAndroid) return platforms.contains('android');
    if (Platform.isIOS) return platforms.contains('ios');
    if (Platform.isMacOS) return platforms.contains('macos');
    if (Platform.isLinux) return platforms.contains('linux');
    if (Platform.isWindows) return platforms.contains('windows');
    if (Platform.isFuchsia) return platforms.contains('fuchsia');
    return false;
  }

  bool get socSupported {
    if (socLimitations.isEmpty) return true;
    final soc = P.rwkv.socName.q;
    return socLimitations.contains(soc);
  }

  bool get available {
    if (isDebug) return kDebugMode && platformSupported;
    if (fileType == FileType.downloadTest) return kDebugMode;
    if (unsupportedSocBrand.contains(P.rwkv.socBrand.q)) return false;
    return platformSupported && socSupported;
  }

  bool get isReasoning => tags.contains(Config.reasonTag);

  WorldType? get worldType => switch (fileName) {
    "RWKV7-0.4B-G1-SigLIP2-ColdStart-encoder-f16.gguf" => WorldType.reasoningQA,
    "RWKV7-0.4B-G1-SigLIP2-ColdStart-Q8_0.gguf" => WorldType.reasoningQA,
    "RWKV7-0.4B-G1-SigLIP2-ColdStart-a16w8_8elite_combined_embedding.bin" => WorldType.reasoningQA,
    "RWKV7-0.4B-G1-SigLIP2-ColdStart-a16w8_8gen3_combined_embedding.bin" => WorldType.reasoningQA,
    "rwkv7-v-0.4B-siglip_vision_encoder-f16.gguf" => WorldType.qa,
    "rwkv7-v-0.4B-Q8_0.gguf" => WorldType.qa,
    "rwkv7-v-0.4B-a16w8_8elite_combined_embedding.bin" => WorldType.qa,
    "rwkv7-v-0.4B-a16w8_8gen3_combined_embedding.bin" => WorldType.qa,
    "RWKV7-0.4B-G1-SigLIP2-encoder-f16.gguf" => WorldType.ocr,
    "RWKV7-0.4B-G1-SigLIP2-Q8_0.gguf" => WorldType.ocr,
    "RWKV7-0.4B-G1-SigLIP2-a16w8_8elite_combined_embedding.bin" => WorldType.ocr,
    "RWKV7-0.4B-G1-SigLIP2-a16w8_8gen3_combined_embedding.bin" => WorldType.ocr,
    _ => null,
  };

  bool get isEncoder => tags.contains('encoder');

  @override
  List<Object?> get props => [raw];

  @override
  String toString() {
    return '''name: $name,
fileName: $fileName,
fileType: $fileType,
fileSize: $fileSize,
raw: $raw,
isDebug: $isDebug,
availableIn: $availableIn,
supportedPlatforms: $supportedPlatforms,
backend: $backend,
sha256: $sha256,
modelSize: $modelSize,
ext: $ext,
quantization: $quantization,
tags: $tags,
socLimitations: $socLimitations,
unsupportedSocBrand: $unsupportedSocBrand,
''';
  }
}

enum FileType {
  weights,
  encoder,
  runtime,
  downloadTest,
}
