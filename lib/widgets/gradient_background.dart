import 'package:flutter/material.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/model/custom_theme.dart';
import 'package:zone/store/p.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlack = isDark && P.app.customTheme.q is LightsOut;

    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isBlack ? Colors.black : null,
        gradient: isBlack
            ? null
            : LinearGradient(
                begin: .topLeft,
                end: .bottomCenter,
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
