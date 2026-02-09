import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/store/p.dart';

class PageTab extends ConsumerWidget {
  final Widget child;

  const PageTab({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final useBottomNavigationBar = screenWidth <= 600;
    final tabIndex = ref.watch(P.app.tabIndex);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final paddingBottom = ref.watch(P.app.paddingBottom);
    final qb = ref.watch(P.app.qb);

    final verticalLayout = Stack(
      children: <Widget>[
        child,
        Positioned(
          bottom: paddingBottom + 12,
          left: appTheme.tabBarLeftPadding,
          right: appTheme.tabBarRightPadding,
          height: appTheme.tabBarHeight,
          child: ClipRRect(
            borderRadius: .circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: appTheme.scaffoldBg.q(.5),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: paddingBottom + 12,
          left: appTheme.tabBarLeftPadding,
          right: appTheme.tabBarRightPadding,
          height: appTheme.tabBarHeight,
          child: Container(
            decoration: BoxDecoration(
              color: appTheme.scaffoldBg.q(.4),
              borderRadius: .circular(100),
              border: Border.all(color: qb.q(.2), width: .5),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: _TabItem(
                    labelKey: _TabLabelKey.home,
                    icon: FontAwesomeIcons.house,
                    selectedIcon: FontAwesomeIcons.solidHouse,
                    index: 0,
                  ),
                ),
                const Expanded(
                  child: _TabItem(
                    labelKey: _TabLabelKey.conversations,
                    icon: FontAwesomeIcons.message,
                    selectedIcon: FontAwesomeIcons.solidMessage,
                    index: 1,
                  ),
                ),
                const Expanded(
                  child: _TabItem(
                    labelKey: _TabLabelKey.settings,
                    icon: FontAwesomeIcons.gear,
                    selectedIcon: FontAwesomeIcons.cog,
                    index: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final horizontalLayout = Row(
      children: <Widget>[
        NavigationRail(
          selectedIndex: tabIndex,
          onDestinationSelected: P.app.onTabSelected,
          labelType: NavigationRailLabelType.all,
          leading: const SizedBox(height: 12),
          trailing: const SizedBox(height: 12),
          destinations: <NavigationRailDestination>[
            NavigationRailDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: Text(s.home),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.chat_bubble_outline),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: Text(s.conversations),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: Text(s.settings),
            ),
          ],
        ),
        const VerticalDivider(thickness: 0.5, width: 0.5),
        Expanded(child: child),
      ],
    );

    final theme = ref.watch(P.app.theme);
    final systemOverlayStyle = theme.isLight ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Scaffold(body: useBottomNavigationBar ? verticalLayout : horizontalLayout),
    );
  }
}

enum _TabLabelKey {
  home,
  conversations,
  settings,
}

class _TabItem extends ConsumerWidget {
  final _TabLabelKey labelKey;
  final IconData icon;
  final int index;
  final IconData selectedIcon;

  const _TabItem({
    required this.labelKey,
    required this.icon,
    required this.index,
    required this.selectedIcon,
  });

  String _resolveLabel(BuildContext context) {
    final s = S.of(context);
    switch (labelKey) {
      case _TabLabelKey.home:
        return s.home;
      case _TabLabelKey.conversations:
        return s.conversations;
      case _TabLabelKey.settings:
        return s.settings;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(P.app.tabIndex);
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final color = qb.q(selectedIndex == index ? 1 : .4);

    return GD(
      onTap: () => P.app.onTabSelected(index),
      child: C(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: .circular(100),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            FaIcon(selectedIndex == index ? selectedIcon : icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              _resolveLabel(context),
              style: TextStyle(fontSize: 12, color: color),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
