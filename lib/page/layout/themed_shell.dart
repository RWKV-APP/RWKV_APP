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

class ThemedAppShell extends ConsumerWidget {
  const ThemedAppShell({super.key, required this.presentation, required this.style, required this.child});

  final AppPresentation presentation;
  final AppStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final palette = ref.watch(P.app.theme);
    final selected = ref.watch(P.app.tabIndex);
    final placement = presentation.navigation;
    final destinations = [
      (label: s.home, icon: Icons.home_outlined, active: Icons.home),
      (label: s.conversations, icon: Icons.chat_bubble_outline, active: Icons.chat_bubble),
      (label: s.settings, icon: Icons.settings_outlined, active: Icons.settings),
    ];

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final side = wide && (placement == .editorial || placement == .rail);
          final top = placement == .topTabs || placement == .commandBar || (placement == .editorial && !side);
          final floating = placement == .dock || placement == .segmented;
          final corners = BorderRadius.circular(placement == .dock ? 32 : style.radius);

          Widget destination(int index) {
            final item = destinations[index];
            final active = index == selected;
            final foreground = active ? palette.primary : palette.qb3;
            return Semantics(
              selected: active,
              child: TextButton(
                onPressed: () => P.app.onTabSelected(index),
                style: TextButton.styleFrom(
                  foregroundColor: foreground,
                  backgroundColor: active ? palette.userMsgBg : Colors.transparent,
                  minimumSize: const Size(0, 46),
                  padding: .symmetric(horizontal: side ? 12 : 4, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: corners),
                ),
                child: side || wide
                    ? Row(
                        mainAxisAlignment: side ? .start : .center,
                        children: [
                          Icon(active ? item.active : item.icon, size: 18),
                          const SizedBox(width: 8),
                          Flexible(child: Text(item.label, textAlign: .center)),
                        ],
                      )
                    : Column(
                        mainAxisSize: .min,
                        children: [
                          Icon(active ? item.active : item.icon, size: 18),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: .scaleDown,
                            child: Text(item.label, maxLines: 1),
                          ),
                        ],
                      ),
              ),
            );
          }

          final brand = Row(
            mainAxisSize: .min,
            children: [
              ClipRRect(
                borderRadius: .circular(5),
                child: Image.asset('assets/img/chat/icon.png', width: 24, height: 24),
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(Config.appTitle, style: Theme.of(context).textTheme.titleMedium)),
            ],
          );

          if (side) {
            return Row(
              children: [
                Container(
                  width: placement == .editorial ? 182 : 198,
                  color: palette.settingBg,
                  child: ListView(
                    padding: .fromLTRB(12, 20, 12, 16),
                    children: [
                      Padding(padding: const .fromLTRB(8, 0, 0, 20), child: brand),
                      for (var index = 0; index < destinations.length; index++) ...[
                        destination(index),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
                Container(width: 1, color: palette.qb0.withValues(alpha: .12)),
                Expanded(child: child),
              ],
            );
          }

          final strip = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: floating ? 440 : (top ? 1180 : 620)),
              child: Padding(
                padding: floating ? const .fromLTRB(10, 4, 10, 8) : const .all(5),
                child: DecoratedBox(
                  decoration: floating ? style.box(palette, corners) : const BoxDecoration(),
                  child: Row(
                    children: [
                      if (top && wide) ...[
                        Padding(padding: const .symmetric(horizontal: 14), child: brand),
                        const Spacer(),
                      ],
                      for (var index = 0; index < destinations.length; index++) Expanded(child: destination(index)),
                    ],
                  ),
                ),
              ),
            ),
          );
          final navigation = DecoratedBox(
            decoration: BoxDecoration(
              color: palette.settingBg,
              border: floating
                  ? null
                  : Border(
                      bottom: top ? BorderSide(color: palette.qb12) : BorderSide.none,
                      top: top ? BorderSide.none : BorderSide(color: palette.qb12),
                    ),
            ),
            child: strip,
          );
          return Column(
            children: [
              if (top) navigation,
              Expanded(child: child),
              if (!top) navigation,
            ],
          );
        },
      ),
    );
  }
}
