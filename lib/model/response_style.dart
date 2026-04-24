// Package imports:
import 'package:equatable/equatable.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';

enum ResponseStyleRoute { jin, gu, mao, en, ja, yue }

List<ResponseStyleRoute> normalizeResponseStyleRoutes(
  Iterable<ResponseStyleRoute> routes,
) {
  final routeSet = routes.toSet();
  return ResponseStyleRoute.values.where(routeSet.contains).toList(growable: false);
}

ResponseStyleRoute? responseStyleRouteFromLabel(String label) {
  final normalizedLabel = label.trim();
  for (final route in ResponseStyleRoute.values) {
    if (route.label == normalizedLabel) {
      return route;
    }
  }
  return null;
}

bool responseStyleBatchRequiresAssistantPrefixes({
  required Iterable<ResponseStyleRoute> routes,
  Map<ResponseStyleRoute, String?>? assistantPrefixes,
}) {
  for (final route in routes) {
    if (route.defaultAssistantPrefix != null) {
      return true;
    }
  }

  if (assistantPrefixes == null) {
    return false;
  }

  for (final prefix in assistantPrefixes.values) {
    if (prefix != null) {
      return true;
    }
  }

  return false;
}

extension ResponseStyleRouteX on ResponseStyleRoute {
  static const ResponseStyleRoute defaultRoute = ResponseStyleRoute.jin;

  bool get isDefaultRoute {
    return this == defaultRoute;
  }

  String get label {
    switch (this) {
      case .jin:
        return "今";
      case .gu:
        return "古";
      case .mao:
        return "猫";
      case .en:
        return "英";
      case .ja:
        return "日";
      case .yue:
        return "粤";
    }
  }

  String? get userPromptSuffix {
    switch (this) {
      case .jin:
        return null;
      case .gu:
        return " 请用文言文回答。";
      case .mao:
        return " 请用可爱的猫咪口吻回答，多使用“喵”，保持猫风格。";
      case .en:
        return " Use English only. Direct answer. No preface. Never speak in Chinese. Do not use any Chinese characters.";
      case .ja:
        return " 日本語のみ。前置きなしで直接回答。";
      case .yue:
        return " 全程香港書面粵語。唔好開場白，直接答。";
    }
  }

  String? get defaultAssistantPrefix {
    switch (this) {
      case .jin:
      case .gu:
      case .en:
      case .ja:
      case .yue:
        return null;
      case .mao:
        return "<think>喵";
    }
  }

  String detail(S s) {
    switch (this) {
      case .jin:
        return s.response_style_route_jin_detail;
      case .gu:
        return s.response_style_route_gu_detail;
      case .mao:
        return s.response_style_route_mao_detail;
      case .en:
        return s.response_style_route_en_detail;
      case .ja:
        return s.response_style_route_ja_detail;
      case .yue:
        return s.response_style_route_yue_detail;
    }
  }

  List<String> buildHistory({
    required List<String> history,
    String? assistantMessage,
  }) {
    final nextHistory = _applySuffixToLatestUserMessage(
      history,
      userPromptSuffix,
    );
    final resolvedAssistantMessage = resolveAssistantMessage(assistantMessage);
    if (resolvedAssistantMessage == null) {
      return nextHistory;
    }

    return <String>[
      ...nextHistory,
      resolvedAssistantMessage,
    ];
  }

  String? resolveAssistantMessage(String? assistantMessage) {
    return assistantMessage ?? defaultAssistantPrefix;
  }

  String? batchAssistantPrefix({
    required bool batchRequiresAssistantPrefixes,
    String? assistantPrefix,
  }) {
    if (assistantPrefix != null) {
      return assistantPrefix;
    }

    final defaultAssistantPrefix = this.defaultAssistantPrefix;
    if (defaultAssistantPrefix != null) {
      return defaultAssistantPrefix;
    }
    if (batchRequiresAssistantPrefixes) {
      return "";
    }
    return null;
  }

  String? restoreAssistantPrefix(String? rawValue) {
    final defaultAssistantPrefix = this.defaultAssistantPrefix;
    if (defaultAssistantPrefix == null) {
      return rawValue;
    }
    if (rawValue == null || rawValue.isEmpty) {
      return defaultAssistantPrefix;
    }
    return rawValue;
  }
}

extension ResponseStyleStateButtonLabelX on ResponseStyleState {
  String buttonLabel({
    required String baseLabel,
  }) {
    final routes = enabledRoutesInOrder;
    if (routes.length == 1 && routes.first.isDefaultRoute) {
      return baseLabel;
    }

    final joinedLabels = routes.map((route) => route.label).join("|");
    if (joinedLabels.isEmpty) {
      return baseLabel;
    }
    if (routes.length == 1) {
      return "$baseLabel：$joinedLabels";
    }
    return joinedLabels;
  }
}

final class ResponseStyleState extends Equatable {
  final List<ResponseStyleRoute> enabledRoutes;

  const ResponseStyleState({
    this.enabledRoutes = const <ResponseStyleRoute>[ResponseStyleRoute.jin],
  });

  factory ResponseStyleState.only(ResponseStyleRoute route) {
    return ResponseStyleState(enabledRoutes: <ResponseStyleRoute>[route]);
  }

  bool enabledFor(ResponseStyleRoute route) {
    return enabledRoutesInOrder.contains(route);
  }

  List<ResponseStyleRoute> get enabledRoutesInOrder {
    return normalizeResponseStyleRoutes(enabledRoutes);
  }

  List<String> get enabledLabelsInOrder {
    return enabledRoutesInOrder.map((route) => route.label).toList(growable: false);
  }

  int get activeCount => enabledRoutesInOrder.length;

  bool get isDefault {
    final routes = enabledRoutesInOrder;
    if (routes.length != 1) {
      return false;
    }
    return routes.first.isDefaultRoute;
  }

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
    List<ResponseStyleRoute>? enabledRoutes,
  }) {
    return ResponseStyleState(
      enabledRoutes: enabledRoutes ?? enabledRoutesInOrder,
    );
  }

  ResponseStyleState copyWithRoute(ResponseStyleRoute route, bool enabled) {
    final nextRoutes = enabledRoutesInOrder.toSet();
    if (enabled) {
      nextRoutes.add(route);
    } else {
      nextRoutes.remove(route);
    }

    return copyWith(enabledRoutes: normalizeResponseStyleRoutes(nextRoutes));
  }

  @override
  List<Object?> get props => <Object?>[
    enabledRoutesInOrder,
  ];
}

List<String> _applySuffixToLatestUserMessage(
  List<String> history,
  String? suffix,
) {
  final next = <String>[...history];
  if (suffix == null || suffix.isEmpty) {
    return next;
  }
  if (next.isEmpty) {
    return next;
  }
  if (next.length.isEven) {
    return next;
  }

  next[next.length - 1] = "${next.last}$suffix";
  return next;
}
