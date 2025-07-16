import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';

/// Flutter code sample for [NavigationRail].

class PageTab extends StatefulWidget {
  final Widget content;

  const PageTab({super.key, required this.content});

  @override
  State<PageTab> createState() => _PageTabState();
}

class _PageTabState extends State<PageTab> {
  int _selectedIndex = 0;
  late final theme = Theme.of(context);

  void _onTabSelected(int index) async {
    _selectedIndex = index;
    setState(() {});
    switch (index) {
      case 0:
        replace(PageKey.home);
        break;
      case 1:
        replace(PageKey.conversation);
        break;
      case 2:
        replace(PageKey.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final useBottomNavigationBar = screenWidth <= 600;

    final verticalLayout = Column(
      children: <Widget>[
        Expanded(child: widget.content),
        SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: buildItem(S.of(context).home, FontAwesomeIcons.house, 0),
              ),
              Expanded(
                child: buildItem(S.of(context).conversations, FontAwesomeIcons.solidMessage, 1),
              ),
              Expanded(
                child: buildItem(S.of(context).settings, FontAwesomeIcons.gear, 2),
              ),
            ],
          ),
        ),
      ],
    );

    final horizontalLayout = Row(
      children: <Widget>[
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabSelected,
          labelType: NavigationRailLabelType.all,
          destinations: <NavigationRailDestination>[
            NavigationRailDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: Text(S.of(context).home),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: Text(S.of(context).conversations),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: Text(S.of(context).settings),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: widget.content),
        // This is the main content.
      ],
    );

    return Scaffold(body: useBottomNavigationBar ? verticalLayout : horizontalLayout);
  }

  Widget buildItem(String label, IconData icon, int index) {
    final color = _selectedIndex == index ? theme.primaryColor : Colors.grey;
    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(100),
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
