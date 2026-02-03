import 'dart:math';

/// Format bytes to human readable string, e.g. "1.2 GB"
String formatBytes(int bytes) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  final i = (log(bytes) / log(1024)).floor();
  return ((bytes / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
}
