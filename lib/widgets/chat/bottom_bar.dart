// ignore: unused_import
import 'dart:developer';
import 'dart:ui';

import 'package:halo_state/halo_state.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/bottom_interactions.dart';
import 'package:zone/widgets/chat/tts/bottom_interactions.dart';

class BottomBar extends ConsumerWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final primary = Theme.of(context).colorScheme.primary;
    final demoType = ref.watch(P.app.demoType);
    final isChat = demoType == DemoType.chat;

    final theme = Theme.of(context);
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;

    return MeasureSize(
      onChange: (size) {
        P.chat.inputHeight.q = size.height;
      },
      child: ClipRRect(
        borderRadius: !isChat ? BorderRadius.zero : BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: C(
            decoration: BD(
              color: isChat ? theme.cardColor : scaffoldBackgroundColor.q(.8),
              border: isChat
                  ? null
                  : Border(
                      top: BorderSide(
                        color: primary.q(.33),
                        width: .5,
                      ),
                    ),
            ),
            padding: EI.o(
              l: 10,
              r: 10,
              b: paddingBottom + 12,
              t: 12,
            ),
            child: AnimatedSize(
              duration: 250.ms,
              child: Column(
                children: [
                  const _TextField(),
                  if (demoType != DemoType.tts) const BottomInteractions(),
                  if (demoType == DemoType.tts) const TTSBottomInteractions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextField extends ConsumerWidget {
  const _TextField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final loaded = ref.watch(P.rwkv.loaded);
    final loading = ref.watch(P.rwkv.loading);
    final demoType = ref.watch(P.app.demoType);
    final isChat = demoType == DemoType.chat;

    String hintText;
    switch (demoType) {
      case DemoType.chat:
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
      case DemoType.world:
        hintText = s.send_message_to_rwkv;
      case DemoType.tts:
        hintText = s.i_want_rwkv_to_say;
    }
    if (isChat) {
      hintText = s.ask_me_anything;
    }

    bool textFieldEnabled = loaded && !loading;

    final borderRadius = demoType != DemoType.tts ? 12.r : 6.r;

    final textInInput = ref.watch(P.chat.textInInput);
    final intonationShown = ref.watch(P.tts.intonationShown);
    final keyboardType = intonationShown ? TextInputType.none : TextInputType.multiline;

    final qw = ref.watch(P.app.qw);

    return GD(
      onTap: textFieldEnabled ? null : _onTapTextFieldWhenItsDisabled,
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
          contentPadding: const EI.o(
            l: 12,
            r: 12,
            t: 4,
            b: 4,
          ),
          fillColor: qw,
          focusColor: qw,
          hoverColor: qw,
          iconColor: qw,
          border: isChat
              ? InputBorder.none
              : OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(color: primary.q(.33)),
                ),
          enabledBorder: isChat
              ? InputBorder.none
              : OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(color: primary.q(.33)),
                ),
          focusedBorder: isChat
              ? InputBorder.none
              : OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(color: primary.q(.33)),
                ),
          focusedErrorBorder: isChat
              ? InputBorder.none
              : OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(color: primary.q(.33)),
                ),
          hintText: hintText,
          hintStyle: !isChat ? null : TextStyle(color: Colors.grey),
          suffixIcon: textInInput.isEmpty || isChat
              ? null
              : GD(
                  onTap: P.chat.onTapClearInput,
                  child: const Icon(Icons.clear),
                ),
        ),
      ),
    );
  }

  void _onChanged(String value) {}

  void _onTap() async {
    qq;
    await Future.delayed(const Duration(milliseconds: 300));
    await P.chat.scrollToBottom();
  }

  void _onAppPrivateCommand(String action, Map<String, dynamic> data) {}

  void _onTapOutside(PointerDownEvent event) {}

  void _onKeyEvent(KeyEvent event) {
    final character = event.character;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter && character != null;
    if (!isEnterPressed) return;
    if (isShiftPressed) {
      final currentValue = P.chat.textEditingController.value;
      if (currentValue.text.trim().isNotEmpty) {
        P.chat.textEditingController.value = TextEditingValue(text: P.chat.textEditingController.value.text);
      } else {
        Alert.warning(S.current.chat_empty_message);
        P.chat.textEditingController.value = const TextEditingValue(text: "");
      }
    } else {
      P.chat.onSendButtonPressed();
    }
  }

  void _onTapTextFieldWhenItsDisabled() {
    qq;
    if (!checkModelSelection()) return;
  }
}
