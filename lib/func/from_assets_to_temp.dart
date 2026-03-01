// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:halo/halo.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Project imports:
import 'package:zone/func/save_asset_to_file.dart';

Future<String> fromAssetsToTemp(String assetsPath, {String? targetPath}) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final finalPath = path.join(tempDir.path, targetPath ?? assetsPath);
    await saveAssetToFile(assetsPath, finalPath);
    return finalPath;
  } catch (e) {
    qqe("$e");
    if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
    return "";
  }
}
