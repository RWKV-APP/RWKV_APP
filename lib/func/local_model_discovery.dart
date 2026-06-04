// Dart imports:
import 'dart:io';

// Package imports:
import 'package:path/path.dart' as p;

// Project imports:
import 'package:zone/func/gguf_metadata.dart';

enum LocalModelFileKind {
  pth,
  rwkvGguf,
}

class LocalModelFile {
  final String path;
  final String fileName;
  final String displayName;
  final int fileSize;
  final LocalModelFileKind kind;
  final String? ggufArchitecture;
  final String? ggufName;
  final Object? ggufFileType;
  final String? ggufSizeLabel;
  final String? ggufQuantization;
  final int? ggufQuantizationVersion;
  final int? ggufArchitectureVersion;
  final int? ggufContextLength;
  final int? ggufBlockCount;
  final int? ggufEmbeddingLength;
  final int? ggufFeedForwardLength;

  const LocalModelFile({
    required this.path,
    required this.fileName,
    required this.displayName,
    required this.fileSize,
    required this.kind,
    required this.ggufArchitecture,
    required this.ggufName,
    required this.ggufFileType,
    required this.ggufSizeLabel,
    required this.ggufQuantization,
    required this.ggufQuantizationVersion,
    required this.ggufArchitectureVersion,
    required this.ggufContextLength,
    required this.ggufBlockCount,
    required this.ggufEmbeddingLength,
    required this.ggufFeedForwardLength,
  });
}

class LocalModelDiscoveryResult {
  final List<LocalModelFile> files;
  final bool hasError;

  const LocalModelDiscoveryResult({
    required this.files,
    required this.hasError,
  });
}

bool isLocalModelFileExtension(String filePath) {
  final extension = p.extension(filePath).toLowerCase();
  if (extension == ".pth") return true;
  if (extension == ".gguf") return true;
  return false;
}

Future<LocalModelDiscoveryResult> discoverLocalModelFiles(String folderPath) async {
  final directory = Directory(folderPath);
  late final List<FileSystemEntity> entities;
  try {
    entities = directory.listSync();
  } catch (_) {
    return const LocalModelDiscoveryResult(files: [], hasError: true);
  }

  final files = <LocalModelFile>[];
  for (final entity in entities) {
    if (entity is! File) continue;

    final extension = p.extension(entity.path).toLowerCase();
    if (extension == ".pth") {
      files.add(await _createPthModelFile(entity));
      continue;
    }

    if (extension == ".gguf") {
      final file = await _createRwkvGgufModelFile(entity);
      if (file == null) continue;
      files.add(file);
    }
  }

  files.sort((a, b) => b.fileSize.compareTo(a.fileSize));
  return LocalModelDiscoveryResult(files: files, hasError: false);
}

Future<LocalModelFile?> discoverLocalModelFile(String filePath) async {
  final file = File(filePath);
  final extension = p.extension(file.path).toLowerCase();
  if (extension == ".pth") return _createPthModelFile(file);
  if (extension == ".gguf") return _createRwkvGgufModelFile(file);
  return null;
}

Future<bool> isRecognizedRwkvGgufFile(String filePath) async {
  if (p.extension(filePath).toLowerCase() != ".gguf") return false;
  final metadata = await GgufMetadataReader.read(filePath);
  if (metadata == null) return false;
  return metadata.isRwkvArchitecture;
}

Future<LocalModelFile> _createPthModelFile(File file) async {
  final stat = await file.stat();
  final fileName = p.basename(file.path);
  return LocalModelFile(
    path: file.path,
    fileName: fileName,
    displayName: fileName,
    fileSize: stat.size,
    kind: LocalModelFileKind.pth,
    ggufArchitecture: null,
    ggufName: null,
    ggufFileType: null,
    ggufSizeLabel: null,
    ggufQuantization: null,
    ggufQuantizationVersion: null,
    ggufArchitectureVersion: null,
    ggufContextLength: null,
    ggufBlockCount: null,
    ggufEmbeddingLength: null,
    ggufFeedForwardLength: null,
  );
}

Future<LocalModelFile?> _createRwkvGgufModelFile(File file) async {
  final metadata = await GgufMetadataReader.read(file.path);
  if (metadata == null) return null;
  if (!metadata.isRwkvArchitecture) return null;

  final stat = await file.stat();
  final fileName = p.basename(file.path);
  final sizeLabel = metadata.sizeLabel ?? _parseSizeLabelFromFileName(fileName);
  final quantization = metadata.quantization ?? _parseQuantizationFromFileName(fileName);
  final contextLength = metadata.rwkvContextLength ?? _parseContextLengthFromFileName(fileName);
  return LocalModelFile(
    path: file.path,
    fileName: fileName,
    displayName: fileName,
    fileSize: stat.size,
    kind: LocalModelFileKind.rwkvGguf,
    ggufArchitecture: metadata.architecture,
    ggufName: metadata.name,
    ggufFileType: metadata.fileType,
    ggufSizeLabel: sizeLabel,
    ggufQuantization: quantization,
    ggufQuantizationVersion: metadata.quantizationVersion,
    ggufArchitectureVersion: metadata.rwkvArchitectureVersion,
    ggufContextLength: contextLength,
    ggufBlockCount: metadata.rwkvBlockCount,
    ggufEmbeddingLength: metadata.rwkvEmbeddingLength,
    ggufFeedForwardLength: metadata.rwkvFeedForwardLength,
  );
}

String? _parseSizeLabelFromFileName(String fileName) {
  final match = RegExp(r'(\d+(?:\.\d+)?)([bBmMkK])').firstMatch(fileName);
  if (match == null) return null;
  return '${match.group(1)}${match.group(2)?.toUpperCase()}';
}

String? _parseQuantizationFromFileName(String fileName) {
  final normalized = p.basenameWithoutExtension(fileName);
  final patterns = <RegExp>[
    RegExp(r'(IQ\d_[A-Z]+)', caseSensitive: false),
    RegExp(r'(Q\d_K_[A-Z]+)', caseSensitive: false),
    RegExp(r'(Q\d_K)', caseSensitive: false),
    RegExp(r'(Q\d_[01])', caseSensitive: false),
    RegExp(r'(Q8_0)', caseSensitive: false),
    RegExp(r'(BF16)', caseSensitive: false),
    RegExp(r'(F16)', caseSensitive: false),
    RegExp(r'(F32)', caseSensitive: false),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(normalized);
    if (match == null) continue;
    return match.group(1)?.toUpperCase();
  }
  return null;
}

int? _parseContextLengthFromFileName(String fileName) {
  final match = RegExp(r'ctx(\d+)', caseSensitive: false).firstMatch(fileName);
  if (match == null) return null;
  return int.tryParse(match.group(1) ?? "");
}
