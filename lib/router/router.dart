// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zone/page/tab.dart';
import 'package:zone/router/page_key.dart';

BuildContext? getContext() => _getRooNavigatorKey().currentState?.context;

GlobalKey<NavigatorState> _getRooNavigatorKey() => _rootNavigatorKey;
GlobalKey<NavigatorState> _getShellNavigatorKey() => _shellNavigatorKey;

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final kRouter = GoRouter(
  debugLogDiagnostics: false,
  navigatorKey: _rootNavigatorKey,
  initialLocation: PageKey.initialLocation,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => PageTab(content: child),
      routes: [
        PageKey.home.route,
        PageKey.conversation.route,
        PageKey.settings.route,
      ],
    ),
    ...PageKey.values.map((e) => e.route),
  ],
);
