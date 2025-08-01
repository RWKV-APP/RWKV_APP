// ignore: unused_import
import 'dart:developer';
import 'dart:ui';

import 'package:halo_state/halo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/bottom_interactions.dart';
import 'package:zone/widgets/chat/input_text_field.dart';
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
        borderRadius: !isChat ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(16)),
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
                  const InputTextField(),
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
