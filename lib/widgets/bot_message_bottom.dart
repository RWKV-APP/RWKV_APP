// Dart imports:
import 'dart:async';
import 'dart:math' as math;

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/gen/assets.gen.dart';
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
    final bool showBranchSwitcher = !changing && branchSwitcherAvailable;
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
    final String messageTokenCountText = msg.changing
        ? s.generating
        : (persistedMessageTokenCount ?? adapterMessageTokenCount)?.toString() ?? "--";
    final String contextTokenCountText = msg.changing
        ? s.generating
        : (persistedConversationTokenCount ?? adapterConversationTokenCount)?.toString() ?? "--";

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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _BottomActionLayout layout = _BottomActionLayout.resolve(
          availableWidth: constraints.maxWidth,
          showCopyButton: showCopyButton,
          showShareButton: showShareButton,
          showRegenerateButton: showBotRegenerateButton,
          showChangingIndicator: changing,
          showChangingSpeedTexts: changing && !detailsExpanded,
          showChangingProgressText: showChangingPrefillProgress,
          hasBranchSwitcher: showBranchSwitcher,
          showMoreButton: showMoreButton,
          showResumeButton: showResumeAction,
        );
        final bool showCopyInMain = layout.showCopyInMain;
        final bool showShareInMain = layout.showShareInMain;
        final bool showRegenerateInMain = layout.showRegenerateInMain;
        final bool showCopyInPanel = layout.showCopyInPanel;
        final bool showShareInPanel = layout.showShareInPanel;
        final bool showRegenerateInPanel = layout.showRegenerateInPanel;
        final bool hasCompactedActions = showCopyInPanel || showShareInPanel || showRegenerateInPanel;

        return Padding(
          padding: .only(top: isMobile ? .0 : 8.0),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                mainAxisAlignment: .start,
                children: [
                  _AnimatedActionItem(
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
                              const SizedBox(width: 4),
                              Column(
                                mainAxisSize: .min,
                                crossAxisAlignment: .start,
                                children: [
                                  Text(
                                    "${s.prefill}: $changingInlinePrefillSpeedText t/s",
                                    style: TS(c: primaryColor.q(.92), s: 10, w: .w600),
                                  ),
                                  Text(
                                    "${s.decode}: $changingInlineDecodeSpeedText t/s",
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
                    visible: showBranchSwitcher,
                    duration: actionAnimDuration,
                    curve: actionAnimCurve,
                    child: branchSwitcher,
                  ),
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
                            color: Colors.transparent,
                            borderRadius: .circular(6),
                          ),
                          child: Row(
                            mainAxisSize: .min,
                            children: [
                              Icon(
                                Symbols.more_horiz,
                                color: detailsExpanded || hasCompactedActions ? primaryColor : primaryColor.q(.82),
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
                ],
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
                      if (showEditAction || showRegenerateInPanel || showShareInPanel || showCopyInPanel)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (showEditAction)
                              _BottomDetailsActionChip(
                                icon: Symbols.edit,
                                label: s.edit,
                                color: primaryColor,
                                onTap: disableDefaultActions ? null : _onBotEditPressed,
                              ),
                            if (showRegenerateInPanel)
                              _BottomDetailsActionChip(
                                icon: Symbols.refresh,
                                label: s.regenerate,
                                color: primaryColor,
                                onTap: disableDefaultActions ? null : _onRegeneratePressed,
                              ),
                            if (showShareInPanel)
                              _BottomDetailsActionChip(
                                icon: Symbols.share_rounded,
                                label: s.share,
                                color: primaryColor,
                                onTap: disableDefaultActions ? null : _onSharePressed,
                              ),
                            if (showCopyInPanel)
                              _BottomDetailsActionChip(
                                icon: Symbols.content_copy,
                                label: s.copy_text,
                                color: primaryColor,
                                onTap: disableDefaultActions ? null : _onCopyPressed,
                              ),
                          ],
                        ),
                      if (showEditAction || showRegenerateInPanel || showShareInPanel || showCopyInPanel) 6.h,
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _BottomDetailsMetaChip(
                            label: s.model,
                            value: modelNameText,
                            color: primaryColor,
                          ),
                          if (!isTTSDemo)
                            _BottomDetailsMetaChip(
                              label: s.message_token_count,
                              value: messageTokenCountText,
                              color: primaryColor,
                            ),
                          if (!isTTSDemo)
                            _BottomDetailsMetaChip(
                              label: s.conversation_token_count,
                              value: contextTokenCountText,
                              color: primaryColor,
                            ),
                          _BottomDetailsMetaChip(
                            label: s.prefill_speed_tokens_per_second,
                            value: detailsPrefillSpeedText,
                            color: primaryColor,
                          ),
                          _BottomDetailsMetaChip(
                            label: s.decode_speed_tokens_per_second,
                            value: detailsDecodeSpeedText,
                            color: primaryColor,
                          ),
                          if (!isTTSDemo)
                            _BottomDetailsMetaChip(
                              label: s.reasoning_enabled,
                              value: runningModeText,
                              color: primaryColor,
                              leading: SvgPicture.asset(
                                Assets.img.chat.think,
                                width: 12,
                                height: 12,
                                colorFilter: .mode(primaryColor.q(.82), BlendMode.srcIn),
                              ),
                            ),
                          if (!isTTSDemo && decodeParamSummary != null)
                            _BottomDetailsMetaChip(
                              label: s.decode_param,
                              value: decodeParamSummary,
                              color: primaryColor,
                              leading: Icon(
                                Symbols.auto_awesome,
                                size: 13,
                                color: primaryColor.q(.82),
                              ),
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
      },
    );
  }
}

class _ChangingPrefillProgressInline extends ConsumerStatefulWidget {
  final bool changing;
  final bool detailsExpanded;
  final Color color;

  const _ChangingPrefillProgressInline({
    required this.changing,
    required this.detailsExpanded,
    required this.color,
  });

  @override
  ConsumerState<_ChangingPrefillProgressInline> createState() => _ChangingPrefillProgressInlineState();
}

class _ChangingPrefillProgressInlineState extends ConsumerState<_ChangingPrefillProgressInline> {
  Timer? _hideTimer;
  bool _hiddenAfterComplete = false;

  @override
  void didUpdateWidget(covariant _ChangingPrefillProgressInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.changing) return;
    _hideTimer?.cancel();
    _hideTimer = null;
    _hiddenAfterComplete = false;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hideTimer = null;
    super.dispose();
  }

  int _percentValue({required double progress}) {
    final double clampedProgress = progress.clamp(0, 1).toDouble();
    return (clampedProgress * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (!widget.changing) return const SizedBox.shrink();

    final S s = S.of(context);
    final double progress = ref.watch(P.rwkv.prefillProgress).clamp(0, 1).toDouble();
    final int percent = _percentValue(progress: progress);

    if (percent >= 100) {
      if (!_hiddenAfterComplete && _hideTimer == null) {
        _hideTimer = Timer(const Duration(milliseconds: 500), () {
          _hideTimer = null;
          if (!mounted) return;
          setState(() {
            _hiddenAfterComplete = true;
          });
        });
      }
    } else {
      _hideTimer?.cancel();
      _hideTimer = null;
      _hiddenAfterComplete = false;
    }

    if (_hiddenAfterComplete) return const SizedBox.shrink();
    final String percentText = "$percent%";
    final String progressLabel = s.prefill_progress_percent(percentText);

    return Row(
      mainAxisSize: .min,
      children: [
        SizedBox(width: widget.detailsExpanded ? 6 : 8),
        Text(
          progressLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: widget.color.q(.92),
            fontWeight: .w700,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _BottomActionLayout {
  final bool showRegenerateInMain;
  final bool showShareInMain;
  final bool showCopyInMain;
  final bool showRegenerateInPanel;
  final bool showShareInPanel;
  final bool showCopyInPanel;

  const _BottomActionLayout({
    required this.showRegenerateInMain,
    required this.showShareInMain,
    required this.showCopyInMain,
    required this.showRegenerateInPanel,
    required this.showShareInPanel,
    required this.showCopyInPanel,
  });

  static _BottomActionLayout resolve({
    required double availableWidth,
    required bool showRegenerateButton,
    required bool showShareButton,
    required bool showCopyButton,
    required bool showChangingIndicator,
    required bool showChangingSpeedTexts,
    required bool showChangingProgressText,
    required bool hasBranchSwitcher,
    required bool showMoreButton,
    required bool showResumeButton,
  }) {
    bool mainRegenerate = showRegenerateButton;
    bool mainShare = showShareButton;
    bool mainCopy = showCopyButton;
    bool panelRegenerate = false;
    bool panelShare = false;
    bool panelCopy = false;

    double estimatedWidth = _estimateMainRowWidth(
      showRegenerateButton: mainRegenerate,
      showShareButton: mainShare,
      showCopyButton: mainCopy,
      showChangingIndicator: showChangingIndicator,
      showChangingSpeedTexts: showChangingSpeedTexts,
      showChangingProgressText: showChangingProgressText,
      hasBranchSwitcher: hasBranchSwitcher,
      showMoreButton: showMoreButton,
      showResumeButton: showResumeButton,
    );

    if (estimatedWidth > availableWidth && mainRegenerate) {
      mainRegenerate = false;
      panelRegenerate = true;
      estimatedWidth = _estimateMainRowWidth(
        showRegenerateButton: mainRegenerate,
        showShareButton: mainShare,
        showCopyButton: mainCopy,
        showChangingIndicator: showChangingIndicator,
        showChangingSpeedTexts: showChangingSpeedTexts,
        showChangingProgressText: showChangingProgressText,
        hasBranchSwitcher: hasBranchSwitcher,
        showMoreButton: showMoreButton,
        showResumeButton: showResumeButton,
      );
    }

    if (estimatedWidth > availableWidth && mainCopy) {
      mainCopy = false;
      panelCopy = true;
      estimatedWidth = _estimateMainRowWidth(
        showRegenerateButton: mainRegenerate,
        showShareButton: mainShare,
        showCopyButton: mainCopy,
        showChangingIndicator: showChangingIndicator,
        showChangingSpeedTexts: showChangingSpeedTexts,
        showChangingProgressText: showChangingProgressText,
        hasBranchSwitcher: hasBranchSwitcher,
        showMoreButton: showMoreButton,
        showResumeButton: showResumeButton,
      );
    }

    if (estimatedWidth > availableWidth && mainShare) {
      mainShare = false;
      panelShare = true;
    }

    return _BottomActionLayout(
      showRegenerateInMain: mainRegenerate,
      showShareInMain: mainShare,
      showCopyInMain: mainCopy,
      showRegenerateInPanel: panelRegenerate,
      showShareInPanel: panelShare,
      showCopyInPanel: panelCopy,
    );
  }

  static double _estimateMainRowWidth({
    required bool showRegenerateButton,
    required bool showShareButton,
    required bool showCopyButton,
    required bool showChangingIndicator,
    required bool showChangingSpeedTexts,
    required bool showChangingProgressText,
    required bool hasBranchSwitcher,
    required bool showMoreButton,
    required bool showResumeButton,
  }) {
    double width = 0;
    if (showRegenerateButton) width = width + 30;
    if (showShareButton) width = width + 30;
    if (showCopyButton) width = width + 30;
    if (showChangingIndicator) {
      width = width + 32;
      if (showChangingSpeedTexts) width = width + 102;
      if (showChangingProgressText) width = width + 78;
    }
    if (hasBranchSwitcher) width = width + 92;
    if (showMoreButton) width = width + 52;
    if (showResumeButton) width = width + 84;

    return width + 12;
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
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "$label: $value",
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
                  TextSpan(
                    text: "$label: ",
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
    final ThemeData theme = Theme.of(context);
    final bool disabled = onTap == null;
    return Tooltip(
      message: label,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: .circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              padding: const .symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: disabled ? color.q(.04) : color.q(.1),
                borderRadius: .circular(6),
                border: Border.all(color: disabled ? color.q(.14) : color.q(.28)),
              ),
              child: Row(
                mainAxisSize: .min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: disabled ? color.q(.42) : color.q(.86),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: disabled ? color.q(.5) : color.q(.92),
                      fontWeight: .w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
