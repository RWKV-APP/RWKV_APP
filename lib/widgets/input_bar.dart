// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat_layout_metrics.dart';
import 'package:zone/widgets/input_interactions.dart';
import 'package:zone/widgets/input_text_field.dart';
import 'package:zone/widgets/measure_size.dart';

class InputBar extends ConsumerWidget {
  final DemoType preferredDemoType;

  const InputBar({super.key, this.preferredDemoType = .chat});

  void _onChangeSize(Size size) {
    P.chat.inputHeight.q = size.height;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final inRWKVSee = P.app.pageKey.q == .see;

    final selectMessageMode = ref.watch(P.chat.isSharing);
    if (selectMessageMode) return const SizedBox.shrink();

    final appTheme = ref.watch(P.app.theme);

    final gradientStartForInputBar = ref.watch(P.ui.gradientStartForInputBar);
    final gradientForInputBar = ref.watch(P.ui.gradientForInputBar);

    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: MeasureSize(
        onChange: _onChangeSize,
        child: Container(
          decoration: BoxDecoration(
            // color: Colors.red,
            gradient: LinearGradient(
              colors: [
                appTheme.scaffoldBg.withValues(alpha: 0),
                appTheme.scaffoldBg.withValues(alpha: 1),
              ],
              begin: Alignment(0, gradientStartForInputBar),
              end: Alignment(0, gradientForInputBar),
            ),
          ),
          child: InputBarWidthLimit(
            child: AnimatedSize(
              duration: Duration(milliseconds: 250),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  if (preferredDemoType == .chat) const SizedBox(height: 12),
                  if (inRWKVSee) const _WaitingMsg(),
                  if (preferredDemoType != .tts) InputInteractions(preferredDemoType: preferredDemoType),
                  InputTextField(preferredDemoType: preferredDemoType),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InputBarWidthLimit extends StatelessWidget {
  final Widget child;

  const InputBarWidthLimit({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: chatInputBarMaxWidth),
        child: child,
      ),
    );
  }
}

class _WaitingMsg extends ConsumerWidget {
  const _WaitingMsg();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final s = S.of(context);
    final waitingText = ref.watch(P.see.waitingText);
    if (waitingText == null) return const SizedBox.shrink();
    final waitingImagePath = ref.watch(P.see.waitingImagePath);
    final appTheme = ref.watch(P.app.theme);
    final horizontalPadding = appTheme.inputBarHorizontalPadding;
    final count = 1;
    return Padding(
      padding: .symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            s.message_in_queue(count),
            style: const TextStyle(fontSize: 12),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.transparent.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)),
            margin: const .only(bottom: 4, top: 4),
            child: Row(
              crossAxisAlignment: .center,
              children: [
                if (waitingImagePath != null) _ImagePreview(small: true, imagePath: waitingImagePath),
                if (waitingImagePath != null) const SizedBox(width: 4),
                Text(
                  waitingText,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends ConsumerWidget {
  final bool small;
  final String imagePath;

  const _ImagePreview({this.small = false, required this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
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
              borderRadius: BorderRadius.circular((small ? 2 : 12).toDouble()),
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
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: .5), borderRadius: BorderRadius.circular(1000)),
                          child: Icon(
                            Icons.close,
                            color: Colors.white.withValues(alpha: 1),
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
