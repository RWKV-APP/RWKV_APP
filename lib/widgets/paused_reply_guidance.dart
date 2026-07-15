// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';

class PausedReplyGuidance extends ConsumerWidget {
  const PausedReplyGuidance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final editingOrRegeneratingIndex = ref.watch(P.msg.editingOrRegeneratingIndex);
    final pausedReplyId = editingOrRegeneratingIndex == null ? ref.watch(P.chat.pausedReplyGuidanceMessageId) : null;
    final appTheme = ref.watch(P.app.theme);
    final horizontalPadding = appTheme.inputBarHorizontalPadding;
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final duration = animationsDisabled ? Duration.zero : const Duration(milliseconds: 200);

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            alignment: AlignmentDirectional.bottomEnd,
            sizeFactor: animation,
            child: child,
          ),
        );
      },
      child: pausedReplyId == null
          ? const SizedBox(
              key: ValueKey("paused-reply-guidance-empty"),
            )
          : Padding(
              key: ValueKey("paused-reply-guidance-$pausedReplyId"),
              padding: .only(
                left: horizontalPadding + 24,
                right: horizontalPadding,
                bottom: 8,
              ),
              child: Align(
                alignment: .centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: _PausedReplyGuidanceBubble(
                    pausedReplyId: pausedReplyId,
                  ),
                ),
              ),
            ),
    );
  }
}

class _PausedReplyGuidanceBubble extends ConsumerWidget {
  final int pausedReplyId;

  const _PausedReplyGuidanceBubble({required this.pausedReplyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final colors = interactionVisualColors(
      appTheme: appTheme,
      state: .available,
    );
    final useBackdropFilter = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final backgroundAlpha = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final darkBackgroundAlphaModifier = ref.watch(P.ui.backdropFilterBgAlphaForInputOptionsDarkModifier);
    final sigma = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);
    final borderRadius = BorderRadius.circular(16);
    final backgroundColor = colors.background.withValues(
      alpha: useBackdropFilter ? backgroundAlpha * darkBackgroundAlphaModifier : 1,
    );

    return Semantics(
      liveRegion: true,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
          ),
          enabled: useBackdropFilter,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: .all(color: colors.border),
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const .only(left: 12, top: 4, right: 2, bottom: 4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final useCompactLayout = constraints.maxWidth < 460;
                    final message = Row(
                      crossAxisAlignment: .center,
                      children: [
                        Expanded(
                          child: Text(
                            s.paused_reply_edit_hint,
                            style: TextStyle(
                              color: colors.foreground,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    );
                    final editButton = TextButton(
                      onPressed: () => P.chat.onEditOriginalQuestionForPausedReplyPressed(pausedReplyId: pausedReplyId),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.foreground,
                        minimumSize: const Size(0, 44),
                        padding: const .symmetric(horizontal: 10),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        s.edit_original_question,
                        style: const TextStyle(fontWeight: .w600),
                      ),
                    );
                    final closeButton = Tooltip(
                      message: s.close,
                      child: IconButton(
                        onPressed: () => P.chat.dismissPausedReplyGuidance(pausedReplyId: pausedReplyId),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: colors.foreground.withValues(alpha: .72),
                        ),
                      ),
                    );

                    if (useCompactLayout) {
                      return Column(
                        mainAxisSize: .min,
                        children: [
                          message,
                          Row(
                            mainAxisAlignment: .end,
                            children: [
                              editButton,
                              closeButton,
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: message),
                        const SizedBox(width: 8),
                        editButton,
                        closeButton,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
