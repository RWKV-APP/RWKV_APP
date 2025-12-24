// ignore: unused_import
import 'dart:developer';
import 'dart:io';

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
  final DemoType preferredDemoType;

  const BottomBar({super.key, this.preferredDemoType = DemoType.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final isChat = preferredDemoType == DemoType.chat;

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

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
                _ImagePreview(preferredDemoType: preferredDemoType),
                InputTextField(preferredDemoType: preferredDemoType),
                if (preferredDemoType != DemoType.tts) BottomInteractions(preferredDemoType: preferredDemoType),
                if (preferredDemoType == DemoType.tts) const TTSBottomInteractions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends ConsumerWidget {
  final DemoType preferredDemoType;
  const _ImagePreview({required this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedImagePath = ref.watch(P.see.imagePath);
    final screenWidth = ref.watch(P.app.screenWidth);
    if (selectedImagePath == null) return const SizedBox.shrink();
    if (preferredDemoType != DemoType.see) return const SizedBox.shrink();
    return Row(
      children: [
        Padding(
          padding: const .only(bottom: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.2,
              maxHeight: screenWidth * 0.2,
            ),
            child: ClipRRect(
              borderRadius: 12.r,
              child: Stack(
                children: [
                  Image.file(
                    File(selectedImagePath),
                  ),
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
