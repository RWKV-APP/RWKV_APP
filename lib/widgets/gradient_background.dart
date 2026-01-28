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
                        const Color(0xFF1C1C1E), // Apple System Background (Dark)
                        const Color(0xFF2C2C2E), // Apple Secondary Background (Dark)
                      ]
                    : [
                        const Color(0xFFFFFFFF), // Pure white
                        const Color(0xFFF2F2F7), // Apple Secondary System Background
                      ],
              ),
      ),
      child: child,
    );
  }
}
