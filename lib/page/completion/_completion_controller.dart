// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_mobile_flutter/from_rwkv.dart';
import 'package:rxdart/rxdart.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/page/completion/_completion_state.dart';
import 'package:zone/page/completion/_suggestions_dialog.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/arguments_panel.dart';
import 'package:zone/widgets/completion/batch_completion_settings_panel.dart';
import 'package:zone/widgets/model_selector.dart';

class CompletionController {
  StreamSubscription? _subscription;
  StreamSubscription? _subscription2;
  CompletionItemNode _node = CompletionItemNode.user('');
  static final _originDecodeParam = <Argument, double>{};
  static final _decodeParam = <Argument, double>{
    Argument.temperature: DecodeParamType.creative.temperature,
    Argument.topP: DecodeParamType.creative.topP,
    Argument.presencePenalty: DecodeParamType.creative.presencePenalty,
    Argument.frequencyPenalty: DecodeParamType.creative.frequencyPenalty,
    Argument.penaltyDecay: DecodeParamType.creative.penaltyDecay,
  };

  static final current = CompletionController._();

  CompletionController._();

  void dispose() {
    _subscription?.cancel();
    _subscription2?.cancel();
    _subscription = null;
    _subscription2 = null;
    P.rwkv.stop();

    for (final arg in _decodeParam.keys) {
      _decodeParam[arg] = P.rwkv.arguments(arg).q;
      P.rwkv.arguments(arg).q = _originDecodeParam[arg]!;
    }
  }

  void init() {
    for (final arg in _decodeParam.keys) {
      _originDecodeParam[arg] = P.rwkv.arguments(arg).q;
      P.rwkv.arguments(arg).q = _decodeParam[arg]!;
    }
    qqq('completion controller init');
    CompletionState.controllerInput.q = TextEditingController()
      ..addListener(() {
        final isEmpty = CompletionState.controllerInput.q?.text.isEmpty ?? true;
        final show = (isEmpty) && _node.isTail;
        if (show == CompletionState.showSuggestionButton.q) return;
        CompletionState.showSuggestionButton.q = show;
      });
    CompletionState.batchSettings.q = BatchCompletionSettings.initial();
    CompletionState.controllerInputScroll.q = ScrollController();
    CompletionState.showSuggestionButton.q = true;
    CompletionState.generating.q = false;
    CompletionState.generateButtonEnabled.q = true;
    CompletionState.items.q = [];
    _node = CompletionItemNode.user('');
    if (CompletionState.model.q == null) {
      onModelSelectTap();
    }
    // avoid decode param override by model load
    _subscription2?.cancel();
    var model = CompletionState.model.q;
    _subscription2 = P.rwkv.broadcastStream.whereType<SamplerParams>().listen((e) async {
      if (model != CompletionState.model.q) {
        for (final arg in _decodeParam.keys) {
          P.rwkv.arguments(arg).q = _decodeParam[arg]!;
        }
        qqq('DEBUG: decode param restored');
        model = CompletionState.model.q;
      } else {
        for (final arg in _decodeParam.keys) {
          _decodeParam[arg] = P.rwkv.arguments(arg).q;
        }
        qqq('DEBUG: decode param stored');
      }
    });
  }

  void onStopTap() async {
    CompletionState.generateButtonEnabled.q = false;
    P.rwkv.stop();
    await Future.delayed(const Duration(seconds: 1));
    CompletionState.generating.q = false;
    CompletionState.generateButtonEnabled.q = true;
  }

  void onCompletionTap({bool regenerate = false}) async {
    if (CompletionState.model.q == null) {
      onModelSelectTap();
      return;
    }

    final input = regenerate ? '' : (CompletionState.controllerInput.q?.text ?? '');
    if (!regenerate && input.isEmpty && CompletionState.items.q.length == 1) {
      Alert.warning(S.current.please_entry_some_text_to_continue);
      return;
    }
    final batchSetting = CompletionState.batchSettings.q;

    CompletionState.controllerInput.q?.clear();
    CompletionState.showSuggestionButton.q = false;

    final lastNode = regenerate ? _node.tail : CompletionItemNode.user(input);
    if (!regenerate) {
      final tail = _node.tail;
      if (!tail.isUser) {
        tail.decodeSpeed = P.rwkv.decodeSpeed.q;
        tail.prefillSpeed = P.rwkv.prefillSpeed.q;
        tail.parent.switched = true;
      }
      _node.tail = lastNode;
    } else {
      _node.tail.switched = false;
    }

    CompletionState.generating.q = true;
    CompletionState.generateButtonEnabled.q = false;

    final batch = batchSetting.enabled ? batchSetting.batchCount : 1;
    final outputs = CompletionItemNode.fromResult(
      parent: lastNode,
      outputs: List.filled(batch, ''),
      completed: List.filled(batch, false),
    );
    lastNode.children = outputs;
    lastNode.next = outputs[0];
    _notifyItemChanged();

    await P.rwkv.clearStates();

    final prompt = _node.joinedContent;
    final trimLen = prompt.length;
    bool firstOutput = true;

    _subscription?.cancel();
    _subscription = P.rwkv
        .completion(prompt, batchSize: batch)
        .listen(
          (v) {
            if (firstOutput) CompletionState.generateButtonEnabled.q = true;
            firstOutput = false;
            for (var i = 0; i < v.responseBufferContent.length; i++) {
              String content = v.responseBufferContent[i];
              if (content.isEmpty) continue;
              if (content.length > trimLen) {
                content = content.substring(prompt.length);
              } else {
                content = '';
              }
              if (content.endsWith('<EOD>')) {
                content = content.substring(0, content.length - 5);
              }
              outputs[i].content = content;
              outputs[i].completed = v.eosFound[i];
            }
            _notifyItemChanged();
          },
          onDone: () {
            CompletionState.generating.q = false;
            qqq('completion done');
          },
          onError: (e) {
            qqe(e);
            onStopTap();
          },
        );

    P.rwkv.broadcastStream
        .whereType<IsGenerating>() //
        .where((e) => !e.isGenerating)
        .take(1)
        .listen((_) {
          CompletionState.generating.q = false;
          _subscription?.cancel();
          _subscription = null;
        });
  }

  void onModelSelectTap() async {
    await ModelSelector.show();
    if (CompletionState.batchSettings.q.enabled) {
      final batch = CompletionState.model.q?.tags.contains('batch') == true;
      if (!batch) {
        CompletionState.batchSettings.q = CompletionState.batchSettings.q.copyWith(enabled: false);
      }
    }
  }

  void onParallelTap(BuildContext ctx) async {
    final batch = CompletionState.model.q?.tags.contains('batch') == true;
    if (!batch) {
      Alert.warning(S.current.this_model_does_not_support_batch_inference);
      return;
    }
    await BatchCompletionSettingsPanel.show(ctx: ctx);
  }

  void onDecodeParamChanged(BuildContext ctx, DecodeParamType type) {
    if (type == DecodeParamType.custom) {
      ArgumentsPanel.show(ctx);
    } else {
      P.rwkv.syncSamplerParamsFromDefault(type);
    }
  }

  void onRegenerateTap(CompletionItemNode item) {
    try {
      _node.tail = null;
      onCompletionTap(regenerate: true);
    } catch (e, s) {
      qqe(s);
    }
  }

  void onPrevChooseTap(CompletionItemNode item) {
    item.replaceToSibling(item.index - 1);
    _notifyItemChanged();
  }

  void onNextChooseTap(CompletionItemNode item) {
    item.replaceToSibling(item.index + 1);
    _notifyItemChanged();
  }

  void switchChooseTo(CompletionItemNode item) {
    item.switchToSibling(item);
    _notifyItemChanged();
  }

  void onSuggestionTap(BuildContext context) async {
    final r = await CompletionSuggestionDialog.show(context);
    if (r == null) return;
    CompletionState.controllerInput.q?.text = r;
  }

  void onClearAllTap() {
    CompletionState.controllerInput.q?.clear();
    CompletionState.showSuggestionButton.q = true;
    _node = CompletionItemNode.user('');
    CompletionState.items.q = [];
  }

  void _notifyItemChanged() {
    CompletionState.items.q = _node.list;
  }
}
