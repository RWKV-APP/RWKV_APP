import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

    final verticalLayout = Column(
      children: <Widget>[
        Expanded(child: child),
        SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: _buildItem(ref, context, s.home, FontAwesomeIcons.house, 0),
              ),
              Expanded(
                child: _buildItem(ref, context, s.conversations, FontAwesomeIcons.solidMessage, 1),
              ),
              Expanded(
                child: _buildItem(ref, context, s.settings, FontAwesomeIcons.gear, 2),
              ),
            ],
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

    final theme = ref.watch(P.app.customTheme);
    final systemOverlayStyle = theme.isLight ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Scaffold(body: useBottomNavigationBar ? verticalLayout : horizontalLayout),
    );
  }

  Widget _buildItem(
    WidgetRef ref,
    BuildContext context,
    String label,
    IconData icon,
    int index,
  ) {
    final selectedIndex = ref.watch(P.app.tabIndex);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = selectedIndex == index
        ? (isDark ? Colors.grey.shade400 : theme.primaryColor) //
        : (isDark ? Colors.grey.shade800 : Colors.grey);
    return InkWell(
      onTap: () => P.app.onTabSelected(index),
      borderRadius: .circular(100),
      child: Column(
        children: [
          const SizedBox(height: 12),
          FaIcon(icon, size: 20, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
