import 'package:flutter/material.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/page/completion/_suggestions_dialog.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/arguments_panel.dart';
import 'package:zone/widgets/chat/batch_completion_settings_panel.dart';
import 'package:zone/widgets/model_selector.dart';

import '_completion_state.dart';

class CompletionController {
  static final current = CompletionController._();

  CompletionController._();

  void dispose() {
    P.rwkv.stop();
  }

  void init() {
    qqq('completion controller init');
    CompletionState.controllerInput.q = TextEditingController()
      ..addListener(() {
        final empty = CompletionState.controllerInput.q?.text.isEmpty ?? true;
        if (empty == CompletionState.showSuggestionButton.q) return;
        if (CompletionState.items.q.isNotEmpty) return;
        CompletionState.showSuggestionButton.q = empty;
      });
    CompletionState.batchSettings.q = BatchCompletionSettings.initial();
    CompletionState.controllerInputScroll.q = ScrollController();
    CompletionState.showSuggestionButton.q = true;
    CompletionState.generating.q = false;
    CompletionState.generateButtonEnabled.q = true;
    CompletionState.items.q = [];
    if (CompletionState.model.q == null) {
      onModelSelectTap();
    }
  }

  void onStopTap() async {
    CompletionState.generateButtonEnabled.q = false;
    P.rwkv.stop();
    await Future.delayed(Duration(seconds: 1));
    CompletionState.generating.q = false;
    CompletionState.generateButtonEnabled.q = true;
  }

  void onCompletionTap({bool regenerate = false}) async {
    final input = regenerate ? '' : (CompletionState.controllerInput.q?.text ?? '');
    if (!regenerate && input.isEmpty) {
      Alert.warning('Please enter some text first');
      return;
    }

    CompletionState.generating.q = true;
    CompletionState.generateButtonEnabled.q = false;

    final batchSetting = CompletionState.batchSettings.q;
    final items = CompletionState.items.q;
    final prompt = items.map((e) => e.content).join() + input;

    qqq('completion:$prompt');

    try {
      final batch = batchSetting.enabled ? batchSetting.batchCount : 1;
      await P.rwkv.clearStates();
      final stream = P.rwkv
          .completion(prompt, batchSize: batch)
          .takeWhile((e) => e.eosFound.any((e) => !e) && CompletionState.generating.q);
      bool firstOutput = true;
      final trimLen = prompt.length;
      await for (final v in stream) {
        final outputs = v.responseBufferContent
            .map((e) {
              String r = e;
              if (r.length > trimLen) {
                r = r.substring(prompt.length);
              } else {
                return '';
              }
              if (r.endsWith('<EOD>')) {
                r = r.substring(0, r.length - 5);
              }
              return r;
            }) //
            .toList();
        /// if (outputs.every((e) => e.isEmpty)) continue;
        final newList = [
          ...items, //
          if (input.isNotEmpty) CompletionItemState.user(input),
          CompletionItemState.ai(
            output: outputs,
            completed: v.eosFound,
          ),
        ];
        if (firstOutput) {
          CompletionState.controllerInput.q?.clear();
          CompletionState.generateButtonEnabled.q = true;
        }
        CompletionState.items.q = newList;
        firstOutput = false;
      }
    } catch (e) {
      qqe(e);
      onStopTap();
    }
    CompletionState.generating.q = false;
    CompletionState.showSuggestionButton.q = false;
    qqq('completion done');
  }

  void onModelSelectTap() {
    ModelSelector.show();
  }

  void onParallelTap(BuildContext ctx) async {
    final settings = await BatchCompletionSettingsPanel.show(ctx: ctx);
    CompletionState.batchSettings.q = settings;
  }

  void onDecodeParamChanged(BuildContext ctx, DecodeParamType type) {
    if (type == DecodeParamType.unknown) {
      ArgumentsPanel.show(ctx);
    } else {
      P.rwkv.syncSamplerParamsFromDefault(type);
    }
  }

  void onRegenerateTap(CompletionItemState item) {
    CompletionState.items.q = [...CompletionState.items.q]..removeLast();
    onCompletionTap(regenerate: true);
  }

  void onPrevChooseTap(CompletionItemState item) {
    CompletionState.items.q = CompletionState.items.q
        .map(
          (e) => e == item ? item.copyWith(index: item.index - 1) : e,
        )
        .toList();
  }

  void onNextChooseTap(CompletionItemState item) {
    CompletionState.items.q = CompletionState.items.q
        .map(
          (e) => e == item ? item.copyWith(index: item.index + 1) : e,
        )
        .toList();
  }

  void onKeyboardVisibleChanged(bool visible) async {}

  void onSuggestionTap(BuildContext context) async {
    final r = await CompletionSuggestionDialog.show(context);
    if (r == null) return;
    CompletionState.controllerInput.q?.text = r;
  }

  void onClearAllTap() {
    CompletionState.controllerInput.q?.clear();
    CompletionState.showSuggestionButton.q = true;
    CompletionState.items.q = [];
  }
}
