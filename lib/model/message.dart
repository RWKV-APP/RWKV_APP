import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/message_type.dart';
import 'package:zone/model/ref_info.dart';

@immutable
final class Message extends Equatable {
  /// 消息创建时间, 单位: 毫秒
  final int id;
  final String content;
  final bool isMine;
  final bool changing;
  final MessageType type;
  final bool isReasoning;
  final bool paused;
  final RefInfo reference;

  final String? imageUrl;
  final String? audioUrl;
  final int? audioLength;
  final bool isSensitive;

  @Deprecated("")
  final int? ttsCFMSteps;
  final String? ttsTarget;
  final String? ttsSpeakerName;
  final String? ttsSourceAudioPath;
  final String? ttsInstruction;
  @Deprecated("")
  final double? ttsOverallProgress;
  @Deprecated("")
  final List<double>? ttsPerWavProgress;
  @Deprecated("")
  final List<String>? ttsFilePaths;

  final String? modelName;
  final String? runningMode;

  const Message({
    required this.id,
    required this.content,
    required this.isMine,
    required this.isReasoning,
    required this.paused,
    this.reference = const RefInfo(list: [], enable: false, error: ''),
    this.changing = false,
    this.type = MessageType.text,
    this.imageUrl,
    this.audioUrl,
    this.audioLength,
    this.ttsTarget,
    this.ttsSpeakerName,
    this.ttsSourceAudioPath,
    this.ttsInstruction,
    this.ttsCFMSteps = 5,
    this.isSensitive = false,
    this.ttsOverallProgress,
    this.ttsPerWavProgress,
    this.ttsFilePaths,
    this.modelName,
    this.runningMode,
  });

  @override
  List<Object?> get props => [
    id,
    content,
    isMine,
    changing,
    reference,
    type,
    imageUrl,
    audioUrl,
    audioLength,
    isReasoning,
    paused,
    ttsTarget,
    ttsSpeakerName,
    ttsSourceAudioPath,
    ttsInstruction,
    isSensitive,
    ttsOverallProgress,
    ...ttsPerWavProgress ?? [],
    ...ttsFilePaths ?? [],
    modelName,
    runningMode,
  ];

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json["id"] as int,
      content: json["content"] as String,
      isMine: json["roleType"] == 1,
      changing: false,
      reference: RefInfo.fromJson(json["reference"]),
      type: MessageType.values.firstWhere((e) => e.name == json["type"]),
      imageUrl: json["imageUrl"] as String?,
      audioUrl: json["audioUrl"] as String?,
      audioLength: json["audioLength"] as int?,
      isReasoning: json["isReasoning"] as bool,
      paused: json["paused"] as bool,
      ttsTarget: json["ttsTarget"] as String?,
      ttsSpeakerName: json["ttsSpeakerName"] as String?,
      ttsSourceAudioPath: json["ttsSourceAudioPath"] as String?,
      ttsInstruction: json["ttsInstruction"] as String?,
      isSensitive: json["isSensitive"] as bool,
      ttsOverallProgress: json["ttsOverallProgress"] as double?,
      ttsPerWavProgress: json["ttsPerWavProgress"] as List<double>?,
      ttsFilePaths: json["ttsFilePaths"] as List<String>?,
      modelName: json["modelName"] as String?,
      runningMode: json["runningMode"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "content": content,
      "roleType": isMine ? 1 : 0,
      "type": type.name,
      "imageUrl": imageUrl,
      "audioUrl": audioUrl,
      "audioLength": audioLength,
      "isReasoning": isReasoning,
      "changing": false,
      "reference": reference.toJson(),
      "paused": paused,
      "ttsTarget": ttsTarget,
      "ttsSpeakerName": ttsSpeakerName,
      "ttsSourceAudioPath": ttsSourceAudioPath,
      "ttsInstruction": ttsInstruction,
      "isSensitive": isSensitive,
      "ttsOverallProgress": ttsOverallProgress,
      "ttsPerWavProgress": ttsPerWavProgress,
      "ttsFilePaths": ttsFilePaths,
      "modelName": modelName,
      "runningMode": runningMode,
    };
  }

  Message copyWith({
    int? id,
    String? content,
    bool? isMine,
    bool? changing,
    RefInfo? reference,
    MessageType? type,
    String? imageUrl,
    String? audioUrl,
    int? audioLength,
    bool? isReasoning,
    bool? paused,
    String? ttsTarget,
    String? ttsSpeakerName,
    String? ttsSourceAudioPath,
    String? ttsInstruction,
    bool? isSensitive,
    double? ttsOverallProgress,
    List<double>? ttsPerWavProgress,
    List<String>? ttsFilePaths,
    String? modelName,
    String? runningMode,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isMine: isMine ?? this.isMine,
      changing: changing ?? this.changing,
      reference: reference ?? this.reference,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      audioLength: audioLength ?? this.audioLength,
      isReasoning: isReasoning ?? this.isReasoning,
      paused: paused ?? this.paused,
      ttsTarget: ttsTarget ?? this.ttsTarget,
      ttsSpeakerName: ttsSpeakerName ?? this.ttsSpeakerName,
      ttsSourceAudioPath: ttsSourceAudioPath ?? this.ttsSourceAudioPath,
      ttsInstruction: ttsInstruction ?? this.ttsInstruction,
      isSensitive: isSensitive ?? this.isSensitive,
      ttsOverallProgress: ttsOverallProgress ?? this.ttsOverallProgress,
      ttsPerWavProgress: ttsPerWavProgress ?? this.ttsPerWavProgress,
      ttsFilePaths: ttsFilePaths ?? this.ttsFilePaths,
      modelName: modelName ?? this.modelName,
      runningMode: runningMode ?? this.runningMode,
    );
  }

  @override
  String toString() {
    return """
Message(
  id: $id,
  content: $content,
  isMine: $isMine,
  changing: $changing,
  reference: $reference,
  type: $type,
  imageUrl: $imageUrl,
  audioUrl: $audioUrl,
  audioLength: $audioLength,
  isReasoning: $isReasoning,
  paused: $paused,
  ttsTarget: $ttsTarget,
  ttsSpeakerName: $ttsSpeakerName,
  ttsSourceAudioPath: $ttsSourceAudioPath,
  ttsInstruction: $ttsInstruction,
  isSensitive: $isSensitive,
  ttsOverallProgress: $ttsOverallProgress,
  ttsPerWavProgress: $ttsPerWavProgress,
  ttsFilePaths: $ttsFilePaths,
  modelName: $modelName,
  runningMode: $runningMode,
)""";
  }
}

extension MessageX on Message {
  bool get ttsHasContent => ttsFilePaths?.isNotEmpty ?? false;

  bool get ttsIsDone => (ttsOverallProgress ?? 0.0) >= 1.0;

  int get createAtInMS => id;

  bool get isCotFormat => content.startsWith("<think>");

  bool get containsCotEndMark => content.contains("</think>");

  /// Append web search reference text behind of the user input content
  String getContentForHistoryWithRef(RefInfo? reference) {
    final contentForHistory = getContentForHistory();
    if (!isMine || reference == null) {
      return contentForHistory;
    }
    final ref = reference.enable ? reference.toLlmReferenceText() : null;
    qqq("$contentForHistory, ${ref?.substring(0, 30)}");
    if (ref == null) {
      return contentForHistory;
    } else {
      return "$ref\n$contentForHistory";
    }
  }

  String getContentForHistory({bool appendThinkTagInThinkingTagIsEmpty = false}) {
    if (!isReasoning) return content;
    if (!isCotFormat) return content;
    if (!containsCotEndMark) return content;
    if (paused) return content;
    final (cotContent, cotResult) = getCotContentAndResult(
      appendThinkTagInThinkingTagIsEmpty: appendThinkTagInThinkingTagIsEmpty,
    );
    return cotResult;
  }

  (String cotContent, String cotResult) getCotContentAndResult({bool appendThinkTagInThinkingTagIsEmpty = false}) {
    if (!isCotFormat) return ("", "");

    if (!containsCotEndMark) return (content.substring(7), "");

    final endIndex = content.indexOf("</think>");
    final thinkingContent = content.substring(7, endIndex);

    String result = "";
    if (endIndex + 9 < content.length) {
      result = content.substring(endIndex + 9);
    }

    if (appendThinkTagInThinkingTagIsEmpty && content.contains("<think>\n</think>")) {
      return (thinkingContent, content);
    }

    return (thinkingContent, result);
  }
}

const _batchMarker = "V9m!T7#q2fH@x1Lz*8YwK0^g4";

extension BatchMessage on Message {
  (List<String> batch, bool isBatch, int batchCount, int? selectedBatch) get batchInfo {
    final decodedInfo = content.split(_batchMarker);
    if (decodedInfo.length == 1) {
      return ([content], false, 0, 0);
    }
    final dataCount = decodedInfo.length;
    final batch = decodedInfo.sublist(0, dataCount - 1);
    int? selectedBatch = int.tryParse(decodedInfo.last);
    if (selectedBatch != null && selectedBatch < 0) selectedBatch = null;
    return (batch, true, dataCount - 1, selectedBatch);
  }
}
