import 'dart:io';

import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zone/func/extensions/num.dart';
import 'package:zone/gen/l10n.dart';

/// Opens the given folder path in the system file manager (or default handler for directory URIs).
Future<void> openFolder(
  String? path, {
  void Function(String)? onInfoMessage,
}) async {
  final swAll = Stopwatch()..start();

  void log(String msg) {
    final t = swAll.elapsedMilliseconds.toString().padLeft(5, ' ');
    onInfoMessage?.call('[$t ms] $msg');
  }

  String normalizeWindowsPath(String p) {
    var s = p.trim();
    s = s.replaceAll('/', r'\');

    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      s = s.substring(1, s.length - 1);
    }

    if (s.endsWith(r'\')) {
      final isDriveRoot = RegExp(r'^[a-zA-Z]:\\$').hasMatch(s);
      final isUncLikeRoot = s.startsWith(r'\\') && s.split(r'\').where((e) => e.isNotEmpty).length <= 2;
      if (!isDriveRoot && !isUncLikeRoot) {
        s = s.substring(0, s.length - 1);
      }
    }
    return s;
  }

  Future<bool> launchExplorer(String p) async {
    final sw = Stopwatch()..start();
    log('launch explorer.exe, path="$p"');
    try {
      await Process.start('explorer.exe', <String>[p], runInShell: true);
      log('explorer.exe started OK elapsed=${sw.elapsedMilliseconds}ms');
      return true;
    } catch (e, st) {
      qqe("explorer.exe start failed: $e");
      log('explorer.exe START ERROR after ${sw.elapsedMilliseconds}ms: $e');
      log('stack: $st');
      Sentry.captureException(e, stackTrace: st);
      return false;
    }
  }

  try {
    log('openFolder() called. raw path="$path" platform=${Platform.operatingSystem}');
    if (path == null) {
      final msg = S.current.open_folder_path_is_null;
      log('ERROR: path is null');
      Alert.warning(msg);
      Sentry.captureException(Exception(msg), stackTrace: StackTrace.current);
      return;
    }

    final fixedPath = Platform.isWindows ? normalizeWindowsPath(path) : path.trim();
    log('fixedPath="$fixedPath"');

    final dir = Directory(fixedPath);
    final exists = await dir.exists();
    log('dir.exists=$exists');

    if (!exists) {
      log('Directory does not exist, creating (recursive=true)...');
      try {
        Alert.info(S.current.open_folder_creating_empty);
        await dir.create(recursive: true);
        1000.msLater.then((_) {
          Alert.info(S.current.open_folder_created_success);
        });
        log('Directory created OK');
      } catch (e, st) {
        qqe("Failed to create empty folder: $e");
        log('ERROR: Failed to create directory: $e');
        log('stack: $st');
        Alert.error(S.current.open_folder_create_failed(e.toString()));
        Sentry.captureException(e, stackTrace: st);
        return;
      }
    }

    if (Platform.isWindows) {
      final ok = await launchExplorer(fixedPath);
      if (!ok) {
        Alert.error("Failed to open folder: explorer failed");
      }
      return;
    }

    await launchUrl(Uri.directory(fixedPath));
  } catch (e, st) {
    qqe("openFolder fatal error: $e");
    log('FATAL ERROR: $e');
    log('stack: $st');
    Sentry.captureException(e, stackTrace: st);
    Alert.error(e.toString());
  } finally {
    swAll.stop();
  }
}
