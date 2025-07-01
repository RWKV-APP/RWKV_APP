class FeatureRollout {
  final bool webSearch;

  const FeatureRollout({this.webSearch = false});

  factory FeatureRollout.fromMap(dynamic json) {
    if (json == null) return const FeatureRollout();

    return FeatureRollout(
      webSearch: json['web_search'] ?? false,
    );
  }

  FeatureRollout merge(FeatureRollout other) {
    return FeatureRollout(
      webSearch: webSearch || other.webSearch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'web_search': webSearch,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FeatureRollout && runtimeType == other.runtimeType && webSearch == other.webSearch;

  @override
  int get hashCode => webSearch.hashCode;

  FeatureRollout copyWith({bool? webSearch}) {
    return FeatureRollout(
      webSearch: webSearch ?? this.webSearch,
    );
  }
}
