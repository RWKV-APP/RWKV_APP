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

  bool generating = false;
  bool resuming = false;

  bool canResume = false;
  bool hasPrompt = false;
  bool isSensitive = false;
  bool isTouchingOutput = false;

  bool get showPause => generating && hasPrompt && !resuming;

  bool get showResume => (!generating && hasPrompt && canResume) || resuming;

  bool get showSubmit => !generating && !canResume;

  @override
  void initState() {
    super.initState();

    controllerCheckSensitive.stream
        .throttleTime(const Duration(milliseconds: 100), trailing: true) //
        .listen((v) {
          checkSensitive(v);
        });

    controllerPrompt.addListener(() {
      if (generating) {
        return;
      }
      final r = controllerPrompt.text.isNotEmpty;
      if (r != hasPrompt) {
        setState(() {
          hasPrompt = r;
        });
      }
    });

    controllerOutput.addListener(() {
      if (generating) {
        return;
      }
      final r = controllerOutput.text.isNotEmpty;
      if (r != canResume && !isSensitive) {
        setState(() {
          canResume = r;
        });
      }
    });
  }

  void listenGenEvent() {
    ref.listen(P.chat.receivedTokens, (p, v) {
      if (isSensitive || v.isEmpty) {
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
      var output = v.replaceFirst(prompt, "");
      if (output.endsWith("<EOD>")) {
        setState(() {
          canResume = false;
        });
        output = output.substring(0, output.length - 5);
      }
      controllerOutput.text = output;
      if (0 < remain && remain < 80 && !isTouchingOutput) {
        scrollController.jumpTo(max);
      }
      controllerCheckSensitive.add(v);
    });
    ref.listen(P.chat.receivingTokens, (p, v) {
      if (v != generating) {
        qqq('generating => $v');
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {
            generating = v;
          });
        });
      }
    });
  }

  Future checkSensitive(String content) async {
    isSensitive = await P.guard.isSensitive(content);
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
    controllerCheckSensitive.close();
    controllerPrompt.dispose();
    controllerOutput.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void onSubmitTap({bool regenerate = false}) async {
    if (!checkModelSelection()) return;

    final prompt = controllerPrompt.text.trim();
    if (prompt.isEmpty) {
      return;
    }
    qqq('submit->$prompt');
    final contains = P.guard.isSensitiveSync(prompt);
    if (contains) {
      setState(() {
        canResume = false;
        isSensitive = true;
      });
      return;
    }
    setState(() {
      isSensitive = false;
    });
    P.chat.completion(prompt);
  }

  void onStopTap() async {
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
    final contains = P.guard.isSensitiveSync(prompt);
    if (contains) {
      setState(() {
        canResume = false;
        isSensitive = true;
      });
      return;
    }
    qqq('resume->$prompt');
    P.chat.completion(prompt + output);
  }

  void onClearOutputTap() {
    controllerOutput.clear();
    setState(() {
      isSensitive = false;
      canResume = false;
    });
  }

  void onClearInputTap() {
    controllerPrompt.clear();
    setState(() {
      isSensitive = false;
      canResume = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    listenGenEvent();
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
          const SizedBox(height: 50),
        ],
      ),
    );
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
