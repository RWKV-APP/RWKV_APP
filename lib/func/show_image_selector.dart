import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart';
import 'package:zone/route/router.dart';
import 'package:zone/state/p.dart';

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
    ],
  );
  qqq("result: $result");
  if (result == null) return;
  final ImagePicker picker = ImagePicker();
  late final XFile? image;
  if (result == "take_photo") {
    image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    final imagePath = image.path;
    qqq("imagePath: $imagePath");
  } else if (result == "select_from_library") {
    image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final imagePath = image.path;
    qqq("imagePath: $imagePath");
  } else {
    throw Exception("Invalid result: $result");
  }
  P.world.imagePath.q = image.path;
  P.chat.clearMessages();
  P.rwkv.clearStates();
  P.rwkv.setImagePath(path: image.path);
  P.chat.send("", type: MessageType.userImage, imageUrl: image.path);
}
