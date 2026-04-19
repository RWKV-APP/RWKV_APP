// Dart imports:
import 'dart:math' as math;

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
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
    final useBuilder = ref.watch(P.preference.useBatchListViewBuilderEnabled);
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

    return useBuilder
        ? ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: padding,
            cacheExtent: 0,
            itemCount: batchCount,
            itemBuilder: (context, i) => RepaintBoundary(
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
          )
        : SingleChildScrollView(
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
            child: Container(
              decoration: BoxDecoration(
                color: qw,
                border: .all(color: qb.q(.1)),
                borderRadius: .circular(20),
              ),
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
            child: Container(
              decoration: BoxDecoration(
                color: qw,
                border: .all(color: qb.q(.1)),
                borderRadius: .circular(20),
              ),
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
    final hasSlotLabel = slotLabel != null && slotLabel!.trim().isNotEmpty;
    final hasQuestion = question != null && question!.trim().isNotEmpty;
    final hasHeader = hasSlotLabel || decodeParam != null;

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
            onPreviewPressed: () => P.ui.onBatchSlotPreviewPressed(
              messageId: msg.id,
              slotIndex: slotIndex,
            ),
          ),
        ),
        if (hasHeader || hasQuestion) const SizedBox(height: 8),
        Expanded(
          child: RepaintBoundary(
            child: _SlotScrollFade(
              enabled: bodyCanScroll,
              child: NotificationListener<ScrollNotification>(
                onNotification: P.ui.onBatchSlotVerticalScrollNotification,
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: .only(bottom: 16, top: 16),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      if (hasQuestion) _UserQuestionCard(question: question!),
                      if (hasQuestion) const SizedBox(height: 8),
                      _MarkdownBody(data: data),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
  final VoidCallback onPreviewPressed;

  const _SlotHeaderRow({
    required this.slotLabel,
    required this.decodeParam,
    required this.onPreviewPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSlotLabel = slotLabel != null && slotLabel!.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: .center,
      children: [
        if (hasSlotLabel) _SlotLabelBadge(label: slotLabel!),
        if (hasSlotLabel && decodeParam != null) const SizedBox(width: 6),
        if (decodeParam != null) Flexible(child: _DecodeParamBadge(decodeParam: decodeParam!)),
        const Spacer(),
        _SlotPreviewButton(onTap: onPreviewPressed),
      ],
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

  const _MarkdownBody({required this.data});

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
          MarkdownRender(raw: output, useMessageLineHeight: true),
        ],
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (thought.isNotEmpty) MarkdownRender(raw: thought, color: qb.q(.55), useMessageLineHeight: true),
        if (output.isNotEmpty) const SizedBox(height: 4),
        if (output.isNotEmpty) MarkdownRender(raw: output, useMessageLineHeight: true),
      ],
    );
  }
}
