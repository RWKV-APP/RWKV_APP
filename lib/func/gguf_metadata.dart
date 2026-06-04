// Dart imports:
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class GgufMetadata {
  final int version;
  final int tensorCount;
  final int metadataCount;
  final String? architecture;
  final String? name;
  final Object? fileType;
  final String? sizeLabel;
  final int? quantizationVersion;
  final int? rwkvArchitectureVersion;
  final int? rwkvContextLength;
  final int? rwkvBlockCount;
  final int? rwkvEmbeddingLength;
  final int? rwkvFeedForwardLength;

  const GgufMetadata({
    required this.version,
    required this.tensorCount,
    required this.metadataCount,
    required this.architecture,
    required this.name,
    required this.fileType,
    required this.sizeLabel,
    required this.quantizationVersion,
    required this.rwkvArchitectureVersion,
    required this.rwkvContextLength,
    required this.rwkvBlockCount,
    required this.rwkvEmbeddingLength,
    required this.rwkvFeedForwardLength,
  });

  bool get isRwkvArchitecture => isRwkvArchitectureValue(architecture);

  String? get quantization {
    final fileType = this.fileType;
    if (fileType is int) return quantizationFromFileType(fileType);
    return null;
  }

  static bool isRwkvArchitectureValue(String? value) {
    if (value == null) return false;
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (normalized == "rwkv") return true;
    if (normalized.startsWith("rwkv")) return true;
    if (normalized.startsWith("arwkv")) return true;
    return false;
  }

  static String? quantizationFromFileType(int fileType) {
    return switch (fileType) {
      0 => "F32",
      1 => "F16",
      2 => "Q4_0",
      3 => "Q4_1",
      7 => "Q8_0",
      8 => "Q5_0",
      9 => "Q5_1",
      10 => "Q2_K",
      11 => "Q3_K_S",
      12 => "Q3_K_M",
      13 => "Q3_K_L",
      14 => "Q4_K_S",
      15 => "Q4_K_M",
      16 => "Q5_K_S",
      17 => "Q5_K_M",
      18 => "Q6_K",
      19 => "IQ2_XXS",
      20 => "IQ2_XS",
      21 => "Q2_K_S",
      22 => "IQ3_XS",
      23 => "IQ3_XXS",
      24 => "IQ1_S",
      25 => "IQ4_NL",
      26 => "IQ3_S",
      27 => "IQ3_M",
      28 => "IQ2_S",
      29 => "IQ2_M",
      30 => "IQ4_XS",
      31 => "IQ1_M",
      32 => "BF16",
      33 => "TQ1_0",
      34 => "TQ2_0",
      _ => null,
    };
  }
}

class GgufMetadataReader {
  static Future<GgufMetadata?> read(String path) async {
    RandomAccessFile? file;
    try {
      file = await File(path).open();
      final reader = _GgufBinaryReader(file);
      final magic = await reader.readAscii(4);
      if (magic != "GGUF") return null;

      final version = await reader.readUint32();
      final tensorCount = await reader.readUint64();
      final metadataCount = await reader.readUint64();

      String? architecture;
      String? name;
      Object? fileType;
      String? sizeLabel;
      int? quantizationVersion;
      int? rwkvArchitectureVersion;
      int? rwkvContextLength;
      int? rwkvBlockCount;
      int? rwkvEmbeddingLength;
      int? rwkvFeedForwardLength;

      for (int i = 0; i < metadataCount; i++) {
        final key = await reader.readString();
        final valueType = await reader.readUint32();
        final shouldRead =
            key == "general.architecture" ||
            key == "general.name" ||
            key == "general.file_type" ||
            key == "general.size_label" ||
            key == "general.quantization_version" ||
            key == "rwkv.architecture_version" ||
            key == "rwkv.context_length" ||
            key == "rwkv.block_count" ||
            key == "rwkv.embedding_length" ||
            key == "rwkv.feed_forward_length";

        if (shouldRead) {
          final value = await reader.readValue(valueType);
          if (key == "general.architecture" && value is String) {
            architecture = value;
          } else if (key == "general.name" && value is String) {
            name = value;
          } else if (key == "general.file_type") {
            fileType = value;
          } else if (key == "general.size_label" && value is String) {
            sizeLabel = value;
          } else if (key == "general.quantization_version" && value is int) {
            quantizationVersion = value;
          } else if (key == "rwkv.architecture_version" && value is int) {
            rwkvArchitectureVersion = value;
          } else if (key == "rwkv.context_length" && value is int) {
            rwkvContextLength = value;
          } else if (key == "rwkv.block_count" && value is int) {
            rwkvBlockCount = value;
          } else if (key == "rwkv.embedding_length" && value is int) {
            rwkvEmbeddingLength = value;
          } else if (key == "rwkv.feed_forward_length" && value is int) {
            rwkvFeedForwardLength = value;
          }
        } else {
          await reader.skipValue(valueType);
        }

        if (architecture != null && key.startsWith("tokenizer.")) break;
      }

      return GgufMetadata(
        version: version,
        tensorCount: tensorCount,
        metadataCount: metadataCount,
        architecture: architecture,
        name: name,
        fileType: fileType,
        sizeLabel: sizeLabel,
        quantizationVersion: quantizationVersion,
        rwkvArchitectureVersion: rwkvArchitectureVersion,
        rwkvContextLength: rwkvContextLength,
        rwkvBlockCount: rwkvBlockCount,
        rwkvEmbeddingLength: rwkvEmbeddingLength,
        rwkvFeedForwardLength: rwkvFeedForwardLength,
      );
    } catch (_) {
      return null;
    } finally {
      await file?.close();
    }
  }
}

class _GgufBinaryReader {
  final RandomAccessFile file;

  const _GgufBinaryReader(this.file);

  Future<String> readAscii(int length) async {
    final bytes = await _readExact(length);
    return ascii.decode(bytes);
  }

  Future<int> readUint32() async {
    final bytes = await _readExact(4);
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    return data.getUint32(0, Endian.little);
  }

  Future<int> readUint64() async {
    final bytes = await _readExact(8);
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    return data.getUint64(0, Endian.little);
  }

  Future<String> readString() async {
    final length = await readUint64();
    final bytes = await _readExact(length);
    return utf8.decode(bytes);
  }

  Future<Object?> readValue(int valueType) async {
    return switch (valueType) {
      0 => (await _readExact(1)).first,
      1 => ByteData.sublistView(Uint8List.fromList(await _readExact(1))).getInt8(0),
      2 => ByteData.sublistView(Uint8List.fromList(await _readExact(2))).getUint16(0, Endian.little),
      3 => ByteData.sublistView(Uint8List.fromList(await _readExact(2))).getInt16(0, Endian.little),
      4 => await readUint32(),
      5 => ByteData.sublistView(Uint8List.fromList(await _readExact(4))).getInt32(0, Endian.little),
      6 => ByteData.sublistView(Uint8List.fromList(await _readExact(4))).getFloat32(0, Endian.little),
      7 => (await _readExact(1)).first != 0,
      8 => await readString(),
      9 => await _readArray(),
      10 => await readUint64(),
      11 => ByteData.sublistView(Uint8List.fromList(await _readExact(8))).getInt64(0, Endian.little),
      12 => ByteData.sublistView(Uint8List.fromList(await _readExact(8))).getFloat64(0, Endian.little),
      _ => throw FormatException("Unsupported GGUF metadata type: $valueType"),
    };
  }

  Future<void> skipValue(int valueType) async {
    final elementSize = _fixedElementSize(valueType);
    if (elementSize != null) {
      await _skip(elementSize);
      return;
    }

    if (valueType == 8) {
      final length = await readUint64();
      await _skip(length);
      return;
    }

    if (valueType == 9) {
      await _skipArray();
      return;
    }

    throw FormatException("Unsupported GGUF metadata type: $valueType");
  }

  Future<List<Object?>> _readArray() async {
    final elementType = await readUint32();
    final length = await readUint64();
    final values = <Object?>[];
    for (int i = 0; i < length; i++) {
      values.add(await readValue(elementType));
    }
    return values;
  }

  Future<void> _skipArray() async {
    final elementType = await readUint32();
    final length = await readUint64();
    final elementSize = _fixedElementSize(elementType);
    if (elementSize != null) {
      await _skip(elementSize * length);
      return;
    }

    for (int i = 0; i < length; i++) {
      await skipValue(elementType);
    }
  }

  int? _fixedElementSize(int valueType) {
    return switch (valueType) {
      0 || 1 || 7 => 1,
      2 || 3 => 2,
      4 || 5 || 6 => 4,
      10 || 11 || 12 => 8,
      _ => null,
    };
  }

  Future<void> _skip(int length) async {
    if (length < 0) throw const FormatException("Invalid GGUF skip length");
    final position = await file.position();
    await file.setPosition(position + length);
  }

  Future<List<int>> _readExact(int length) async {
    if (length < 0) throw const FormatException("Invalid GGUF read length");
    final bytes = await file.read(length);
    if (bytes.length != length) {
      throw const FormatException("Unexpected end of GGUF file");
    }
    return bytes;
  }
}
