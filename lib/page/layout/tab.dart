// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/store/p.dart';

class PageTab extends ConsumerWidget {
  final Widget child;

  const PageTab({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    final useBottomNavigationBar = screenWidth <= 600 || screenWidth <= (screenHeight - 100);
    final tabIndex = ref.watch(P.app.tabIndex);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final rawPaddingBottom = ref.watch(P.app.paddingBottom);
    double paddingBottom = rawPaddingBottom / 2;
    final qb = ref.watch(P.app.qb);

    double tabBarLeftPadding = appTheme.tabBarLeftPadding;
    tabBarLeftPadding += rawPaddingBottom / 5;

    double tabBarRightPadding = appTheme.tabBarRightPadding;
    tabBarRightPadding += rawPaddingBottom / 5;

    // TODO: @wangce 没有用到的话就不要创建两个 layout 的代码

    final verticalLayout = Stack(
      children: <Widget>[
        child,
        Positioned(
          bottom: paddingBottom + 12,
          left: tabBarLeftPadding,
          right: tabBarRightPadding,
          height: appTheme.tabBarHeight,
          child: ClipRRect(
            borderRadius: .circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: appTheme.settingBg.q(.5),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: paddingBottom + 12,
          left: tabBarLeftPadding,
          right: tabBarRightPadding,
          height: appTheme.tabBarHeight,
          child: Container(
            decoration: BoxDecoration(
              color: appTheme.settingBg.q(.5),
              borderRadius: .circular(100),
              border: Border.all(color: qb.q(.2), width: .5),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _TabItem(
                    labelKey: _TabLabelKey.home,
                    icon: FontAwesomeIcons.house,
                    selectedIcon: FontAwesomeIcons.solidHouse,
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    labelKey: _TabLabelKey.conversations,
                    icon: FontAwesomeIcons.message,
                    selectedIcon: FontAwesomeIcons.solidMessage,
                    index: 1,
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    labelKey: _TabLabelKey.settings,
                    icon: FontAwesomeIcons.gear,
                    selectedIcon: FontAwesomeIcons.gear,
                    index: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final isLight = appTheme.isLight;
    final hoverColor = isLight ? kW.q(.95) : kW.q(.15);
    final indicatorColor = isLight ? kW.q(.99) : kW.q(.2);

    final horizontalLayout = Row(
      children: <Widget>[
        Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: hoverColor, // Hover 颜色将变成 Colors.red.withOpacity(0.04)
            ),
          ),
          child: NavigationRail(
            backgroundColor: appTheme.qb144,
            indicatorColor: indicatorColor,
            indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            selectedIndex: tabIndex,
            onDestinationSelected: P.app.onTabSelected,
            labelType: NavigationRailLabelType.all,
            leading: const SizedBox(height: 12),
            trailing: const SizedBox(height: 12),
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined, color: appTheme.qb3),
                selectedIcon: Icon(Icons.home, color: appTheme.qb3),
                label: Text(s.home, style: TextStyle(color: appTheme.qb3)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline, color: appTheme.qb3),
                selectedIcon: Icon(Icons.chat_bubble, color: appTheme.qb3),
                label: Text(s.conversations, style: TextStyle(color: appTheme.qb3)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined, color: appTheme.qb3),
                selectedIcon: Icon(Icons.settings, color: appTheme.qb3),
                label: Text(s.settings, style: TextStyle(color: appTheme.qb3)),
              ),
            ],
          ),
        ),
        Container(
          width: .5,
          height: double.infinity,
          color: qb.q(.2),
        ),
        Expanded(child: child),
      ],
    );

    final currentTheme = ref.watch(P.app.theme);
    final systemOverlayStyle = currentTheme.isLight ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark;

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
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 12, color: color) ?? TextStyle(fontSize: 12, color: color),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
