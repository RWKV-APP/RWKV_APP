// Dart imports:
import 'dart:math' as math;

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/thinking_mode.dart' as thinking_mode;
import 'package:zone/model/world_type.dart' as world_type;
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/branch_switcher.dart';

class BotMessageBottom extends ConsumerWidget {
  final model.Message msg;
  final int index;
  final DemoType? preferredDemoType;
  final String? finalContent;
  final VoidCallback? onRegeneratePressed;
  final VoidCallback? onResumePressed;
  final bool disableDefaultActions;

  const BotMessageBottom(
    this.msg,
    this.index, {
    super.key,
    this.preferredDemoType,
    this.finalContent,
    this.onRegeneratePressed,
    this.onResumePressed,
    this.disableDefaultActions = false,
  });

  void _onSharePressed() {
    if (disableDefaultActions) return;
    if (P.rwkv.generating.q) {
      P.chat.onStopButtonPressed();
    }

    final list = P.msg.list.q;
    final index = list.indexOf(msg);
    if (index > 0) {
      P.chat.sharingSelectedMsgIds.q = {list[index - 1].id, msg.id};
    }
    P.chat.isSharing.q = true;
  }

  void _onResumePressed() {
    if (onResumePressed != null) {
      onResumePressed?.call();
      return;
    }
    if (disableDefaultActions) return;
    P.chat.resumeMessageById(id: msg.id);
  }

  void _onBotEditPressed() async {
    if (disableDefaultActions) return;
    await P.chat.onTapEditInBotMessageBubble(index: index);
  }

  void _onRegeneratePressed() async {
    if (onRegeneratePressed != null) {
      onRegeneratePressed?.call();
      return;
    }
    if (disableDefaultActions) return;
    await P.chat.onRegeneratePressed(index: index, preferredDemoType: preferredDemoType ?? .chat);
  }

  void _onCopyPressed() {
    if (disableDefaultActions) return;
    Alert.success(S.current.chat_copied_to_clipboard);
    final isBatch = getIsBatch(msg.content);
    String message = msg.content;
    if (isBatch) {
      message = message.replaceAll(Config.batchMarker, "\n\n");
      message = message.substring(0, message.length - 3);
    }
    Clipboard.setData(ClipboardData(text: message));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (msg.isMine) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final S s = S.of(context);

    final DemoType demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    if (demoType == .tts) return const SizedBox.shrink();

    final int? receiveId = ref.watch(P.chat.receiveId);
    final bool selectMessageMode = ref.watch(P.chat.isSharing);

    final bool isMobile = ref.watch(P.app.isMobile);

    final bool paused = msg.paused;

    final bool changing = msg.changing;

    final Color primaryColor = theme.colorScheme.primary;

    final world_type.WorldType? worldType = ref.watch(P.rwkv.currentWorldType);

    bool showEditButton = true;
    bool showCopyButton = true;
    bool showBotRegenerateButton = true;
    bool showResumeButton = true;
    bool showShareButton = false;

    switch (worldType) {
      case null:
        break;
      default:
        showEditButton = false;
        showCopyButton = false;
    }

    switch (demoType) {
      case .tts:
        showEditButton = false;
        showCopyButton = false;
        showBotRegenerateButton = false;
        showResumeButton = false;
        break;
      case .chat:
        showShareButton = true;
        break;
      default:
        break;
    }

    if (msg.isSensitive || selectMessageMode) {
      showResumeButton = false;
      showCopyButton = false;
      showEditButton = false;
      showShareButton = false;
    }
    if (selectMessageMode) {
      showBotRegenerateButton = false;
    }

    final thinkingMode = thinking_mode.ThinkingMode.fromString(msg.runningMode);
    final bool inSee = ref.watch(P.app.pageKey) == .see;

    final Widget? modeWidget = switch (thinkingMode) {
      .none =>
        inSee
            ? const SizedBox.shrink()
            : Padding(
                padding: const .only(left: 4, top: 4, right: 4, bottom: 4),
                child: Icon(
                  CupertinoIcons.zzz,
                  color: primaryColor.q(.8),
                  size: 14,
                ),
              ).debug,
      _ => null,
    };

    final bool isBatch = getIsBatch(finalContent ?? msg.content);

    if (isBatch) {
      showEditButton = false;
    }

    if (changing) {
      showCopyButton = false;
      showBotRegenerateButton = false;
      showEditButton = false;
      showShareButton = false;
    }

    final double verticalPaddingAdditions = isMobile ? 8.0 : 0.0;
    final Widget branchSwitcher = IgnorePointer(
      ignoring: disableDefaultActions,
      child: BranchSwitcher(msg, index).debug,
    );
    const Duration actionAnimDuration = Duration(milliseconds: 200);
    const Curve actionAnimCurve = Curves.easeOutCubic;
    final bool showEditAction = showEditButton && !changing;
    final bool resumeMatched = disableDefaultActions ? true : receiveId == msg.id;
    final bool showResumeAction = showResumeButton && paused && resumeMatched && !isBatch;

    return Padding(
      padding: .only(top: isMobile ? .0 : 8.0),
      child: Row(
        mainAxisAlignment: .start,
        children: [
          _AnimatedActionItem(
            visible: showCopyButton,
            duration: actionAnimDuration,
            curve: actionAnimCurve,
            child: Tooltip(
              message: s.copy_text,
              child: GestureDetector(
                onTap: _onCopyPressed,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Padding(
                    padding: .only(left: 4, top: 4 + verticalPaddingAdditions, right: 4, bottom: 4 + verticalPaddingAdditions),
                    child: Icon(
                      Symbols.content_copy,
                      color: primaryColor.q(.8),
                      size: 20,
                    ).debug,
                  ),
                ),
              ),
            ).debug,
          ),
          _AnimatedActionItem(
            visible: showBotRegenerateButton,
            duration: actionAnimDuration,
            curve: actionAnimCurve,
            child: Tooltip(
              message: s.regenerate,
              child: GestureDetector(
                onTap: _onRegeneratePressed,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Padding(
                    padding: .only(left: 4, top: 4 + verticalPaddingAdditions, right: 4, bottom: 4 + verticalPaddingAdditions),
                    child: Icon(
                      Symbols.refresh,
                      color: primaryColor.q(.8),
                      size: 20,
                    ).debug,
                  ),
                ),
              ),
            ).debug,
          ),
          _AnimatedActionItem(
            visible: showEditAction,
            duration: actionAnimDuration,
            curve: actionAnimCurve,
            child: Tooltip(
              message: s.edit,
              child: GestureDetector(
                onTap: _onBotEditPressed,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Padding(
                    padding: .only(left: 4, top: 4 + verticalPaddingAdditions, right: 4, bottom: 4 + verticalPaddingAdditions),
                    child: Icon(
                      Symbols.edit,
                      color: primaryColor.q(.8),
                      size: 20,
                    ).debug,
                  ),
                ),
              ),
            ).debug,
          ),
          _AnimatedActionItem(
            visible: changing,
            duration: actionAnimDuration,
            curve: actionAnimCurve,
            child: Tooltip(
              message: s.generating,
              child: Padding(
                padding: .only(left: 4, top: 4 + verticalPaddingAdditions, right: 4, bottom: 4 + verticalPaddingAdditions),
                child: TweenAnimationBuilder(
                  tween: Tween(begin: .0, end: 1.0),
                  duration: const Duration(milliseconds: 1000000000),
                  builder: (context, value, child) => Transform.rotate(
                    angle: value * 2 * math.pi * 1000000,
                    child: child,
                  ),
                  child: Icon(
                    Symbols.hourglass_top,
                    color: primaryColor,
                    size: 20,
                  ).debug,
                ),
              ),
            ).debug,
          ),
          _AnimatedActionItem(
            visible: showShareButton,
            duration: actionAnimDuration,
            curve: actionAnimCurve,
            child: Tooltip(
              message: s.share,
              child: GestureDetector(
                onTap: _onSharePressed,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Padding(
                    padding: .only(left: 4, top: 4 + verticalPaddingAdditions, right: 4, bottom: 4 + verticalPaddingAdditions),
                    child: Icon(
                      Symbols.share_rounded,
                      color: primaryColor.q(.8),
                      size: 20,
                    ).debug,
                  ),
                ),
              ),
            ).debug,
          ),
          branchSwitcher,
          if (msg.modelName != null) ...[
            4.w,
            Expanded(
              child: Text(
                msg.modelName!,
                style: TS(c: primaryColor.q(.8), s: 10),
                maxLines: 1,
                overflow: .ellipsis,
              ).debug,
            ),
          ],
          ?modeWidget,
          _AnimatedActionItem(
            visible: showResumeAction,
            duration: actionAnimDuration,
            curve: actionAnimCurve,
            child: Row(
              mainAxisSize: .min,
              children: [
                4.w,
                Tooltip(
                  message: s.chat_resume,
                  child: GestureDetector(
                    onTap: _onResumePressed,
                    child: Container(
                      padding: .zero,
                      child: Container(
                        padding: const .symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: .all(color: primaryColor.q(.67)),
                          borderRadius: .circular(4),
                        ),
                        child: Text(
                          s.chat_resume,
                          style: TS(c: primaryColor, w: .w600, s: 16),
                        ),
                      ),
                    ),
                  ).debug,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedActionItem extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const _AnimatedActionItem({
    required this.visible,
    required this.child,
    required this.duration,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Alignment alignment = theme.useMaterial3 ? .centerLeft : .centerLeft;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: .0, end: visible ? 1.0 : .0),
      duration: duration,
      curve: curve,
      child: child,
      builder: (BuildContext context, double value, Widget? child) {
        final bool hidden = value <= .001;

        return IgnorePointer(
          ignoring: !visible,
          child: ExcludeSemantics(
            excluding: hidden,
            child: Opacity(
              opacity: value,
              child: ClipRect(
                child: Align(
                  alignment: alignment,
                  widthFactor: value,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
