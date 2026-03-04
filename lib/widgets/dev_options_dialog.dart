// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/model/feature_rollout.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/albatross.dart';
import 'package:zone/store/p.dart';

class WithDevOption extends StatefulWidget {
  final Widget child;

  const WithDevOption({super.key, required this.child});

  @override
  State<WithDevOption> createState() => _WithDevOptionState();
}

class _WithDevOptionState extends State<WithDevOption> {
  int count = 0;
  int firstTap = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (count == 0) {
          firstTap = DateTime.now().millisecondsSinceEpoch;
        }
        count++;
        if (count < 6) return;
        final int span = DateTime.now().millisecondsSinceEpoch - firstTap;
        count = 0;
        if (span >= 1300) return;
        await _DevOptionsDialog.show();
      },
      child: widget.child,
    );
  }
}

class _DevOptionsDialog extends StatefulWidget {
  static const String panelKey = 'DevOptionsDialog';
  final ScrollController scrollController;

  const _DevOptionsDialog({required this.scrollController});

  static Future<void> show() async {
    await P.ui.showPanel(
      key: panelKey,
      isDismissible: false,
      initialChildSize: .8,
      maxChildSize: .92,
      expand: false,
      snap: true,
      builder: (ScrollController scrollController) => _DevOptionsDialog(scrollController: scrollController),
    );
  }

  @override
  State<_DevOptionsDialog> createState() => _DevOptionsDialogState();
}

class _DevOptionsDialogState extends State<_DevOptionsDialog> {
  final TextEditingController _controllerHost = TextEditingController(text: Albatross.instance.host);

  @override
  void dispose() {
    final String host = _controllerHost.text;
    if (host != Albatross.instance.host) {
      Albatross.instance.host = host;
      Albatross.instance.init();
    }
    _controllerHost.dispose();
    super.dispose();
  }

  void _onWebSearchChanged(bool value) {
    final FeatureRollout nextFeatureRollout = P.app.featureRollout.q.copyWith(webSearch: value);
    P.preference.setFeatureRollout(nextFeatureRollout);
    P.app.featureRollout.q = nextFeatureRollout;
    setState(() {});
  }

  void _onAlbatrossChanged(bool value) {
    P.rwkv.enableAlbatross.q = value;
    setState(() {});
  }

  void _onOpenTest2Pressed() async {
    await pop();
    await push(PageKey.test2);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final FeatureRollout featureRollout = P.app.featureRollout.q;
    final Color panelColor = theme.colorScheme.surface;
    final Color cardColor = theme.colorScheme.surfaceContainerHighest;
    final Color borderColor = theme.colorScheme.outlineVariant;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

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
                padding: .only(
                  left: 16,
                  top: 14,
                  right: 16,
                  bottom: 16 + bottomPadding,
                ),
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
                          title: 'Albatross',
                          subtitle: 'Use Albatross bridge in RWKV runtime.',
                          value: P.rwkv.enableAlbatross.q,
                          onChanged: _onAlbatrossChanged,
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
    final ThemeData theme = Theme.of(context);

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
    final ThemeData theme = Theme.of(context);

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
    final ThemeData theme = Theme.of(context);

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
    final ThemeData theme = Theme.of(context);

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
