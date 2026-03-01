// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/model/message_type.dart';
import 'package:zone/model/ref_info.dart';
import 'package:zone/model/sampler_and_penalty_param.dart';

@immutable
final class Message extends Equatable {
  /// 消息创建时间, 单位: 毫秒
  final int id;
  final String content;
  final bool isMine;
  final bool changing;
  final MessageType type;

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

  final String? modelName;
  final String? runningMode;
  final String? rawDecodeParams;

  const Message({
    required this.id,
    required this.content,
    required this.isMine,
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
    this.modelName,
    this.runningMode,
    this.rawDecodeParams,
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
    modelName,
    runningMode,
    rawDecodeParams,
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
      paused: json["paused"] as bool,
      ttsTarget: json["ttsTarget"] as String?,
      ttsSpeakerName: json["ttsSpeakerName"] as String?,
      ttsSourceAudioPath: json["ttsSourceAudioPath"] as String?,
      ttsInstruction: json["ttsInstruction"] as String?,
      isSensitive: json["isSensitive"] as bool,
      modelName: json["modelName"] as String?,
      runningMode: json["runningMode"] as String?,
      rawDecodeParams: json["rawDecodeParams"] as String?,
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
      "modelName": modelName,
      "runningMode": runningMode,
      "rawDecodeParams": rawDecodeParams,
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
    String? modelName,
    String? runningMode,
    String? rawDecodeParams,
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
      paused: paused ?? this.paused,
      ttsTarget: ttsTarget ?? this.ttsTarget,
      ttsSpeakerName: ttsSpeakerName ?? this.ttsSpeakerName,
      ttsSourceAudioPath: ttsSourceAudioPath ?? this.ttsSourceAudioPath,
      ttsInstruction: ttsInstruction ?? this.ttsInstruction,
      isSensitive: isSensitive ?? this.isSensitive,
      modelName: modelName ?? this.modelName,
      runningMode: runningMode ?? this.runningMode,
      rawDecodeParams: rawDecodeParams ?? this.rawDecodeParams,
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
  modelName: $modelName,
  runningMode: $runningMode,
  rawDecodeParams: $rawDecodeParams,
)""";
  }
}

extension MessageX on Message {
  bool get isReasoning => content.startsWith("<think>");

  int get createAtInMS => id;

  bool get isCotFormat => content.startsWith("<think>");

  bool get containsCotEndMark => content.contains("</think>");

  /// Append web search reference text behind of the user input content
  String getContentForHistoryWithRef(RefInfo? reference) {
    final contentForHistory = _getContentForHistory();
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

  String _getContentForHistory({bool appendThinkTagInThinkingTagIsEmpty = false}) {
    if (isMine) return contentAndTails.first + contentAndTails.last;
    if (!isReasoning) return content;
    if (!isCotFormat) return content;
    if (!containsCotEndMark) return content;
    if (paused) return content;
    final (cotContent, cotResult) = _getCotContentAndResult(
      appendThinkTagInThinkingTagIsEmpty: appendThinkTagInThinkingTagIsEmpty,
    );
    return cotResult;
  }

  String getHistoryContent() {
    if (!isReasoning) return content;
    if (!isCotFormat) return content;
    if (!containsCotEndMark) return content;
    if (paused) return content;
    final (cotContent, cotResult) = _getCotContentAndResult(
      appendThinkTagInThinkingTagIsEmpty: true,
    );
    if (cotResult.length <= 200) return content;
    return cotResult;
  }

  (String cotContent, String cotResult) _getCotContentAndResult({bool appendThinkTagInThinkingTagIsEmpty = false}) {
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

extension BatchMessage on Message {
  (List<String> batch, bool isBatch, int batchCount, int? selectedBatch) get batchInfo => getBatchInfo(content);

  List<String> get contentAndTails => content.split(Config.userMsgModifierSep);

  // TODO: 应该作为 msg 的内存值, 不要在 Build 方法中调用, 如果 msg 没有这个值, 调用并解析, 如果 msg 这个值不为空, 直接取值

  // TODO: @wangce 检查一下什么时候这个方法会被传递空值
  List<SamplerAndPenaltyParam> get parsedDecodeParams => SamplerAndPenaltyParamWithString.fromRawDecodeParams(rawDecodeParams ?? "");
}
