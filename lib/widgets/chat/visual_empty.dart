// ignore: unused_import
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/func/show_image_selector.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/state/p.dart';

class VisualEmpty extends ConsumerWidget {
  const VisualEmpty({super.key});

  void _onTapImageSelector() async {
    await showImageSelector();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    final paddingTop = ref.watch(P.app.paddingTop);
    final inputHeight = ref.watch(P.chat.inputHeight);
    final maxW = screenWidth;
    final maxH = screenHeight - paddingTop - kToolbarHeight - inputHeight;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
    final primary = Theme.of(context).colorScheme.primary;
    final imagePath = ref.watch(P.world.imagePath);
    if (imagePath != null) return Positioned(child: IgnorePointer(child: C()));
    final currentWorldType = ref.watch(P.rwkv.currentWorldType);
    final s = S.of(context);

    switch (currentWorldType) {
      case WorldType.engVisualQA:
      case WorldType.qa:
      case WorldType.reasoningQA:
      case WorldType.ocr:
        break;
      case null:
      case WorldType.engAudioQA:
      case WorldType.chineseASR:
      case WorldType.engASR:
        return Positioned(child: IgnorePointer(child: C()));
    }

    final messages = ref.watch(P.msg.list);

    bool show = true;
    if (messages.isNotEmpty) {
      show = false;
    }

    return AnimatedPositioned(
      duration: 200.ms,
      curve: Curves.easeInOutBack,
      bottom: show ? inputHeight : -screenHeight,
      left: 0,
      width: screenWidth,
      top: paddingTop + kToolbarHeight,
      child: Column(
        crossAxisAlignment: CAA.center,
        mainAxisAlignment: MAA.center,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: 12.r,
              child: GD(
                onTap: _onTapImageSelector,
                child: C(
                  decoration: BD(
                    color: primaryContainer.q(.5),
                    border: Border.all(color: primary.q(.5)),
                    borderRadius: 12.r,
                  ),
                  width: math.min(maxW, maxH) - 16,
                  height: math.min(maxW, maxH) * .75,
                  child: Column(
                    crossAxisAlignment: CAA.center,
                    mainAxisAlignment: MAA.center,
                    children: [
                      if (imagePath == null) const Icon(Icons.image),
                      if (imagePath == null) 8.h,
                      if (imagePath == null) T(s.click_to_load_image, s: const TS(w: FW.w500, s: 20)),
                      if (imagePath == null) 8.h,
                      if (imagePath == null) T(s.then_you_can_start_to_chat_with_rwkv),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
