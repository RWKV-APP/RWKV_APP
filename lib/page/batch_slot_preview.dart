// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/func/extract_thought_and_output_for_batch_inference.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/markdown_render.dart';

class PageBatchSlotPreview extends ConsumerWidget {
  const PageBatchSlotPreview({super.key});

  String _resolveTitle({
    required S s,
    required List<String>? slotLabels,
    required int slotIndex,
  }) {
    if (slotLabels != null && slotIndex < slotLabels.length) {
      final label = slotLabels[slotIndex].trim();
      if (label.isNotEmpty) return label;
    }
    return "${s.multi_question_title} ${slotIndex + 1}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final target = ref.watch(P.chat.batchPreviewTarget);
    final pool = ref.watch(P.msg.pool);
    final received = ref.watch(P.chat.visibleReceivedTokens);

    if (target == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.multi_question_title)),
        body: const SizedBox.shrink(),
      );
    }

    final (messageId, slotIndex) = target;
    final msg = pool[messageId];

    if (msg == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.multi_question_title)),
        body: const SizedBox.shrink(),
      );
    }

    final finalContent = msg.changing && received.isNotEmpty ? received : msg.content;
    final (batch, isBatch, batchCount, _) = getBatchInfo(finalContent);

    if (!isBatch || slotIndex >= batchCount) {
      return Scaffold(
        appBar: AppBar(title: Text(s.multi_question_title)),
        body: const SizedBox.shrink(),
      );
    }

    final rawSlot = batch[slotIndex];
    final (thought, output) = extractThoughtAndOutputForBatchInference(rawSlot);
    final title = _resolveTitle(s: s, slotLabels: msg.batchSlotLabels, slotIndex: slotIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TS(s: 16, w: .w600)),
      ),
      body: SingleChildScrollView(
        padding: .only(
          left: appTheme.msgListMarginLeft,
          right: appTheme.msgListMarginRight,
          top: 12,
          bottom: 24,
        ),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            if (thought.isNotEmpty) ...[
              MarkdownRender(raw: thought, color: qb.q(.55), useMessageLineHeight: true),
              const SizedBox(height: 12),
              Container(height: 0.5, color: theme.dividerColor.q(.3)),
              const SizedBox(height: 12),
            ],
            if (output.isNotEmpty) MarkdownRender(raw: output, useMessageLineHeight: true),
          ],
        ),
      ),
    );
  }
}
