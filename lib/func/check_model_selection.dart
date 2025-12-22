// ignore: unused_import

import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/model_selector.dart';

/// Return true if the model is selected
bool checkModelSelection({
  bool showAlert = true,
  bool showModelSelector = true,
  required DemoType preferredDemoType,
}) {
  final loadedModelsCount = P.rwkv.loadedModelsCount.q;

  if (loadedModelsCount == 0) {
    if (showAlert) Alert.info(S.current.please_load_model_first);
    if (showModelSelector) ModelSelector.show(preferredDemoType: preferredDemoType);
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
