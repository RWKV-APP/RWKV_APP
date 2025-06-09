// ignore: unused_import
import 'dart:developer';

import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/model_selector.dart';

class Empty extends ConsumerWidget {
  const Empty({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final messages = ref.watch(P.msg.list);
    if (messages.isNotEmpty) return Positioned.fill(child: IgnorePointer(child: Container()));
    final loaded = ref.watch(P.rwkv.loaded);
    final currentModel = ref.watch(P.rwkv.currentModel);

    final demoType = ref.watch(P.app.demoType);
    final currentWorldType = ref.watch(P.rwkv.currentWorldType);
    String logoPath = "assets/img/${demoType.name}/logo.square.png";

    final hasSpecificEmpty = demoType == DemoType.world && currentWorldType != null;

    final primary = Theme.of(context).colorScheme.primary;

    final inputHeight = demoType == DemoType.tts ? ref.watch(P.chat.inputHeight) : 0;

    return AnimatedPositioned(
      duration: 200.ms,
      curve: Curves.easeInOutBack,
      bottom: hasSpecificEmpty ? -2000 : 0,
      left: 0,
      right: 0,
      top: 0,
      child: AnimatedOpacity(
        opacity: hasSpecificEmpty ? 0 : 1,
        duration: 200.ms,
        curve: Curves.easeInOutBack,
        child: GD(
          onTap: () {
            P.chat.focusNode.unfocus();
            P.tts.dismissAllShown();
          },
          child: Stack(
            children: [
              Positioned.fill(
                left: 32,
                right: 32,
                child: Column(
                  crossAxisAlignment: CAA.center,
                  children: [
                    const Spacer(),
                    Image.asset(logoPath, width: 140),
                    12.h,
                    T(s.chat_welcome_to_use(Config.appTitle), s: const TS(s: 18, w: FW.w600)),
                    12.h,
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: T(s.intro),
                    ),
                    12.h,
                    if (!loaded) T(s.start_a_new_chat_by_clicking_the_button_below),
                    if (!loaded) 12.h,
                    if (!loaded)
                      TextButton(
                        onPressed: () async {
                          ModelSelector.show();
                        },
                        child: T(demoType == DemoType.world ? s.select_a_world_type : s.select_a_model, s: const TS(s: 16, w: FW.w600)),
                      ),
                    if (!loaded) 12.h,
                    if (loaded) T(s.you_are_now_using("")),
                    4.h,
                    if (loaded)
                      C(
                        padding: const EI.s(h: 4, v: 2),
                        decoration: BD(
                          border: Border.all(color: primary),
                          borderRadius: 4.r,
                        ),
                        child: T(
                          currentModel?.name ?? "",
                          s: TS(s: 16, w: FW.w600, c: primary),
                        ),
                      ),
                    const Spacer(),
                    if (demoType == DemoType.tts) (inputHeight / 1.5).h,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
