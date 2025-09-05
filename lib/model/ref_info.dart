import 'dart:convert';
import 'package:halo/halo.dart';
import 'package:zone/model/reference.dart';

final class RefInfo {
  final List<Reference> list;
  final bool enable;
  final String error;

  const RefInfo({required this.list, required this.enable, required this.error});

  factory RefInfo.empty() => const RefInfo(list: [], enable: false, error: "");

  factory RefInfo.deserialize(String? json) => json == null || json.isEmpty ? RefInfo.empty() : RefInfo.fromJson(jsonDecode(json));

  factory RefInfo.fromJson(dynamic json) {
    if (json == null) return RefInfo.empty();
    try {
      return RefInfo(
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
      "error": error,
    };
  }

  RefInfo copyWith({
    List<Reference>? list,
    bool? enable,
    String? error,
  }) {
    return RefInfo(
      list: list ?? this.list,
      enable: enable ?? this.enable,
      error: error ?? this.error,
    );
  }
}
