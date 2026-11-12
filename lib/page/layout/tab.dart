// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/app_presentation.dart';
import 'package:zone/page/layout/themed_shell.dart';
import 'package:zone/store/p.dart';

class PageTab extends ConsumerWidget {
  final Widget child;

  const PageTab({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final useBottomNavigationBar = ref.watch(P.app.useBottomTabBar);
    final tabIndex = ref.watch(P.app.tabIndex);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final style = ref.watch(P.preference.appStyle);
    final presentation = AppPresentation.forStyle(style);
    if (presentation != null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: appTheme.isLight ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark,
        child: Scaffold(
          body: ThemedAppShell(presentation: presentation, style: style, child: child),
        ),
      );
    }
    final navCorners = BorderRadius.circular(style.navigationRadius);
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
            borderRadius: navCorners,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: appTheme.settingBg.withValues(alpha: .5),
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
              color: appTheme.settingBg.withValues(alpha: .5),
              borderRadius: navCorners,
              border: Border.all(color: qb.withValues(alpha: .2), width: .5),
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
    final hoverColor = isLight ? Colors.white.withValues(alpha: .95) : Colors.white.withValues(alpha: .15);
    final indicatorColor = isLight ? Colors.white.withValues(alpha: .99) : Colors.white.withValues(alpha: .2);
    final railSelectedIndex = tabIndex == 2 ? null : tabIndex;
    final indicatorCorners = BorderRadius.circular(4);

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
            indicatorShape: RoundedRectangleBorder(borderRadius: indicatorCorners),
            selectedIndex: railSelectedIndex,
            onDestinationSelected: P.app.onTabSelected,
            labelType: NavigationRailLabelType.all,
            leading: const SizedBox(height: 12),
            trailingAtBottom: true,
            trailing: _SideRailSettingsItem(
              label: s.settings,
              selected: tabIndex == 2,
              color: appTheme.qb3,
              indicatorColor: indicatorColor,
              indicatorCorners: indicatorCorners,
            ),
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
            ],
          ),
        ),
        Container(
          width: .5,
          height: double.infinity,
          color: qb.withValues(alpha: .2),
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
  final FaIconData icon;
  final int index;
  final FaIconData selectedIcon;

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
    final theme = Theme.of(context);
    final selectedIndex = ref.watch(P.app.tabIndex);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final style = ref.watch(P.preference.appStyle);
    final selected = selectedIndex == index;
    final color = selected ? (style.isClassic ? qb : appTheme.primary) : appTheme.qb6;

    return GestureDetector(
      onTap: () => P.app.onTabSelected(index),
      child: Container(
        decoration: BoxDecoration(
          color: selected && !style.isClassic ? appTheme.userMsgBg : Colors.transparent,
          borderRadius: .circular(style.navigationRadius),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            FaIcon(selected ? selectedIcon : icon, size: 20, color: color),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                _resolveLabel(context),
                maxLines: 1,
                overflow: .ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 12, color: color) ?? TextStyle(fontSize: 12, color: color),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SideRailSettingsItem extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color indicatorColor;
  final BorderRadius indicatorCorners;

  const _SideRailSettingsItem({
    required this.label,
    required this.selected,
    required this.color,
    required this.indicatorColor,
    required this.indicatorCorners,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelMedium?.copyWith(color: color) ?? TextStyle(color: color);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Padding(
        padding: const .only(bottom: 32),
        child: InkWell(
          onTap: () => P.app.onTabSelected(2),
          borderRadius: indicatorCorners,
          child: SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: .min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected ? indicatorColor : Colors.transparent,
                    borderRadius: indicatorCorners,
                  ),
                  child: Icon(selected ? Icons.settings : Icons.settings_outlined, color: color),
                ),
                const SizedBox(height: 4),
                Text(label, textAlign: TextAlign.center, style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
