import 'package:local_web_search/src/models/search_engine.dart';

enum SearchEngineAvailabilityStatus {
  unknown,
  checking,
  available,
  unavailable,
}

class SearchEngineAvailability {
  final SearchEngine engine;
  final SearchEngineAvailabilityStatus status;
  final int? statusCode;
  final String? error;
  final DateTime? checkedAt;
  final Duration? elapsed;

  const SearchEngineAvailability({
    required this.engine,
    required this.status,
    this.statusCode,
    this.error,
    this.checkedAt,
    this.elapsed,
  });

  factory SearchEngineAvailability.unknown(SearchEngine engine) {
    return SearchEngineAvailability(engine: engine, status: .unknown);
  }

  factory SearchEngineAvailability.checking(SearchEngine engine) {
    return SearchEngineAvailability(engine: engine, status: .checking);
  }

  factory SearchEngineAvailability.available({
    required SearchEngine engine,
    required int statusCode,
    required Duration elapsed,
  }) {
    return SearchEngineAvailability(
      engine: engine,
      status: .available,
      statusCode: statusCode,
      checkedAt: DateTime.now(),
      elapsed: elapsed,
    );
  }

  factory SearchEngineAvailability.unavailable({
    required SearchEngine engine,
    int? statusCode,
    String? error,
    Duration? elapsed,
  }) {
    return SearchEngineAvailability(
      engine: engine,
      status: .unavailable,
      statusCode: statusCode,
      error: error,
      checkedAt: DateTime.now(),
      elapsed: elapsed,
    );
  }

  bool get isAvailable => status == .available;

  bool get isChecking => status == .checking;

  bool get isUnavailable => status == .unavailable;

  bool get canSearch => status == .available || status == .unknown;

  String get statusLabel {
    if (status == .available) return 'Available';
    if (status == .unavailable) return 'Unavailable';
    if (status == .checking) return 'Checking';
    return 'Unknown';
  }

  String get tooltipMessage {
    if (status == .available) {
      return '${engine.label} request is available.';
    }
    if (status == .checking) {
      return 'Checking ${engine.label} request availability.';
    }
    if (status == .unavailable) {
      final detail = error == null || error!.isEmpty ? '' : ' $error';
      return '当前请求不可用。$detail';
    }
    return '${engine.label} has not been checked yet. Search will try it directly; run diagnostics only when you want to test every engine.';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'engine': engine.toJson(),
      'status': status.name,
      'statusCode': statusCode,
      'error': error,
      'checkedAt': checkedAt?.toIso8601String(),
      'elapsedMs': elapsed?.inMilliseconds,
    };
  }
}
