// ignore: unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';

class SendingInteraction extends ConsumerWidget {
  final DemoType preferredDemoType;

  const SendingInteraction({super.key, required this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generating = ref.watch(P.rwkv.generating);
    final hiddenPrefilling = ref.watch(P.rwkv.hiddenPrefilling);
    // final waitingImagePath = ref.watch(P.see.waitingImagePath);
    final waitingText = ref.watch(P.see.waitingText);

    if (!generating || (hiddenPrefilling && waitingText == null)) return _Send(preferredDemoType: preferredDemoType);

    return const _Stop();
  }
}

class _Send extends ConsumerWidget {
  final DemoType preferredDemoType;
  const _Send({required this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(P.app.theme);
    final sendingButtonColor = appTheme.sendingButtonC;

    final editingBotMessage = ref.watch(P.msg.editingBotMessage);
    final inSee = ref.watch(P.app.pageKey) == .see;
    final imagePath = ref.watch(P.see.imagePath);
    final hasAtLeastOneImage = ref.watch(P.msg.hasAtLeastOneImage);
    final inputHasContent = ref.watch(P.chat.inputHasContent);
    final sendingButtonTouchMinSize = appTheme.sendingButtonTouchMinSize;
    final sendingButtonVisualSize = appTheme.sendingButtonVisualSize;
    final sendingButtonDisabledOpacity = appTheme.sendingButtonDisabledOpacity;
    final hasText = ref.watch(P.chat.inputHasContent);

    final readyForSee = (imagePath != null || hasAtLeastOneImage) && inputHasContent;
    final opacity = inSee
        ? (!hasText ? sendingButtonDisabledOpacity : (readyForSee ? 1.0 : .38))
        : (hasText ? 1.0 : sendingButtonDisabledOpacity);

    final icon = editingBotMessage ? Icons.edit : CupertinoIcons.arrow_up_circle_fill;

    return AnimatedOpacity(
      opacity: opacity,
      duration: 250.ms,
      child: GestureDetector(
        onTap: () => P.chat.onSendButtonPressed(preferredDemoType: preferredDemoType),
        child: Container(
          constraints: BoxConstraints(
            minWidth: sendingButtonTouchMinSize.width,
            minHeight: sendingButtonTouchMinSize.height,
          ),
          child: Icon(
            icon,
            color: sendingButtonColor,
            size: sendingButtonVisualSize.width,
          ),
        ),
      ),
    );
  }
}

class _Stop extends ConsumerWidget {
  const _Stop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(P.app.theme);
    final sendingButtonColor = appTheme.sendingButtonC;
    final sendingButtonTouchMinSize = appTheme.sendingButtonTouchMinSize;

    return GestureDetector(
      onTap: P.chat.onStopButtonPressed,
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Stack(
          children: [
            SizedBox(
              width: sendingButtonTouchMinSize.width,
              height: sendingButtonTouchMinSize.height,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(color: sendingButtonColor, borderRadius: 2.r),
                  width: 12,
                  height: 12,
                ),
              ),
            ),
            SizedBox(
              width: sendingButtonTouchMinSize.width,
              height: sendingButtonTouchMinSize.height,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: sendingButtonColor.q(.5),
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
