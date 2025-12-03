import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/widgets/chat/batch_completion_settings_panel.dart';
import 'package:zone/widgets/model_selector.dart';

import '_completion_state.dart';

class CompletionController {
  static final current = CompletionController._();

  CompletionController._();

  void init() {
    CompletionState.controllerList.q = ScrollController();
    CompletionState.controllerInput.q = TextEditingController();

    CompletionState.items.q = [
      CompletionItemState(
        isUser: true, //
        chooses: [
          CompletionResultState(
            content: '看看吧，这就是虫子，它们的技术与我们的差距，远大于我们与三体文明的差距。',
            completed: true, //
          ),
        ],
      ),
      CompletionItemState(
        isUser: false,
        chooses: [
          CompletionResultState(
            content: '人类竭尽全力消灭它们，用尽各种毒剂，用飞机喷洒，引进和培养它们的天敌，搜寻并毁掉它们的卵，用基因改造使它们绝育；用火烧它们，用水淹它们，每个家庭都有对付它们的灭害灵，每个办公桌下都有像苍蝇拍这种击杀它们的武器……',
            completed: true,
          ),
          CompletionResultState(
            content: '人类竭尽全力消灭它们，用尽各种毒剂，用飞机喷洒，引进和培养它们的天敌，搜寻并毁掉它们的卵',
            completed: true,
          ),
        ],
      ),
    ];
  }

  void onModelSelectTap() {
    ModelSelector.show();
  }

  void onParallelTap() async {
    final settings = await BatchCompletionSettingsPanel.show();
  }

  void onDecodeParamTap() {}

  void onCompletionTap() {
    //
  }

  void onRegenerateTap(CompletionItemState item) {
    //
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

  void onKeyboardVisibleChanged(bool visible) async {
    if (visible) {
      await Future.delayed(Duration(milliseconds: 500));
      final controller = CompletionState.controllerList.q;
      if (controller == null) return;
      controller.animateTo(
        controller.offset + 60,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void onClearAllTap() {
    //
  }

  void dispose() {
    //
  }
}
