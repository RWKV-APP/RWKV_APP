// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/multi_question_input.dart';

class MultiQuestionPanel extends ConsumerWidget {
  static const String panelKey = 'MultiQuestionPanel';

  static Future<void> show() async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final batchCount = P.chat.batchCount.q;
    P.multiQuestion.initQuestions(batchCount);

    await P.ui.showPanel(
      key: panelKey,
      initialChildSize: .78,
      maxChildSize: .94,
      builder: (scrollController) => MultiQuestionPanel(scrollController: scrollController),
    );
  }

  final ScrollController scrollController;

  const MultiQuestionPanel({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final questions = ref.watch(P.multiQuestion.questions);
    final canSend = ref.watch(P.multiQuestion.canSend);
    final batchCount = ref.watch(P.chat.batchCount);
    final supportedBatchSizes = ref.watch(P.rwkv.supportedBatchSizes);
    final int maxBatchSize = supportedBatchSizes.isNotEmpty ? supportedBatchSizes.reduce((a, b) => a > b ? a : b) : 4;
    final bool canAdd = batchCount < maxBatchSize;
    final bool canRemove = questions.length > 2;

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(12),
        topRight: .circular(12),
      ),
      child: Scaffold(
        backgroundColor: appTheme.settingBg,
        appBar: AppBar(
          title: Text(s.multi_question_title),
          automaticallyImplyLeading: false,
          backgroundColor: appTheme.settingBg,
          actions: [
            Padding(
              padding: const .only(right: 4),
              child: IconButton(
                onPressed: canAdd
                    ? () {
                        P.chat.batchCount.q += 1;
                        P.multiQuestion.addQuestion();
                      }
                    : null,
                icon: Icon(Icons.add, color: canAdd ? null : theme.colorScheme.onSurface.q(.3)),
              ),
            ),
            Padding(
              padding: const .only(right: 8),
              child: IconButton(
                onPressed: () => pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: .fromLTRB(12, 8, 12, 12 + paddingBottom),
                children: [
                  for (int i = 0; i < questions.length; i++) MultiQuestionInput(index: i, canRemove: canRemove),
                ],
              ),
            ),
            _SendBar(canSend: canSend),
          ],
        ),
      ),
    );
  }
}

class _SendBar extends ConsumerWidget {
  final bool canSend;

  const _SendBar({required this.canSend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);

    return Container(
      padding: .fromLTRB(16, 8, 16, 12 + paddingBottom),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: FilledButton.icon(
          onPressed: canSend
              ? () {
                  pop();
                  P.multiQuestion.sendAll();
                }
              : null,
          icon: const Icon(Symbols.send, size: 18),
          label: Text(s.multi_question_send_all),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            disabledBackgroundColor: theme.colorScheme.primary.q(.3),
            shape: RoundedRectangleBorder(borderRadius: .circular(10)),
          ),
        ),
      ),
    );
  }
}
