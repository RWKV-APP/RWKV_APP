import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Helper to find the offset of the 'data' chunk ID, its size, and the data start offset.
/// Returns a record (dataIdOffset, dataChunkSizeBytes, audioDataStartOffset)
/// Returns null if 'data' chunk is not found or WAV is malformed.
(int, int, int)? _findWavDataChunkInfo(Uint8List wavBytes) {
  if (wavBytes.length < 44) return null; // Basic check for minimal header
  ByteData byteData = ByteData.view(wavBytes.buffer);

  // Check RIFF/WAVE header
  if (String.fromCharCodes(wavBytes.sublist(0, 4)) != "RIFF" || String.fromCharCodes(wavBytes.sublist(8, 12)) != "WAVE") {
    debugPrint("Invalid RIFF/WAVE header");
    return null;
  }

  // Find "fmt " chunk - assuming it's at offset 12 for simplicity here
  int fmtIdOffset = 12;
  if (String.fromCharCodes(wavBytes.sublist(fmtIdOffset, fmtIdOffset + 4)) != "fmt ") {
    debugPrint("fmt chunk not found at offset 12");
    return null;
  }
  int fmtChunkContentSize = byteData.getUint32(fmtIdOffset + 4, Endian.little);

  // Position after "fmt " content to start searching for other chunks
  int currentOffset = fmtIdOffset + 8 + fmtChunkContentSize;

  while (currentOffset + 8 <= wavBytes.lengthInBytes) {
    String chunkId = String.fromCharCodes(wavBytes.sublist(currentOffset, currentOffset + 4));
    int chunkContentSize = byteData.getUint32(currentOffset + 4, Endian.little);

    if (chunkId == "data") {
      int dataIdOffset = currentOffset;
      int audioDataStartOffset = currentOffset + 8;
      if (audioDataStartOffset + chunkContentSize > wavBytes.lengthInBytes) {
        debugPrint(
          "Data chunk size exceeds file length. Path: $chunkId, Declared size: $chunkContentSize, Actual available: ${wavBytes.lengthInBytes - audioDataStartOffset}",
        );
        // Allow to proceed with available data if header size is wrong but data seems to be there till end
        // chunkContentSize = wavBytes.lengthInBytes - audioDataStartOffset;
        // if(chunkContentSize < 0) return null; // or throw
        return null; // Strict: header size must be valid
      }
      return (dataIdOffset, chunkContentSize, audioDataStartOffset);
    }

    currentOffset += 8 + (chunkContentSize ~/ 2) * 2;
  }
  debugPrint("data chunk not found after fmt chunk");
  return null; // "data" chunk not found
}

/// 将多个 .wav 文件合并为一个 .wav 文件, 拼接文件内容, 已知 sample rate 相等
///
/// e.g.
/// foobar.0.wav
/// foobar.1.wav
/// foobar.2.wav
///
/// 注意一定要忽略原始的 foobar.wav
///
/// 合并后为 foobar.merged.wav
///
/// 返回合并后的文件路径, 在原始文件夹位置合并
Future<String> mergeWavFiles(List<String> filePaths) async {
  if (filePaths.isEmpty) {
    throw ArgumentError("File paths list cannot be empty.");
  }

  final firstFilePath = filePaths.first;
  final dirName = p.dirname(firstFilePath);
  final baseNameWithoutExt = p.basenameWithoutExtension(firstFilePath);
  final originalNamePart = baseNameWithoutExt.replaceFirst(RegExp(r'\.\d+$'), '');
  final outputFileName = '$originalNamePart.merged.wav';
  final outputFilePath = p.join(dirName, outputFileName);

  int? sampleRate;
  int? numChannels;
  int? bitsPerSample;

  List<Uint8List> audioDataSegments = [];
  int totalAudioDataLength = 0;

  for (final filePath in filePaths) {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException("File not found", filePath);
    }
    final Uint8List fileBytes = await file.readAsBytes();
    final ByteData byteDataView = ByteData.view(fileBytes.buffer);

    final dataChunkInfo = _findWavDataChunkInfo(fileBytes);
    if (dataChunkInfo == null) {
      throw FormatException("Could not find 'data' chunk or invalid WAV format in $filePath");
    }
    final (_, int dataChunkSizeBytes, int audioDataStartOffset) = dataChunkInfo;

    if (audioDataStartOffset + dataChunkSizeBytes > fileBytes.lengthInBytes) {
      throw FormatException("Data chunk size indicates data beyond file length in $filePath. File might be corrupted.");
    }

    final Uint8List currentAudioData = fileBytes.sublist(audioDataStartOffset, audioDataStartOffset + dataChunkSizeBytes);

    if (sampleRate == null) {
      // First valid file, extract format details from 'fmt ' chunk
      final int fmtChunkSizeFromFile = byteDataView.getUint32(16, Endian.little);
      final int audioFormat = byteDataView.getUint16(20, Endian.little);

      if (fmtChunkSizeFromFile < 16 || audioFormat != 1) {
        // Standard PCM format requires 'fmt ' chunk size of at least 16 bytes
        // and AudioFormat to be 1.
        throw FormatException("Unsupported 'fmt ' chunk in $filePath. Requires PCM format (AudioFormat=1) with fmt_chunk_size >= 16.");
      }
      numChannels = byteDataView.getUint16(22, Endian.little);
      sampleRate = byteDataView.getUint32(24, Endian.little);
      bitsPerSample = byteDataView.getUint16(34, Endian.little);

      if (numChannels == 0 || sampleRate == 0 || bitsPerSample == 0) {
        throw FormatException("Invalid audio parameters (channels, sample rate, or bits per sample are zero) in $filePath");
      }
    } else {
      // Validate subsequent files against the first one's parameters
      final int currentFmtChunkSize = byteDataView.getUint32(16, Endian.little);
      final int currentAudioFormat = byteDataView.getUint16(20, Endian.little);
      if (currentFmtChunkSize < 16 || currentAudioFormat != 1) {
        throw FormatException("Unsupported 'fmt ' chunk in $filePath during validation. Requires PCM format.");
      }
      final int currentNumChannels = byteDataView.getUint16(22, Endian.little);
      final int currentSampleRate = byteDataView.getUint32(24, Endian.little);
      final int currentBitsPerSample = byteDataView.getUint16(34, Endian.little);

      if (currentNumChannels != numChannels || currentSampleRate != sampleRate || currentBitsPerSample != bitsPerSample) {
        throw FormatException(
          "Mismatch in audio parameters between WAV files. Expected Ch=$numChannels, SR=$sampleRate, BPS=$bitsPerSample. Got Ch=$currentNumChannels, SR=$currentSampleRate, BPS=$currentBitsPerSample in $filePath",
        );
      }
    }
    audioDataSegments.add(currentAudioData);
    totalAudioDataLength += currentAudioData.length;
  }

  if (sampleRate == null || numChannels == null || bitsPerSample == null) {
    throw StateError(
      "Could not determine audio parameters from input files. All files might have been invalid or list was effectively empty of valid WAVs.",
    );
  }
  if (audioDataSegments.isEmpty) {
    throw StateError("No audio data could be extracted from the provided files.");
  }

  final ByteData newHeader = ByteData(44);
  // RIFF chunk
  newHeader.setUint8(0, 0x52); // 'R'
  newHeader.setUint8(1, 0x49); // 'I'
  newHeader.setUint8(2, 0x46); // 'F'
  newHeader.setUint8(3, 0x46); // 'F'
  newHeader.setUint32(4, 36 + totalAudioDataLength, Endian.little); // ChunkSize
  newHeader.setUint8(8, 0x57); // 'W'
  newHeader.setUint8(9, 0x41); // 'A'
  newHeader.setUint8(10, 0x56); // 'V'
  newHeader.setUint8(11, 0x45); // 'E'
  // "fmt " sub-chunk
  newHeader.setUint8(12, 0x66); // 'f'
  newHeader.setUint8(13, 0x6d); // 'm'
  newHeader.setUint8(14, 0x74); // 't'
  newHeader.setUint8(15, 0x20); // ' '
  newHeader.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  newHeader.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
  newHeader.setUint16(22, numChannels, Endian.little);
  newHeader.setUint32(24, sampleRate, Endian.little);
  final int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  newHeader.setUint32(28, byteRate, Endian.little);
  final int blockAlign = numChannels * (bitsPerSample ~/ 8);
  newHeader.setUint16(32, blockAlign, Endian.little);
  newHeader.setUint16(34, bitsPerSample, Endian.little);
  // "data" sub-chunk
  newHeader.setUint8(36, 0x64); // 'd'
  newHeader.setUint8(37, 0x61); // 'a'
  newHeader.setUint8(38, 0x74); // 't'
  newHeader.setUint8(39, 0x61); // 'a'
  newHeader.setUint32(40, totalAudioDataLength, Endian.little);

  final BytesBuilder mergedBytesBuilder = BytesBuilder(copy: false);
  mergedBytesBuilder.add(newHeader.buffer.asUint8List());
  for (final segment in audioDataSegments) {
    mergedBytesBuilder.add(segment);
  }
  final Uint8List finalWavBytes = mergedBytesBuilder.toBytes();

  final outputFile = File(outputFilePath);
  await outputFile.writeAsBytes(finalWavBytes, flush: true);

  return outputFilePath;
}
