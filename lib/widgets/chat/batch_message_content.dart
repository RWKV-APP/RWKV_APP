// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/func/extract_thought_and_output_for_batch_inference.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/sampler_and_penalty_param.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/markdown_render.dart';

class BatchMessageContent extends ConsumerStatefulWidget {
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
  ConsumerState<BatchMessageContent> createState() => _BatchMessageContentState();
}

class _BatchMessageContentState extends ConsumerState<BatchMessageContent> {
  final ScrollController _scrollController = ScrollController();
  static final showLeft = qs(false);
  static final showRight = qs(false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateButtonsVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateButtonsVisibility());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateButtonsVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateButtonsVisibility() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final left = position.pixels > 0.5;
    final right = position.pixels < (position.maxScrollExtent - 0.5);
    final bool _showLeft = showLeft.q;
    final bool _showRight = showRight.q;
    if (left != _showLeft || right != _showRight) {
      showLeft.q = left;
      showRight.q = right;
    }
  }

  Future<void> _scrollBy(double delta) async {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (position.pixels + delta).clamp(0.0, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5) return;
    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    _updateButtonsVisibility();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _BatchSlotsScrollView(
          msg: widget.msg,
          finalContent: widget.finalContent,
          scrollController: _scrollController,
          perSlotQuestions: widget.perSlotQuestions,
          slotLabels: widget.slotLabels,
        ),
        _BatchScrollLeftButton(
          scrollBy: _scrollBy,
        ),
        _BatchScrollRightButton(
          scrollBy: _scrollBy,
        ),
      ],
    );
  }
}

class _BatchSlotsScrollView extends ConsumerWidget {
  final model.Message msg;
  final String finalContent;
  final ScrollController scrollController;
  final List<String>? perSlotQuestions;
  final List<String>? slotLabels;

  const _BatchSlotsScrollView({
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
    final (batch, _, batchCount, _) = getBatchInfo(finalContent);
    final screenWidth = ref.watch(P.app.screenWidth);
    final batchVW = ref.watch(P.chat.batchVW);
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final appTheme = ref.watch(P.app.theme);
    final batchSelection = ref.watch(P.msg.batchSelection(msg));
    final parsedDecodeParams = msg.parsedDecodeParams;
    final slotWidth = screenWidth * (batchVW / 100);

    return Theme(
      data: theme,
      child: SingleChildScrollView(
        padding: .only(
          left: appTheme.msgListMarginLeft,
          right: appTheme.msgListMarginRight,
        ),
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: .start,
          crossAxisAlignment: .start,
          children:
              [
                for (final i in Iterable<int>.generate(batchCount))
                  GD(
                    onTap: () {
                      P.msg.batchSelection(msg).q = i;
                    },
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: slotWidth,
                        minWidth: slotWidth,
                      ),
                      padding: const .all(8),
                      decoration: BoxDecoration(
                        color: qw,
                        border: .all(color: batchSelection == i ? kCG : qb.q(.1)),
                        borderRadius: .circular(8),
                      ),
                      child: RepaintBoundary(
                        child: _SlotContent(
                          slotLabel: _slotLabelAt(i),
                          question: _questionAt(i),
                          data: batch[i],
                          decodeParam: _decodeParamAt(parsedDecodeParams, i),
                          qb: qb,
                        ),
                      ),
                    ),
                  ),
              ].widgetJoin(
                (index) => const SizedBox(width: 8),
              ),
        ),
      ),
    );
  }
}

class _BatchScrollLeftButton extends ConsumerWidget {
  final Future<void> Function(double delta) scrollBy;

  const _BatchScrollLeftButton({
    required this.scrollBy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenWidth = ref.watch(P.app.screenWidth);
    final batchVW = ref.watch(P.chat.batchVW);
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final step = screenWidth * (batchVW / 100) * 0.9;
    final bool show = ref.watch(_BatchMessageContentState.showLeft);

    return Theme(
      data: theme,
      child: AnimatedPositioned(
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
              onTap: () => scrollBy(-step),
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
      ),
    );
  }
}

class _BatchScrollRightButton extends ConsumerWidget {
  final Future<void> Function(double delta) scrollBy;

  const _BatchScrollRightButton({
    required this.scrollBy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenWidth = ref.watch(P.app.screenWidth);
    final batchVW = ref.watch(P.chat.batchVW);
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final step = screenWidth * (batchVW / 100) * 0.9;
    final bool show = ref.watch(_BatchMessageContentState.showRight);

    return Theme(
      data: theme,
      child: AnimatedPositioned(
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
              onTap: () => scrollBy(step),
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
      ),
    );
  }
}

class _SlotContent extends ConsumerWidget {
  final String? slotLabel;
  final String? question;
  final String data;
  final SamplerAndPenaltyParam? decodeParam;
  final Color qb;

  const _SlotContent({
    required this.slotLabel,
    required this.question,
    required this.data,
    required this.decodeParam,
    required this.qb,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasSlotLabel = slotLabel != null && slotLabel!.trim().isNotEmpty;
    final bool hasQuestion = question != null && question!.trim().isNotEmpty;
    final bool hasMetaBadges = hasSlotLabel || decodeParam != null;

    // 普通 batch inference（无 question）：保持现有行为
    if (!hasQuestion && !hasSlotLabel) {
      return _MarkdownBody(data: data, decodeParam: decodeParam);
    }

    // 带标签或问题的 batch：第一行放 meta badges，之后是问题卡片和回答
    return Column(
      crossAxisAlignment: .start,
      children: [
        if (hasMetaBadges)
          _MetaBadgeRow(
            slotLabel: slotLabel,
            decodeParam: decodeParam,
          ),
        if (hasMetaBadges) const SizedBox(height: 8),
        if (hasQuestion) _UserQuestionCard(question: question!),
        if (hasQuestion) const SizedBox(height: 8),
        _MarkdownBody(data: data),
      ],
    );
  }
}

class _UserQuestionCard extends ConsumerWidget {
  final String question;

  const _UserQuestionCard({required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final theme = Theme.of(context);
    // final bool isDark = theme.brightness == Brightness.dark;
    // final borderColor = theme.colorScheme.primary.q(isDark ? .34 : .18);
    // final backgroundColor = theme.colorScheme.secondary.q(isDark ? .12 : .06);
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
        style: const TextStyle(
          // color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _MetaBadgeRow extends StatelessWidget {
  final String? slotLabel;
  final SamplerAndPenaltyParam? decodeParam;

  const _MetaBadgeRow({
    required this.slotLabel,
    required this.decodeParam,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: .topLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (slotLabel != null && slotLabel!.trim().isNotEmpty) _SlotLabelBadge(label: slotLabel!),
          if (decodeParam != null) _DecodeParamBadge(decodeParam: decodeParam!),
        ],
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

  final SamplerAndPenaltyParam? decodeParam;

  const _MarkdownBody({required this.data, this.decodeParam});

  void _onTapDecodeParam() async {
    final _ = await showOkAlertDialog(
      context: getContext()!,
      title: S.current.decode_param,
      message:
          """Decode Param: ${decodeParam!.displayName}
      Temperature: ${decodeParam!.temperature.toStringAsFixed(1)}
      TopP: ${decodeParam!.topP.toStringAsFixed(2)}
      Presence Penalty: ${decodeParam!.presencePenalty.toStringAsFixed(1)}
      Frequency Penalty: ${decodeParam!.frequencyPenalty.toStringAsFixed(1)}
      Penalty Decay: ${decodeParam!.penaltyDecay.toStringAsFixed(3)}
""",
      okLabel: S.current.got_it,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);

    final (thought, output) = extractThoughtAndOutputForBatchInference(data);

    final s = S.of(context);

    final displayText = s.decode_param + s.hyphen + (decodeParam?.displayName ?? "unknown");

    final Widget? decodeParamWidget = decodeParam != null
        ? Align(
            alignment: .topLeft,
            child: GD(
              onTap: _onTapDecodeParam,
              child: Container(
                decoration: BoxDecoration(
                  border: .all(color: kCG.q(.5)),
                  borderRadius: .circular(4),
                ),
                padding: const .symmetric(horizontal: 6, vertical: 2),
                child: Text(displayText),
              ),
            ),
          )
        : null;

    if (thought.isEmpty) {
      return Column(
        crossAxisAlignment: .stretch,
        children: [
          ?decodeParamWidget,
          MarkdownRender(raw: output, useMessageLineHeight: true),
        ],
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        ?decodeParamWidget,
        if (thought.isNotEmpty) MarkdownRender(raw: thought, color: qb.q(.55), useMessageLineHeight: true),
        if (output.isNotEmpty) const SizedBox(height: 4),
        if (output.isNotEmpty) MarkdownRender(raw: output, useMessageLineHeight: true),
      ],
    );
  }
}
