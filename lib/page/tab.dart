import 'package:flutter/material.dart';
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
        BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Conversation',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onTabSelected,
        ),
      ],
    );

    final horizontalLayout = Row(
      children: <Widget>[
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabSelected,
          labelType: NavigationRailLabelType.all,
          destinations: const <NavigationRailDestination>[
            NavigationRailDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: Text('Home'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: Text('Conversation'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: Text('Settings'),
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
}
