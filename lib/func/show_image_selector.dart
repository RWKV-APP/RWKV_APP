import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';

Future<void> showImageSelector() async {
  qq;
  if (P.chat.focusNode.hasFocus) {
    P.chat.focusNode.unfocus();
    return;
  }
  final result = await showModalActionSheet(
    context: getContext()!,
    title: S.current.select_image,
    message: S.current.please_select_an_image_from_the_following_options,
    cancelLabel: S.current.cancel,
    actions: [
      if (Platform.isAndroid || Platform.isIOS)
        SheetAction(
          label: S.current.take_photo,
          icon: Icons.camera,
          key: "take_photo",
        ),
      SheetAction(
        label: S.current.select_from_library,
        icon: Icons.photo,
        key: "select_from_library",
      ),
      SheetAction(
        label: S.current.select_from_file,
        icon: Icons.file_open,
        key: "select_from_file",
      ),
    ],
  );
  qqq("result: $result");
  if (result == null) return;
  final ImagePicker picker = ImagePicker();
  late final String? imagePath;
  if (result == "take_photo") {
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    imagePath = image.path;
  } else if (result == "select_from_library") {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    imagePath = image.path;
  } else if (result == "select_from_file") {
    final result = await FilePicker.platform.pickFiles(type: .image);
    if (result == null) return;
    imagePath = result.files.first.path;
  } else {
    throw Exception("Invalid result: $result");
  }
  if (imagePath == null) {
    Alert.warning("No image selected");
    return;
  }
  P.see.imagePath.q = imagePath;
}
