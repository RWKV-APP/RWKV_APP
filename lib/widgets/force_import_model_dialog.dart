import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:zone/gen/l10n.dart';

Future<bool> showForceImportModelDialog(BuildContext context, String fileName) async {
  final s = S.of(context);
  final result = await showOkCancelAlertDialog(
    context: context,
    title: s.force_import_model_title,
    message: '$fileName\n\n${s.force_import_model_message}',
    okLabel: s.force_import,
    cancelLabel: s.cancel,
  );
  return result == OkCancelResult.ok;
}
