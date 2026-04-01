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

  const BatchMessageContent(this.msg, this.index, this.finalContent, {this.perSlotQuestions, super.key});

  @override
  ConsumerState<BatchMessageContent> createState() => _BatchMessageContentState();
}

class _BatchMessageContentState extends ConsumerState<BatchMessageContent> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeft = false;
  bool _showRight = false;

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
    if (left != _showLeft || right != _showRight) {
      setState(() {
        _showLeft = left;
        _showRight = right;
      });
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
    final ref = this.ref;
    final (batch, isBatch, batchCount, selectedBatch) = getBatchInfo(widget.finalContent);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final batchVW = ref.watch(P.chat.batchVW);
    final qb = ref.watch(P.app.qb);
    final batchSelection = ref.watch(P.msg.batchSelection(widget.msg));

    final step = screenWidth * (batchVW / 100) * 0.9;

    final qw = ref.watch(P.app.qw);

    final parsedDecodeParams = widget.msg.parsedDecodeParams;

    final appTheme = ref.watch(P.app.theme);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: .only(
            left: appTheme.msgListMarginLeft,
            right: appTheme.msgListMarginRight,
          ),
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: .start,
            crossAxisAlignment: .start,
            children:
                [
                  for (var i = 0; i < batchCount; i++)
                    GD(
                      onTap: () {
                        P.msg.batchSelection(widget.msg).q = i;
                      },
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * (batchVW / 100),
                          minWidth: screenWidth * (batchVW / 100),
                        ),
                        padding: const .all(8),
                        decoration: BoxDecoration(
                          color: qw,
                          border: .all(color: batchSelection == i ? kCG : qb.q(.1)),
                          borderRadius: .circular(8),
                        ),
                        child: _SlotContent(
                          question: widget.perSlotQuestions != null && i < widget.perSlotQuestions!.length
                              ? widget.perSlotQuestions![i]
                              : null,
                          data: batch[i],
                          decodeParam: parsedDecodeParams.isNotEmpty
                              ? parsedDecodeParams[i < parsedDecodeParams.length ? i : parsedDecodeParams.length - 1]
                              : null,
                          qb: qb,
                        ),
                      ),
                    ),
                ].widgetJoin(
                  (index) => const SizedBox(width: 8),
                ),
          ),
        ),
        AnimatedPositioned(
          left: _showLeft ? 4 : -100,
          top: 0,
          duration: 250.ms,
          curve: Curves.easeOut,
          bottom: 0,
          child: AnimatedOpacity(
            opacity: _showLeft ? 1 : 0,
            duration: 250.ms,
            curve: Curves.easeOut,
            child: Center(
              child: GD(
                onTap: () => _scrollBy(-step),
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
        AnimatedPositioned(
          right: _showRight ? 4 : -100,
          top: 0,
          bottom: 0,
          duration: 250.ms,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _showRight ? 1 : 0,
            duration: 250.ms,
            curve: Curves.easeOut,
            child: Center(
              child: GD(
                onTap: () => _scrollBy(step),
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
      ],
    );
  }
}

class _SlotContent extends ConsumerWidget {
  final String? question;
  final String data;
  final SamplerAndPenaltyParam? decodeParam;
  final Color qb;

  const _SlotContent({
    required this.question,
    required this.data,
    required this.decodeParam,
    required this.qb,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool hasQuestion = question != null && question!.trim().isNotEmpty;

    // 普通 batch inference（无 question）：保持现有行为
    if (!hasQuestion) {
      return _MarkdownBody(data: data, decodeParam: decodeParam);
    }

    // 多问题并行：decode param → user question → bot answer
    return Column(
      crossAxisAlignment: .start,
      children: [
        if (decodeParam != null) _DecodeParamBadge(decodeParam: decodeParam!),
        if (decodeParam != null) const SizedBox(height: 6),
        _UserQuestionCard(question: question!),
        const SizedBox(height: 10),
        _QuestionAnswerDivider(
          qb: qb,
          accentColor: theme.colorScheme.primary.q(.4),
        ),
        const SizedBox(height: 10),
        _MarkdownBody(data: data),
      ],
    );
  }
}

class _UserQuestionCard extends StatelessWidget {
  final String question;

  const _UserQuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.colorScheme.primary.q(isDark ? .34 : .18);
    final backgroundColor = theme.colorScheme.secondary.q(isDark ? .12 : .06);

    return Container(
      width: double.infinity,
      padding: const .symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: .circular(4),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Text(
        question,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _QuestionAnswerDivider extends StatelessWidget {
  final Color qb;
  final Color accentColor;

  const _QuestionAnswerDivider({required this.qb, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 0.5,
          color: accentColor,
        ),
        Container(
          width: 8,
        ),
        Expanded(
          child: Container(
            height: 0.5,
            color: qb.q(.16),
          ),
        ),
      ],
    );
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
    // ignore: unused_local_variable
    final theme = Theme.of(context);
    final s = S.of(context);
    final displayText = s.decode_param + s.hyphen + decodeParam.displayName;

    return Align(
      alignment: .topLeft,
      child: GD(
        onTap: _onTap,
        child: Container(
          decoration: BoxDecoration(
            border: .all(color: kCG.q(.5)),
            borderRadius: .circular(4),
          ),
          padding: const .symmetric(horizontal: 6, vertical: 2),
          child: Text(displayText),
        ),
      ),
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
