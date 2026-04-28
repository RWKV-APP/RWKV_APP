// Package imports:
import 'package:equatable/equatable.dart';
import 'package:rwkv_mobile_flutter/rwkv_mobile_ffi.dart' as rwkv;

// Project imports:
import 'package:zone/gen/l10n.dart';

enum ResponseStyleRoute {
  jin,
  gu,
  mao,
  en,
  ja,
  yue
  ;

  String? get userPromptSuffix => switch (this) {
    jin => null,
    gu => " 请用文言文回答",
    mao => " 请扮演猫娘回答",
    en => " 请用英语回答",
    ja => " 请用日语回答",
    yue => " 请用香港粵語回答",
  };

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

  int get forceLang {
    switch (this) {
      case .en:
        return rwkv.FORCE_LANG_EN;
      case .jin:
      case .gu:
      case .mao:
      case .ja:
      case .yue:
        return rwkv.FORCE_LANG_NONE;
    }
  }
}

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

extension ResponseStyleRouteX on ResponseStyleRoute {
  static const ResponseStyleRoute defaultRoute = ResponseStyleRoute.jin;

  bool get isDefaultRoute {
    return this == defaultRoute;
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
    if (assistantMessage == null) {
      return nextHistory;
    }

    return <String>[
      ...nextHistory,
      assistantMessage,
    ];
  }
}

extension ResponseStyleStateButtonLabelX on ResponseStyleState {
  String buttonLabel({
    required String baseLabel,
    required String manyLabel,
  }) {
    final routes = enabledRoutesInOrder;
    if (routes.length == 1 && routes.first.isDefaultRoute) {
      return baseLabel;
    }
    if (routes.length >= 4) {
      return manyLabel;
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

  factory ResponseStyleState.all() {
    return const ResponseStyleState(enabledRoutes: ResponseStyleRoute.values);
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

  bool get hasAllRoutes => activeCount == ResponseStyleRoute.values.length;

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
