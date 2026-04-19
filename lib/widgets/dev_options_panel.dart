// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/albatross.dart';
import 'package:zone/store/p.dart';

class DevOptionsPanel extends ConsumerStatefulWidget {
  static const String _panelKey = 'DevOptionsPanel';
  final ScrollController scrollController;

  const DevOptionsPanel({super.key, required this.scrollController});

  static Future<void> show() async {
    await P.ui.showPanel(
      key: _panelKey,
      isDismissible: false,
      initialChildSize: .8,
      maxChildSize: .92,
      expand: false,
      snap: true,
      builder: (ScrollController scrollController) => DevOptionsPanel(scrollController: scrollController),
    );
  }

  static Widget trigger({required Widget child}) => _DevOptionsTrigger(child: child);

  @override
  ConsumerState<DevOptionsPanel> createState() => _DevOptionsPanelState();
}

class _DevOptionsTrigger extends StatefulWidget {
  final Widget child;

  const _DevOptionsTrigger({required this.child});

  @override
  State<_DevOptionsTrigger> createState() => _DevOptionsTriggerState();
}

class _DevOptionsTriggerState extends State<_DevOptionsTrigger> {
  int _count = 0;
  int _firstTap = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_count == 0) {
          _firstTap = DateTime.now().millisecondsSinceEpoch;
        }
        _count++;
        if (_count < 6) return;
        final span = DateTime.now().millisecondsSinceEpoch - _firstTap;
        _count = 0;
        if (span >= 1300) return;
        await DevOptionsPanel.show();
      },
      child: widget.child,
    );
  }
}

class _DevOptionsPanelState extends ConsumerState<DevOptionsPanel> {
  final TextEditingController _controllerHost = TextEditingController(text: Albatross.instance.host);

  @override
  void dispose() {
    final host = _controllerHost.text;
    if (host != Albatross.instance.host) {
      Albatross.instance.host = host;
      Albatross.instance.init();
    }
    _controllerHost.dispose();
    super.dispose();
  }

  void _onWebSearchChanged(bool value) {
    final next = P.app.featureRollout.q.copyWith(webSearch: value);
    P.preference.setFeatureRollout(next);
    P.app.featureRollout.q = next;
    setState(() {});
  }

  void _onParallelAnsweringChanged(bool value) {
    final next = P.app.featureRollout.q.copyWith(parallelAnswering: value);
    P.preference.setFeatureRollout(next);
    P.app.featureRollout.q = next;
    setState(() {});
  }

  void _onAlbatrossChanged(bool value) {
    P.rwkv.enableAlbatross.q = value;
    setState(() {});
  }

  void _onTelemetryChanged(bool value) {
    P.telemetry.setEnabled(value);
    setState(() {});
  }

  void _onRenderMarkdownAndLatexChanged(bool value) {
    P.preference.setRenderMarkdownAndLatexEnabled(value);
    setState(() {});
  }

  void _onUseBatchListViewBuilderChanged(bool value) {
    P.preference.setUseBatchListViewBuilderEnabled(value);
    setState(() {});
  }

  void _onOpenTest2Pressed() async {
    await pop();
    await push(PageKey.test2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final featureRollout = P.app.featureRollout.q;
    final panelColor = theme.colorScheme.surface;
    final cardColor = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.colorScheme.outlineVariant;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final fakeBatchInferenceBenchmarkEnabled = ref.watch(P.chat.fakeBatchInferenceBenchmarkEnabled);
    final renderMarkdownAndLatexEnabled = ref.watch(P.preference.renderMarkdownAndLatexEnabled);
    final useBatchListViewBuilderEnabled = ref.watch(P.preference.useBatchListViewBuilderEnabled);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Material(
        color: panelColor,
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            _DevPanelHeader(borderColor: borderColor),
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const .only(left: 16, top: 14, right: 16, bottom: 16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: .circular(14),
                      border: .all(color: borderColor, width: .5),
                    ),
                    child: Column(
                      children: [
                        _DevSwitchItem(
                          title: 'Web Search',
                          subtitle: 'Enable experimental web search.',
                          value: featureRollout.webSearch,
                          onChanged: _onWebSearchChanged,
                        ),
                        Container(height: .5, color: borderColor),
                        _DevSwitchItem(
                          title: 'Parallel Answering',
                          subtitle: 'Show parallel answering buttons in batch and ask-question panels.',
                          value: featureRollout.parallelAnswering,
                          onChanged: _onParallelAnsweringChanged,
                        ),
                        Container(height: .5, color: borderColor),
                        _DevSwitchItem(
                          title: S.current.fake_batch_inference_benchmark,
                          subtitle: 'Replace real chat inference with random UI-only streaming output.',
                          value: fakeBatchInferenceBenchmarkEnabled,
                          onChanged: P.chat.onFakeBatchInferenceBenchmarkChanged,
                        ),
                        Container(height: .5, color: borderColor),
                        _DevSwitchItem(
                          title: 'Markdown + LaTeX',
                          subtitle: 'Disable to render assistant output as plain text only.',
                          value: renderMarkdownAndLatexEnabled,
                          onChanged: _onRenderMarkdownAndLatexChanged,
                        ),
                        Container(height: .5, color: borderColor),
                        _DevSwitchItem(
                          title: 'Batch ListView.builder',
                          subtitle: 'On: lazy-render batch slots with ListView.builder. Off: render all slots statically.',
                          value: useBatchListViewBuilderEnabled,
                          onChanged: _onUseBatchListViewBuilderChanged,
                        ),
                        Container(height: .5, color: borderColor),
                        _DevSwitchItem(
                          title: 'Albatross',
                          subtitle: 'Use Albatross bridge in RWKV runtime.',
                          value: P.rwkv.enableAlbatross.q,
                          onChanged: _onAlbatrossChanged,
                        ),
                        Container(height: .5, color: borderColor),
                        _DevSwitchItem(
                          title: 'Telemetry',
                          subtitle: 'Upload anonymous inference speed after each reply.',
                          value: P.telemetry.enabled.q,
                          onChanged: _onTelemetryChanged,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DevHostCard(
                    controller: _controllerHost,
                    cardColor: cardColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 12),
                  _DevActionCard(
                    cardColor: cardColor,
                    borderColor: borderColor,
                    title: 'Test2 Page',
                    subtitle: 'Open test_2.dart with router push.',
                    actionText: 'Open',
                    onTap: _onOpenTest2Pressed,
                  ),
                ],
              ),
            ),
            _DevApplyButton(bottomPadding: bottomPadding, borderColor: borderColor),
          ],
        ),
      ),
    );
  }
}

class _DevPanelHeader extends StatelessWidget {
  final Color borderColor;

  const _DevPanelHeader({required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const .only(left: 16, top: 8, right: 8, bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: .5),
        ),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: .circular(100),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dev Options',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: .w700),
                ),
              ),
              const CloseButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class _DevApplyButton extends StatelessWidget {
  final double bottomPadding;
  final Color borderColor;

  const _DevApplyButton({required this.bottomPadding, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final backgroundColor = dark ? Colors.white : Colors.black;
    final foregroundColor = dark ? Colors.black : Colors.white;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor, width: .5)),
      ),
      padding: EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12 + bottomPadding),
      child: FilledButton(
        onPressed: pop,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: .circular(12)),
        ),
        child: Text(
          'Apply all changes',
          style: theme.textTheme.labelLarge?.copyWith(
            color: foregroundColor,
            fontWeight: .w600,
          ),
        ),
      ),
    );
  }
}

class _DevSwitchItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DevSwitchItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const .symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: .w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DevHostCard extends StatelessWidget {
  final TextEditingController controller;
  final Color cardColor;
  final Color borderColor;

  const _DevHostCard({
    required this.controller,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: .circular(14),
        border: .all(color: borderColor, width: .5),
      ),
      padding: const .all(12),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            'Albatross Host',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: .w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Custom endpoint for Albatross bridge.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: theme.colorScheme.surface,
              hintText: 'http://127.0.0.1:8080',
              contentPadding: const .symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: .circular(10),
                borderSide: BorderSide(color: borderColor, width: .5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: .circular(10),
                borderSide: BorderSide(color: borderColor, width: .5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: .circular(10),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevActionCard extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onTap;

  const _DevActionCard({
    required this.cardColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: .circular(14),
        border: .all(color: borderColor, width: .5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: .circular(14),
          onTap: onTap,
          child: Padding(
            padding: const .symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: .w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const .symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: .circular(999),
                  ),
                  child: Text(
                    actionText,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: .w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
