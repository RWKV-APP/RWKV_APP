// Dart imports:
import 'dart:math' as math;
import 'dart:ui';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/func/extract_thought_and_output_for_batch_inference.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/sampler_and_penalty_param.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/markdown_render.dart';

const double _kSlotGap = 8.0;
const double _kSlotScrollFadeHeight = 18.0;
const int _kBatchMarkdownStableBlockTargetChars = 640;
const bool _kDebugTintBatchStableMarkdown = true;
const Color _kDebugBatchStableMarkdownTint = Color(0x224CAF50);
const String _kMarkdownFenceBacktick = "```";
const String _kMarkdownFenceTilde = "~~~";
final RegExp _batchMarkdownFenceLineExp = RegExp(r"^(```|~~~)");
final RegExp _batchStreamingTailFullMarkdownLineExp = RegExp(r"^\s{0,3}(#{1,6}(\s|$)|[-*+]\s+|\d+[.)]\s+|>\s+|\|)");
final RegExp _batchStreamingTailInlineCodeExp = RegExp(r"`[^`]+`");
final RegExp _batchStreamingTailLinkExp = RegExp(r"\[[^\]]+\]\([^)]+\)");

class BatchMessageContent extends ConsumerWidget {
  final model.Message msg;
  final int index;
  final String finalContent;
  final List<String>? perSlotQuestions;
  final List<String>? slotLabels;

  const BatchMessageContent(
    this.msg,
    this.index,
    this.finalContent, {
    this.perSlotQuestions,
    this.slotLabels,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final scrollController = P.ui.batchMessageScrollController(messageId: msg.id);
    P.ui.scheduleBatchMessageScrollButtonSync(messageId: msg.id);

    return Stack(
      children: [
        _BatchSlotsListView(
          msg: msg,
          finalContent: finalContent,
          scrollController: scrollController,
          perSlotQuestions: perSlotQuestions,
          slotLabels: slotLabels,
        ),
        _BatchScrollLeftButton(
          messageId: msg.id,
        ),
        _BatchScrollRightButton(
          messageId: msg.id,
        ),
      ],
    );
  }
}

class _BatchSlotsListView extends ConsumerWidget {
  final model.Message msg;
  final String finalContent;
  final ScrollController scrollController;
  final List<String>? perSlotQuestions;
  final List<String>? slotLabels;

  const _BatchSlotsListView({
    required this.msg,
    required this.finalContent,
    required this.scrollController,
    required this.perSlotQuestions,
    required this.slotLabels,
  });

  String? _slotLabelAt(int index) {
    final labels = slotLabels;
    if (labels == null) return null;
    if (index >= labels.length) return null;
    return labels[index];
  }

  String? _questionAt(int index) {
    final questions = perSlotQuestions;
    if (questions == null) return null;
    if (index >= questions.length) return null;
    return questions[index];
  }

  SamplerAndPenaltyParam? _decodeParamAt(List<SamplerAndPenaltyParam> parsedDecodeParams, int index) {
    if (parsedDecodeParams.isEmpty) return null;
    if (index < parsedDecodeParams.length) return parsedDecodeParams[index];
    return parsedDecodeParams.last;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final (batch, _, batchCount, _) = getBatchInfo(finalContent);
    final appTheme = ref.watch(P.app.theme);
    final batchVW = ref.watch(P.chat.batchVW);
    final generating = ref.watch(P.rwkv.generating);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final parsedDecodeParams = msg.parsedDecodeParams;
    final slotWidth = screenWidth * (batchVW / 100);
    final shouldGateByViewport = msg.changing && generating;

    final EdgeInsets padding = .only(
      left: appTheme.msgListMarginLeft,
      right: appTheme.msgListMarginRight,
    );

    final visibleSlotIndexes = P.ui.resolveBatchVisibleSlotIndexes(
      messageId: msg.id,
      batchCount: batchCount,
      paddingLeft: padding.left,
      slotWidth: slotWidth,
      viewportWidth: screenWidth,
    );

    P.ui.scheduleBatchSlotsViewportSync(
      messageId: msg.id,
      batchCount: batchCount,
      paddingLeft: padding.left,
      slotWidth: slotWidth,
      viewportWidth: screenWidth,
    );

    // return C();

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (int i = 0; i < batchCount; i++)
            RepaintBoundary(
              child: _BatchSlotItem(
                msg: msg,
                slotIndex: i,
                slotWidth: slotWidth,
                isLast: i == batchCount - 1,
                shouldGateByViewport: shouldGateByViewport,
                initialViewportVisible: visibleSlotIndexes.contains(i),
                slotLabel: _slotLabelAt(i),
                question: _questionAt(i),
                data: batch[i],
                decodeParam: _decodeParamAt(parsedDecodeParams, i),
              ),
            ),
        ],
      ),
    );
  }
}

class _BatchSlotItem extends ConsumerWidget {
  final model.Message msg;
  final int slotIndex;
  final double slotWidth;
  final bool isLast;
  final bool shouldGateByViewport;
  final bool initialViewportVisible;
  final String? slotLabel;
  final String? question;
  final String data;
  final SamplerAndPenaltyParam? decodeParam;

  const _BatchSlotItem({
    required this.msg,
    required this.slotIndex,
    required this.slotWidth,
    required this.isLast,
    required this.shouldGateByViewport,
    required this.initialViewportVisible,
    required this.slotLabel,
    required this.question,
    required this.data,
    required this.decodeParam,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final viewportSynced = ref.watch(P.ui.batchVisibleSlotIndexesSynced(msg.id));
    final viewportVisible = viewportSynced
        ? ref.watch(P.ui.batchSlotViewportVisible((messageId: msg.id, slotIndex: slotIndex)))
        : initialViewportVisible;

    if (shouldGateByViewport && !viewportVisible) {
      return Padding(
        padding: .only(right: isLast ? 0 : _kSlotGap),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: slotWidth,
            minWidth: slotWidth,
          ),
        ),
      );
    }

    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final batchSelection = ref.watch(P.msg.batchSelection(msg));

    return Padding(
      padding: .only(right: isLast ? 0 : _kSlotGap),
      child: GD(
        onTap: () {
          P.msg.batchSelection(msg).q = slotIndex;
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: slotWidth,
            minWidth: slotWidth,
          ),
          padding: const .symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: qw,
            border: .all(color: batchSelection == slotIndex ? kCG : qb.q(.1)),
            borderRadius: .circular(8),
          ),
          child: RepaintBoundary(
            child: _SlotContent(
              msg: msg,
              slotIndex: slotIndex,
              slotLabel: slotLabel,
              question: question,
              data: data,
              decodeParam: decodeParam,
            ),
          ),
        ),
      ),
    );
  }
}

class _BatchScrollLeftButton extends ConsumerWidget {
  final int messageId;

  const _BatchScrollLeftButton({
    required this.messageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final screenWidth = ref.watch(P.app.screenWidth);
    final batchVW = ref.watch(P.chat.batchVW);
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final step = screenWidth * (batchVW / 100) * 0.9;
    final visibility = ref.watch(P.ui.batchScrollButtonVisibility(messageId));
    final show = visibility.left;

    return AnimatedPositioned(
      left: show ? 4 : -100,
      top: 0,
      duration: 250.ms,
      curve: Curves.easeOut,
      bottom: 0,
      child: AnimatedOpacity(
        opacity: show ? 1 : 0,
        duration: 250.ms,
        curve: Curves.easeOut,
        child: Center(
          child: GD(
            onTap: () => P.ui.scrollBatchMessageBy(messageId: messageId, delta: -step),
            child: _BatchButtonBackdrop(
              borderRadius: .circular(20),
              background: qw,
              border: .all(color: qb.q(.1)),
              padding: const .all(6),
              child: Icon(Icons.chevron_left, color: qb.q(.7)),
            ),
          ),
        ),
      ),
    );
  }
}

class _BatchScrollRightButton extends ConsumerWidget {
  final int messageId;

  const _BatchScrollRightButton({
    required this.messageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final screenWidth = ref.watch(P.app.screenWidth);
    final batchVW = ref.watch(P.chat.batchVW);
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final step = screenWidth * (batchVW / 100) * 0.9;
    final visibility = ref.watch(P.ui.batchScrollButtonVisibility(messageId));
    final show = visibility.right;

    return AnimatedPositioned(
      right: show ? 4 : -100,
      top: 0,
      bottom: 0,
      duration: 250.ms,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: show ? 1 : 0,
        duration: 250.ms,
        curve: Curves.easeOut,
        child: Center(
          child: GD(
            onTap: () => P.ui.scrollBatchMessageBy(messageId: messageId, delta: step),
            child: _BatchButtonBackdrop(
              borderRadius: .circular(20),
              background: qw,
              border: .all(color: qb.q(.1)),
              padding: const .all(6),
              child: Icon(Icons.chevron_right, color: qb.q(.7)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotContent extends ConsumerWidget {
  final model.Message msg;
  final int slotIndex;
  final String? slotLabel;
  final String? question;
  final String data;
  final SamplerAndPenaltyParam? decodeParam;

  const _SlotContent({
    required this.msg,
    required this.slotIndex,
    required this.slotLabel,
    required this.question,
    required this.data,
    required this.decodeParam,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final key = (messageId: msg.id, slotIndex: slotIndex);
    final scrollController = P.ui.batchSlotScrollController(
      messageId: msg.id,
      slotIndex: slotIndex,
    );
    final bodyCanScroll = ref.watch(P.ui.batchSlotBodyCanScroll(key));
    final streaming = msg.changing && ref.watch(P.rwkv.generating);
    final inferring = ref.watch(P.ui.batchSlotInferring(key));
    final hasQuestion = question != null && question!.trim().isNotEmpty;

    P.ui.scheduleBatchSlotContentSync(
      msg: msg,
      slotIndex: slotIndex,
      data: data,
    );

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: const .only(top: 8),
          child: _SlotHeaderRow(
            slotLabel: slotLabel,
            decodeParam: decodeParam,
            inferring: streaming && inferring,
            onPreviewPressed: () => P.ui.onBatchSlotPreviewPressed(
              messageId: msg.id,
              slotIndex: slotIndex,
            ),
          ),
        ),
        if (hasQuestion) const SizedBox(height: 8),
        Expanded(
          child: RepaintBoundary(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _SlotScrollFade(
                    enabled: bodyCanScroll,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: P.ui.onBatchSlotVerticalScrollNotification,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const .only(bottom: 16, top: 8),
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            if (hasQuestion) _UserQuestionCard(question: question!),
                            if (hasQuestion) const SizedBox(height: 8),
                            _MarkdownBody(
                              data: data,
                              streaming: streaming,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Center(
                    child: _BatchSlotScrollToTopButton(
                      messageId: msg.id,
                      slotIndex: slotIndex,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Center(
                    child: _BatchSlotScrollToBottomButton(
                      messageId: msg.id,
                      slotIndex: slotIndex,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BatchSlotScrollToBottomButton extends ConsumerWidget {
  final int messageId;
  final int slotIndex;

  const _BatchSlotScrollToBottomButton({
    required this.messageId,
    required this.slotIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final key = (messageId: messageId, slotIndex: slotIndex);
    final canScroll = ref.watch(P.ui.batchSlotBodyCanScroll(key));
    final atBottom = ref.watch(P.ui.batchSlotAtBottom(key));
    final show = canScroll && !atBottom;
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);

    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: 200.ms,
      curve: Curves.easeOut,
      child: IgnorePointer(
        ignoring: !show,
        child: GD(
          onTap: () => P.ui.scrollBatchSlotToBottom(
            messageId: messageId,
            slotIndex: slotIndex,
          ),
          child: _BatchButtonBackdrop(
            borderRadius: .circular(14),
            background: qw,
            border: .all(color: qb.q(.1)),
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 48,
              height: 24,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: qb.q(.7),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BatchButtonBackdrop extends ConsumerWidget {
  final BorderRadius borderRadius;
  final Color background;
  final BoxBorder? border;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _BatchButtonBackdrop({
    required this.borderRadius,
    required this.background,
    required this.border,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useBackdropFilter = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final bgAlpha = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final darkModifier = ref.watch(P.ui.backdropFilterBgAlphaForInputOptionsDarkModifier);
    final sigma = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: sigma.toDouble(),
          sigmaY: sigma.toDouble(),
        ),
        enabled: useBackdropFilter,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: background.q(useBackdropFilter ? bgAlpha * darkModifier : 1),
            borderRadius: borderRadius,
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SlotScrollFade extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const _SlotScrollFade({
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return ShaderMask(
      blendMode: .dstIn,
      shaderCallback: (bounds) {
        final fadeStop = bounds.height <= 0 ? .0 : math.min(.5, _kSlotScrollFadeHeight / bounds.height);
        return LinearGradient(
          begin: .topCenter,
          end: .bottomCenter,
          colors: const [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [
            0,
            fadeStop,
            1 - fadeStop,
            1,
          ],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

class _SlotHeaderRow extends StatelessWidget {
  final String? slotLabel;
  final SamplerAndPenaltyParam? decodeParam;
  final bool inferring;
  final VoidCallback onPreviewPressed;

  const _SlotHeaderRow({
    required this.slotLabel,
    required this.decodeParam,
    required this.inferring,
    required this.onPreviewPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSlotLabel = slotLabel != null && slotLabel!.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: .center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (hasSlotLabel) _SlotLabelBadge(label: slotLabel!),
            if (hasSlotLabel && decodeParam != null) const SizedBox(width: 6),
            if (decodeParam != null) _DecodeParamBadge(decodeParam: decodeParam!),
          ],
        ),
        Row(
          children: [
            _SlotPreviewButton(onTap: onPreviewPressed),
          ],
        ),
      ],
    );
  }
}

class _BatchSlotScrollToTopButton extends ConsumerWidget {
  final int messageId;
  final int slotIndex;

  const _BatchSlotScrollToTopButton({
    required this.messageId,
    required this.slotIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (messageId: messageId, slotIndex: slotIndex);
    final canScroll = ref.watch(P.ui.batchSlotBodyCanScroll(key));
    final atTop = ref.watch(P.ui.batchSlotAtTop(key));
    final show = canScroll && !atTop;
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);

    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: 200.ms,
      curve: Curves.easeOut,
      child: IgnorePointer(
        ignoring: !show,
        child: GD(
          onTap: () => P.ui.scrollBatchSlotToTop(
            messageId: messageId,
            slotIndex: slotIndex,
          ),
          child: _BatchButtonBackdrop(
            borderRadius: .circular(14),
            background: qw,
            border: .all(color: qb.q(.1)),
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 48,
              height: 24,
              child: Icon(
                Icons.keyboard_arrow_up,
                color: qb.q(.7),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotPreviewButton extends ConsumerWidget {
  final VoidCallback onTap;

  const _SlotPreviewButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final qb = ref.watch(P.app.qb);

    return GD(
      onTap: onTap,
      child: Container(
        padding: const .all(4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: .circular(4),
        ),
        child: Icon(
          Symbols.open_in_full,
          size: 16,
          color: qb.q(.6),
        ),
      ),
    );
  }
}

class _UserQuestionCard extends ConsumerWidget {
  final String question;

  const _UserQuestionCard({required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final appTheme = ref.watch(P.app.theme);

    return Container(
      padding: const .symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: appTheme.g1,
        borderRadius: .circular(4),
        border: Border.all(
          color: appTheme.qb12,
        ),
      ),
      child: Text(
        question,
        style: const TextStyle(),
      ),
    );
  }
}

class _MetaBadge extends ConsumerWidget {
  final String text;
  final VoidCallback? onTap;

  const _MetaBadge({
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final fontSize = theme.textTheme.bodySmall?.fontSize ?? 12.0;

    return GD(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: .all(
            color: appTheme.qb12,
          ),
          borderRadius: .circular(4),
        ),
        padding: const .symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: appTheme.qb0,
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.w500,
          ),
          strutStyle: StrutStyle(
            fontSize: fontSize,
            height: 1,
            forceStrutHeight: true,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}

class _SlotLabelBadge extends StatelessWidget {
  final String label;

  const _SlotLabelBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return _MetaBadge(text: label);
  }
}

class _DecodeParamBadge extends StatelessWidget {
  final SamplerAndPenaltyParam decodeParam;

  const _DecodeParamBadge({required this.decodeParam});

  void _onTap() async {
    final _ = await showOkAlertDialog(
      context: getContext()!,
      title: S.current.decode_param,
      message:
          """Decode Param: ${decodeParam.displayName}
      Temperature: ${decodeParam.temperature.toStringAsFixed(1)}
      TopP: ${decodeParam.topP.toStringAsFixed(2)}
      Presence Penalty: ${decodeParam.presencePenalty.toStringAsFixed(1)}
      Frequency Penalty: ${decodeParam.frequencyPenalty.toStringAsFixed(1)}
      Penalty Decay: ${decodeParam.penaltyDecay.toStringAsFixed(3)}
""",
      okLabel: S.current.got_it,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final displayText = s.decode_param + s.colon + decodeParam.decodeParamType.displayNameShort;
    return _MetaBadge(
      text: displayText,
      onTap: _onTap,
    );
  }
}

class _MarkdownBody extends ConsumerWidget {
  final String data;
  final bool streaming;

  const _MarkdownBody({
    required this.data,
    required this.streaming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final qb = ref.watch(P.app.qb);

    final (thought, output) = extractThoughtAndOutputForBatchInference(data);

    if (thought.isEmpty) {
      return Column(
        crossAxisAlignment: .stretch,
        children: [
          _BatchIncrementalMarkdown(
            key: const ValueKey("batch-output"),
            raw: output,
            streaming: streaming,
            useMessageLineHeight: true,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (thought.isNotEmpty)
          _BatchIncrementalMarkdown(
            key: const ValueKey("batch-thought"),
            raw: thought,
            color: qb.q(.55),
            streaming: streaming,
            useMessageLineHeight: true,
          ),
        if (output.isNotEmpty) const SizedBox(height: 4),
        if (output.isNotEmpty)
          _BatchIncrementalMarkdown(
            key: const ValueKey("batch-output"),
            raw: output,
            streaming: streaming,
            useMessageLineHeight: true,
          ),
      ],
    );
  }
}

class _BatchIncrementalMarkdown extends StatefulWidget {
  final String raw;
  final Color? color;
  final bool streaming;
  final bool useMessageLineHeight;

  const _BatchIncrementalMarkdown({
    required this.raw,
    required this.streaming,
    required this.useMessageLineHeight,
    this.color,
    super.key,
  });

  @override
  State<_BatchIncrementalMarkdown> createState() => _BatchIncrementalMarkdownState();
}

class _BatchIncrementalMarkdownState extends State<_BatchIncrementalMarkdown> {
  final _stableBlockCache = <_BatchMarkdownStableBlockCacheEntry>[];

  @override
  void didUpdateWidget(covariant _BatchIncrementalMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streaming == widget.streaming) return;
    if (widget.streaming) return;
    _clearStableCache();
  }

  void _clearStableCache() {
    _stableBlockCache.clear();
  }

  List<Widget> _stableMarkdownBlockWidgets(List<String> rawBlocks) {
    _trimStableBlockCache(rawBlocks.length);
    final widgets = <Widget>[];
    for (int i = 0; i < rawBlocks.length; i++) {
      widgets.add(
        _stableMarkdownBlockWidget(
          index: i,
          raw: rawBlocks[i],
        ),
      );
    }
    return widgets;
  }

  void _trimStableBlockCache(int count) {
    if (_stableBlockCache.length <= count) return;
    _stableBlockCache.removeRange(count, _stableBlockCache.length);
  }

  Widget _stableMarkdownBlockWidget({
    required int index,
    required String raw,
  }) {
    if (index < _stableBlockCache.length) {
      final cached = _stableBlockCache[index];
      if (cached.matches(
        raw: raw,
        color: widget.color,
        useMessageLineHeight: widget.useMessageLineHeight,
      )) {
        return cached.widget;
      }
    }

    final markdown = MarkdownRender(
      raw: raw,
      color: widget.color,
      useMessageLineHeight: widget.useMessageLineHeight,
    );

    final cached = _BatchMarkdownStableBlockCacheEntry(
      raw: raw,
      color: widget.color,
      useMessageLineHeight: widget.useMessageLineHeight,
      widget: _debugTintStableMarkdown(markdown),
    );
    if (index < _stableBlockCache.length) {
      _stableBlockCache[index] = cached;
      return cached.widget;
    }
    _stableBlockCache.add(cached);
    return cached.widget;
  }

  Widget _debugTintStableMarkdown(Widget child) {
    if (!kDebugMode) return child;
    if (!_kDebugTintBatchStableMarkdown) return child;
    return ColoredBox(
      color: _kDebugBatchStableMarkdownTint,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.streaming) {
      return MarkdownRender(
        raw: widget.raw,
        color: widget.color,
        useMessageLineHeight: widget.useMessageLineHeight,
      );
    }

    final split = _splitBatchStreamingMarkdown(widget.raw);
    if (split.stableBlocks.isEmpty) {
      return _BatchStreamingTailMarkdown(
        raw: split.tail,
        color: widget.color,
        useMessageLineHeight: widget.useMessageLineHeight,
      );
    }

    final children = _stableMarkdownBlockWidgets(split.stableBlocks);
    if (split.tail.isNotEmpty) {
      children.add(
        _BatchStreamingTailMarkdown(
          raw: split.tail,
          color: widget.color,
          useMessageLineHeight: widget.useMessageLineHeight,
        ),
      );
    }

    if (children.length == 1) return children.first;

    return Column(
      crossAxisAlignment: .stretch,
      children: children,
    );
  }
}

class _BatchMarkdownStableBlockCacheEntry {
  final String raw;
  final Color? color;
  final bool useMessageLineHeight;
  final Widget widget;

  const _BatchMarkdownStableBlockCacheEntry({
    required this.raw,
    required this.color,
    required this.useMessageLineHeight,
    required this.widget,
  });

  bool matches({
    required String raw,
    required Color? color,
    required bool useMessageLineHeight,
  }) {
    if (this.raw != raw) return false;
    if (this.color != color) return false;
    return this.useMessageLineHeight == useMessageLineHeight;
  }
}

class _BatchStreamingTailMarkdown extends ConsumerWidget {
  final String raw;
  final Color? color;
  final bool useMessageLineHeight;

  const _BatchStreamingTailMarkdown({
    required this.raw,
    required this.color,
    required this.useMessageLineHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;

    if (raw.isEmpty) return const SizedBox.shrink();

    final renderMarkdownAndLatexEnabled = ref.watch(P.preference.renderMarkdownAndLatexEnabled);
    if (renderMarkdownAndLatexEnabled && _shouldRenderStreamingTailAsFullMarkdown(raw)) {
      return MarkdownRender(
        raw: raw,
        color: color,
        useMessageLineHeight: useMessageLineHeight,
      );
    }

    final textScaler = MediaQuery.textScalerOf(context);
    const scale = Config.msgFontScale;
    final textScaleFactor = textScaler.scale(1.0);
    final effectiveScale = scale * textScaleFactor;
    final qb = ref.watch(P.app.qb);
    final effectiveMessageLineHeight = ref.watch(P.preference.effectiveMessageLineHeight);
    final messageLineHeight = useMessageLineHeight ? effectiveMessageLineHeight : null;

    return Text(
      raw,
      style: TextStyle(
        color: color ?? qb,
        fontSize: Config.markdownBodyFontSize * effectiveScale,
        height: messageLineHeight,
      ),
      textScaler: .noScaling,
    );
  }
}

({List<String> stableBlocks, String tail}) _splitBatchStreamingMarkdown(String raw) {
  if (raw.isEmpty) return (stableBlocks: const <String>[], tail: "");

  final boundaries = _stableBatchMarkdownBoundaries(raw);
  if (boundaries.isEmpty) return (stableBlocks: const <String>[], tail: raw);

  final stableEnd = boundaries.last.offset;
  if (stableEnd <= 0) return (stableBlocks: const <String>[], tail: raw);
  return (
    stableBlocks: _stableBatchMarkdownBlocks(
      raw: raw,
      boundaries: boundaries,
      stableEnd: stableEnd,
    ),
    tail: stableEnd >= raw.length ? "" : raw.substring(stableEnd),
  );
}

List<String> _stableBatchMarkdownBlocks({
  required String raw,
  required List<({int offset, bool hard})> boundaries,
  required int stableEnd,
}) {
  final blocks = <String>[];
  int blockStart = 0;

  for (final boundary in boundaries) {
    if (boundary.offset > stableEnd) break;
    if (boundary.offset <= blockStart) continue;

    final shouldCloseBlock =
        boundary.hard || boundary.offset - blockStart >= _kBatchMarkdownStableBlockTargetChars || boundary.offset >= stableEnd;
    if (!shouldCloseBlock) continue;

    blocks.add(raw.substring(blockStart, boundary.offset));
    blockStart = boundary.offset;
  }

  if (blockStart < stableEnd) {
    blocks.add(raw.substring(blockStart, stableEnd));
  }
  if (blocks.isNotEmpty) return blocks;
  return <String>[raw.substring(0, stableEnd)];
}

List<({int offset, bool hard})> _stableBatchMarkdownBoundaries(String raw) {
  final boundaries = <({int offset, bool hard})>[];
  bool insideFence = false;
  String fenceMarker = "";
  bool insideDisplayLatex = false;
  bool insideDollarLatex = false;
  bool previousLineWasTable = false;
  int lineStart = 0;

  while (lineStart < raw.length) {
    int lineEnd = raw.indexOf("\n", lineStart);
    if (lineEnd == -1) lineEnd = raw.length;

    final line = raw.substring(lineStart, lineEnd);
    final trimmedLine = line.trim();
    final hasTrailingNewline = lineEnd < raw.length;
    final lineBoundary = lineEnd < raw.length ? lineEnd + 1 : lineEnd;

    final fenceBoundary = _resolveFenceBoundary(
      trimmedLine: trimmedLine,
      lineBoundary: lineBoundary,
      insideFence: insideFence,
      fenceMarker: fenceMarker,
    );
    if (fenceBoundary != null) {
      insideFence = fenceBoundary.insideFence;
      fenceMarker = fenceBoundary.fenceMarker;
      final lastSafeBoundary = fenceBoundary.lastSafeBoundary;
      if (lastSafeBoundary != null) {
        _addStableBatchMarkdownBoundary(
          boundaries: boundaries,
          offset: lastSafeBoundary,
          hard: true,
        );
      }
      lineStart = lineBoundary;
      continue;
    }

    if (insideFence) {
      lineStart = lineBoundary;
      continue;
    }

    final latexBoundary = _resolveLatexBoundary(
      trimmedLine: trimmedLine,
      lineBoundary: lineBoundary,
      insideDisplayLatex: insideDisplayLatex,
      insideDollarLatex: insideDollarLatex,
    );
    insideDisplayLatex = latexBoundary.insideDisplayLatex;
    insideDollarLatex = latexBoundary.insideDollarLatex;
    if (latexBoundary.handled) {
      final lastSafeBoundary = latexBoundary.lastSafeBoundary;
      if (lastSafeBoundary != null) {
        _addStableBatchMarkdownBoundary(
          boundaries: boundaries,
          offset: lastSafeBoundary,
          hard: true,
        );
      }
      lineStart = lineBoundary;
      continue;
    }

    if (trimmedLine.isEmpty) {
      previousLineWasTable = false;
      _addStableBatchMarkdownBoundary(
        boundaries: boundaries,
        offset: lineBoundary,
        hard: true,
      );
      lineStart = lineBoundary;
      continue;
    }

    final isTableLine = _isBatchMarkdownTableLine(trimmedLine);
    if (isTableLine) {
      previousLineWasTable = true;
      lineStart = lineBoundary;
      continue;
    }

    if (previousLineWasTable) {
      previousLineWasTable = false;
      _addStableBatchMarkdownBoundary(
        boundaries: boundaries,
        offset: lineStart,
        hard: true,
      );
    }

    if (hasTrailingNewline) {
      _addStableBatchMarkdownBoundary(
        boundaries: boundaries,
        offset: lineBoundary,
        hard: false,
      );
    }
    lineStart = lineBoundary;
  }

  return boundaries;
}

void _addStableBatchMarkdownBoundary({
  required List<({int offset, bool hard})> boundaries,
  required int offset,
  required bool hard,
}) {
  if (offset <= 0) return;
  if (boundaries.isEmpty) {
    boundaries.add((offset: offset, hard: hard));
    return;
  }

  final last = boundaries.last;
  if (last.offset != offset) {
    boundaries.add((offset: offset, hard: hard));
    return;
  }

  if (!hard || last.hard) return;
  boundaries[boundaries.length - 1] = (offset: offset, hard: true);
}

({bool insideFence, String fenceMarker, int? lastSafeBoundary})? _resolveFenceBoundary({
  required String trimmedLine,
  required int lineBoundary,
  required bool insideFence,
  required String fenceMarker,
}) {
  if (!_batchMarkdownFenceLineExp.hasMatch(trimmedLine)) return null;
  if (!insideFence) {
    final marker = trimmedLine.startsWith(_kMarkdownFenceTilde) ? _kMarkdownFenceTilde : _kMarkdownFenceBacktick;
    return (insideFence: true, fenceMarker: marker, lastSafeBoundary: null);
  }

  if (!trimmedLine.startsWith(fenceMarker)) {
    return (insideFence: insideFence, fenceMarker: fenceMarker, lastSafeBoundary: null);
  }

  return (insideFence: false, fenceMarker: "", lastSafeBoundary: lineBoundary);
}

({bool handled, bool insideDisplayLatex, bool insideDollarLatex, int? lastSafeBoundary}) _resolveLatexBoundary({
  required String trimmedLine,
  required int lineBoundary,
  required bool insideDisplayLatex,
  required bool insideDollarLatex,
}) {
  if (insideDisplayLatex) {
    final closed = trimmedLine.endsWith(r"\]");
    return (
      handled: true,
      insideDisplayLatex: !closed,
      insideDollarLatex: insideDollarLatex,
      lastSafeBoundary: closed ? lineBoundary : null,
    );
  }

  if (insideDollarLatex) {
    final closed = trimmedLine.endsWith(r"$$");
    return (
      handled: true,
      insideDisplayLatex: insideDisplayLatex,
      insideDollarLatex: !closed,
      lastSafeBoundary: closed ? lineBoundary : null,
    );
  }

  if (trimmedLine.startsWith(r"\[") && !trimmedLine.endsWith(r"\]")) {
    return (
      handled: true,
      insideDisplayLatex: true,
      insideDollarLatex: false,
      lastSafeBoundary: null,
    );
  }

  if (trimmedLine.startsWith(r"\[") && trimmedLine.endsWith(r"\]")) {
    return (
      handled: true,
      insideDisplayLatex: false,
      insideDollarLatex: false,
      lastSafeBoundary: lineBoundary,
    );
  }

  if (trimmedLine.startsWith(r"$$") && !trimmedLine.endsWith(r"$$")) {
    return (
      handled: true,
      insideDisplayLatex: false,
      insideDollarLatex: true,
      lastSafeBoundary: null,
    );
  }

  if (trimmedLine == r"$$") {
    return (
      handled: true,
      insideDisplayLatex: false,
      insideDollarLatex: true,
      lastSafeBoundary: null,
    );
  }

  if (trimmedLine.startsWith(r"$$") && trimmedLine.endsWith(r"$$") && trimmedLine.length > 2) {
    return (
      handled: true,
      insideDisplayLatex: false,
      insideDollarLatex: false,
      lastSafeBoundary: lineBoundary,
    );
  }

  return (
    handled: false,
    insideDisplayLatex: false,
    insideDollarLatex: false,
    lastSafeBoundary: null,
  );
}

bool _isBatchMarkdownTableLine(String line) {
  if (!line.contains("|")) return false;
  final cells = line.split("|");
  if (cells.length < 3) return false;
  return true;
}

bool _shouldRenderStreamingTailAsFullMarkdown(String raw) {
  if (raw.isEmpty) return false;
  if (_hasUnclosedBatchMarkdownFence(raw)) return false;
  if (_hasUnclosedBatchDisplayLatex(raw)) return false;

  final trimmed = raw.trimLeft();
  if (trimmed.isEmpty) return false;
  if (_batchStreamingTailFullMarkdownLineExp.hasMatch(trimmed)) return true;
  if (_batchStreamingTailInlineCodeExp.hasMatch(trimmed)) return true;
  if (_batchStreamingTailLinkExp.hasMatch(trimmed)) return true;
  if (trimmed.contains(r"\(")) return true;
  if (trimmed.contains(r"\)")) return true;
  if (trimmed.contains(r"\[")) return true;
  if (trimmed.contains(r"\]")) return true;
  if (trimmed.contains("<br")) return true;
  return trimmed.contains("<BR");
}

bool _hasUnclosedBatchMarkdownFence(String raw) {
  bool insideFence = false;
  String fenceMarker = "";
  final lines = raw.split("\n");

  for (final line in lines) {
    final trimmedLine = line.trim();
    if (!_batchMarkdownFenceLineExp.hasMatch(trimmedLine)) continue;

    if (!insideFence) {
      insideFence = true;
      fenceMarker = trimmedLine.startsWith(_kMarkdownFenceTilde) ? _kMarkdownFenceTilde : _kMarkdownFenceBacktick;
      continue;
    }

    if (!trimmedLine.startsWith(fenceMarker)) continue;
    insideFence = false;
    fenceMarker = "";
  }

  return insideFence;
}

bool _hasUnclosedBatchDisplayLatex(String raw) {
  bool insideDisplayLatex = false;
  bool insideDollarLatex = false;
  final lines = raw.split("\n");

  for (final line in lines) {
    final trimmedLine = line.trim();

    if (insideDisplayLatex) {
      if (trimmedLine.endsWith(r"\]")) insideDisplayLatex = false;
      continue;
    }

    if (insideDollarLatex) {
      if (trimmedLine.endsWith(r"$$")) insideDollarLatex = false;
      continue;
    }

    if (trimmedLine.startsWith(r"\[") && !trimmedLine.endsWith(r"\]")) {
      insideDisplayLatex = true;
      continue;
    }

    if (trimmedLine == r"$$") {
      insideDollarLatex = true;
      continue;
    }

    if (trimmedLine.startsWith(r"$$") && !trimmedLine.endsWith(r"$$")) {
      insideDollarLatex = true;
    }
  }

  return insideDisplayLatex || insideDollarLatex;
}
