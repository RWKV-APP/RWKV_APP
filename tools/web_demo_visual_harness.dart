// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:zone/model/app_theme.dart';
import 'package:zone/page/web_demo.dart';
import 'package:zone/store/p.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  P.app.theme.q = AppTheme.light;
  P.app.qb.q = Colors.black;
  P.app.qw.q = Colors.white;
  runApp(
    const StateWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PageWebDemo(),
      ),
    ),
  );
}
