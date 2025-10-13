import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart' show qqq;
import 'package:halo_state/halo_state.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zone/func/check_model_selection.dart' show checkModelSelection;
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/store/p.dart';
import 'package:zone/widgets/performance_info.dart' show PerformanceInfo;

class Completion extends ConsumerStatefulWidget {
  const Completion({super.key});

  @override
  ConsumerState<Completion> createState() => _CompletionState();
}

class _CompletionState extends ConsumerState<Completion> {
  final TextEditingController controllerPrompt = TextEditingController();
  final TextEditingController controllerOutput = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late final controllerCheckSensitive = StreamController<String>();
  StreamSubscription? subscription;

  int row = 2;
  int col = 2;

  int get batchSize => row * col;
  List<String> outputs = [];

  bool generating = false;
  bool resuming = false;

  bool canResume = false;
  bool hasPrompt = false;
  bool isSensitive = false;
  bool isTouchingOutput = false;

  bool get showPause => generating && hasPrompt && !resuming;

  bool get showResume => (!generating && hasPrompt && canResume && batchSize == 1) || resuming;

  bool get showSubmit => !generating && !canResume && !resuming;

  void onInputOutputEmpty() {
    if (canResume) {
      setState(() {
        canResume = false;
      });
    }
    if (isSensitive) {
      setState(() {
        isSensitive = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    controllerCheckSensitive.stream
        .throttleTime(const Duration(milliseconds: 400), trailing: true) //
        .listen((v) {
          checkSensitive(v);
        });

    controllerPrompt.addListener(() {
      if (generating) {
        return;
      }
      final notEmpty = controllerPrompt.text.isNotEmpty;
      if (!notEmpty) {
        onInputOutputEmpty();
      }
      if (notEmpty != hasPrompt) {
        setState(() {
          hasPrompt = notEmpty;
        });
      }
    });

    controllerOutput.addListener(() {
      if (generating) {
        return;
      }
      final notEmpty = controllerOutput.text.isNotEmpty;
      if (!notEmpty) {
        onInputOutputEmpty();
      }
      if (notEmpty != canResume && !isSensitive) {
        setState(() {
          canResume = notEmpty;
        });
      }
    });
  }

  Future checkSensitive(String content) async {
    isSensitive = await P.guard.isSensitive(content);
    if (!mounted) {
      return;
    }
    if (isSensitive) {
      P.chat.stopCompletion();
      P.chat.receivedTokens.q = "";
      controllerOutput.clear();
      setState(() {
        canResume = false;
      });
    }
    return isSensitive;
  }

  @override
  void dispose() {
    subscription?.cancel();
    controllerCheckSensitive.close();
    controllerPrompt.dispose();
    controllerOutput.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void onSubmitTap({bool regenerate = false}) async {
    if (!checkModelSelection()) return;

    final prompt = controllerPrompt.text.trim();
    qqq('submit->$prompt');
    completion(prompt);
  }

  void onResponse(String content) {
    if (isSensitive || content.isEmpty) {
      return;
    }
    if (resuming) {
      setState(() {
        resuming = false;
      });
    }
    final max = scrollController.position.maxScrollExtent;
    final remain = max - scrollController.position.pixels;
    final prompt = controllerPrompt.text.trim();
    var output = content.replaceFirst(prompt, "");
    if (output.endsWith("<EOD>")) {
      output = output.substring(0, output.length - 5);
    }
    controllerOutput.text = output;
    if (0 < remain && remain < 80 && !isTouchingOutput) {
      scrollController.jumpTo(max);
    }
    controllerCheckSensitive.add(content);
  }

  void onStopTap() async {
    subscription?.cancel();
    subscription = null;
    P.chat.stopCompletion();
    setState(() {
      canResume = true;
    });
  }

  void onResumeTap() async {
    if (resuming) {
      return;
    }
    setState(() {
      resuming = true;
    });
    final prompt = controllerPrompt.text.trim();
    final output = controllerOutput.text.trim();
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    qqq('resume->$prompt');
    completion(prompt + output);
  }

  void completion(String prompt) {
    final contains = P.guard.isSensitiveSync(prompt);
    setState(() {
      isSensitive = false;
      canResume = false;
    });
    if (contains) {
      setState(() {
        isSensitive = true;
      });
      return;
    }
    P.rwkv.clearStates();
    subscription?.cancel();
    subscription = P.rwkv
        .completion(prompt, batchSize: batchSize)
        .listen(
          (e) {
            if (batchSize > 1) {
              setState(() {
                outputs = e.responseBufferContent;
              });
            } else {
              onResponse(e.responseBufferContent[0]);
              if (e.eosFound[0]) {
                setState(() {
                  qqq('message');
                  canResume = false;
                });
              }
            }
          },
          onError: (e) {
            setState(() {
              canResume = false;
            });
          },
          onDone: () {
            qqq('done');
          },
        );
  }

  void onClearOutputTap() {
    controllerOutput.clear();
  }

  void onClearInputTap() {
    controllerPrompt.clear();
  }

  void onSuggestTap() async {
    final res = await _SuggestDialog.show(context);
    if (res == null || !mounted) {
      return;
    }
    controllerPrompt.text = res;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(P.rwkv.generating, (_, v) {
      if (generating != v) {
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {
            generating = v;
          });
        });
      }
    });
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: double.infinity,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(S.current.prompt),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: generating ? null : onSuggestTap,
                child: Text(S.current.suggest),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: generating || !hasPrompt ? null : onClearInputTap,
                child: Text(S.current.clear),
              ),
            ],
          ),
          Expanded(
            child: TextField(
              maxLines: 999999999,
              enabled: !generating,
              controller: controllerPrompt,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildActions(),
          if (batchSize == 1) ..._buildSingleOutput(),
          if (batchSize > 1) ..._buildMultiOutput(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildMultiOutput() {
    return [
      const SizedBox(height: 12),
      Expanded(
        flex: 3,
        child: Column(
          children: [
            for (var i = 0; i < row; i++)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < col; j++)
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: j == col - 1 ? 0 : 8, bottom: i == row - 1 ? 0 : 8),
                          child: _BatchOutputText(
                            text: outputs.length <= i * col + j ? '' : outputs[i * col + j],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildSingleOutput() {
    return [
      Row(
        children: [
          Expanded(child: Text(S.current.output)),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            onPressed: generating ? null : onClearOutputTap,
            child: Text(S.current.clear),
          ),
        ],
      ),
      Expanded(
        flex: 2,
        child: Listener(
          onPointerDown: (event) {
            isTouchingOutput = true;
          },
          onPointerUp: (event) {
            isTouchingOutput = false;
          },
          onPointerCancel: (event) {
            isTouchingOutput = false;
          },
          child: TextField(
            scrollController: scrollController,
            controller: isSensitive ? TextEditingController(text: S.current.filter) : controllerOutput,
            maxLines: 999999999,
            readOnly: generating || isSensitive,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (showSubmit)
          FilledButton.icon(
            onPressed: !hasPrompt ? null : onSubmitTap,
            label: Text(S.current.submit),
          ),

        if (showPause)
          FilledButton.icon(
            onPressed: onStopTap,
            label: Text(S.current.pause),
            icon: const Icon(Icons.pause_rounded),
          ),

        if (showResume)
          FilledButton.icon(
            onPressed: onResumeTap,
            label: Text(S.current.resume),
            icon: resuming
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                  )
                : const Icon(Icons.play_arrow_rounded),
          ),

        if (showResume || showPause) const SizedBox(width: 8),
        if (showResume || showPause)
          OutlinedButton.icon(
            onPressed: generating ? null : onSubmitTap,
            label: Text(S.current.regenerate),
            icon: const Icon(Icons.refresh_rounded),
          ),
        const Spacer(),
        const SizedBox(width: 8),
        const PerformanceInfo(),
      ],
    );
  }
}

class _BatchOutputText extends StatefulWidget {
  final String text;

  const _BatchOutputText({required this.text});

  @override
  State<_BatchOutputText> createState() => _BatchOutputTextState();
}

class _BatchOutputTextState extends State<_BatchOutputText> {
  final ScrollController scrollController = ScrollController();
  late final TextEditingController controller = TextEditingController(text: widget.text);

  @override
  void didUpdateWidget(covariant _BatchOutputText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      controller.text = widget.text;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      scrollController: scrollController,
      maxLines: 99999999,
      readOnly: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        isDense: true,
        border: OutlineInputBorder(),
      ),
      controller: controller,
    );
  }
}

class _SuggestDialog extends StatefulWidget {
  final ScrollController scrollController;

  const _SuggestDialog(this.scrollController);

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (c) => DraggableScrollableSheet(
        maxChildSize: .9,
        minChildSize: .25,
        expand: false,
        snap: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return _SuggestDialog(scrollController);
        },
      ),
    );
  }

  @override
  State<_SuggestDialog> createState() => _SuggestDialogState();
}

class _SuggestDialogState extends State<_SuggestDialog> {
  List<String> items = [];

  @override
  void initState() {
    super.initState();
    items = P.suggestion.config.q.completion;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Expanded(child: Text(S.of(context).suggest, style: theme.textTheme.titleMedium)),
                const CloseButton(),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items) ...[
                    ListTile(
                      title: Text(item, maxLines: 3, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        Navigator.pop(context, item);
                      },
                    ),
                    const Divider(indent: 16, endIndent: 16, height: 6, thickness: 0.5),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
