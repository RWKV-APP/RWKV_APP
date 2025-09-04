import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/func/extrack_thought_and_output.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/store/p.dart';

class BatchMessageContent extends ConsumerWidget {
  final model.Message msg;
  final int index;
  final String finalContent;

  const BatchMessageContent(this.msg, this.index, this.finalContent, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (batch, isBatch, batchCount, selectedBatch) = getBatchInfo(finalContent);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final batchVW = ref.watch(P.chat.batchVW);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            [
              4.w,
              for (var i = 0; i < batchCount; i++)
                Container(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth * (batchVW / 100),
                    minWidth: screenWidth * (batchVW / 100),
                  ),
                  padding: const EI.a(8),
                  decoration: BoxDecoration(
                    color: kC,
                    border: Border.all(color: qb.q(.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _MarkdownBody(data: batch[i]),
                ),
              4.w,
            ].widgetJoin((index) {
              return 8.w;
            }),
      ),
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

    final factorOfOutput = TextScaler.linear(MediaQuery.textScalerOf(context).scale(_kTextScaleFactor));

    final markdownStyleSheet = MarkdownStyleSheet(
      listBulletPadding: const EI.o(l: 0),
      listIndent: 20,
      textScaler: factorOfOutput,
      horizontalRuleDecoration: BoxDecoration(
        color: qb.q(.1),
        border: Border(top: BorderSide(color: qb.q(.1), width: 1)),
      ),
    );

    if (thought.isEmpty) return MarkdownBody(data: output, styleSheet: markdownStyleSheet);

    final factorOfThought = TextScaler.linear(MediaQuery.textScalerOf(context).scale(_kTextScaleFactorForCotContent));

    final markdownStyleSheetForCotContent = MarkdownStyleSheet(
      p: TS(c: qb.q(.5)),
      h1: TS(c: qb.q(.5)),
      h2: TS(c: qb.q(.5)),
      h3: TS(c: qb.q(.5)),
      h4: TS(c: qb.q(.5)),
      h5: TS(c: qb.q(.5)),
      h6: TS(c: qb.q(.5)),
      listBullet: TS(c: qb.q(.5)),
      listBulletPadding: const EI.o(l: 0),
      listIndent: 20,
      textScaler: factorOfThought,
    );

    return Column(
      children: [
        if (thought.isNotEmpty) MarkdownBody(data: thought, styleSheet: markdownStyleSheetForCotContent),
        if (output.isNotEmpty) MarkdownBody(data: output, styleSheet: markdownStyleSheet),
      ],
    );
  }
}
