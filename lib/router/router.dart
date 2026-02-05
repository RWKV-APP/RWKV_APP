// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zone/page/layout/tab.dart';
import 'package:zone/router/page_key.dart';

BuildContext? getContext() => _getRooNavigatorKey().currentState?.context;

GlobalKey<NavigatorState> _getRooNavigatorKey() => _rootNavigatorKey;

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final kRouter = GoRouter(
  debugLogDiagnostics: false,
  navigatorKey: _rootNavigatorKey,
  initialLocation: PageKey.initialLocation,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      pageBuilder: (context, state, child) => NoTransitionPage(child: PageTab(child: child)),
      routes: PageKey.tabs.map((e) => e.route).toList(),
    ),
    ...PageKey.values.map((e) => e.route),
  ],
);
