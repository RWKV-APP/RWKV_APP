// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/router.dart';

enum _Actions {
  takePhoto,
  selectFromLibrary,
  selectFromFile,
}

Future<String?> showImageSelector() async {
  final result = await showModalActionSheet<_Actions>(
    context: getContext()!,
    title: S.current.select_image,
    message: S.current.please_select_an_image_from_the_following_options,
    cancelLabel: S.current.cancel,
    actions: [
      if (Platform.isAndroid || Platform.isIOS)
        SheetAction(
          label: S.current.take_photo,
          icon: Icons.camera,
          key: _Actions.takePhoto,
        ),
      SheetAction(
        label: S.current.select_from_library,
        icon: Icons.photo,
        key: _Actions.selectFromLibrary,
      ),
      SheetAction(
        label: S.current.select_from_file,
        icon: Icons.file_open,
        key: _Actions.selectFromFile,
      ),
    ],
  );
  if (result == null) return null;
  final picker = ImagePicker();
  late final String? imagePath;
  switch (result) {
    case _Actions.takePhoto:
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return null;
      imagePath = image.path;
      break;
    case _Actions.selectFromLibrary:
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      imagePath = image.path;
      break;
    case _Actions.selectFromFile:
      final result = await FilePicker.pickFiles(type: .image);
      if (result == null) return null;
      imagePath = result.files.first.path;
      break;
  }
  return imagePath;
}
