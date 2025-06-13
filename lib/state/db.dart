part of 'p.dart';

class _DB {
  late final db.AppDatabase _db;
}

/// Private methods
extension _$DB on _DB {
  FV _init() async {
    try {
      _db = db.AppDatabase();
    } catch (e) {
      qqe("Failed to open database");
      qqe(e);
    }
  }
}

/// Public methods
extension $DB on _DB {}
