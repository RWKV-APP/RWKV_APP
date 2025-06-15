// ignore: unused_import

import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/model_selector.dart';

/// Return true if the model is selected
bool checkModelSelection({
  bool showAlert = true,
  bool showModelSelector = true,
}) {
  final currentModel = P.rwkv.currentModel.q;

  if (currentModel == null) {
    if (showAlert) Alert.info(S.current.please_load_model_first);
    if (showModelSelector) ModelSelector.show();
    return false;
  }

  final loaded = P.rwkv.loaded.q;

  if (!loaded) {
    if (showAlert) Alert.info(S.current.please_load_model_first);
    return false;
  }

  final loading = P.rwkv.loading.q;
  if (loading) {
    if (showAlert) Alert.info(S.current.please_wait_for_the_model_to_load);
    return false;
  }

  return true;
}
