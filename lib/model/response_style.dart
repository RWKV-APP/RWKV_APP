// Package imports:
import 'package:equatable/equatable.dart';

enum ResponseStyleRoute { jin, gu, mao }

ResponseStyleRoute? responseStyleRouteFromLabel(String label) {
  switch (label) {
    case "今":
      return .jin;
    case "古":
      return .gu;
    case "猫":
      return .mao;
    default:
      return null;
  }
}

extension ResponseStyleRouteX on ResponseStyleRoute {
  String get label {
    switch (this) {
      case .jin:
        return "今";
      case .gu:
        return "古";
      case .mao:
        return "猫";
    }
  }
}

extension ResponseStyleStateButtonLabelX on ResponseStyleState {
  String buttonLabel({
    required String baseLabel,
    required String jinLabel,
    required String guLabel,
    required String maoLabel,
  }) {
    switch ((jinEnabled, guEnabled, maoEnabled)) {
      case (true, false, false):
        return baseLabel;
      case (false, true, false):
        return "$baseLabel：$guLabel";
      case (false, false, true):
        return "$baseLabel：$maoLabel";
      case (true, true, false):
        return "$guLabel$jinLabel";
      case (true, false, true):
        return "$jinLabel|$maoLabel";
      case (false, true, true):
        return "$guLabel|$maoLabel";
      case (true, true, true):
        return "$guLabel|$jinLabel|$maoLabel";
      case (false, false, false):
        return baseLabel;
    }
  }
}

final class ResponseStyleState extends Equatable {
  final bool jinEnabled;
  final bool guEnabled;
  final bool maoEnabled;

  const ResponseStyleState({
    this.jinEnabled = true,
    this.guEnabled = false,
    this.maoEnabled = false,
  });

  bool enabledFor(ResponseStyleRoute route) {
    switch (route) {
      case .jin:
        return jinEnabled;
      case .gu:
        return guEnabled;
      case .mao:
        return maoEnabled;
    }
  }

  List<ResponseStyleRoute> get enabledRoutesInOrder {
    return <ResponseStyleRoute>[
      if (jinEnabled) .jin,
      if (guEnabled) .gu,
      if (maoEnabled) .mao,
    ];
  }

  List<String> get enabledLabelsInOrder {
    return enabledRoutesInOrder.map((ResponseStyleRoute route) => route.label).toList();
  }

  int get activeCount => enabledRoutesInOrder.length;

  bool get isDefault => jinEnabled && !guEnabled && !maoEnabled;

  bool canToggle(ResponseStyleRoute route, bool enabled) {
    if (enabled) {
      return true;
    }
    if (!enabledFor(route)) {
      return true;
    }
    return activeCount > 1;
  }

  ResponseStyleState copyWith({
    bool? jinEnabled,
    bool? guEnabled,
    bool? maoEnabled,
  }) {
    return ResponseStyleState(
      jinEnabled: jinEnabled ?? this.jinEnabled,
      guEnabled: guEnabled ?? this.guEnabled,
      maoEnabled: maoEnabled ?? this.maoEnabled,
    );
  }

  ResponseStyleState copyWithRoute(ResponseStyleRoute route, bool enabled) {
    switch (route) {
      case .jin:
        return copyWith(jinEnabled: enabled);
      case .gu:
        return copyWith(guEnabled: enabled);
      case .mao:
        return copyWith(maoEnabled: enabled);
    }
  }

  @override
  List<Object?> get props => <Object?>[
    jinEnabled,
    guEnabled,
    maoEnabled,
  ];
}
