import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/backend_state.dart';
import 'package:zone/model/browser_tab.dart';
import 'package:zone/model/browser_window.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/model_selector.dart';

class PageTranslator extends ConsumerWidget {
  const PageTranslator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final isDesktop = ref.watch(P.app.isDesktop);
    final title = isDesktop ? s.offline_translator_server : s.offline_translator;

    return GestureDetector(
      onTap: isDesktop ? null : () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(title),
          actions: [
            if (isDesktop)
              IconButton(
                onPressed: () {
                  P.translator.debugCheck();
                },
                icon: const Icon(Icons.help_outline),
              ),
          ],
        ),
        body: isDesktop ? const _DesktopLayout() : const _MobileLayout(),
      ),
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const .all(16),
      children: const [
        _TranslatorInterface(),
        SizedBox(height: 16),
        _InferenceInfo(),
      ],
    );
  }
}

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: .start,
      children: [
        Expanded(
          child: ListView(
            padding: const .all(16),
            children: const [
              _TranslatorInterface(),
              SizedBox(height: 16),
              _InferenceInfo(),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const .all(16),
            children: const [
              _ServiceInfo(),
              SizedBox(height: 16),
              _BrowserInfo(),
              SizedBox(height: 16),
              _TranslatorDebugInfo(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TranslatorInterface extends ConsumerWidget {
  const _TranslatorInterface();

  Future<void> _onPressTest() async {
    qq;
    P.translator.onPressTest();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return Card(
      elevation: 2,
      margin: .zero,
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          const _Source(),
          Divider(height: 1, color: theme.colorScheme.outline.q(0.2)),
          const _TranslationDirectionButton(),
          Divider(height: 1, color: theme.colorScheme.outline.q(0.2)),
          const _Result(),
          Padding(
            padding: const .all(12.0),
            child: FilledButton.icon(
              onPressed: _onPressTest,
              icon: const Icon(Icons.translate),
              label: Text(s.translate),
              style: FilledButton.styleFrom(
                padding: const .symmetric(vertical: 12),
                textStyle: theme.textTheme.titleSmall,
              ),
            ),
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
    final theme = Theme.of(context);
    final s = S.of(context);
    final enToZh = ref.watch(P.translator.enToZh);

    return Padding(
      padding: const .fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Text(
                enToZh ? s.input_english_text_here : s.input_chinese_text_here,
                style: theme.textTheme.labelLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => P.translator.textEditingController.clear(),
                tooltip: s.clear_text,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: P.translator.textEditingController,
            decoration: InputDecoration.collapsed(
              hintText: s.enter_text_to_translate,
            ),
            minLines: 4,
            maxLines: 8,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _Result extends ConsumerStatefulWidget {
  const _Result();

  @override
  ConsumerState<_Result> createState() => _ResultState();
}

class _ResultState extends ConsumerState<_Result> {
  late final ScrollController _scrollController;
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _listener = () {
      if (_scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    };

    P.translator.resultTextEditingController.addListener(_listener);
  }

  @override
  void dispose() {
    P.translator.resultTextEditingController.removeListener(_listener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final enToZh = ref.watch(P.translator.enToZh);

    return Container(
      width: double.infinity,
      padding: const .fromLTRB(16, 8, 16, 16),
      color: theme.colorScheme.surfaceContainerHighest.q(0.3),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Text(
                enToZh ? s.chinese_translation_result : s.english_translation_result,
                style: theme.textTheme.labelLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_all_outlined, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: P.translator.resultTextEditingController.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.chat_copied_to_clipboard)),
                  );
                },
                tooltip: s.copy_text,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: P.translator.resultTextEditingController,
            scrollController: _scrollController,
            decoration: const InputDecoration.collapsed(hintText: ""),
            readOnly: true,
            minLines: 4,
            maxLines: 8,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _InferenceInfo extends ConsumerWidget {
  const _InferenceInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final isGenerating = ref.watch(P.translator.isGenerating);
    final currentModel = ref.watch(P.rwkv.latestModel);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.q(0.3),
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: Padding(
        padding: const .all(8.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const .symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                s.inference_engine,
                style: theme.textTheme.titleMedium,
              ),
            ),
            ListTile(
              title: Text(s.model),
              subtitle: Text(currentModel?.name ?? s.no_model_selected),
              trailing: FilledButton.tonal(
                onPressed: () => ModelSelector.show(),
                child: Text(s.change),
              ),
            ),
            ListTile(
              title: Text(s.status),
              subtitle: Text(isGenerating ? s.translating : s.idle),
              trailing: isGenerating
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceInfo extends ConsumerWidget {
  const _ServiceInfo();

  Future<void> _onPressed() async {
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
        final currentModel = P.rwkv.latestModel.q;
        if (currentModel == null) {
          ModelSelector.show();
          return;
        }
        await P.backend.start();
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final backendState = ref.watch(P.backend.httpState);
    final websocketState = ref.watch(P.backend.websocketState);
    final httpPort = ref.watch(P.backend.httpPort);
    final websocketPort = ref.watch(P.backend.websocketPort);

    final buttonText = switch (backendState) {
      BackendState.starting => s.starting,
      BackendState.running => s.stop_service,
      BackendState.stopping => s.stopping,
      BackendState.stopped => s.start_service,
    };
    final canPress = backendState == BackendState.running || backendState == BackendState.stopped;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.q(0.3),
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: Padding(
        padding: const .all(8.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const .symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(s.lan_server, style: theme.textTheme.titleMedium),
            ),
            ListTile(
              title: Text(s.http_service_port(httpPort)),
              subtitle: Text(backendState.name),
              trailing: backendState == BackendState.running
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.cancel_outlined, color: Colors.red),
            ),
            ListTile(
              title: Text(s.websocket_service_port(websocketPort)),
              subtitle: Text(websocketState.name),
              trailing: websocketState == BackendState.running
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.cancel_outlined, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Center(
              child: FilledButton.tonal(
                onPressed: canPress ? _onPressed : null,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowserInfo extends ConsumerWidget {
  const _BrowserInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final browserWindows = ref.watch(P.translator.browserWindows);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.q(0.3),
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: Padding(
        padding: const .all(8.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const .symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(s.browser_status, style: theme.textTheme.titleMedium),
            ),
            if (browserWindows.isEmpty)
              ListTile(
                title: Text(s.no_browser_windows_connected),
                subtitle: Text(s.start_service_and_open_browser),
              )
            else
              ...browserWindows.map((e) => _BrowserWindow(window: e)),
          ],
        ),
      ),
    );
  }
}

class _BrowserWindow extends ConsumerWidget {
  const _BrowserWindow({required this.window});

  final BrowserWindow window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final browserTabs = ref.watch(P.translator.browserTabs.select((v) => v.where((e) => e.windowId == window.id).toList()));
    final focused = window.focused;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(8),
        side: BorderSide(
          color: focused ? theme.colorScheme.primary : theme.colorScheme.outline.q(0.5),
          width: focused ? 2 : 1,
        ),
      ),
      margin: const .symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(s.window_id(window.id), style: TextStyle(fontWeight: focused ? .bold : .normal)),
        subtitle: Text(s.x_tabs(browserTabs.length)),
        initiallyExpanded: focused,
        children: browserTabs.map((e) => _BrowserTab(tab: e)).toList(),
      ),
    );
  }
}

class _BrowserTab extends ConsumerWidget {
  const _BrowserTab({required this.tab});

  final BrowserTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final pool = ref.watch(P.translator.pool(tab));
    final isActive = ref.watch(P.translator.activedTab.select((v) => v?.id == tab.id));
    final runningTaskTabId = ref.watch(P.translator.runningTaskTabId);
    final isThisTabRunningTask = runningTaskTabId == tab.id;

    return ListTile(
      leading: isActive ? Icon(Icons.gps_fixed, color: theme.colorScheme.primary) : const Icon(Icons.tab_unselected),
      title: Text(tab.title, maxLines: 1, overflow: .ellipsis),
      subtitle: Text(tab.url, maxLines: 1, overflow: .ellipsis),
      trailing: isThisTabRunningTask
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : (pool.isNotEmpty ? Text(s.queued_x(pool.length)) : null),
      tileColor: isActive ? theme.colorScheme.primaryContainer.q(0.4) : null,
    );
  }
}

class _TranslatorDebugInfo extends ConsumerWidget {
  const _TranslatorDebugInfo();

  Future<void> _onPressClearCompleterPool() async {
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
    final theme = Theme.of(context);
    final s = S.of(context);
    final runningTaskKey = ref.watch(P.translator.runningTaskKey);
    final translations = ref.watch(P.translator.translations);
    final runningTaskUrl = ref.watch(P.translator.runningTaskUrl);
    final runningTaskTabId = ref.watch(P.translator.runningTaskTabId);
    final translationCountInSandbox = ref.watch(P.translator.translationCountInSandbox);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.q(0.3),
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: Padding(
        padding: const .all(8.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const .symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(s.translator_debug_info, style: theme.textTheme.titleMedium),
            ),
            ListTile(
              title: Text(s.cached_translations_memory),
              subtitle: Text("${translations.length}"),
            ),
            ListTile(
              title: Text(s.cached_translations_disk),
              subtitle: Text("$translationCountInSandbox"),
            ),
            ListTile(
              title: Text(s.current_task_text_length),
              subtitle: Text("${runningTaskKey?.length ?? 0}"),
            ),
            ListTile(
              title: Text(s.current_task_url),
              subtitle: Text("$runningTaskUrl"),
            ),
            ListTile(
              title: Text(s.current_task_tab_id),
              subtitle: Text("$runningTaskTabId"),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _onPressClearCompleterPool,
                icon: const Icon(Icons.delete_sweep),
                label: Text(s.clear_memory_cache),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslationDirectionButton extends ConsumerWidget {
  const _TranslationDirectionButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enToZh = ref.watch(P.translator.enToZh);
    final batchEnabled = ref.watch(P.translator.batchEnabled);
    final sourceText = ref.watch(P.translator.source);
    final isMulti = sourceText.trim().split('\n').where((e) => e.trim().isNotEmpty).length > 1;

    return Container(
      padding: const .symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Row(
          mainAxisSize: .min,
          children: [
            GestureDetector(
              onTap: P.translator.onDirectionButtonPressed,
              child: Container(
                padding: const .symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.q(0.3),
                  borderRadius: .circular(20),
                  border: .all(
                    color: theme.colorScheme.primary.q(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    Text(
                      enToZh ? 'EN' : 'ZH',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: .bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      enToZh ? 'ZH' : 'EN',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: .bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text('Batch', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: batchEnabled,
              onChanged: isMulti ? (v) => P.translator.onBatchToggle(v) : null,
            ),
          ],
        ),
      ),
    );
  }
}
