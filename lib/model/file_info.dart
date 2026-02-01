import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_mobile_flutter/rwkv.dart';
import 'package:zone/config.dart';
import 'package:zone/model/file_download_source.dart';
import 'package:zone/model/world_type.dart';
import 'package:path/path.dart' as p;
import 'package:zone/store/p.dart';

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
  /// q4_0, q4_1, q4_2, q4_3, q4_4, q5_0, q5_1, q5_2, q5_3, q5_4, q8_0, q8_1, q8_2, q8_3, q8_4, ...
  final String? quantization;

  final String? updatedAt;

  final int? timestamp;

  final DateTime? date;

  /// e.g.
  ///
  /// ["encoder", ...]
  final List<String> tags;

  /// e.g.
  ///
  /// ["8 Gen 3", ...]
  final List<String> socLimitations;

  final Set<SocBrand> unsupportedSocBrand;

  final List<ModelStateFile> state;

  final bool fromPthFile;

  const FileInfo({
    required this.name,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.raw,
    required this.isDebug,
    this.availableIn = const [],
    this.supportedPlatforms = const [],
    required this.backend,
    required this.sha256,
    required this.modelSize,
    required this.quantization,
    required this.updatedAt,
    required this.timestamp,
    required this.date,
    this.tags = const [],
    this.socLimitations = const [],
    this.unsupportedSocBrand = const {},
    this.state = const [],
    this.fromPthFile = false,
  });

  factory FileInfo.fromJSON(Map<String, dynamic> json) {
    final firstBackend = HF.list(json['backends'] ?? []).firstOrNull;
    final backend = firstBackend == null ? null : Backend.fromString(firstBackend);
    final rawFileType = json['fileType'];
    final fileType = rawFileType == null ? FileType.weights : FileType.values.byName(rawFileType);
    final socLimitations = HF.list(json['socLimitations'] ?? []).map((e) => e.toString()).toList();
    final unsupportedSocBrand = HF.list(json['unsupportedSocBrand'] ?? []).map((e) => SocBrand.values.byName(e.toString())).toSet();
    final url = json['url'] as String;
    final fileName = p.basename(Uri.parse(url).path);
    return FileInfo(
      name: json['name'],
      fileName: fileName,
      fileType: fileType,
      fileSize: json['fileSize'],
      raw: url,
      isDebug: json['isDebug'] as bool? ?? false,
      availableIn: HF.list(json['availableIn'] ?? []).map((e) => FileDownloadSource.values.byName(e.toString())).toList(),
      supportedPlatforms: HF.list(json['platforms']).map((e) => e.toString()).toList(),
      backend: backend,
      sha256: json['sha256'] as String?,
      modelSize: json['modelSize'] as double?,
      quantization: json['quantization'] as String?,
      updatedAt: json['updatedAt'] as String?,
      timestamp: json['date'] as int?,
      date: json['date'] != null ? DateTime.fromMillisecondsSinceEpoch(json['date'] * 1000) : null,
      tags: HF.list(json['tags'] ?? []).map((e) => e.toString()).toList(),
      socLimitations: socLimitations,
      unsupportedSocBrand: unsupportedSocBrand,
      state: HF.list(json['state'] ?? []).map((e) => ModelStateFile.fromJson(e)).toList(),
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
    "RWKV7-0.4B-G1-SigLIP2-ColdStart-Q8_0.gguf" => .reasoningQA,
    "RWKV7-0.4B-G1-SigLIP2-ColdStart-a16w8_8elite_combined_embedding.bin" => .reasoningQA,
    "RWKV7-0.4B-G1-SigLIP2-ColdStart-a16w8_8gen3_combined_embedding.bin" => .reasoningQA,
    "RWKV7-0.4B-G1-SigLIP2-ColdStart-encoder-f16.gguf" => .reasoningQA,
    "RWKV7-0.4B-G1-SigLIP2-Q8_0.gguf" => .ocr,
    "RWKV7-0.4B-G1-SigLIP2-a16w8_8elite_combined_embedding.bin" => .ocr,
    "RWKV7-0.4B-G1-SigLIP2-a16w8_8gen3_combined_embedding.bin" => .ocr,
    "RWKV7-0.4B-G1-SigLIP2-encoder-f16.gguf" => .ocr,
    "modrwkv-v2-1B5-step4-a16w8-8elite_combined_embedding.bin" => .modrwkvV2,
    "modrwkv-v2-1B5-step4-a16w8-8gen3_combined_embedding.bin" => .modrwkvV2,
    "modrwkv-v2-1B5-step4-q6_K.gguf" => .modrwkvV2,
    "modrwkv-v2-vision-adapter-1B5-step4-f16.gguf" => .modrwkvV2,
    "rwkv-vl-0.4b-251222-MT6989.rmpack" => .modrwkvV3,
    "rwkv-vl-0.4b-251222-a16w8-8elite.rmpack" => .modrwkvV3,
    "rwkv-vl-0.4b-251222-a16w8-8elitegen5.rmpack" => .modrwkvV3,
    "rwkv-vl-0.4b-251222-a16w8-8gen2.rmpack" => .modrwkvV3,
    "rwkv-vl-0.4b-251222-a16w8-8gen3.rmpack" => .modrwkvV3,
    "rwkv-vl-0.4b-251222-a16w8-8sgen3.rmpack" => .modrwkvV3,
    "rwkv-vl-0.4b-251222-a16w8-8plusgen1.rmpack" => .modrwkvV3,
    "rwkv-vl-0.4b-251222-q8_0.gguf" => .modrwkvV3,
    "rwkv-vl-0.4b-adapter-int8.mnn" => .modrwkvV3,
    "rwkv-vl-0.4b-siglip-encoder-int8.mnn" => .modrwkvV3,
    _ => null,
  };

  bool get isEncoder => tags.contains('encoder');

  bool get isAdapter => tags.contains('adapter');

  bool get isNeko => name.contains('Neko');

  bool get isTTS => name.toLowerCase().contains('tts');

  bool get isAlbatross => tags.contains('albatross');

  String? get dateDisplayString {
    if (date != null) {
      final chinaTime = date!.toUtc().add(const Duration(hours: 8));
      final y = chinaTime.year.toString().substring(2);
      final m = chinaTime.month.toString().padLeft(2, '0');
      final d = chinaTime.day.toString().padLeft(2, '0');
      return '$y$m$d';
    }

    // 用正则表达式匹配 "20250317", "20381101" 这样的日期
    final re = RegExp(r'(20\d{2})(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])');

    for (final s in [fileName]) {
      if (s.isEmpty) continue;
      final m = re.firstMatch(s);
      if (m != null) {
        // 2025
        // 但是只取后两位
        final y = m.group(1)!.substring(2);
        // 03
        final mo = m.group(2)!;
        // 17
        final d = m.group(3)!;
        // 20250317
        return '$y$mo$d';
      }
    }

    if (updatedAt != null) return updatedAt;

    return null;
  }

  WeightType? get weightType => switch (fileType) {
    FileType.weights => () {
      if (P.fileManager.chatWeights.q.contains(this)) return WeightType.chat;
      if (P.fileManager.seeWeights.q.contains(this)) return WeightType.see;
      if (P.fileManager.ttsWeights.q.contains(this)) return WeightType.tts;
      if (P.fileManager.sudokuWeights.q.contains(this)) return WeightType.sudoku;
      if (P.fileManager.othelloWeights.q.contains(this)) return WeightType.othello;
      if (P.fileManager.roleplayWeights.q.contains(this)) return WeightType.roleplay;
      qqw('unknown weight type: $this');
      return WeightType.chat;
    }(),
    FileType.encoder => null,
    FileType.runtime => null,
    FileType.downloadTest => null,
  };

  @override
  List<Object?> get props => [raw, name];

  @override
  String toString() {
    return '''
FileInfo($name,
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
  quantization: $quantization,
  updatedAt: $updatedAt,
  timestamp: $timestamp,
  tags: $tags,
  socLimitations: $socLimitations,
  unsupportedSocBrand: $unsupportedSocBrand,
)''';
  }
}

enum FileType {
  weights,
  encoder,
  runtime,
  downloadTest,
}

enum WeightType {
  /// Translate and Completion are included in Chat
  chat,
  see,
  tts,
  sudoku,
  othello,
  roleplay,
}

class ModelStateFile extends FileInfo {
  final dynamic decodeParam;

  const ModelStateFile({
    required super.name,
    required super.fileName,
    required super.fileSize,
    required super.raw,
    super.updatedAt = '',
    super.timestamp,
    super.date,
    super.fileType = FileType.weights,
    super.isDebug = false,
    super.availableIn = const [],
    super.supportedPlatforms = const [],
    super.backend,
    super.sha256,
    super.modelSize,
    super.quantization,
    super.tags = const [],
    super.socLimitations = const [],
    super.unsupportedSocBrand = const {},
    super.state = const [],
    this.decodeParam,
  });

  factory ModelStateFile.fromJson(dynamic json) {
    return ModelStateFile(
      fileName: json["fileName"],
      raw: json["url"],
      fileSize: json["fileSize"],
      name: json['name'],
      decodeParam: json['decodeParam'] ?? {},
    );
  }
}
