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
    final paddingTop = ref.watch(P.app.paddingTop);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chrome Offline Translator'),
      ),
      body: ListView(
        children: [
          32.h,
          SB(height: paddingTop),
          const _Dashboard(),
          const _TabInfo(),
          const _Source(),
          const _Result(),
        ],
      ),
    );
  }
}

class _TabInfo extends ConsumerWidget {
  const _TabInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightUrl = ref.watch(P.translator.highlightUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("所有打开的标签页"),
        Text("正在交互中的标签页: $highlightUrl"),
      ],
    );
  }
}

class _Source extends ConsumerWidget {
  const _Source();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return C(
      decoration: BD(color: kC),
      padding: const EdgeInsets.all(8),
      child: TextField(
        minLines: 1,
        maxLines: 8,
        controller: P.translator.textEditingController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
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
      decoration: BD(color: kC),
      padding: const EdgeInsets.all(8),
      child: TextField(
        minLines: 1,
        maxLines: 8,
        controller: TextEditingController(text: result),
        enabled: false,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
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
    P.translator.translations.q = {};
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
      BackendState.starting => "正在启动...",
      BackendState.running => "停止服务",
      BackendState.stopping => "正在停止...",
      BackendState.stopped => "启动服务",
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
              child: const Text("选择不同模型"),
            ),
            TextButton(
              onPressed: _onPressTest,
              child: const Text("翻译当前文本框中的文本"),
            ),
            TextButton(
              onPressed: _onPressClearCompleterPool,
              child: const Text("清除缓存"),
            ),
            TextButton(
              onPressed: P.translator.debugCheck,
              child: const Text("检查"),
            ),
          ],
        ),
      ],
    );
  }
}
