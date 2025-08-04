import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/browser_tab.dart';
import 'package:zone/model/browser_window.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/widgets/performance_info.dart';

class PageTranslator extends ConsumerWidget {
  const PageTranslator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final isDesktop = ref.watch(P.app.isDesktop);
    final title = isDesktop ? s.rwkv_offline_translator_server : s.rwkv_offline_translator;
    return GestureDetector(
      onTap: isDesktop ? null : () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (isDesktop)
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
                      _InferenceInfo(),
                      if (isDesktop) _ServiceInfo(),
                      _TranslatiorInfo(),
                    ],
                  ),
                ),
                if (isDesktop)
                  Expanded(
                    child: _BrowserInfo(),
                  ),
              ],
            ),
          ],
        ),
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
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "局域网服务器信息",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
          ),
          8.h,
          Text("HTTP 服务 (端口号: $httpPort): ${backendState.name}"),
          if (backendState != BackendState.running)
            TextButton(
              onPressed: _onPressBackend,
              child: const Text("启动"),
            ),
          Text("WebSocket 服务 (端口号: $websocketPort): ${websocketState.name}"),
          if (websocketState != BackendState.running)
            TextButton(
              onPressed: _onPressWebsocket,
              child: const Text("启动"),
            ),
          Text("WebSocket 消息接收数量: $websocketReceivedCount"),
          Text("WebSocket 消息发送数量: $websocketSentCount"),
          if (backendState == BackendState.running)
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
    final browserWindows = ref.watch(P.translator.browserWindows);
    final browserTabs = ref.watch(P.translator.browserTabs);
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
            "浏览器运行状态信息",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
          ),
          8.h,
          Text("窗口 - 标签页 (${browserTabs.length})"),
          8.h,
          if (browserWindows.isNotEmpty)
            Wrap(
              runSpacing: 4,
              spacing: 4,
              children: browserWindows.map((e) => _BrowserWindow(window: e)).toList(),
            ),
        ],
      ),
    );
  }
}

class _BrowserWindow extends ConsumerWidget {
  const _BrowserWindow({required this.window});

  final BrowserWindow window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserTabs = ref.watch(P.translator.browserTabs.select((v) => v.where((e) => e.windowId == window.id).toList()));
    final qb = ref.watch(P.app.qb);
    final focused = window.focused;
    final border = Border.all(color: focused ? kCR.q(1) : qb.q(0.33), width: 2);
    return C(
      decoration: BD(
        color: kC,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Window: ${window.id}", style: TextStyle(color: focused ? kCR.q(1) : qb.q(1))),
          4.h,
          Wrap(
            runSpacing: 4,
            spacing: 4,
            children: browserTabs.map((e) {
              return _BrowserTab(tab: e);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BrowserTab extends ConsumerWidget {
  const _BrowserTab({required this.tab});

  final BrowserTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    final url = tab.url.replaceAll("https://", "").replaceAll("http://", "").replaceAll("www.", "");
    final innerSize = ref.watch(P.translator.browserTabInnerSize.select((v) => v[tab.id]));
    final scrollRect = ref.watch(P.translator.browserTabScrollRect.select((v) => v[tab.id]));
    final lastAccessed = tab.lastAccessed;
    final timeDisplay = DateTime.fromMillisecondsSinceEpoch(lastAccessed.toInt()).toString();
    final pool = ref.watch(P.translator.pool(tab));
    final isActive = ref.watch(P.translator.activedTab.select((v) => v?.id == tab.id));
    final latestTab = ref.watch(P.translator.latestTabs.select((v) => v[tab.windowId]));
    final isLatestInWindow = latestTab == tab;
    final runningTaskTabId = ref.watch(P.translator.runningTaskTabId);

    late final Color color;
    if (isActive) {
      color = kCG.q(1);
    } else if (isLatestInWindow) {
      color = kCG.q(0.5);
    } else {
      color = qb.q(0.33);
    }

    final border = Border.all(color: color, width: 2);

    return DefaultTextStyle(
      style: TextStyle(fontSize: 10, color: qb.q(.5)),
      child: C(
        constraints: const BoxConstraints(maxWidth: 180, minWidth: 120),
        decoration: BD(
          color: qb.q(0.1),
          border: border,
          borderRadius: 4.r,
        ),
        padding: const EI.o(t: 5, l: 6, b: 5, r: 6),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: qb.q(1)),
                ),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: qb.q(1)),
                ),
                if (pool.isNotEmpty) Text("Waiting requests: ${pool.length}"),
                // TODO: 这里还没对齐
                Text(timeDisplay, style: TextStyle(fontSize: 10, color: qb.q(.5))),
                Text("full: ${scrollRect?.width.toStringAsFixed(0)} x ${scrollRect?.height.toStringAsFixed(0)}"),
                Text("inner: ${innerSize?.width.toStringAsFixed(0)} x ${innerSize?.height.toStringAsFixed(0)}"),
                Text("scroll: ${scrollRect?.left.toStringAsFixed(0)} x ${scrollRect?.top.toStringAsFixed(0)}"),
              ],
            ),
            if (runningTaskTabId == tab.id)
              Positioned(
                height: 20,
                width: 20,
                right: 0,
                bottom: 0,
                child: SB(
                  child: CircularProgressIndicator(
                    color: kCG.q(1),
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
          ],
        ),
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

  FV _onPressClearCompleterPool() async {
    qq;
    P.backend.runningTasks.q = {};
    P.translator.browserTabInnerSize.q = {};
    P.translator.browserTabOuterSize.q = {};
    P.translator.browserTabScrollRect.q = {};
    P.translator.browserTabs.q = [];
    P.translator.browserWindows.q = [];
    P.translator.isGenerating.q = false;
    P.translator.runningTaskKey.q = null;
    P.translator.translations.q = {};
    P.translator.activedTab.q = null;
    P.translator.browserTabOuterSize.q = {};
    P.translator.browserTabInnerSize.q = {};
    P.translator.browserTabScrollRect.q = {};
    P.translator.browserWindows.q = [];
    P.translator.activedTab.q = null;
    P.translator.runningTaskTabId.q = null;
    P.translator.runningTaskUrl.q = null;
    P.rwkv.stop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    final primary = Theme.of(context).colorScheme.primary;
    final runningTaskKey = ref.watch(P.translator.runningTaskKey);
    final translations = ref.watch(P.translator.translations);
    final runningTaskUrl = ref.watch(P.translator.runningTaskUrl);
    final runningTaskTabId = ref.watch(P.translator.runningTaskTabId);
    final translationCountInSandbox = ref.watch(P.translator.translationCountInSandbox);
    final isDesktop = ref.watch(P.app.isDesktop);
    return C(
      decoration: BD(
        color: kC,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: qb.q(0.67), width: 1),
      ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "翻译器信息",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
            ),
            8.h,
            if (!isDesktop) Text("暂未在移动平台启用缓存功能, 可随时启用, 性能消耗可忽略不计"),
            if (isDesktop) Text("已经缓存的翻译结果数量: ${translations.length}"),
            if (isDesktop) Text("已经持久化的翻译结果数量: $translationCountInSandbox"),
            Text("正在翻译的文本长度: ${runningTaskKey?.length ?? 0}"),
            if (isDesktop) Text("正在翻译的 URL: $runningTaskUrl"),
            if (isDesktop) Text("正在翻译的标签页 ID: $runningTaskTabId"),
            if (isDesktop)
              TextButton(
                onPressed: _onPressClearCompleterPool,
                child: Text("清除内存缓存", style: TextStyle(color: kCR.q(1))),
              ),
            8.h,
            const Text("翻译状态 / 测试"),
            4.h,
            if (isDesktop)
              Row(
                children: [
                  const Expanded(child: _Source()),
                  8.w,
                  const Expanded(child: _Result()),
                ],
              ),
            if (!isDesktop)
              SizedBox(
                height: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        T("翻译目标", s: TS(s: 10)),
                        Spacer(),
                        TextButton(
                          onPressed: () => P.translator.textEditingController.clear(),
                          child: const Text("清空翻译目标文本"),
                        ),
                      ],
                    ),
                    2.h,
                    const Expanded(child: _Source()),
                    4.h,
                    T("翻译结果", s: TS(s: 8)),
                    2.h,
                    const Expanded(child: _Result()),
                  ],
                ),
              ),
            4.h,
            TextButton(
              onPressed: _onPressTest,
              child: const Text("翻译当前文本框中的文本"),
            ),
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
      decoration: const BD(color: kC),
      child: TextField(
        minLines: 1,
        maxLines: 4,
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
    return C(
      decoration: const BD(color: kC),
      child: TextField(
        minLines: 1,
        maxLines: 4,
        controller: P.translator.resultTextEditingController,
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
              const Text("请选择模型"),
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
