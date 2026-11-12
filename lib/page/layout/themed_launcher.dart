// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/app_presentation.dart';
import 'package:zone/model/app_style.dart';
import 'package:zone/store/p.dart';

class ThemedLauncher extends ConsumerWidget {
  const ThemedLauncher({
    super.key,
    required this.presentation,
    required this.style,
    required this.chat,
    required this.features,
    required this.utilities,
  });

  final AppPresentation presentation;
  final AppStyle style;
  final Widget chat;
  final List<Widget> features;
  final List<Widget> utilities;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final palette = ref.watch(P.app.theme);
    final version = ref.watch(P.app.version);
    final arrangement = presentation.launcher;
    final compact = arrangement == .directory || arrangement == .console;
    final centered = arrangement == .focus || arrangement == .device;
    final solid = arrangement == .studio || arrangement == .workshop;
    final gap = compact ? 12.0 : 20.0;
    final accent = solid ? theme.colorScheme.onPrimary : palette.primary;
    final ink = solid ? theme.colorScheme.onPrimary : palette.qb1;

    final mark = ClipRRect(
      borderRadius: .circular(style.radius.clamp(0, 14)),
      child: Image.asset('assets/img/chat/icon.png', width: compact ? 36 : 54, height: compact ? 36 : 54),
    );
    final title = Text(
      compact ? s.home : Config.appTitle,
      style: theme.textTheme.headlineLarge?.copyWith(
        fontSize: compact ? 26 : style.headingSize,
        color: ink,
        height: 1.12,
      ),
      textAlign: centered ? .center : .start,
    );
    final identity = Text(
      [if (compact) Config.appTitle, style.displayName(s), if (version.isNotEmpty) version].join(' · '),
      style: theme.textTheme.labelMedium?.copyWith(color: solid ? ink : palette.qb6, letterSpacing: .2),
      textAlign: centered ? .center : .start,
    );
    final headingText = Column(
      mainAxisSize: .min,
      crossAxisAlignment: centered ? .center : .start,
      children: [title, const SizedBox(height: 6), identity],
    );
    final heading = Container(
      padding: solid || centered ? const .all(18) : const .symmetric(vertical: 10),
      decoration: solid
          ? style.box(palette, .circular(style.radius), fill: palette.primary)
          : arrangement == .device
          ? style.box(palette, .circular(style.radius))
          : null,
      child: switch (arrangement) {
        .dashboard || .console || .directory || .workshop => Row(
          children: [
            mark,
            const SizedBox(width: 14),
            Expanded(child: headingText),
          ],
        ),
        _ => Column(
          crossAxisAlignment: centered ? .center : .start,
          children: [
            mark,
            const SizedBox(height: 14),
            headingText,
            if (arrangement == .editorial) ...[
              const SizedBox(height: 16),
              SizedBox(width: 64, height: 2, child: ColoredBox(color: accent)),
            ],
          ],
        ),
      },
    );

    Widget group(String title, List<Widget> children, {required int columns, bool panel = false}) {
      return _LauncherGroup(title: title, items: children, columns: columns, gap: style.gap, panel: panel, style: style);
    }

    final featureGrid = group(s.workspace_create, features, columns: 3);
    final featureList = group(s.workspace_create, features, columns: 1);
    final utilityList = group(s.workspace_tools, utilities, columns: 1);
    final utilityGrid = group(s.workspace_tools, utilities, columns: 3);
    final pairedTools = group(s.workspace_tools, utilities, columns: 1, panel: true);
    Widget stack(List<Widget> children) => _LauncherStack(gap: gap, children: children);

    final body = switch (arrangement) {
      .editorial => _LauncherSplit(
        gap: gap,
        primary: stack([heading, chat]),
        secondary: stack([featureList, utilityList]),
        asideWidth: 430,
        featureFirst: false,
      ),
      .dashboard => stack([heading, chat, _LauncherSplit(gap: gap, primary: featureGrid, secondary: pairedTools)]),
      .studio => stack([heading, chat, featureGrid, utilityGrid]),
      .ledger => stack([heading, chat, _LauncherSplit(gap: gap, primary: featureList, secondary: utilityList)]),
      .focus => stack([
        heading,
        Align(
          alignment: .center,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: chat),
        ),
        group(s.workspace_create, features, columns: 2),
        utilityGrid,
      ]),
      .workshop => stack([
        heading,
        _LauncherSplit(gap: gap, primary: stack([chat, featureGrid]), secondary: pairedTools),
      ]),
      .console => stack([
        heading,
        group(s.workspace_create, [chat, ...features], columns: 1, panel: true),
        utilityList,
      ]),
      .directory => stack([heading, chat, featureList, utilityList]),
      .device => stack([heading, chat, group(s.workspace_create, features, columns: 2, panel: true), utilityGrid]),
    };

    return Scaffold(
      backgroundColor: palette.settingBg,
      body: SingleChildScrollView(
        controller: P.ui.homeController,
        padding: .fromLTRB(gap, gap, gap, gap + 12),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: switch (arrangement) {
                .focus => 760,
                .console || .directory => 900,
                _ => 1280,
              },
            ),
            child: body,
          ),
        ),
      ),
    );
  }
}

class _LauncherStack extends StatelessWidget {
  const _LauncherStack({required this.gap, required this.children});

  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i != 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    );
  }
}

class _LauncherSplit extends StatelessWidget {
  const _LauncherSplit({
    required this.gap,
    required this.primary,
    required this.secondary,
    this.asideWidth = 260,
    this.featureFirst = true,
  });

  final double gap;
  final Widget primary;
  final Widget secondary;
  final double asideWidth;
  final bool featureFirst;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) return _LauncherStack(gap: gap, children: [primary, secondary]);
        return Row(
          crossAxisAlignment: .start,
          children: [
            if (featureFirst) Expanded(child: primary) else SizedBox(width: asideWidth, child: primary),
            SizedBox(width: gap),
            if (featureFirst) SizedBox(width: asideWidth, child: secondary) else Expanded(child: secondary),
          ],
        );
      },
    );
  }
}

class _LauncherGroup extends ConsumerWidget {
  const _LauncherGroup({
    required this.title,
    required this.items,
    required this.columns,
    required this.gap,
    required this.panel,
    required this.style,
  });

  final String title;
  final List<Widget> items;
  final int columns;
  final double gap;
  final bool panel;
  final AppStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = ref.watch(P.app.theme);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Container(
      padding: panel ? const .all(12) : .zero,
      decoration: panel ? style.box(palette, .circular(style.radius)) : null,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium)),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = ((constraints.maxWidth + gap) / (142 * scale.clamp(1, 1.7) + gap)).floor().clamp(1, columns);
              if (count == 1) {
                return Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    for (int index = 0; index < items.length; index++) ...[
                      if (index > 0) SizedBox(height: gap),
                      items[index],
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (int start = 0; start < items.length; start += count) ...[
                    if (start > 0) SizedBox(height: gap),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: .stretch,
                        children: [
                          for (int column = 0; column < count; column++) ...[
                            if (column > 0) SizedBox(width: gap),
                            Expanded(child: start + column < items.length ? items[start + column] : const SizedBox.shrink()),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
