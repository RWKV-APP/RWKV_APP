// ignore: unused_import
import 'dart:developer';
import 'dart:io';

import 'package:halo_state/halo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/bottom_interactions.dart';
import 'package:zone/widgets/input_text_field.dart';
import 'package:zone/widgets/talk/tts_bottom_interactions.dart';

class InputBar extends ConsumerWidget {
  final DemoType preferredDemoType;

  const InputBar({super.key, this.preferredDemoType = .chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final isChat = preferredDemoType == .chat;
    final inRWKVSee = P.app.pageKey.q == .see;

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final imagePath = ref.watch(P.see.imagePath);

    return MeasureSize(
      onChange: (size) {
        P.chat.inputHeight.q = size.height;
      },
      child: ClipRRect(
        borderRadius: !isChat ? .zero : const .vertical(top: .circular(16)),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: isChat
                ? null
                : Border(
                    top: BorderSide(
                      color: primary.q(.33),
                      width: .5,
                    ),
                  ),
          ),
          padding: .only(left: 8, top: 8, right: 8, bottom: paddingBottom + 8),
          child: AnimatedSize(
            duration: 250.ms,
            child: Column(
              children: [
                if (inRWKVSee) const _WaitingMsg(),
                if (inRWKVSee) _ImagePreview(imagePath: imagePath ?? ""),
                InputTextField(preferredDemoType: preferredDemoType),
                if (preferredDemoType != .tts) BottomInteractions(preferredDemoType: preferredDemoType),
                if (preferredDemoType == .tts) const TTSBottomInteractions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitingMsg extends ConsumerWidget {
  const _WaitingMsg();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final waitingText = ref.watch(P.see.waitingText);
    if (waitingText == null) return const SizedBox.shrink();
    final waitingImagePath = ref.watch(P.see.waitingImagePath);
    final count = 1;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        T(
          s.message_in_queue(count),
          s: const TS(s: 12),
        ),
        Container(
          decoration: BD(color: kC.q(.1), borderRadius: 12.r),
          margin: const .only(bottom: 4, top: 4),
          child: Row(
            crossAxisAlignment: .center,
            children: [
              if (waitingImagePath != null) _ImagePreview(small: true, imagePath: waitingImagePath),
              if (waitingImagePath != null) 4.w,
              T(
                waitingText,
                s: const TS(s: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImagePreview extends ConsumerWidget {
  final bool small;
  final String imagePath;

  const _ImagePreview({this.small = false, required this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = ref.watch(P.app.screenWidth);
    if (imagePath.isEmpty) return const SizedBox.shrink();

    final maxWidth = small ? 20.0 : screenWidth * 0.2;

    return Row(
      children: [
        Padding(
          padding: .only(bottom: small ? 0 : 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxWidth,
            ),
            child: ClipRRect(
              borderRadius: (small ? 2 : 12).r,
              child: Stack(
                children: [
                  Image.file(
                    File(imagePath),
                  ),
                  if (!small)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: () {
                          P.see.imagePath.q = null;
                        },
                        icon: Container(
                          decoration: BD(color: kB.q(.5), borderRadius: 1000.r),
                          child: Icon(
                            Icons.close,
                            color: kW.q(1),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
