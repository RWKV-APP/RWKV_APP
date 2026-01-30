// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/assets.gen.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/gradient_background.dart';
import 'package:zone/widgets/chat_app_bar.dart';
import 'package:zone/widgets/talk/audio_input.dart';
import 'package:zone/widgets/input_bar.dart';
import 'package:zone/widgets/message.dart';
import 'package:zone/widgets/talk/suggestions.dart';
import 'package:zone/widgets/model_selector.dart';

class PageTalk extends ConsumerWidget {
  const PageTalk({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     P.tts.test();
      //   },
      // ),
      body: Stack(
        children: [
          GradientBackground(child: SizedBox()),
          _List(),
          _Empty(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatAppBar(preferredDemoType: .tts),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Column(
              crossAxisAlignment: .stretch,
              mainAxisSize: .min,
              children: [
                Suggestions(),
                InputBar(preferredDemoType: .tts),
              ],
            ),
          ),
          AudioInput(demoType: .tts),
        ],
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(P.msg.list);
    final paddingTop = ref.watch(P.app.paddingTop);
    final paddingLeft = ref.watch(P.app.paddingLeft);
    final paddingRight = ref.watch(P.app.paddingRight);
    final inputHeight = ref.watch(P.chat.inputHeight);

    double top = paddingTop + kToolbarHeight + 4;
    double bottom = inputHeight + 12;
    double scrollBarBottom = inputHeight + 4;

    bottom += Suggestions.defaultHeight;
    scrollBarBottom += Suggestions.defaultHeight;
    final qb = ref.watch(P.app.qb);

    return Positioned.fill(
      child: GestureDetector(
        onTap: P.chat.onTapMessageList,
        child: RawScrollbar(
          radius: 100.rr,
          thickness: 4,
          thumbColor: qb.q(.4),
          padding: .only(top: top, right: 4, bottom: scrollBarBottom),
          controller: P.chat.scrollController,
          child: ListView.separated(
            reverse: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: .only(left: paddingLeft, top: top, right: paddingRight, bottom: bottom),
            controller: P.chat.scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final finalIndex = messages.length - 1 - index;
              final msg = messages[finalIndex];
              return Message(msg, finalIndex, preferredDemoType: .tts);
            },
            separatorBuilder: (context, index) {
              return const SizedBox(height: 15);
            },
          ),
        ),
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoSquare = Assets.img.chat.logoSquare;
    final inputHeight = ref.watch(P.chat.inputHeight);
    final version = ref.watch(P.app.version);
    final s = S.of(context);
    final loaded = ref.watch(P.rwkv.loaded);
    final messages = ref.watch(P.msg.list);
    final qb = ref.watch(P.app.qb);

    return AnimatedPositioned(
      duration: 200.ms,
      curve: Curves.ease,
      bottom: inputHeight,
      left: 28,
      right: 28,
      top: 0,
      child: AnimatedOpacity(
        opacity: messages.isEmpty ? 1 : 0,
        duration: 200.ms,
        curve: Curves.ease,
        child: Column(
          crossAxisAlignment: .center,
          mainAxisAlignment: .center,
          children: [
            logoSquare.image(width: 140),
            Text(s.chat_welcome_to_use("RWKV Chat"), style: const TS(s: 18, w: .w600)),
            4.h,
            Text("v$version"),
            12.h,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                s.intro,
                style: TS(c: qb, w: .w500),
              ),
            ),
            12.h,
            if (!loaded)
              Text(
                s.start_a_new_chat_by_clicking_the_button_below,
                style: TS(c: qb, s: 12),
              ),
            12.h,
            if (!loaded)
              TextButton(
                onPressed: () => ModelSelector.show(preferredDemoType: .tts),
                child: Text(s.select_a_model, style: const TS(s: 16, w: .w600)),
              ),
          ],
        ),
      ),
    );
  }
}
