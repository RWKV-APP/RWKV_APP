// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/performance_info.dart';

extension _VisiblePage on PageKey {
  bool get isVisible => switch (this) {
    .chat => true,
    .talk => true,
    .see => true,
    .translator => true,
    .ocr => true,
    _ => false,
  };

  bool get short => switch (this) {
    .translator => true,
    _ => false,
  };
}

class FloatingPerformaceInfo extends ConsumerWidget {
  const FloatingPerformaceInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingTop = ref.watch(P.app.paddingTop);
    final navbarHeight = 58.0;
    final screenWidth = ref.watch(P.app.screenWidth);

    final pageKey = ref.watch(P.app.pageKey);
    final isVisible = pageKey.isVisible;
    final isMobile = ref.watch(P.app.isMobile);
    final short = (pageKey.short & isMobile) || screenWidth <= 400;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeOutCirc,
      left: 54,
      top: isVisible ? paddingTop : -100,
      height: navbarHeight,
      child: AnimatedOpacity(
        opacity: pageKey.isVisible ? 0.9 : 0.0,
        duration: const Duration(milliseconds: 2000),
        curve: Curves.easeOutCirc,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: PerformanceInfo(short: short),
          ),
        ),
      ),
    );
  }
}
