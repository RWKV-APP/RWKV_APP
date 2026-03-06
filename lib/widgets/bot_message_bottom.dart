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
import 'package:zone/func/extensions/num.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/sampler_and_penalty_param.dart';
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

  void _onDeleteBranchPressed() async {
    if (disableDefaultActions) return;
    await P.chat.onDeleteBranchPressed(msg: msg);
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

  String _formatSpeed({required double? speed}) {
    if (speed == null || speed <= 0) return "--";
    return speed.toStringAsFixed(1);
  }

  String _formatCompactSpeed({required double? speed}) {
    if (speed == null || speed <= 0) return "--";
    return speed.toStringAsFixed(1);
  }

  double _estimateInlineTokenWidth({
    required String text,
  }) {
    final length = text.runes.length;
    final estimated = 18 + length * 4.8;
    if (estimated < 52) return 52;
    if (estimated > 90) return 90;
    return estimated;
  }

  String? _localizedDecodeParamSummary({
    required List<SamplerAndPenaltyParam> parsedDecodeParams,
  }) {
    if (parsedDecodeParams.isEmpty) return null;
    final displayName = parsedDecodeParams.first.displayName;
    if (parsedDecodeParams.length == 1) return displayName;
    return "$displayName x${parsedDecodeParams.length}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (msg.isMine) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final s = S.of(context);

    final demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    final isTTSDemo = demoType == .tts;

    final receiveId = ref.watch(P.chat.receiveId);
    final selectMessageMode = ref.watch(P.chat.isSharing);

    final isMobile = ref.watch(P.app.isMobile);

    final paused = msg.paused;

    final changing = msg.changing;

    final primaryColor = theme.colorScheme.primary;

    final worldType = ref.watch(P.rwkv.currentWorldType);

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

    final isBatch = getIsBatch(finalContent ?? msg.content);

    if (isBatch) {
      showEditButton = false;
    }

    if (changing) {
      showCopyButton = false;
      showBotRegenerateButton = false;
      showEditButton = false;
      showShareButton = false;
    }

    final detailsScope = bottomDetailsScope ?? (disableDefaultActions ? "preview_bot_message_bottom" : "chat_bot_message_bottom");
    final detailsExpandedMap = ref.watch(P.msg.bottomDetailsExpanded);
    final detailsStateKey = "$detailsScope::${msg.id}";
    final detailsExpanded = detailsExpandedMap[detailsStateKey] ?? false;

    final verticalPaddingAdditions = isMobile ? 8.0 : 0.0;
    final branchSwitcherAvailable = P.msg.siblingCount(msg) > 1;
    final showBranchSwitcher = branchSwitcherAvailable;
    final showDeleteBranchAction = branchSwitcherAvailable && !disableDefaultActions && !changing && !selectMessageMode;
    final Widget branchSwitcher = IgnorePointer(
      ignoring: disableDefaultActions,
      child: BranchSwitcher(msg, index),
    );
    const actionAnimDuration = Duration(milliseconds: 200);
    const Curve actionAnimCurve = Curves.easeOutCubic;
    final resumeMatched = disableDefaultActions ? true : receiveId == msg.id;
    final showResumeAction = showResumeButton && paused && resumeMatched && !isBatch;
    final showEditAction = showEditButton && !changing;
    ref.watch(P.msg.msgNode);

    final messageTokensCountMap = ref.watch(P.msg.bottomMessageTokensCount);
    final conversationTokensCountMap = ref.watch(P.msg.bottomConversationTokensCount);
    final adapterMessageTokenCount = messageTokensCountMap[msg.id];
    final adapterConversationTokenCount = conversationTokensCountMap[msg.id];
    final persistedMessageTokenCount = msg.messageTokensCount;
    final persistedConversationTokenCount = msg.conversationTokensCount;

    final resolvedMessageTokenCount = msg.changing
        ? (adapterMessageTokenCount ?? persistedMessageTokenCount)
        : (persistedMessageTokenCount ?? adapterMessageTokenCount);

    final resolvedConversationTokenCount = msg.changing
        ? (adapterConversationTokenCount ?? persistedConversationTokenCount)
        : (persistedConversationTokenCount ?? adapterConversationTokenCount);

    final messageTokenCountText = resolvedMessageTokenCount?.toString() ?? (msg.changing ? s.generating : "--");
    final contextTokenCountText = resolvedConversationTokenCount?.toString() ?? (msg.changing ? s.generating : "--");

    final showConversationTokenLimitHint =
        !msg.changing &&
        resolvedConversationTokenCount != null &&
        resolvedConversationTokenCount >= Config.newConversationTokenReminderThreshold;
    final isInlineTokenGenerating = messageTokenCountText == s.generating || contextTokenCountText == s.generating;

    final inlineConversationTokenCoreText = isInlineTokenGenerating ? s.generating : "$messageTokenCountText/$contextTokenCountText tok";

    final inlineConversationTokenText = showConversationTokenLimitHint
        ? "$inlineConversationTokenCoreText · ${s.conversation_token_limit_hint_short}"
        : inlineConversationTokenCoreText;

    final livePrefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final liveDecodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final effectiveLivePrefillSpeed = livePrefillSpeed > 0 ? livePrefillSpeed : (msg.prefillSpeed ?? .0);
    final effectiveLiveDecodeSpeed = liveDecodeSpeed > 0 ? liveDecodeSpeed : (msg.decodeSpeed ?? .0);
    final changingInlinePrefillSpeedText = _formatCompactSpeed(speed: effectiveLivePrefillSpeed);
    final changingInlineDecodeSpeedText = _formatCompactSpeed(speed: effectiveLiveDecodeSpeed);
    final settledPrefillSpeedText = _formatSpeed(speed: msg.prefillSpeed);
    final settledDecodeSpeedText = _formatSpeed(speed: msg.decodeSpeed);
    final detailsPrefillSpeedText = msg.changing ? changingInlinePrefillSpeedText : settledPrefillSpeedText;
    final detailsDecodeSpeedText = msg.changing ? changingInlineDecodeSpeedText : settledDecodeSpeedText;
    final detailsPrefillSpeedDisplay = detailsPrefillSpeedText == "--" ? "--" : "$detailsPrefillSpeedText t/s";
    final detailsDecodeSpeedDisplay = detailsDecodeSpeedText == "--" ? "--" : "$detailsDecodeSpeedText t/s";

    final parsedDecodeParams = msg.parsedDecodeParams;
    final currentDecodeParamType = ref.watch(P.rwkv.decodeParamType);
    final currentDecodeParamDisplayName = SamplerAndPenaltyParam.fromDecodeParamType(currentDecodeParamType).displayName;
    String? decodeParamSummary = _localizedDecodeParamSummary(parsedDecodeParams: parsedDecodeParams);
    if (decodeParamSummary == null && (msg.changing || msg.paused || receiveId == msg.id)) {
      decodeParamSummary = currentDecodeParamDisplayName;
    }
    final latestModel = ref.watch(P.rwkv.latestModel);
    final currentGroupInfo = ref.watch(P.rwkv.currentGroupInfo);
    final liveModelName = isTTSDemo ? (latestModel?.name ?? currentGroupInfo?.displayName) : null;
    final modelNameText = msg.modelName?.isNotEmpty == true ? msg.modelName! : (liveModelName ?? "--");
    final showChangingPrefillProgress = changing && !isTTSDemo;

    final inlineConversationTokenEstimatedWidth = isTTSDemo ? .0 : _estimateInlineTokenWidth(text: inlineConversationTokenText);
    final showCopyInMain = showCopyButton;
    final showShareInMain = showShareButton;
    final showRegenerateInMain = showBotRegenerateButton;
    final showEditInMain = showEditAction;
    final shouldUseWrapRatherThanRow = ref.watch(P.ui.shouldUseWrapRatherThanRow);
    final messageListLayoutKeys = ref.watch(P.ui.messageListLayoutKeys);
    final layoutItemVisibility = {
      "copy": showCopyInMain,
      "share": showShareInMain,
      "regenerate": showRegenerateInMain,
      "edit": showEditInMain,
      "changing": changing,
      "branch_switcher": showBranchSwitcher,
      "t": true,
      "more": showMoreButton,
      "resume": showResumeAction,
    };
    bool hasStaleHiddenLayoutKey = false;
    for (final MapEntry<String, bool> entry in layoutItemVisibility.entries) {
      if (entry.value) {
        continue;
      }
      final hiddenItemWidth = messageListLayoutKeys[entry.key] ?? .0;
      if (hiddenItemWidth <= .0) {
        continue;
      }
      hasStaleHiddenLayoutKey = true;
      break;
    }
    if (hasStaleHiddenLayoutKey) {
      Future.microtask(() {
        final updatedLayoutKeys = {
          ...P.ui.messageListLayoutKeys.q,
        };
        bool changed = false;
        for (final MapEntry<String, bool> entry in layoutItemVisibility.entries) {
          if (entry.value) {
            continue;
          }
          final hiddenItemWidth = updatedLayoutKeys[entry.key] ?? .0;
          if (hiddenItemWidth <= .0) {
            continue;
          }
          updatedLayoutKeys[entry.key] = .0;
          changed = true;
        }
        if (!changed) {
          return;
        }
        P.ui.messageListLayoutKeys.q = updatedLayoutKeys;
      });
    }

    final children =
        [
          if (showCopyInMain)
            KeyedSubtree(
              key: const ValueKey<String>("copy"),
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (showShareInMain)
            KeyedSubtree(
              key: const ValueKey<String>("share"),
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (showRegenerateInMain)
            KeyedSubtree(
              key: const ValueKey<String>("regenerate"),
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (showEditInMain)
            KeyedSubtree(
              key: const ValueKey<String>("edit"),
              child: Tooltip(
                message: s.edit,
                child: GestureDetector(
                  onTap: _onBotEditPressed,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Padding(
                      padding: .only(left: 4, top: 4 + verticalPaddingAdditions, right: 4, bottom: 4 + verticalPaddingAdditions),
                      child: Icon(
                        Icons.edit_outlined,
                        color: primaryColor.q(.8),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (changing)
            KeyedSubtree(
              key: const ValueKey<String>("changing"),
              child: Tooltip(
                message: s.generating,
                child: Padding(
                  padding: .only(left: 4, top: 4 + verticalPaddingAdditions, right: 4, bottom: 4 + verticalPaddingAdditions),
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      TweenAnimationBuilder(
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
                        ),
                      ),
                      if (!detailsExpanded) ...[
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: .min,
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              "${s.prefill} $changingInlinePrefillSpeedText t/s",
                              style: TS(c: primaryColor.q(.92), s: 10, w: .w600),
                            ),
                            Text(
                              "${s.decode} $changingInlineDecodeSpeedText t/s",
                              style: TS(c: primaryColor.q(.92), s: 10, w: .w600),
                            ),
                          ],
                        ),
                      ],
                      if (showChangingPrefillProgress)
                        _ChangingPrefillProgressInline(
                          changing: changing,
                          detailsExpanded: detailsExpanded,
                          color: primaryColor,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (showBranchSwitcher)
            KeyedSubtree(
              key: const ValueKey<String>("branch_switcher"),
              child: branchSwitcher,
            ),
          KeyedSubtree(
            key: const ValueKey<String>("t"),
            child: Padding(
              padding: const .symmetric(horizontal: 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: inlineConversationTokenEstimatedWidth,
                ),
                child: Text(
                  inlineConversationTokenText,
                  maxLines: 1,
                  overflow: .ellipsis,
                  softWrap: false,
                  style: TS(
                    c: primaryColor.q(.76),
                    s: 10,
                    w: .w600,
                  ),
                  textAlign: .left,
                ),
              ),
            ),
          ),
          if (!shouldUseWrapRatherThanRow) const Spacer(),
          if (showMoreButton)
            KeyedSubtree(
              key: const ValueKey<String>("more"),
              child: Tooltip(
                message: detailsExpanded ? "${s.more} ↑" : "${s.more} ↓",
                child: GestureDetector(
                  onTap: () => P.msg.toggleBottomDetailsExpanded(scope: detailsScope, messageId: msg.id),
                  child: AnimatedContainer(
                    duration: actionAnimDuration,
                    curve: actionAnimCurve,
                    padding: .only(
                      left: 2,
                      top: 4 + verticalPaddingAdditions,
                      right: 2,
                      bottom: 4 + verticalPaddingAdditions,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: .circular(6),
                    ),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        Icon(
                          Symbols.more_horiz,
                          color: detailsExpanded ? primaryColor : primaryColor.q(.82),
                          size: 20,
                        ),
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
              ),
            ),
          if (showResumeAction)
            KeyedSubtree(
              key: const ValueKey<String>("resume"),
              child: Tooltip(
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
                ),
              ),
            ),
          // TODO: Horizontal layout logic
        ].m((w) {
          if (w is Spacer) return w;
          return MeasureSize(
            onChange: (size) async {
              final width = size.width.roundToDouble();
              await 0.msLater;
              final widgetKey = w.key;
              final layoutKey = widgetKey is ValueKey<String> ? widgetKey.value : "t";
              final updatedLayoutKeys = {
                ...P.ui.messageListLayoutKeys.q,
              };
              for (final entry in layoutItemVisibility.entries) {
                if (entry.value) {
                  continue;
                }
                updatedLayoutKeys[entry.key] = .0;
              }
              updatedLayoutKeys[layoutKey] = width;
              P.ui.messageListLayoutKeys.q = updatedLayoutKeys;
            },
            // child: w.debug,
            child: w,
          );
        });

    return Padding(
      padding: .only(top: isMobile ? .0 : 8.0),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // qqq("constraints.maxWidth: $constraints.maxWidth");
              final maxWidth = constraints.maxWidth;

              Future.delayed(30.ms).then((_) {
                P.ui.maxWidthAllowedForLayout.q = maxWidth;
              });

              if (shouldUseWrapRatherThanRow) {
                return Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: .center,
                  runSpacing: 8,
                  children: children,
                );
              }

              return Row(
                mainAxisAlignment: .start,
                children: children,
              );
            },
          ),
          _AnimatedBottomDetailsSection(
            visible: detailsExpanded,
            duration: actionAnimDuration,
            curve: actionAnimCurve,
            child: Padding(
              padding: const .only(top: 4),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _BottomDetailsMetaChip(
                        label: "",
                        value: modelNameText,
                        color: primaryColor,
                      ),
                      _BottomDetailsMetaChip(
                        label: s.prefill,
                        value: detailsPrefillSpeedDisplay,
                        color: primaryColor,
                      ),
                      _BottomDetailsMetaChip(
                        label: s.decode,
                        value: detailsDecodeSpeedDisplay,
                        color: primaryColor,
                      ),
                    ],
                  ),
                  if (showDeleteBranchAction)
                    Padding(
                      padding: const .only(top: 8),
                      child: Tooltip(
                        message: s.delete,
                        child: GestureDetector(
                          onTap: _onDeleteBranchPressed,
                          child: Container(
                            padding: const .symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryColor.q(.05),
                              borderRadius: .circular(8),
                              border: Border.all(color: primaryColor.q(.14)),
                            ),
                            child: Row(
                              mainAxisSize: .min,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: primaryColor.q(.9),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.delete,
                                  style: TS(c: primaryColor.q(.92), s: 11, w: .w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

class _ChangingPrefillProgressInline extends ConsumerWidget {
  final bool changing;
  final bool detailsExpanded;
  final Color color;

  const _ChangingPrefillProgressInline({
    required this.changing,
    required this.detailsExpanded,
    required this.color,
  });

  int _percentValue({required double progress}) {
    final clampedProgress = progress.clamp(0, 1).toDouble();
    return (clampedProgress * 100).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (!changing) return const SizedBox.shrink();

    final progress = ref.watch(P.rwkv.prefillProgress).clamp(0, 1).toDouble();
    final percent = _percentValue(progress: progress);
    if (percent >= 100) return const SizedBox.shrink();

    final percentText = "$percent%";

    return Row(
      mainAxisSize: .min,
      children: [
        SizedBox(width: detailsExpanded ? 6 : 8),
        Text(
          percentText,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color.q(.92),
            fontWeight: .w700,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _BottomDetailsMetaChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Widget? leading;

  const _BottomDetailsMetaChip({
    required this.label,
    required this.value,
    required this.color,
    // ignore: unused_element_parameter
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final tooltipText = label.isEmpty ? value : "$label $value";

    return Tooltip(
      message: tooltipText,
      child: Container(
        padding: const .symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.q(.05),
          borderRadius: .circular(8),
          border: Border.all(color: color.q(.14)),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 4),
            ],
            Text.rich(
              TextSpan(
                children: [
                  if (label.isNotEmpty)
                    TextSpan(
                      text: "$label ",
                      style: TS(c: color.q(.62), s: 10, w: .w500),
                    ),
                  TextSpan(
                    text: value,
                    style: TS(c: color.q(.92), s: 11, w: .w600),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: .ellipsis,
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
        final hidden = value <= .001;
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
