// Dart imports:
import 'dart:math' as math;

// Flutter imports:
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
import 'package:zone/model/sampler_and_penalty_param.dart';
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
  final String? bottomDetailsScope;

  const BotMessageBottom(
    this.msg,
    this.index, {
    super.key,
    this.preferredDemoType,
    this.finalContent,
    this.onRegeneratePressed,
    this.onResumePressed,
    this.disableDefaultActions = false,
    this.bottomDetailsScope,
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

  int _estimateTokenCount(String content) {
    final String normalized = content.trim();
    if (normalized.isEmpty) return 0;

    final RegExp cjk = RegExp(r'[\u3400-\u9FFF]');
    final RegExp latinDigit = RegExp(r'[A-Za-z0-9]');

    int cjkCount = 0;
    int latinCount = 0;
    int otherCount = 0;

    for (final int rune in normalized.runes) {
      final String char = String.fromCharCode(rune);
      if (char.trim().isEmpty) continue;
      if (cjk.hasMatch(char)) {
        cjkCount = cjkCount + 1;
        continue;
      }
      if (latinDigit.hasMatch(char)) {
        latinCount = latinCount + 1;
        continue;
      }
      otherCount = otherCount + 1;
    }

    final int latinTokenEstimate = (latinCount / 4).ceil();
    final int estimated = cjkCount + latinTokenEstimate + otherCount;
    return estimated;
  }

  String _formatSpeed({required double speed}) {
    if (speed <= 0) return "--";
    return "${speed.toStringAsFixed(1)} tok/s";
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
    final bool showMoreButton = true;

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

    final String detailsScope = bottomDetailsScope ?? (disableDefaultActions ? "preview_bot_message_bottom" : "chat_bot_message_bottom");
    final Map<String, bool> detailsExpandedMap = ref.watch(P.msg.bottomDetailsExpanded);
    final String detailsStateKey = "$detailsScope::${msg.id}";
    final bool detailsExpanded = detailsExpandedMap[detailsStateKey] ?? false;

    final double verticalPaddingAdditions = isMobile ? 8.0 : 0.0;
    final Widget branchSwitcher = IgnorePointer(
      ignoring: disableDefaultActions,
      child: BranchSwitcher(msg, index).debug,
    );
    const Duration actionAnimDuration = Duration(milliseconds: 200);
    const Curve actionAnimCurve = Curves.easeOutCubic;
    final bool resumeMatched = disableDefaultActions ? true : receiveId == msg.id;
    final bool showResumeAction = showResumeButton && paused && resumeMatched && !isBatch;
    final bool showEditAction = showEditButton && !changing;

    final int messageTokenCount = _estimateTokenCount(msg.content);
    final List<model.Message> pathMessages = ref.watch(P.msg.list);
    final int currentPathIndex = pathMessages.indexWhere((model.Message message) => message.id == msg.id);
    final Iterable<model.Message> contextMessages = currentPathIndex < 0 ? <model.Message>[msg] : pathMessages.take(currentPathIndex + 1);
    int contextTokenCount = 0;
    for (final model.Message message in contextMessages) {
      contextTokenCount = contextTokenCount + _estimateTokenCount(message.content);
    }

    final double prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final double decodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final bool showLiveSpeed = receiveId == msg.id || msg.changing || msg.paused;
    final String prefillSpeedText = showLiveSpeed ? _formatSpeed(speed: prefillSpeed) : "--";
    final String decodeSpeedText = showLiveSpeed ? _formatSpeed(speed: decodeSpeed) : "--";

    final List<SamplerAndPenaltyParam> parsedDecodeParams = msg.parsedDecodeParams;
    final String decodeParamSummary = switch (parsedDecodeParams.length) {
      0 => "--",
      1 => parsedDecodeParams.first.displayName,
      _ => "${parsedDecodeParams.first.displayName} x${parsedDecodeParams.length}",
    };

    final String runningModeText = msg.runningMode ?? "--";
    final String modelNameText = msg.modelName ?? "--";
    final String rawDecodeParamsText = (msg.rawDecodeParams == null || msg.rawDecodeParams!.trim().isEmpty)
        ? "--"
        : msg.rawDecodeParams!.trim();

    return Padding(
      padding: .only(top: isMobile ? .0 : 8.0),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
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
              branchSwitcher,
              const Spacer(),
              _AnimatedActionItem(
                visible: showMoreButton,
                duration: actionAnimDuration,
                curve: actionAnimCurve,
                child: Tooltip(
                  message: detailsExpanded ? "${s.more} ↑" : "${s.more} ↓",
                  child: GestureDetector(
                    onTap: () => P.msg.toggleBottomDetailsExpanded(scope: detailsScope, messageId: msg.id),
                    child: AnimatedContainer(
                      duration: actionAnimDuration,
                      curve: actionAnimCurve,
                      padding: .only(left: 6, top: 4 + verticalPaddingAdditions, right: 6, bottom: 4 + verticalPaddingAdditions),
                      decoration: BoxDecoration(
                        color: detailsExpanded ? Colors.transparent : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisSize: .min,
                        children: [
                          Icon(
                            Symbols.more_horiz,
                            color: detailsExpanded ? primaryColor : primaryColor.q(.82),
                            size: 20,
                          ).debug,
                          AnimatedRotation(
                            turns: detailsExpanded ? .5 : .0,
                            duration: actionAnimDuration,
                            curve: actionAnimCurve,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: detailsExpanded ? primaryColor : primaryColor.q(.72),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).debug,
              ),
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
          _AnimatedBottomDetailsSection(
            visible: detailsExpanded,
            duration: actionAnimDuration,
            curve: actionAnimCurve,
            child: Padding(
              padding: const .only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (showEditAction)
                    _BottomDetailsActionChip(
                      icon: Symbols.edit,
                      label: s.edit,
                      color: primaryColor,
                      onTap: disableDefaultActions ? null : _onBotEditPressed,
                    ),
                  _BottomDetailsMetaChip(
                    label: "msg tok",
                    value: messageTokenCount.toString(),
                    color: primaryColor,
                  ),
                  _BottomDetailsMetaChip(
                    label: "ctx tok",
                    value: contextTokenCount.toString(),
                    color: primaryColor,
                  ),
                  _BottomDetailsMetaChip(
                    label: s.prefill,
                    value: prefillSpeedText,
                    color: primaryColor,
                  ),
                  _BottomDetailsMetaChip(
                    label: s.decode,
                    value: decodeSpeedText,
                    color: primaryColor,
                  ),
                  _BottomDetailsMetaChip(
                    label: "mode",
                    value: runningModeText,
                    color: primaryColor,
                  ),
                  _BottomDetailsMetaChip(
                    label: "model",
                    value: modelNameText,
                    color: primaryColor,
                  ),
                  _BottomDetailsMetaChip(
                    label: s.decode_param,
                    value: decodeParamSummary,
                    color: primaryColor,
                  ),
                  _BottomDetailsMetaChip(
                    label: "raw",
                    value: rawDecodeParamsText,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomDetailsMetaChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BottomDetailsMetaChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "$label: $value",
      child: Container(
        padding: const .symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.q(.08),
          borderRadius: .circular(6),
          border: Border.all(color: color.q(.22)),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            Text(
              "$label: ",
              style: TS(c: color.q(.82), s: 11, w: .w500),
            ),
            Text(
              value,
              style: TS(c: color, s: 11, w: .w600),
              maxLines: 1,
              overflow: .ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomDetailsActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _BottomDetailsActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const .symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: disabled ? color.q(.04) : color.q(.08),
          borderRadius: .circular(6),
          border: Border.all(color: disabled ? color.q(.14) : color.q(.24)),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            Icon(
              icon,
              size: 14,
              color: disabled ? color.q(.42) : color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TS(c: disabled ? color.q(.42) : color, s: 11, w: .w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBottomDetailsSection extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const _AnimatedBottomDetailsSection({
    required this.visible,
    required this.child,
    required this.duration,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
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
            child: ClipRect(
              child: Align(
                alignment: .topLeft,
                heightFactor: value,
                child: Opacity(
                  opacity: value,
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
