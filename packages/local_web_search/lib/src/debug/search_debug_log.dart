// Flutter imports:
import 'package:flutter/foundation.dart';

const bool localWebSearchDebugLoggingEnabled =
    kDebugMode &&
    bool.fromEnvironment(
      'LOCAL_WEB_SEARCH_LOG_WEBVIEW_LOADS',
      defaultValue: false,
    );

void logLocalWebSearchDebug(String message) {
  if (!localWebSearchDebugLoggingEnabled) return;
  debugPrint(message);
}
