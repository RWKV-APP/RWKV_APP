import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/reference.dart';

enum MessageType {
  text,
  userImage,
  userTTS,
  ttsGeneration,
  @Deprecated("Xuan 说 RWKV-See 不添加 Audio QA 功能")
  userAudio,
}

final class RefInfo {
  final List<Reference> list;
  final bool enable;
  final String error;

  // 1 web search, 2 rag
  final int source;

  const RefInfo({
    required this.list,
    required this.enable,
    required this.error,
    required this.source,
  });

  factory RefInfo.empty() => const RefInfo(list: [], enable: false, error: "", source: 0);

  factory RefInfo.deserialize(String? json) => json == null || json.isEmpty ? RefInfo.empty() : RefInfo.fromJson(jsonDecode(json));

  factory RefInfo.fromJson(dynamic json) {
    if (json == null) return RefInfo.empty();
    try {
      return RefInfo(
        source: json["source"] ?? 0,
        list: (json["list"] as Iterable).map((e) => Reference.fromJson(e)).toList(),
        enable: json["enable"] as bool,
        error: json["error"] as String,
      );
    } catch (e) {
      qqe(e);
      return RefInfo.empty();
    }
  }

  String toLlmReferenceText() {
    return list.map((e) => e.summary).join("\n");
  }

  String serialize() => jsonEncode(toJson());

  Map<String, dynamic> toJson() {
    return {
      "list": list.map((e) => e.toJson()).toList(),
      "enable": enable,
      "source": source,
      "error": error,
    };
  }

  RefInfo copyWith({
    List<Reference>? list,
    bool? enable,
    String? error,
    int? source,
  }) {
    return RefInfo(
      source: source ?? this.source,
      list: list ?? this.list,
      enable: enable ?? this.enable,
      error: error ?? this.error,
    );
  }
}

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

  bool get ttsHasContent => ttsFilePaths?.isNotEmpty ?? false;

  bool get ttsIsDone => (ttsOverallProgress ?? 0.0) >= 1.0;

  int get createAtInMS => id;

  const Message({
    required this.id,
    required this.content,
    required this.isMine,
    required this.isReasoning,
    required this.paused,
    this.reference = const RefInfo(list: [], enable: false, error: '', source: 0),
    this.changing = false,
    this.type = MessageType.text,
    this.imageUrl,
    this.audioUrl,
    this.audioLength,
    this.ttsTarget,
    this.ttsSpeakerName,
    this.ttsSourceAudioPath,
    this.ttsInstruction,
    this.ttsCFMSteps,
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
    ttsCFMSteps,
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
      ttsCFMSteps: json["ttsCFMSteps"] as int?,
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
      "ttsCFMSteps": ttsCFMSteps,
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
    int? ttsCFMSteps,
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
      ttsCFMSteps: ttsCFMSteps ?? this.ttsCFMSteps,
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
  ttsCFMSteps: $ttsCFMSteps,
  isSensitive: $isSensitive,
  ttsOverallProgress: $ttsOverallProgress,
  ttsPerWavProgress: $ttsPerWavProgress,
  ttsFilePaths: $ttsFilePaths,
  modelName: $modelName,
  runningMode: $runningMode,
)""";
  }

  bool get isCotFormat => content.startsWith("<think>");

  bool get containsCotEndMark => content.contains("</think>");

  /// Append web search reference text behind of the user input content
  String getContentForHistoryWithRef(RefInfo? reference) {
    final content = getContentForHistory();
    if (!isMine || reference == null) {
      return content;
    }
    final ref = reference.enable ? reference.toLlmReferenceText() : null;
    qqq("$content, ${ref?.substring(0, 30)}");
    if (ref == null) {
      return content;
    } else {
      return "$ref\n$content";
    }
  }

  String getContentForHistory() {
    if (!isReasoning) return content;
    if (!isCotFormat) return content;
    if (!containsCotEndMark) return content;
    if (paused) return content;
    final (cotContent, cotResult) = cotContentAndResult;
    return cotResult;
  }

  (String cotContent, String cotResult) get cotContentAndResult {
    if (!isCotFormat) {
      return ("", "");
    }
    if (!containsCotEndMark) {
      return (content.substring(7), "");
    }

    final endIndex = content.indexOf("</think>");
    final _content = content.substring(7, endIndex);
    String _result = "";
    if (endIndex + 9 < content.length) {
      _result = content.substring(endIndex + 9);
    }

    return (_content, _result);
  }
}
