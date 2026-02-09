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
import 'package:zone/widgets/interactions.dart';
import 'package:zone/widgets/input_text_field.dart';
import 'package:zone/widgets/talk/tts_bottom_interactions.dart';

class InputBar extends ConsumerWidget {
  final DemoType preferredDemoType;

  const InputBar({super.key, this.preferredDemoType = .chat});

  void _onChangeSize(Size size) {
    P.chat.inputHeight.q = size.height;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inRWKVSee = P.app.pageKey.q == .see;

    final imagePath = ref.watch(P.see.imagePath);

    final selectMessageMode = ref.watch(P.chat.isSharing);
    if (selectMessageMode) return const SizedBox.shrink();

    final customTheme = ref.watch(P.app.theme);

    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: MeasureSize(
        onChange: _onChangeSize,
        child: Container(
          decoration: BoxDecoration(
            // color: kCR,
            gradient: LinearGradient(
              colors: [
                customTheme.scaffold.q(0),
                customTheme.scaffold.q(1),
              ],
              begin: .topCenter,
              end: const Alignment(0, -0.6),
            ),
          ),
          child: AnimatedSize(
            duration: 250.ms,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                const SizedBox(height: 12),
                if (inRWKVSee) const _WaitingMsg(),
                if (inRWKVSee) _ImagePreview(imagePath: imagePath ?? ""),
                if (preferredDemoType != .tts) InputInteractions(preferredDemoType: preferredDemoType),
                if (preferredDemoType == .tts) const TTSInteractions(),
                InputTextField(preferredDemoType: preferredDemoType),
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
        Text(
          s.message_in_queue(count),
          style: const TS(s: 12),
        ),
        Container(
          decoration: BoxDecoration(color: kC.q(.1), borderRadius: 12.r),
          margin: const .only(bottom: 4, top: 4),
          child: Row(
            crossAxisAlignment: .center,
            children: [
              if (waitingImagePath != null) _ImagePreview(small: true, imagePath: waitingImagePath),
              if (waitingImagePath != null) const SizedBox(width: 4),
              Text(
                waitingText,
                style: const TS(s: 12),
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
                          decoration: BoxDecoration(color: kB.q(.5), borderRadius: 1000.r),
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
