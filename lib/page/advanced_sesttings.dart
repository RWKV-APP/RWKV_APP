// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/settings/chat_template_dialog.dart';

class PageAdvancedSettings extends ConsumerStatefulWidget {
  const PageAdvancedSettings({super.key});

  @override
  ConsumerState<PageAdvancedSettings> createState() => _PageAdvancedSettingsState();
}

class _PageAdvancedSettingsState extends ConsumerState<PageAdvancedSettings> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classic = ref.watch(P.preference.appStyle).isClassic;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(S.current.advance_settings),
      ),
      body: SingleChildScrollView(
        padding: classic ? null : const .all(12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            buildGroupTitle(S.current.prompt_template, theme),
            item(
              title: S.current.system_prompt,
              child: const SizedBox(
                height: 56,
                width: 18,
                child: Icon(Icons.arrow_forward_ios, size: 18),
              ),
              onTap: () {
                ChatTemplateDialog.show(context, systemPrompt: true);
              },
            ),
            const SizedBox(height: 8),
            item(
              title: S.current.thinking_mode_template,
              child: const SizedBox(
                height: 56,
                width: 18,
                child: Icon(Icons.arrow_forward_ios, size: 18),
              ),
              onTap: () {
                ChatTemplateDialog.show(context, thinking: true);
              },
            ),
            const SizedBox(height: 8),
            item(
              title: S.current.new_chat_template,
              child: const SizedBox(
                height: 56,
                width: 18,
                child: Icon(Icons.arrow_forward_ios, size: 18),
              ),
              onTap: () {
                ChatTemplateDialog.show(context, newChat: true);
              },
            ),
            const SizedBox(height: 16),
            ...buildAppBehaviorGroup(theme),
            const SizedBox(height: 16),
            // ...buildRagGroup(),
          ],
        ),
      ),
    );
  }

  List<Widget> buildAppBehaviorGroup(ThemeData theme) {
    return [
      buildGroupTitle(S.current.other_settings, theme),
      item(
        title: S.current.enable_system_proxy,
        child: Switch(
          value: P.preference.enableSystemProxy,
          onChanged: (v) async {
            await P.preference.setEnableSystemProxy(v);
            P.remote.initDownloader();
            setState(() {});
          },
        ),
      ),
    ];
  }

  Widget item({required String title, required Widget child, VoidCallback? onTap}) {
    final style = ref.watch(P.preference.appStyle);
    final row = InkWell(
      onTap: onTap,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          child,
          const SizedBox(width: 16),
        ],
      ),
    );
    if (style.isClassic) return row;
    final palette = ref.watch(P.app.theme);
    final corners = BorderRadius.circular(style.radius);
    return Material(
      color: palette.settingItem,
      borderRadius: corners,
      clipBehavior: .antiAlias,
      child: row,
    );
  }

  Widget buildGroupTitle(String title, ThemeData theme) {
    if (!ref.watch(P.preference.appStyle).isClassic) {
      return Padding(
        padding: const .fromLTRB(4, 4, 4, 10),
        child: Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium)),
      );
    }
    final surface = theme.colorScheme.surface;
    return Container(
      margin: const .only(bottom: 16),
      padding: const .symmetric(horizontal: 16, vertical: 12),
      color: surface,
      child: Text(title),
    );
  }

  List<Widget> buildRagGroup() {
    return [
      Container(
        margin: const .only(bottom: 16),
        padding: const .symmetric(horizontal: 16, vertical: 12),
        color: Colors.grey.shade100,
        child: const Text('知识库'),
      ),
      item(
        title: "知识库搜索结果数量",
        child: const DropdownMenu(
          initialSelection: 10,
          dropdownMenuEntries: [
            DropdownMenuEntry(value: 3, label: '3'),
            DropdownMenuEntry(value: 5, label: '5'),
            DropdownMenuEntry(value: 10, label: '10'),
            DropdownMenuEntry(value: 20, label: '20'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      item(
        title: "文本切割长度范围",
        child: const DropdownMenu(
          initialSelection: 0,
          enableFilter: false,
          dropdownMenuEntries: [
            DropdownMenuEntry(value: 0, label: '30-100'),
            DropdownMenuEntry(value: 1, label: '30-150'),
            DropdownMenuEntry(value: 2, label: '50-150'),
            DropdownMenuEntry(value: 3, label: '100-200'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      item(
        title: "切割字符",
        child: const Row(
          children: [
            Text('，。？！\\n'),
            SizedBox(width: 12, height: 56),
            Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    ];
  }
}
