import 'package:flutter/material.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/store/p.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;

  const AppScaffold({super.key, required this.body, this.appBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: AppGradientBackground(child: body),
    );
  }
}

class AppGradientBackground extends StatelessWidget {
  final Widget child;

  const AppGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlack = isDark && P.app.customTheme.q.toString() == "LightsOut";

    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isBlack ? Colors.black : null,
        gradient: isBlack
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF152D57),
                        const Color(0xFF0B1528),
                      ]
                    : [
                        const Color(0xFFF0F4FC),
                        const Color(0xFFD6E3F8),
                      ],
              ),
      ),
      child: child,
    );
  }
}
