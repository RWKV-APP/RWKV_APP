import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/func/extrack_thought_and_output.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/store/p.dart';

class BatchMessageContent extends ConsumerStatefulWidget {
  final model.Message msg;
  final int index;
  final String finalContent;

  const BatchMessageContent(this.msg, this.index, this.finalContent, {super.key});

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
    final bool left = position.pixels > 0.5;
    final bool right = position.pixels < (position.maxScrollExtent - 0.5);
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
    final double target = (position.pixels + delta).clamp(0.0, position.maxScrollExtent);
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

    final double step = screenWidth * (batchVW / 100) * 0.9;

    final qw = ref.watch(P.app.qw);

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              4.w,
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
                    padding: const EI.a(8),
                    decoration: BoxDecoration(
                      color: qw,
                      border: Border.all(color: batchSelection == i ? kCG : qb.q(.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _MarkdownBody(data: batch[i]),
                  ),
                ),
              4.w,
            ].widgetJoin((index) => 8.w),
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
                    border: Border.all(color: qb.q(.1)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EI.a(6),
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
                    border: Border.all(color: qb.q(.1)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EI.a(6),
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

const double _kTextScaleFactor = 1.1;
const double _kTextScaleFactorForCotContent = 1;

class _MarkdownBody extends ConsumerWidget {
  final String data;

  const _MarkdownBody({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);

    final (thought, output) = extrackThoughtAndOutput(data);

    if (thought.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GptMarkdown(output),
        ],
      );
    }

    final rawFontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;

    final textScaleFactor = TextScaler.linear(MediaQuery.textScalerOf(context).scale(_kTextScaleFactor));

    final v = textScaleFactor.scale(14.0) / 14.0;
    final alphaS = 1.5 / v;

    final gptMarkdownStyle = TextStyle(
      // color: kCR,
      fontSize: rawFontSize * _kTextScaleFactor,
    );

    return GptMarkdownTheme(
      gptThemeData: GptMarkdownTheme.of(context).copyWith(
        h1: TextStyle(fontSize: rawFontSize * 1.0 * alphaS),
        h2: TextStyle(fontSize: rawFontSize * 0.98 * alphaS),
        h3: TextStyle(fontSize: rawFontSize * 0.96 * alphaS),
        h4: TextStyle(fontSize: rawFontSize * 0.94 * alphaS),
        h5: TextStyle(fontSize: rawFontSize * 0.92 * alphaS),
        h6: TextStyle(fontSize: rawFontSize * 0.9 * alphaS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (thought.isNotEmpty)
            GptMarkdown(
              thought,
              style: TextStyle(
                color: qb.q(.6),
                fontSize: rawFontSize * _kTextScaleFactorForCotContent,
              ),
            ),
          if (output.isNotEmpty) 4.h,
          if (output.isNotEmpty)
            GptMarkdown(
              output,
              style: gptMarkdownStyle,
              orderedListBuilder: (context, no, child, config) {
                return MediaQuery.withNoTextScaling(child: child);
              },
              unOrderedListBuilder: (context, child, config) {
                return MediaQuery.withNoTextScaling(child: child);
              },
            ),
        ],
      ),
    );
  }
}
