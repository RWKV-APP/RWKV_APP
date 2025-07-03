// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zone/router/page_key.dart';

BuildContext? getContext() => _getNavigatorKey().currentState?.context;

GlobalKey<NavigatorState> _getNavigatorKey() => _navigatorKey;

final _navigatorKey = GlobalKey<NavigatorState>(debugLabel: "root");

final kRouter = GoRouter(
  debugLogDiagnostics: false,
  navigatorKey: _navigatorKey,
  initialLocation: PageKey.initialLocation,
  routes: [
    ...PageKey.values.map((e) => e.route),
  ],
);
