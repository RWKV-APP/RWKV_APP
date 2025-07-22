// ignore: unused_import
import 'dart:developer';
import 'dart:math';

import 'package:zone/config.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/suggestions.dart';
import 'package:zone/widgets/dev_options_dialog.dart';
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

    final inputHeight = ref.watch(P.chat.inputHeight);
    final version = ref.watch(P.app.version);

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
              if (demoType == DemoType.chat)
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 90),
                      const Flexible(
                        child: SingleChildScrollView(
                          child: _EmptyV2(),
                        ),
                      ),
                      SizedBox(height: inputHeight.toDouble()),
                    ],
                  ),
                ),
              if (demoType != DemoType.chat)
                Positioned.fill(
                  left: 32,
                  right: 32,
                  child: Column(
                    crossAxisAlignment: CAA.center,
                    children: [
                      const Spacer(),
                      WithDevOption(child: Image.asset(logoPath, width: 140)),
                      12.h,
                      Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Opacity(
                            opacity: 0.0,
                            child: T(version, s: const TS(s: 10)),
                          ),
                          T(s.chat_welcome_to_use(Config.appTitle), s: const TS(s: 18, w: FW.w600)),
                          Opacity(
                            opacity: 0.5,
                            child: Padding(
                              padding: const EI.o(b: 4),
                              child: T(version, s: const TS(s: 10)),
                            ),
                          ),
                        ],
                      ),
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

class _EmptyV2 extends ConsumerWidget {
  const _EmptyV2();

  Color _rndColor() {
    return HSLColor.fromAHSL(1, Random().nextDouble() * 360, .6, 0.7).toColor();
  }

  void onTap(dynamic suggestion) {
    if (!checkModelSelection()) return;
    final s = (suggestion as Suggestion);
    P.chat.send(s.prompt.isEmpty ? s.display : s.prompt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(P.suggestion.suggestion);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        16.h,
        Text(
          S.of(context).hello_ask_me_anything,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        36.h,
        for (final item in suggestions) ...[
          12.h,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: buildSuggestion(item),
          ),
        ],
        if (suggestions.isNotEmpty) 12.h,
        if (suggestions.isNotEmpty)
          Material(
            borderRadius: 60.r,
            child: InkWell(
              borderRadius: 60.r,
              onTap: () async {
                final suggestion = await AllSuggestionDialog.show(context);
                if (suggestion != null) onTap(suggestion);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                child: Text(
                  S.current.more_questions,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        16.h,
      ],
    );
  }

  Widget buildSuggestion(dynamic item) {
    return Material(
      borderRadius: 60.r,
      child: InkWell(
        borderRadius: 60.r,
        onTap: () => onTap(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  color: _rndColor(),
                  borderRadius: 60.r,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  item is Suggestion ? item.display : item.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
