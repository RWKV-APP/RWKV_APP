// Dart imports:
import 'dart:convert';

// Project imports:
import 'package:zone/func/debug_trace.dart';
import 'package:zone/model/reference.dart';
import 'package:zone/model/web_search_trace.dart';

final class RefInfo {
  final List<Reference> list;
  final bool enable;
  final String error;
  final WebSearchTrace? trace;

  const RefInfo({
    required this.list,
    required this.enable,
    required this.error,
    this.trace,
  });

  factory RefInfo.empty() => const RefInfo(list: [], enable: false, error: "");

  factory RefInfo.deserialize(String? json) => json == null || json.isEmpty ? RefInfo.empty() : RefInfo.fromJson(jsonDecode(json));

  factory RefInfo.fromJson(dynamic json) {
    if (json == null) return RefInfo.empty();
    try {
      return RefInfo(
        list: (json["list"] as Iterable).map((e) => Reference.fromJson(e)).toList(),
        enable: json["enable"] as bool,
        error: json["error"] as String,
        trace: json["trace"] == null ? null : WebSearchTrace.fromJson(json["trace"]),
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
      "error": error,
      if (trace != null) "trace": trace!.toJson(),
    };
  }

  RefInfo copyWith({
    List<Reference>? list,
    bool? enable,
    String? error,
    WebSearchTrace? trace,
    bool clearTrace = false,
  }) {
    return RefInfo(
      list: list ?? this.list,
      enable: enable ?? this.enable,
      error: error ?? this.error,
      trace: clearTrace ? null : (trace ?? this.trace),
    );
  }
}
