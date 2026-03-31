// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

class MultiQuestionInput extends ConsumerStatefulWidget {
  final int index;
  final bool canRemove;

  const MultiQuestionInput({super.key, required this.index, required this.canRemove});

  @override
  ConsumerState<MultiQuestionInput> createState() => _MultiQuestionInputState();
}

class _MultiQuestionInputState extends ConsumerState<MultiQuestionInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final questions = ref.read(P.multiQuestion.questions);
    final initial = widget.index < questions.length ? questions[widget.index] : "";
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final questions = ref.watch(P.multiQuestion.questions);

    // 同步外部状态到 controller
    final externalText = widget.index < questions.length ? questions[widget.index] : "";
    if (_controller.text != externalText) {
      _controller.text = externalText;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }

    return Container(
      margin: const .only(bottom: 8),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: .circular(8),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: const .fromLTRB(12, 8, 4, 0),
            child: Row(
              children: [
                Text(
                  "${s.question} ${widget.index + 1}",
                  style: TextStyle(
                    color: qb.q(.6),
                    fontSize: 12,
                    fontWeight: .w500,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 28,
                  width: 28,
                  child: IconButton(
                    padding: .zero,
                    iconSize: 18,
                    onPressed: () {
                      P.multiQuestion.refreshQuestion(widget.index);
                    },
                    icon: Icon(Symbols.refresh, color: theme.colorScheme.primary),
                  ),
                ),
                SizedBox(
                  height: 28,
                  width: 28,
                  child: IconButton(
                    padding: .zero,
                    iconSize: 18,
                    onPressed: widget.canRemove
                        ? () {
                            P.chat.batchCount.q -= 1;
                            P.multiQuestion.removeQuestion(widget.index);
                          }
                        : null,
                    icon: Icon(Icons.remove_circle_outline, color: widget.canRemove ? qb.q(.4) : qb.q(.15)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const .fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _controller,
              maxLines: 3,
              minLines: 1,
              style: TextStyle(color: qb, fontSize: 14),
              decoration: InputDecoration(
                hintText: s.multi_question_input_hint,
                hintStyle: TextStyle(color: qb.q(.3)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const .only(top: 4),
              ),
              onChanged: (value) {
                P.multiQuestion.updateQuestion(widget.index, value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
