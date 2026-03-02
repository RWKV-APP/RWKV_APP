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
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/group_info.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/sampler_and_penalty_param.dart';
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
    final int length = text.runes.length;
    final double estimated = 18 + length * 4.8;
    if (estimated < 52) return 52;
    if (estimated > 90) return 90;
    return estimated;
  }

  String _extractSuffixBySeparator({
    required String source,
    required String separator,
  }) {
    final int separatorIndex = source.lastIndexOf(separator);
    if (separatorIndex < 0) return source;
    return source.substring(separatorIndex + separator.length).trim();
  }

  String _localizedReasoningMode({
    required S s,
    required String? runningMode,
  }) {
    final thinking_mode.ThinkingMode mode = thinking_mode.ThinkingMode.fromString(runningMode);
    final String localizedWithPrefix = switch (mode) {
      .lighting => s.thinking_mode_auto(""),
      .none => s.thinking_mode_off(""),
      .free => s.thinking_mode_high(""),
      .preferChinese => s.thinking_mode_high(""),
      .fast => s.think_button_mode_fast(""),
      .en => s.think_button_mode_en(""),
      .enShort => s.think_button_mode_en_short(""),
      .enLong => s.think_button_mode_en_long(""),
    };
    return _extractSuffixBySeparator(source: localizedWithPrefix, separator: s.hyphen);
  }

  String? _localizedDecodeParamSummary({
    required List<SamplerAndPenaltyParam> parsedDecodeParams,
  }) {
    if (parsedDecodeParams.isEmpty) return null;
    final String displayName = parsedDecodeParams.first.displayName;
    if (parsedDecodeParams.length == 1) return displayName;
    return "$displayName x${parsedDecodeParams.length}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (msg.isMine) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final S s = S.of(context);

    final DemoType demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    final bool isTTSDemo = demoType == .tts;

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
    final bool branchSwitcherAvailable = P.msg.siblingCount(msg) > 1;
    final bool showBranchSwitcher = branchSwitcherAvailable;
    final Widget branchSwitcher = IgnorePointer(
      ignoring: disableDefaultActions,
      child: BranchSwitcher(msg, index),
    );
    const Duration actionAnimDuration = Duration(milliseconds: 200);
    const Curve actionAnimCurve = Curves.easeOutCubic;
    final bool resumeMatched = disableDefaultActions ? true : receiveId == msg.id;
    final bool showResumeAction = showResumeButton && paused && resumeMatched && !isBatch;
    final bool showEditAction = showEditButton && !changing;
    ref.watch(P.msg.msgNode);

    final Map<int, int> messageTokensCountMap = ref.watch(P.msg.bottomMessageTokensCount);
    final Map<int, int> conversationTokensCountMap = ref.watch(P.msg.bottomConversationTokensCount);
    final int? adapterMessageTokenCount = messageTokensCountMap[msg.id];
    final int? adapterConversationTokenCount = conversationTokensCountMap[msg.id];
    final int? persistedMessageTokenCount = msg.messageTokensCount;
    final int? persistedConversationTokenCount = msg.conversationTokensCount;
    final int? resolvedMessageTokenCount = msg.changing
        ? (adapterMessageTokenCount ?? persistedMessageTokenCount)
        : (persistedMessageTokenCount ?? adapterMessageTokenCount);
    final int? resolvedConversationTokenCount = msg.changing
        ? (adapterConversationTokenCount ?? persistedConversationTokenCount)
        : (persistedConversationTokenCount ?? adapterConversationTokenCount);
    final String messageTokenCountText = resolvedMessageTokenCount?.toString() ?? (msg.changing ? s.generating : "--");
    final String contextTokenCountText = resolvedConversationTokenCount?.toString() ?? (msg.changing ? s.generating : "--");
    final bool showConversationTokenLimitHint =
        !msg.changing &&
        resolvedConversationTokenCount != null &&
        resolvedConversationTokenCount >= Config.newConversationTokenReminderThreshold;
    final bool isInlineTokenGenerating = messageTokenCountText == s.generating || contextTokenCountText == s.generating;
    final String inlineConversationTokenCoreText = isInlineTokenGenerating
        ? s.generating
        : "$messageTokenCountText/$contextTokenCountText tok";
    final String inlineConversationTokenText = showConversationTokenLimitHint
        ? "$inlineConversationTokenCoreText · ${s.conversation_token_limit_hint_short}"
        : inlineConversationTokenCoreText;

    final double livePrefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final double liveDecodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final double effectiveLivePrefillSpeed = livePrefillSpeed > 0 ? livePrefillSpeed : (msg.prefillSpeed ?? .0);
    final double effectiveLiveDecodeSpeed = liveDecodeSpeed > 0 ? liveDecodeSpeed : (msg.decodeSpeed ?? .0);
    final String changingInlinePrefillSpeedText = _formatCompactSpeed(speed: effectiveLivePrefillSpeed);
    final String changingInlineDecodeSpeedText = _formatCompactSpeed(speed: effectiveLiveDecodeSpeed);
    final String settledPrefillSpeedText = _formatSpeed(speed: msg.prefillSpeed);
    final String settledDecodeSpeedText = _formatSpeed(speed: msg.decodeSpeed);
    final String detailsPrefillSpeedText = msg.changing ? changingInlinePrefillSpeedText : settledPrefillSpeedText;
    final String detailsDecodeSpeedText = msg.changing ? changingInlineDecodeSpeedText : settledDecodeSpeedText;
    final String detailsPrefillSpeedDisplay = detailsPrefillSpeedText == "--" ? "--" : "$detailsPrefillSpeedText t/s";
    final String detailsDecodeSpeedDisplay = detailsDecodeSpeedText == "--" ? "--" : "$detailsDecodeSpeedText t/s";

    final List<SamplerAndPenaltyParam> parsedDecodeParams = msg.parsedDecodeParams;
    final DecodeParamType currentDecodeParamType = ref.watch(P.rwkv.decodeParamType);
    final String currentDecodeParamDisplayName = SamplerAndPenaltyParam.fromDecodeParamType(currentDecodeParamType).displayName;
    String? decodeParamSummary = _localizedDecodeParamSummary(parsedDecodeParams: parsedDecodeParams);
    if (decodeParamSummary == null && (msg.changing || msg.paused || receiveId == msg.id)) {
      decodeParamSummary = currentDecodeParamDisplayName;
    }
    final String runningModeText = _localizedReasoningMode(
      s: s,
      runningMode: msg.runningMode,
    );
    final FileInfo? latestModel = ref.watch(P.rwkv.latestModel);
    final GroupInfo? currentGroupInfo = ref.watch(P.rwkv.currentGroupInfo);
    final String? liveModelName = isTTSDemo ? (latestModel?.name ?? currentGroupInfo?.displayName) : null;
    final String modelNameText = msg.modelName?.isNotEmpty == true ? msg.modelName! : (liveModelName ?? "--");
    final bool showChangingPrefillProgress = changing && !isTTSDemo;

    final double inlineConversationTokenEstimatedWidth = isTTSDemo ? .0 : _estimateInlineTokenWidth(text: inlineConversationTokenText);
    final bool showCopyInMain = showCopyButton;
    final bool showShareInMain = showShareButton;
    final bool showRegenerateInMain = showBotRegenerateButton;
    final bool showEditInMain = showEditAction;

    final List<Widget> children =
        [
          _AnimatedActionItem(
            layoutKey: "copy",
            visible: showCopyInMain,
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
                    ),
                  ),
                ),
              ),
            ),
          ),
          _AnimatedActionItem(
            layoutKey: "share",
            visible: showShareInMain,
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
                    ),
                  ),
                ),
              ),
            ),
          ),
          _AnimatedActionItem(
            layoutKey: "regenerate",
            visible: showRegenerateInMain,
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
                    ),
                  ),
                ),
              ),
            ),
          ),
          _AnimatedActionItem(
            layoutKey: "edit",
            visible: showEditInMain,
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
                      Icons.edit_outlined,
                      color: primaryColor.q(.8),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _AnimatedActionItem(
            layoutKey: "changing",
            visible: changing,
            duration: actionAnimDuration,
            curve: actionAnimCurve,
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
          _AnimatedActionItem(
            layoutKey: "branch_switcher",
            visible: showBranchSwitcher,
            duration: actionAnimDuration,
            curve: actionAnimCurve,
            child: branchSwitcher,
          ),
          Padding(
            padding: const .symmetric(horizontal: 4),
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
          const Spacer(),
          _AnimatedActionItem(
            layoutKey: "more",
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
          _AnimatedActionItem(
            layoutKey: "resume",
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
                  ),
                ),
              ],
            ),
          ),
          // TODO: Horizontal layout logic
        ].m((w) {
          if (w is Spacer) return w;
          return MeasureSize(
            onChange: (size) async {
              await 10.msLater;
              if (w is _AnimatedActionItem) {
                P.ui.messageListLayoutKeys.q = {
                  ...P.ui.messageListLayoutKeys.q,
                  w.layoutKey: size.width,
                };
              } else {
                P.ui.messageListLayoutKeys.q = {
                  ...P.ui.messageListLayoutKeys.q,
                  "t": size.width,
                };
              }
            },
            child: w,
          );
        });

    final shouldUseWrapRatherThanRow = true;

    return Padding(
      padding: .only(top: isMobile ? .0 : 8.0),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              Future.delayed(0.ms).then((_) {
                P.ui.maxWidthAllowedForLayout.q = maxWidth;
              });

              if (shouldUseWrapRatherThanRow) {
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
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
    final double clampedProgress = progress.clamp(0, 1).toDouble();
    return (clampedProgress * 100).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    if (!changing) return const SizedBox.shrink();

    final S s = S.of(context);
    final double progress = ref.watch(P.rwkv.prefillProgress).clamp(0, 1).toDouble();
    final int percent = _percentValue(progress: progress);
    if (percent >= 100) return const SizedBox.shrink();

    final String percentText = "$percent%";
    final String progressLabel = s.prefill_progress_percent(percentText);

    return Row(
      mainAxisSize: .min,
      children: [
        SizedBox(width: detailsExpanded ? 6 : 8),
        Text(
          progressLabel,
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
    final String tooltipText = label.isEmpty ? value : "$label $value";

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
  final String layoutKey;

  const _AnimatedActionItem({
    required this.visible,
    required this.child,
    required this.duration,
    required this.curve,
    required this.layoutKey,
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
