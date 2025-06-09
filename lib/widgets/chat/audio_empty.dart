// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/state/p.dart';

class AudioEmpty extends ConsumerWidget {
  const AudioEmpty({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    final paddingTop = ref.watch(P.app.paddingTop);
    final inputHeight = ref.watch(P.chat.inputHeight);
    final primary = Theme.of(context).colorScheme.primary;

    final imagePath = ref.watch(P.world.imagePath);
    if (imagePath != null) {
      return Positioned(child: IgnorePointer(child: C()));
    }

    final currentWorldType = ref.watch(P.rwkv.currentWorldType);

    switch (currentWorldType) {
      case WorldType.chineseASR:
      case WorldType.engASR:
      case WorldType.engAudioQA:
        break;
      case WorldType.engVisualQA:
      case WorldType.qa:
      case WorldType.reasoningQA:
      case WorldType.ocr:
      case null:
        return Positioned(child: IgnorePointer(child: C()));
    }

    final messages = ref.watch(P.msg.list);

    bool show = true;
    if (messages.isNotEmpty) {
      show = false;
    }

    String message = "";
    switch (currentWorldType) {
      case null:
      case WorldType.engVisualQA:
      case WorldType.qa:
      case WorldType.reasoningQA:
      case WorldType.ocr:
        message = "";
      case WorldType.engAudioQA:
        message = "Press and hold the microphone button below to start recording.\nRelease to send it to RWKV.";
      case WorldType.chineseASR:
        message = "请长按下方按钮开始录音\n松开即可让 RWKV 识别你的声音";
      case WorldType.engASR:
        message = "Please press and hold the microphone button below to start recording.\nRelease to let RWKV recognize your voice";
    }

    return AnimatedPositioned(
      duration: 200.ms,
      curve: Curves.easeInOutBack,
      bottom: show ? inputHeight : -screenHeight,
      left: 0,
      width: screenWidth,
      top: paddingTop + kToolbarHeight,
      child: IgnorePointer(
        ignoring: true,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: 200.ms,
          curve: Curves.easeInOutBack,
          child: C(
            decoration: const BD(color: kC),
            child: Column(
              crossAxisAlignment: CAA.center,
              mainAxisAlignment: MAA.center,
              children: [
                C(
                  padding: const EI.s(h: 24),
                  child: T(
                    message,
                    s: TS(s: 20, c: primary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
