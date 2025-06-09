import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart' show qqq;
import 'package:halo_state/halo_state.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/state/p.dart';
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
  bool canResume = false;
  bool hasPrompt = false;
  bool isSensitive = false;

  bool get showPause => generating && hasPrompt;

  bool get showResume => !generating && hasPrompt && canResume;

  bool get showSubmit => !generating && !canResume;

  @override
  void initState() {
    super.initState();

    controllerCheckSensitive.stream.throttleTime(const Duration(seconds: 1)).listen((v) {
      _checkSensitive(v);
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

  void listen() {
    ref.listen(P.chat.receivedTokens, (p, v) {
      qqq(v);
      if (isSensitive) {
        return;
      }
      final max = scrollController.position.maxScrollExtent;
      final remain = max - scrollController.position.pixels;
      final prompt = controllerPrompt.text.trim();
      controllerOutput.text = v.replaceFirst(prompt, "");
      if (0 < remain && remain < 100) {
        scrollController.jumpTo(max);
      }
      controllerCheckSensitive.add(v);
    });
    ref.listen(P.chat.receivingTokens, (p, v) {
      if (v != generating) {
        qqq('Stopped');
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {
            generating = v;
          });
        });
      }
    });
  }

  Future _checkSensitive(String content) async {
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

  void onSubmitTap() async {
    final prompt = controllerPrompt.text.trim();
    if (prompt.isEmpty) {
      return;
    }
    qqq('submit->$prompt');
    final contains = await _checkSensitive(prompt);
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
  }

  void onResumeTap() async {
    final prompt = controllerPrompt.text.trim();
    final output = controllerOutput.text.trim();
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    qqq('resume->$prompt');
    P.chat.completion(prompt + output);
  }

  void onClearTap() async {
    P.chat.stopCompletion();
    controllerPrompt.clear();
    controllerOutput.clear();
  }

  @override
  Widget build(BuildContext context) {
    listen();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: double.infinity,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Prompt'),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: generating || !hasPrompt
                    ? null
                    : () {
                        controllerPrompt.clear();
                        setState(() {
                          canResume = false;
                        });
                      },
                child: const Text('Clear'),
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
          Row(
            children: [
              if (showSubmit) FilledButton.tonal(onPressed: !hasPrompt ? null : onSubmitTap, child: const Text("Submit")),

              if (showPause) FilledButton.tonal(onPressed: onStopTap, child: const Text("Pause")),

              if (showResume) FilledButton.tonal(onPressed: onResumeTap, child: const Text("Resume")),

              if (showResume || showPause) const SizedBox(width: 8),
              if (showResume || showPause)
                FilledButton.tonal(
                  onPressed: generating ? null : onSubmitTap,
                  child: const Text("Regenerate"),
                ),
              const Spacer(),
              const SizedBox(width: 8),
              const PerformanceInfo(),
            ],
          ),
          Row(
            children: [
              const Expanded(child: Text('Output')),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: generating || !hasPrompt
                    ? null
                    : () {
                        controllerOutput.clear();
                        setState(() {
                          canResume = false;
                        });
                      },
                child: const Text('Clear'),
              ),
            ],
          ),
          Expanded(
            flex: 2,
            child: TextField(
              scrollController: scrollController,
              controller: isSensitive ? TextEditingController(text: S.current.filter) : controllerOutput,
              maxLines: 999999999,
              enabled: !generating,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
