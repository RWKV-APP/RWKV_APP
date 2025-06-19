// ignore: unused_import
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/config.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/state/p.dart';
import 'package:zone/page/panel/settings.dart';
import 'package:zone/widgets/chat/conversation_list.dart';

class Menu extends ConsumerWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoType = ref.watch(P.app.demoType);

    switch (demoType) {
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
      case DemoType.tts:
      case DemoType.world:
        return const Settings(isInDrawerMenu: true);
      case DemoType.chat:
        break;
    }

    return const Column(
      mainAxisAlignment: MAA.center,
      children: [
        Expanded(child: ConversationList()),
        _Info(),
      ],
    );
  }
}

class _Info extends ConsumerWidget {
  const _Info();

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

    return Material(
      color: kC,
      child: GD(
        onTap: () {
          Settings.show();
        },
        child: Column(
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
                          Flexible(
                            child: T(
                              version,
                              s: const TS(s: 12),
                            ),
                          ),
                          Flexible(
                            child: T(
                              " ($buildNumber)",
                              s: const TS(s: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                8.w,
                IconButton(
                  onPressed: () {
                    Settings.show();
                  },
                  icon: (Platform.isIOS || Platform.isMacOS) ? const Icon(CupertinoIcons.ellipsis) : const Icon(Icons.more_vert),
                ),
                8.w,
              ],
            ),
            12.h,
            paddingBottom.h,
          ],
        ),
      ),
    );
  }
}
