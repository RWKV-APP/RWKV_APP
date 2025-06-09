import 'dart:io';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:halo/halo.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sentry_flutter/sentry_flutter.dart';

Future<String> fromAssetsToTemp(String assetsPath, {String? targetPath}) async {
  try {
    final data = await rootBundle.load(assetsPath);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(path.join(tempDir.path, targetPath ?? assetsPath));
    await tempFile.create(recursive: true);
    await tempFile.writeAsBytes(data.buffer.asUint8List());
    return tempFile.path;
  } catch (e) {
    qqe("$e");
    if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
    return "";
  }
}
