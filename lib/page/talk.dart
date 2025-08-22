// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/assets.gen.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/app_scaffold.dart';
import 'package:zone/widgets/chat/app_bar.dart';
import 'package:zone/widgets/chat/audio_input.dart';
import 'package:zone/widgets/chat/bottom_bar.dart';
import 'package:zone/widgets/chat/message.dart';
import 'package:zone/widgets/chat/tts/suggestions.dart';
import 'package:zone/widgets/model_selector.dart';

class PageTalk extends ConsumerWidget {
  const PageTalk({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Stack(
        children: [
          AppGradientBackground(child: SizedBox()),
          _List(),
          _Empty(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatAppBar(preferredDemoType: DemoType.tts),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Suggestions(),
                BottomBar(demoType: DemoType.tts),
              ],
            ),
          ),
          AudioInput(demoType: DemoType.tts),
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
          padding: EI.o(
            r: 4,
            b: scrollBarBottom,
            t: top,
          ),
          controller: P.chat.scrollController,
          child: ListView.separated(
            reverse: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EI.o(t: top, b: bottom, l: paddingLeft, r: paddingRight),
            controller: P.chat.scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final finalIndex = messages.length - 1 - index;
              final msg = messages[finalIndex];
              return Message(msg, finalIndex, preferredDemoType: DemoType.tts);
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
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logoSquare.image(width: 140),
            T(s.chat_welcome_to_use("RWKV Talk"), s: const TS(s: 18, w: FontWeight.w600)),
            4.h,
            T("v$version"),
            12.h,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: T(
                s.intro,
                s: TS(c: qb, w: FontWeight.w500),
              ),
            ),
            12.h,
            if (!loaded)
              T(
                s.start_a_new_chat_by_clicking_the_button_below,
                s: TS(c: qb, s: 12),
              ),
            12.h,
            if (!loaded)
              TextButton(
                onPressed: () => ModelSelector.show(preferredDemoType: DemoType.tts),
                child: T(s.select_a_model, s: const TS(s: 16, w: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}
