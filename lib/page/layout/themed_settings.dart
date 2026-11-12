// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:zone/model/app_presentation.dart';
import 'package:zone/model/app_style.dart';
import 'package:zone/model/app_theme.dart';

typedef SettingsSection = ({String title, List<Widget> items});

class ThemedSettings extends StatefulWidget {
  const ThemedSettings({
    super.key,
    required this.style,
    required this.palette,
    required this.arrangement,
    required this.identity,
    required this.appearance,
    required this.sections,
    this.scrollController,
  });

  final AppStyle style;
  final AppTheme palette;
  final SettingsArrangement arrangement;
  final Widget identity;
  final SettingsSection appearance;
  final List<SettingsSection> sections;
  final ScrollController? scrollController;

  @override
  State<ThemedSettings> createState() => _ThemedSettingsState();
}

class _ThemedSettingsState extends State<ThemedSettings> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final gap = widget.style.gap;
    final arrangement = widget.arrangement;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 740;
        final directory = arrangement == .directory;

        Widget section(SettingsSection section) => _SettingsGroup(section: section, style: widget.style, palette: widget.palette);

        List<Widget> sectionButtons() => [
          for (var index = 0; index < widget.sections.length; index++)
            ChoiceChip(
              selected: _section == index,
              label: Text(widget.sections[index].title),
              onSelected: (_) => setState(() => _section = index),
            ),
        ];

        Widget list(List<Widget> items) {
          return ListView(
            controller: widget.scrollController,
            padding: .fromLTRB(gap + 4, gap + 4, gap + 4, gap + 16),
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index != 0) SizedBox(height: gap + 8),
                items[index],
              ],
            ],
          );
        }

        if (directory && wide && widget.scrollController == null) {
          return Row(
            crossAxisAlignment: .start,
            children: [
              SizedBox(
                width: 254,
                child: SingleChildScrollView(
                  padding: .all(gap + 4),
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      widget.identity,
                      SizedBox(height: gap),
                      for (var index = 0; index < widget.sections.length; index++)
                        Semantics(
                          selected: _section == index,
                          child: TextButton(
                            onPressed: () => setState(() => _section = index),
                            style: TextButton.styleFrom(
                              alignment: .centerLeft,
                              minimumSize: const Size(0, 44),
                              backgroundColor: _section == index ? widget.palette.userMsgBg : null,
                            ),
                            child: Text(widget.sections[index].title),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(child: list([section(widget.appearance), section(widget.sections[_section])])),
            ],
          );
        }
        if (directory) {
          return list([
            widget.identity,
            section(widget.appearance),
            Wrap(spacing: 6, runSpacing: 6, children: sectionButtons()),
            section(widget.sections[_section]),
          ]);
        }
        if (arrangement == .dashboard && wide) {
          final sections = widget.sections.map(section).toList();
          return list([
            widget.identity,
            section(widget.appearance),
            for (var index = 0; index < sections.length; index += 2)
              Row(
                crossAxisAlignment: .start,
                children: [
                  Expanded(child: sections[index]),
                  SizedBox(width: gap),
                  Expanded(child: index + 1 < sections.length ? sections[index + 1] : const SizedBox.shrink()),
                ],
              ),
          ]);
        }
        return list([widget.identity, section(widget.appearance), ...widget.sections.map(section)]);
      },
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.section, required this.style, required this.palette});

  final SettingsSection section;
  final AppStyle style;
  final AppTheme palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corners = BorderRadius.circular(style.radius);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Semantics(header: true, child: Text(section.title, style: theme.textTheme.titleLarge)),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: style.box(palette, corners),
          child: ClipRRect(
            borderRadius: corners,
            child: Column(crossAxisAlignment: .stretch, children: section.items),
          ),
        ),
      ],
    );
  }
}
