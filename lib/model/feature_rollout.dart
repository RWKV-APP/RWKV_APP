class FeatureRollout {
  final bool webSearch;
  final bool parallelAnswering;

  const FeatureRollout({this.webSearch = false, this.parallelAnswering = false});

  factory FeatureRollout.fromMap(dynamic json) {
    if (json == null) return const FeatureRollout();

    return FeatureRollout(
      webSearch: json['web_search'] ?? false,
      parallelAnswering: json['parallel_answering'] ?? false,
    );
  }

  FeatureRollout merge(FeatureRollout other) {
    return FeatureRollout(
      webSearch: webSearch || other.webSearch,
      parallelAnswering: parallelAnswering || other.parallelAnswering,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'web_search': webSearch,
      'parallel_answering': parallelAnswering,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureRollout &&
          runtimeType == other.runtimeType &&
          webSearch == other.webSearch &&
          parallelAnswering == other.parallelAnswering;

  @override
  int get hashCode => Object.hash(webSearch, parallelAnswering);

  FeatureRollout copyWith({bool? webSearch, bool? parallelAnswering}) {
    return FeatureRollout(
      webSearch: webSearch ?? this.webSearch,
      parallelAnswering: parallelAnswering ?? this.parallelAnswering,
    );
  }
}
