import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';
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
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final verticalLayout = Stack(
      children: <Widget>[
        Positioned.fill(child: child),
        // Floating pill-shaped bottom navigation bar
        Positioned(
          left: 16,
          right: 16,
          bottom: paddingBottom + 12,
          child: _FloatingBottomBar(
            tabIndex: tabIndex,
            isDark: isDark,
            labels: [s.home, s.conversations, s.settings],
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
          leading: 12.h,
          trailing: 12.h,
          destinations: <NavigationRailDestination>[
            NavigationRailDestination(
              icon: const Icon(RemixIcon.home4Line),
              selectedIcon: const Icon(RemixIcon.home4Fill),
              label: Text(s.home),
            ),
            NavigationRailDestination(
              icon: const Icon(RemixIcon.message3Line),
              selectedIcon: const Icon(RemixIcon.message3Fill),
              label: Text(s.conversations),
            ),
            NavigationRailDestination(
              icon: const Icon(RemixIcon.settings3Line),
              selectedIcon: const Icon(RemixIcon.settings3Fill),
              label: Text(s.settings),
            ),
          ],
        ),
        const VerticalDivider(thickness: 0.5, width: 0.5),
        Expanded(child: child),
      ],
    );

    final theme = ref.watch(P.app.customTheme);
    final systemOverlayStyle = theme.light ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Scaffold(body: useBottomNavigationBar ? verticalLayout : horizontalLayout),
    );
  }
}

/// Floating pill-shaped bottom navigation bar (iOS/ChatGPT style)
class _FloatingBottomBar extends StatelessWidget {
  final int tabIndex;
  final bool isDark;
  final List<String> labels;

  const _FloatingBottomBar({
    required this.tabIndex,
    required this.isDark,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    // Shadow for floating effect
    final boxShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
        blurRadius: 24,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
      if (!isDark)
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
    ];

    final borderColor = isDark
        ? const Color(0xFF3A3A3C)
        : const Color(0xFFE5E5EA);

    // Background color for the blur overlay
    final bgColor = isDark
        ? const Color(0xFF2C2C2E).withOpacity(0.95)
        : Colors.white.withOpacity(0.95);

    return ClipRRect(
      borderRadius: 100.r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: 100.r,
            boxShadow: boxShadow,
            border: Border.all(color: borderColor, width: 0.5),
          ),
          padding: const .symmetric(horizontal: 8, vertical: 6),
          child: _AnimatedNavContent(
            tabIndex: tabIndex,
            isDark: isDark,
            labels: labels,
          ),
        ),
      ),
    );
  }
}

/// Animated navigation content with sliding indicator
class _AnimatedNavContent extends StatelessWidget {
  final int tabIndex;
  final bool isDark;
  final List<String> labels;

  const _AnimatedNavContent({
    required this.tabIndex,
    required this.isDark,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBgColor = isDark
        ? const Color(0xFF3A3A3C)
        : const Color(0xFFF2F2F7);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 3;

        return Stack(
          children: [
            // Animated sliding indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: tabIndex * itemWidth,
              top: 0,
              bottom: 0,
              width: itemWidth,
              child: Center(
                child: Container(
                  margin: const .symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selectedBgColor,
                    borderRadius: 100.r,
                  ),
                ),
              ),
            ),
            // Navigation items
            Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: RemixIcon.home4Line,
                    selectedIcon: RemixIcon.home4Fill,
                    label: labels[0],
                    isSelected: tabIndex == 0,
                    isDark: isDark,
                    onTap: () => P.app.onTabSelected(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: RemixIcon.message3Line,
                    selectedIcon: RemixIcon.message3Fill,
                    label: labels[1],
                    isSelected: tabIndex == 1,
                    isDark: isDark,
                    onTap: () => P.app.onTabSelected(1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: RemixIcon.settings3Line,
                    selectedIcon: RemixIcon.settings3Fill,
                    label: labels[2],
                    isSelected: tabIndex == 2,
                    isDark: isDark,
                    onTap: () => P.app.onTabSelected(2),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTextColor = isDark
        ? Colors.white
        : Colors.black;
    final unselectedTextColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF8E8E93);

    final color = isSelected ? selectedTextColor : unselectedTextColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const .symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 20,
              color: color,
            ),
            2.h,
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
