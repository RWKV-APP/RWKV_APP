// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/app_scaffold.dart';
import 'package:zone/widgets/chat/app_bar.dart';
import 'package:zone/widgets/chat/audio_input.dart';
import 'package:zone/widgets/chat/bottom_bar.dart';
import 'package:zone/widgets/chat/empty.dart';
import 'package:zone/widgets/chat/message.dart';
import 'package:zone/widgets/chat/tts/suggestions.dart';

class PageTalk extends ConsumerWidget {
  const PageTalk({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Stack(
        children: [
          AppGradientBackground(child: SizedBox()),
          _List(),
          Empty(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatAppBar(),
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
              return Message(msg, finalIndex);
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
