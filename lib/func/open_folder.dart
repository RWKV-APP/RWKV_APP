import 'dart:io';

import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zone/func/extensions/num.dart';
import 'package:zone/gen/l10n.dart';

/// Opens the given folder path in the system file manager (or default handler for directory URIs).
Future<void> openFolder(String? path) async {
  if (path == null) {
    final msg = S.current.open_folder_path_is_null;
    Alert.warning(msg);
    Sentry.captureException(Exception(msg), stackTrace: StackTrace.current);
    return;
  }

  final dir = Directory(path);
  final exists = await dir.exists();

  if (!exists) {
    try {
      Alert.info(S.current.open_folder_creating_empty);
      qqw("Creating empty folder: $path");
      await dir.create(recursive: true);
      1000.msLater.then((_) {
        Alert.info(S.current.open_folder_created_success);
      });
    } catch (e) {
      qqe("Failed to create empty folder");
      qqe(e.toString());
      Alert.error(S.current.open_folder_create_failed(e.toString()));
      Sentry.captureException(e, stackTrace: StackTrace.current);
      return;
    }
  }

  await launchUrl(Uri.directory(path));
}
