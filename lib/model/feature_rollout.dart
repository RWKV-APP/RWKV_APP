class FeatureRollout {
  final bool webSearch;
  final bool rag;

  const FeatureRollout({this.webSearch = false, this.rag = false});

  factory FeatureRollout.fromMap(dynamic json) {
    if (json == null) return const FeatureRollout();

    return FeatureRollout(
      webSearch: json['web_search'] ?? false,
      rag: json['rag'] ?? false,
    );
  }

  FeatureRollout merge(FeatureRollout other) {
    return FeatureRollout(
      webSearch: webSearch || other.webSearch,
      rag: rag || other.rag,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'web_search': webSearch,
      'rag': rag,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureRollout && runtimeType == other.runtimeType && webSearch == other.webSearch && rag == other.rag;

  @override
  int get hashCode => webSearch.hashCode ^ rag.hashCode;

  FeatureRollout copyWith({bool? webSearch, bool? rag}) {
    return FeatureRollout(
      webSearch: webSearch ?? this.webSearch,
      rag: rag ?? this.rag,
    );
  }
}
