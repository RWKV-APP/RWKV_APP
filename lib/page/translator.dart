import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/widgets/performance_info.dart';

class PageTranslator extends ConsumerWidget {
  const PageTranslator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingTop = ref.watch(P.app.paddingTop);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RWKV 离线翻译服务器'),
        actions: [
          IconButton(
            onPressed: () {
              P.translator.debugCheck();
            },
            icon: const Icon(Icons.help),
          ),
        ],
      ),
      body: ListView(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _InferenceInfo(),
                    const _BrowserInfo(),
                  ],
                ),
              ),
              Expanded(
                child: const _ServiceInfo(),
              ),
            ],
          ),
          const _TranslatiorInfo(),
          const _Dashboard(),
        ],
      ),
    );
  }
}

class _ServiceInfo extends ConsumerWidget {
  const _ServiceInfo();

  FV _onPressBackend() async {
    qq;
    final currentModel = P.rwkv.currentModel.q;
    if (currentModel == null) {
      ModelSelector.show();
      return;
    }
    P.backend.start();
  }

  FV _onPressWebsocket() async {
    qq;
    P.backend.start();
  }

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendState = ref.watch(P.backend.httpState);
    final websocketState = ref.watch(P.backend.websocketState);
    final qb = ref.watch(P.app.qb);
    final primary = Theme.of(context).colorScheme.primary;
    final httpPort = ref.watch(P.backend.httpPort);
    final websocketPort = ref.watch(P.backend.websocketPort);
    final taskReceivedCount = ref.watch(P.backend.taskReceivedCount);
    final taskHandledCount = ref.watch(P.backend.taskHandledCount);
    final runningTasks = ref.watch(P.backend.runningTasks);
    final websocketReceivedCount = ref.watch(P.backend.websocketReceivedCount);
    final websocketSentCount = ref.watch(P.backend.websocketSentCount);

    final title = switch (backendState) {
      BackendState.starting => "正在启动...",
      BackendState.running => "停止服务",
      BackendState.stopping => "正在停止...",
      BackendState.stopped => "启动服务",
    };

    return C(
      decoration: BD(
        color: kC,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: qb.q(0.67), width: 1),
      ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8).copyWith(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "局域网服务器信息",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
          ),
          8.h,
          Text("HTTP 服务 (端口号: $httpPort): ${backendState.name}"),
          TextButton(
            onPressed: _onPressBackend,
            child: Text("操作"),
          ),
          Text("WebSocket 服务 (端口号: $websocketPort): ${websocketState.name}"),
          TextButton(
            onPressed: _onPressWebsocket,
            child: Text("操作"),
          ),
          Text("HTTP 请求接收数量: $taskReceivedCount"),
          Text("HTTP 请求处理数量: $taskHandledCount"),
          Text("HTTP 请求处理中(并发): ${runningTasks.length}"),
          Text("WebSocket 消息接收数量: $websocketReceivedCount"),
          Text("WebSocket 消息发送数量: $websocketSentCount"),

          TextButton(
            onPressed: _onPressed,
            child: Text(title),
          ),
        ],
      ),
    );
  }
}

class _BrowserInfo extends ConsumerWidget {
  const _BrowserInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    final primary = Theme.of(context).colorScheme.primary;
    final qw = ref.watch(P.app.qw);
    final browserTabs = ref.watch(P.translator.browserTabs);
    final activeBrowserTab = ref.watch(P.translator.activeBrowserTab);
    final activeUrl = activeBrowserTab?.url ?? "";
    final activeTitle = activeBrowserTab?.title ?? "";
    final activeFavicon = activeBrowserTab?.favIconUrl ?? "";
    final activeTabId = activeBrowserTab?.id;
    final runningTaskTabId = ref.watch(P.translator.runningTaskTabId);

    return C(
      decoration: BD(
        color: kC,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: qb.q(0.67), width: 1),
      ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8).copyWith(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "浏览器运行状态信息",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
          ),
          8.h,
          Wrap(
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text("当前标签页"),
              8.w,
              Text("优先翻译已打开的标签页", style: TextStyle(fontSize: 10, color: qb.q(.5))),
            ],
          ),
          Text(
            "URL: $activeUrl",
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "标题: $activeTitle",
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          Text("当前标签页 ID: $activeTabId"),
          Text("正在翻译的标签页 ID: $runningTaskTabId"),
          8.h,
          Text("其他标签页"),
          Text("总数: ${browserTabs.length}"),
        ],
      ),
    );
  }
}

class _TranslatiorInfo extends ConsumerWidget {
  const _TranslatiorInfo();

  FV _onPressTest() async {
    qq;
    P.translator.onPressTest();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    final primary = Theme.of(context).colorScheme.primary;
    final runningTaskKey = ref.watch(P.translator.runningTaskKey);
    final translations = ref.watch(P.translator.translations);
    final completerPool = ref.watch(P.translator.completerPool);
    final runningTaskNodeName = ref.watch(P.translator.runningTaskNodeName);
    final runningTaskPriority = ref.watch(P.translator.runningTaskPriority);
    final runningTaskTick = ref.watch(P.translator.runningTaskTick);
    final runningTaskUrl = ref.watch(P.translator.runningTaskUrl);
    return C(
      decoration: BD(
        color: kC,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: qb.q(0.67), width: 1),
      ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "翻译器信息",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
          ),
          8.h,
          Text("已经缓存的翻译结果数量: ${translations.length}"),
          Text("等待中的翻译任务数量: ${completerPool.length}"),
          Text("正在翻译的文本长度: ${runningTaskKey?.length ?? 0}"),
          Text("正在翻译的节点名称: $runningTaskNodeName"),
          Text("正在翻译的优先级: $runningTaskPriority"),
          Text("正在翻译的 tick: $runningTaskTick"),
          Text("正在翻译的 URL: $runningTaskUrl"),
          8.h,
          Text("翻译测试"),
          4.h,
          Row(
            children: [
              Expanded(
                child: _Source(),
              ),
              8.w,
              Expanded(
                child: _Result(),
              ),
            ],
          ),
          4.h,
          TextButton(
            onPressed: _onPressTest,
            child: const Text("翻译当前文本框中的文本"),
          ),
        ],
      ),
    );
  }
}

class _Source extends ConsumerWidget {
  const _Source();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return C(
      decoration: BD(color: kC),
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

class _InferenceInfo extends ConsumerWidget {
  const _InferenceInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    final primary = Theme.of(context).colorScheme.primary;
    final isGenerating = ref.watch(P.translator.isGenerating);
    final currentModel = ref.watch(P.rwkv.currentModel);
    return C(
      decoration: BD(
        color: kC,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: qb.q(0.67), width: 1),
      ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "RWKV 推理引擎信息",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
          ),
          8.h,
          Wrap(
            runSpacing: 8,
            spacing: 8,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text("当前模型: ${currentModel?.name}"),
              Text("请选择模型"),
              TextButton(
                onPressed: () => ModelSelector.show(),
                child: const Text("选择不同模型"),
              ),
            ],
          ),
          Text("推理器状态: ${isGenerating ? "推理中" : "空闲"}"),
          const PerformanceInfo(),
        ],
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard();

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
