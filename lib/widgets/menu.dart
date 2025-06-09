// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/config.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/app_info.dart';
import 'package:zone/widgets/settings.dart';

class Menu extends ConsumerWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      mainAxisAlignment: MAA.center,
      children: [
        Expanded(child: Settings()),
      ],
    );
  }
}

// TODO: Use this in the future
// ignore: unused_element
class _BottomInfo extends ConsumerWidget {
  const _BottomInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final version = ref.watch(P.app.version);
    final buildNumber = ref.watch(P.app.buildNumber);
    final demoType = ref.watch(P.app.demoType);
    final iconPath = "assets/img/${demoType.name}/icon.png";

    final iconWidget = SB(
      width: 48,
      height: 48,
      child: ClipRRect(
        borderRadius: 8.r,
        child: Image.asset(iconPath),
      ),
    );

    return Column(
      children: [
        12.h,
        Row(
          children: [
            12.w,
            iconWidget,
            8.w,
            Expanded(
              child: Column(
                crossAxisAlignment: CAA.stretch,
                children: [
                  const T(
                    Config.appTitle,
                    s: TS(s: 20),
                  ),
                  Row(
                    // mainAxisAlignment: MAA.center,
                    children: [
                      T(
                        version,
                        s: const TS(s: 12),
                      ),
                      T(
                        " ($buildNumber)",
                        s: const TS(s: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            8.w,
            IconButton(
              onPressed: () {
                AppInfo.show(context);
              },
              icon: const Icon(Icons.info_outline),
            ),
            8.w,
          ],
        ),
        12.h,
        paddingBottom.h,
      ],
    );
  }
}
