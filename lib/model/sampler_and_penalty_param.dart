import 'package:equatable/equatable.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/decode_param_type.dart';

extension SamplerAndPenaltyParamWithString on List<SamplerAndPenaltyParam> {
  String get rawDecodeParams {
    final List<String> res = [];
    for (var i = 0; i < length; i++) {
      res.add(
        "${this[i].temperature}, ${this[i].topP}, ${this[i].presencePenalty}, ${this[i].frequencyPenalty}, ${this[i].penaltyDecay}",
      );
    }
    return res.join("|");
  }

  static List<SamplerAndPenaltyParam> fromRawDecodeParams(String rawDecodeParams) {
    final List<SamplerAndPenaltyParam> res = [];
    final List<String> params = rawDecodeParams.split("|").where((e) => e.isNotEmpty).toList();
    for (var i = 0; i < params.length; i++) {
      final param = params[i].split(",");
      final temperature = double.parse(param[0]);
      final topP = double.parse(param[1]);
      final presencePenalty = double.parse(param[2]);
      final frequencyPenalty = double.parse(param[3]);
      final penaltyDecay = double.parse(param[4]);
      res.add(
        SamplerAndPenaltyParam(
          temperature: temperature,
          topP: topP,
          presencePenalty: presencePenalty,
          frequencyPenalty: frequencyPenalty,
          penaltyDecay: penaltyDecay,
        ),
      );
    }
    return res;
  }
}

class SamplerAndPenaltyParam extends Equatable {
  final double temperature;
  final double topP;
  final double presencePenalty;
  final double frequencyPenalty;
  final double penaltyDecay;

  const SamplerAndPenaltyParam({
    required this.temperature,
    required this.topP,
    required this.presencePenalty,
    required this.frequencyPenalty,
    required this.penaltyDecay,
  });

  @override
  List<Object?> get props => [
    temperature,
    topP,
    presencePenalty,
    frequencyPenalty,
    penaltyDecay,
  ];

  DecodeParamType get decodeParamType {
    final temperature = double.parse(this.temperature.toStringAsFixed(1));
    final topP = double.parse(this.topP.toStringAsFixed(2));
    final presencePenalty = double.parse(this.presencePenalty.toStringAsFixed(1));
    final frequencyPenalty = double.parse(this.frequencyPenalty.toStringAsFixed(1));
    final penaltyDecay = double.parse(this.penaltyDecay.toStringAsFixed(3));
    return DecodeParamType.fromValue(
      temperature: temperature,
      topP: topP,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      penaltyDecay: penaltyDecay,
    );
  }

  static SamplerAndPenaltyParam fromDecodeParamType(DecodeParamType type) {
    return SamplerAndPenaltyParam(
      temperature: type.temperature,
      topP: type.topP,
      presencePenalty: type.presencePenalty,
      frequencyPenalty: type.frequencyPenalty,
      penaltyDecay: type.penaltyDecay,
    );
  }

  bool tolerantEquals(Object other) {
    return other is SamplerAndPenaltyParam &&
        (temperature - other.temperature).abs() < 0.01 &&
        (topP - other.topP).abs() < 0.01 &&
        (presencePenalty - other.presencePenalty).abs() < 0.01 &&
        (frequencyPenalty - other.frequencyPenalty).abs() < 0.01 &&
        (penaltyDecay - other.penaltyDecay).abs() < 0.01;
  }

  String get displayName {
    switch (decodeParamType) {
      case DecodeParamType.defaults:
        return S.current.decode_param_default_;
      case DecodeParamType.creative:
        return S.current.decode_param_creative;
      case DecodeParamType.conservative:
        return S.current.decode_param_conservative;
      case DecodeParamType.fixed:
        return S.current.decode_param_fixed;
      case DecodeParamType.comprehensive:
        return S.current.decode_param_comprehensive;
      case DecodeParamType.custom:
        return S.current.decode_param_custom;
    }
  }

  bool get isCustom => decodeParamType == DecodeParamType.custom;

  SamplerAndPenaltyParam copyWith({
    double? temperature,
    double? topP,
    double? presencePenalty,
    double? frequencyPenalty,
    double? penaltyDecay,
  }) {
    return SamplerAndPenaltyParam(
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      penaltyDecay: penaltyDecay ?? this.penaltyDecay,
    );
  }
}
