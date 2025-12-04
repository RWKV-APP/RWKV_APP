import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart' show qqq;
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zone/func/check_model_selection.dart' show checkModelSelection;
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/model/demo_type.dart';
import 'package:zone/page/completion/_completion_state.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/batch_completion_settings_panel.dart';
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

  BatchCompletionSettings settings = BatchCompletionSettings.initial();
  int row = 1;

  int get col => settings.enabled ? settings.batchCount : 1;

  double get colWidthPercent => settings.width / 100.0;

  int get batchSize => row * col;
  List<String> outputs = [];

  bool generating = false;
  bool resuming = false;

  bool canResume = false;
  bool hasPrompt = false;
  bool isSensitive = false;
  bool isTouchingOutput = false;

  bool get batchCompletion => batchSize > 1;

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

    settings = BatchCompletionSettingsPanel.settings.q;
    if (P.rwkv.currentModel.q?.tags.contains('batch') == false && settings.enabled) {
      settings = settings.copyWith(enabled: false);
    }

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

  void onBatchTap() async {
    if (!checkModelSelection(preferredDemoType: DemoType.chat)) return;
    final unavailable = P.rwkv.currentModel.q?.tags.contains('batch') == false;
    if (unavailable) {
      Alert.warning(S.current.this_model_does_not_support_batch_inference);
      return;
    }
    BatchCompletionSettingsPanel.settings.q = this.settings;
    final settings = await BatchCompletionSettingsPanel.show();
    if (settings.enabled != this.settings.enabled) {
      outputs.clear();
      canResume = false;
      resuming = false;
      controllerOutput.clear();
    }
    setState(() {
      this.settings = settings;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void onSubmitTap({bool regenerate = false}) async {
    if (!checkModelSelection(preferredDemoType: DemoType.chat)) return;

    final prompt = controllerPrompt.text.trim();
    qqq('submit->$prompt');
    completion(prompt, prompt);
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
    qqq('stop');
    subscription?.cancel();
    subscription = null;
    P.chat.stopCompletion();
    setState(() {
      generating = false;
      canResume = batchSize == 1;
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
    completion(prompt + output, prompt);
  }

  void completion(String prompt, String trim) {
    FocusScope.of(context).requestFocus(FocusNode());
    final contains = P.guard.isSensitiveSync(prompt);
    setState(() {
      generating = true;
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
            final resp = e.responseBufferContent.map((e) => e.replaceFirst(trim, '')).toList();
            if (batchSize > 1) {
              setState(() {
                outputs = resp;
              });
            } else {
              onResponse(resp[0]);
              if (e.eosFound[0]) {
                setState(() {
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
    final qb = ref.watch(P.app.qb);
    ref.listen(P.rwkv.generating, (_, v) {
      if (generating != v) {
        qqq('generating=>$v');
        setState(() {
          generating = v;
        });
      }
    });
    ref.listen(P.rwkv.currentModel, (_, v) {
      final batchUnavailable = v?.tags.contains('batch') == false;
      if (batchUnavailable && settings.enabled) {
        settings = settings.copyWith(enabled: false);
        BatchCompletionSettingsPanel.settings.q = settings;
        setState(() {});
      }
    });
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: .only(left: 8, right: 8, bottom: bottomPadding > 0 ? bottomPadding : 8),
      height: double.infinity,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Text(S.current.prompt),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: .compact,
                  padding: .zero,
                  minimumSize: const Size(48, 32),
                ),
                onPressed: generating ? null : onSuggestTap,
                child: Text(S.current.suggest),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: .compact,
                  padding: .zero,
                  minimumSize: const Size(48, 32),
                ),
                onPressed: generating || !hasPrompt ? null : onClearInputTap,
                child: Text(S.current.clear),
              ),
            ],
          ),
          Expanded(
            flex: 2,
            child: TextField(
              maxLines: 999999999,
              readOnly: generating,
              controller: controllerPrompt,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: .circular(4),
                ),
                contentPadding: const .symmetric(horizontal: 4, vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildActions(),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                if (batchSize == 1) ..._buildSingleOutput(),
                if (batchSize > 1) ..._buildMultiOutput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMultiOutput() {
    return [
      const SizedBox(height: 6),
      Expanded(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
            scrollbars: true,
          ),
          child: LayoutBuilder(
            builder: (ctx, cs) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  height: cs.maxHeight,
                  child: Column(
                    children: [
                      for (var i = 0; i < row; i++)
                        SizedBox(
                          height: cs.maxHeight / row,
                          width: cs.maxWidth * colWidthPercent * col,
                          child: Row(
                            crossAxisAlignment: .stretch,
                            children: [
                              for (var j = 0; j < col; j++)
                                Expanded(
                                  child: Container(
                                    margin: .only(right: j == col - 1 ? 0 : 8, bottom: i == row - 1 ? 0 : 8),
                                    child: i * col + j > batchSize
                                        ? const SizedBox()
                                        : _BatchOutputText(
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
              );
            },
          ),
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
              visualDensity: .compact,
              padding: .zero,
              minimumSize: const Size(48, 32),
            ),
            onPressed: generating ? null : onClearOutputTap,
            child: Text(S.current.clear),
          ),
        ],
      ),
      Expanded(
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
              border: OutlineInputBorder(
                borderRadius: .only(
                  topLeft: .circular(4),
                  topRight: .circular(4),
                  bottomLeft: .circular(24),
                  bottomRight: .circular(24),
                ),
              ),
              contentPadding: .symmetric(horizontal: 4, vertical: 0),
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
            label: Text(batchCompletion ? S.current.stop : S.current.pause),
            icon: SizedBox(
              width: 22,
              height: 22,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  batchCompletion ? const Icon(Icons.stop) : const Icon(Icons.pause_rounded),
                  CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2),
                ],
              ),
            ),
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

        if ((showResume || showPause) && !batchCompletion) const SizedBox(width: 6),
        if ((showResume || showPause) && !batchCompletion)
          IconButton.outlined(
            onPressed: generating ? null : onSubmitTap,
            icon: const Icon(Icons.refresh_rounded),
            visualDensity: .compact,
          ),
        const SizedBox(width: 6),
        OutlinedButton(
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(.symmetric(horizontal: 6)),
            visualDensity: .compact,
            backgroundColor: !batchCompletion ? null : WidgetStatePropertyAll(Theme.of(context).colorScheme.primary),
            foregroundColor: !batchCompletion ? null : WidgetStatePropertyAll(Theme.of(context).colorScheme.onPrimary),
          ),
          onPressed: generating ? null : onBatchTap,
          child: Text(!batchCompletion ? S.current.batch_inference_short : S.current.batch_inference_button(batchSize)),
        ),
        const Spacer(),
        const SizedBox(width: 6),
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
      focusNode: Platform.isWindows ? FocusNode() : null,
      readOnly: true,
      decoration: const InputDecoration(
        contentPadding: .symmetric(horizontal: 4, vertical: 6),
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
    final s = S.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const .symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Expanded(child: Text(s.suggest, style: theme.textTheme.titleMedium)),
                const CloseButton(),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  for (final item in items) ...[
                    ListTile(
                      title: Text(item, maxLines: 3, overflow: .ellipsis),
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
