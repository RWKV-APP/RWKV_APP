// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/func/extensions/num.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/sending_interaction.dart';

class InputTextField extends ConsumerWidget {
  final DemoType? preferredDemoType;

  const InputTextField({super.key, this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final loaded = ref.watch(P.rwkv.loaded);
    final loading = ref.watch(P.rwkv.loading);
    final DemoType demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    final isChat = demoType == .chat;

    String hintText;
    switch (demoType) {
      case .chat:
      case .fifthteenPuzzle:
      case .othello:
      case .sudoku:
      case .see:
        hintText = s.send_message_to_rwkv;
      case .tts:
        hintText = s.i_want_rwkv_to_say;
    }
    if (isChat) {
      hintText = s.ask_me_anything;
    }

    bool textFieldEnabled = loaded && !loading;

    final borderRadius = demoType != .tts ? 12.r : 6.r;

    final textInInput = ref.watch(P.chat.textInInput);
    final intonationShown = ref.watch(P.talk.intonationShown);
    final keyboardType = intonationShown ? TextInputType.none : TextInputType.multiline;

    final qw = ref.watch(P.app.qw);

    final isDesktop = ref.watch(P.app.isDesktop);

    final appTheme = ref.watch(P.app.theme);

    final inputBarHorizontalPadding = appTheme.inputBarHorizontalPadding;
    final paddingBottom = ref.watch(P.app.paddingBottom) + appTheme.inputBarMinPaddingBottom;

    final inputBarShadowColor = appTheme.textInputShadowC;
    final inputBarBorderColor = appTheme.textInputBorderC;
    final inputBarBorderRadius = appTheme.inputBarBorderRadius;
    final inputBarBgColor = appTheme.textInputBgC;
    final inputBarShadowRadius = appTheme.inputBarShadowRadius;
    final inputBarShadowOffset = appTheme.inputBarShadowOffset;

    final textFieldWidget = Container(
      padding: .only(
        top: appTheme.inputBarTopDistance,
        left: inputBarHorizontalPadding,
        right: inputBarHorizontalPadding,
        bottom: paddingBottom,
      ),
      child: GestureDetector(
        onTap: textFieldEnabled ? null : _onTapTextFieldWhenItsDisabled,
        child: Container(
          decoration: BoxDecoration(
            color: inputBarBgColor,
            borderRadius: .circular(inputBarBorderRadius),
            border: Border.all(color: inputBarBorderColor, width: .5),
            boxShadow: [
              BoxShadow(
                color: inputBarShadowColor,
                blurRadius: inputBarShadowRadius,
                offset: inputBarShadowOffset,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  focusNode: P.chat.focusNode,
                  enabled: textFieldEnabled,
                  controller: P.chat.textEditingController,
                  onSubmitted: P.chat.onKeyboardSubmitted,
                  onChanged: _onChanged,
                  onEditingComplete: P.chat.onEditingComplete,
                  onAppPrivateCommand: _onAppPrivateCommand,
                  onTap: _onTap,
                  onTapOutside: _onTapOutside,
                  keyboardType: keyboardType,
                  enableSuggestions: true,
                  textInputAction: TextInputAction.newline,
                  maxLines: 10,
                  minLines: 1,
                  decoration: InputDecoration(
                    contentPadding: const .only(left: 12, top: 4, right: 12, bottom: 4),
                    fillColor: qw,
                    focusColor: qw,
                    hoverColor: qw,
                    iconColor: qw,
                    border: .none,
                    enabledBorder: .none,
                    focusedBorder: .none,
                    focusedErrorBorder: .none,
                    hintText: hintText,
                    hintStyle: !isChat ? null : const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              SendingInteraction(preferredDemoType: preferredDemoType ?? .chat),
            ],
          ),
        ),
      ),
    );

    if (!isDesktop) return textFieldWidget;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            return KeyEventResult.ignored;
          } else {
            P.chat.onSendButtonPressed(preferredDemoType: preferredDemoType ?? .chat);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: textFieldWidget,
    );
  }

  void _onChanged(String value) {}

  void _onTap() async {
    qq;
    await 300.msLater;
    await P.chat.scrollToBottom();
  }

  void _onAppPrivateCommand(String action, Map<String, dynamic> data) {}

  void _onTapOutside(PointerDownEvent event) {}

  void _onTapTextFieldWhenItsDisabled() {
    qq;
    if (!checkModelSelection(preferredDemoType: preferredDemoType ?? .chat)) return;
  }
}
