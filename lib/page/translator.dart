import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_mobile_flutter/to_rwkv.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/model_selector.dart';

class PageTranslator extends ConsumerWidget {
  const PageTranslator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final isDesktop = ref.watch(P.app.isDesktop);

    final paddingTop = ref.watch(P.app.paddingTop);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Translator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            SB(height: paddingTop),
            if (!isPortrait)
              Expanded(
                child: Row(
                  children: [
                    const Expanded(child: _Source()),
                    12.w,
                    const Expanded(child: _Result()),
                  ],
                ).debug,
              ),
            if (isDesktop) const _Dashboard(),
          ],
        ),
      ),
    );
  }
}

class _Source extends ConsumerWidget {
  const _Source();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return C(
      decoration: BD(color: kCR.q(.2)),
      child: TextField(
        maxLines: 10,
        controller: P.translator.textEditingController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Source',
          hintText: 'Enter your text here',
        ),
      ),
    );
  }
}

class _Result extends ConsumerWidget {
  const _Result();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(P.translator.result);
    return C(
      decoration: BD(color: kCB.q(.2)),
      child: TextField(
        maxLines: 10,
        controller: TextEditingController(text: result),
        enabled: false,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Translation Result',
          hintText: 'Result will be shown here',
        ),
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard();

  FV _onPressed() async {
    qq;
    final state = P.backend.httpState.q;
    switch (state) {
      case BackendState.starting:
        return;
      case BackendState.running:
        await P.backend.stop();
        return;
      case BackendState.stopping:
        return;
      case BackendState.stopped:
        await P.backend.start();
        return;
    }
  }

  FV _onPressPanel() async {
    qq;
    ModelSelector.show();
  }

  FV _onPressTest() async {
    qq;
    P.translator.onPressTest();
  }

  FV _onPressSetPrompt() async {
    qq;
    P.rwkv.send(SetPrompt(""));
  }

  FV _onPressClearCompleterPool() async {
    qq;
    P.translator.translations.q = LinkedHashMap.from({});
    P.backend.runningTasks.q = {};
    P.translator.completerPool.q = {};
    P.translator.runningTaskKey.q = null;
    P.translator.isGenerating.q = false;
    P.rwkv.stop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendState = ref.watch(P.backend.httpState);

    final title = switch (backendState) {
      BackendState.starting => "Starting...",
      BackendState.running => "Stop Server",
      BackendState.stopping => "Stopping...",
      BackendState.stopped => "Start Server",
    };

    // 设置地址
    // 展示运行状态, prefill & decode
    // 选择模型
    // test translation calling
    return Column(
      children: [
        Row(
          children: [
            TextButton(
              onPressed: _onPressed,
              child: Text(title),
            ),
            TextButton(
              onPressed: _onPressPanel,
              child: const Text("Panel"),
            ),
            TextButton(
              onPressed: _onPressTest,
              child: const Text("Translation Test"),
            ),
            TextButton(
              onPressed: _onPressSetPrompt,
              style: TextButton.styleFrom(
                backgroundColor: kCR.q(1),
                foregroundColor: kW.q(1),
              ),
              child: const Text("Set Prompt to \"\""),
            ),
            TextButton(
              onPressed: _onPressClearCompleterPool,
              child: const Text("Clear Completer Pool"),
            ),
          ],
        ),
      ],
    );
  }
}
