// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/world_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/app_scaffold.dart';
import 'package:zone/widgets/chat/app_bar.dart';
import 'package:zone/widgets/chat/audio_empty.dart';
import 'package:zone/widgets/chat/audio_input.dart';
import 'package:zone/widgets/chat/bottom_bar.dart';
import 'package:zone/widgets/chat/completion_mode.dart';
import 'package:zone/widgets/chat/empty.dart';
import 'package:zone/widgets/chat/message.dart';
import 'package:zone/widgets/chat/share_chat.dart';
import 'package:zone/widgets/chat/suggestions.dart';
import 'package:zone/widgets/chat/visual_empty.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/widgets/pager.dart';

class PageChat extends StatefulWidget {
  const PageChat({super.key});

  @override
  State<PageChat> createState() => _PageChatState();
}

class _PageChatState extends State<PageChat> {
  @override
  void initState() {
    super.initState();

    if (P.app.demoType.q == DemoType.chat) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        final loaded = P.rwkv.currentModel.q != null;
        if (!loaded) {
          await Future.delayed(const Duration(milliseconds: 200));
          ModelSelector.show();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const _Page();
  }
}

class _Page extends ConsumerWidget {
  const _Page();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionMode = ref.watch(P.chat.completionMode);
    final selectMessageMode = ref.watch(P.chat.isSharing);
    final atMainPage = ref.watch(Pager.atMainPage);
    final demoType = ref.watch(P.app.demoType);

    if (completionMode) {
      final qb = ref.watch(P.app.qb);
      return Scaffold(
        resizeToAvoidBottomInset: atMainPage,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ChatAppBar(),
            Divider(color: qb.q(.1), thickness: .5),
            const Expanded(child: Completion()),
          ],
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: atMainPage,
      body: Stack(
        children: [
          if (DemoType.chat == demoType) AppGradientBackground(child: SizedBox()),
          const _List(),
          const Empty(),
          const VisualEmpty(),
          const AudioEmpty(),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatAppBar(),
          ),
          const _NavigationBarBottomLine(),
          if (selectMessageMode) const Positioned.fill(child: ShareChatSheet()),
          if (!selectMessageMode)
            const Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Suggestions(),
                  BottomBar(),
                ],
              ),
            ),
          const AudioInput(),
        ],
      ),
    );
  }
}

class _NavigationBarBottomLine extends ConsumerWidget {
  const _NavigationBarBottomLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingTop = ref.watch(P.app.paddingTop);
    final qb = ref.watch(P.app.qb);
    return Positioned(
      top: paddingTop + kToolbarHeight,
      left: 0,
      right: 0,
      height: .5,
      child: C(
        height: kToolbarHeight,
        color: qb.q(.1),
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
    final demoType = ref.watch(P.app.demoType);

    double top = paddingTop + kToolbarHeight + 4;
    double bottom = inputHeight + 12;
    double scrollBarBottom = inputHeight + 4;

    final currentWorldType = ref.watch(P.rwkv.currentWorldType);

    switch (currentWorldType) {
      case null:
        break;
      case WorldType.engVisualQA:
      case WorldType.qa:
      case WorldType.reasoningQA:
      case WorldType.ocr:
      case WorldType.modrwkvV2:
        if (messages.length == 1 && messages.first.type == model.MessageType.userImage) {
          bottom += 46;
        }
      case WorldType.engAudioQA:
        bottom += 16;
        break;
      case WorldType.chineseASR:
        bottom += 16;
        break;
      case WorldType.engASR:
        bottom += 16;
        break;
    }

    switch (demoType) {
      case DemoType.chat:
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
      case DemoType.world:
        break;
      case DemoType.tts:
        bottom += Suggestions.defaultHeight;
        scrollBarBottom += Suggestions.defaultHeight;
    }
    final qb = ref.watch(P.app.qb);

    // return Positioned.fill(child: C());

    return Positioned.fill(
      child: GD(
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
              return _MessageWrap(msg: msg, finalIndex: finalIndex);
            },
            separatorBuilder: (context, index) {
              return const SB(height: 15);
            },
          ),
        ),
      ),
    );
  }
}

class _MessageWrap extends ConsumerWidget {
  final model.Message msg;
  final int finalIndex;

  const _MessageWrap({required this.msg, required this.finalIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectMessageMode = ref.watch(P.chat.isSharing);

    if (!selectMessageMode) {
      return Message(msg, finalIndex, selectMode: false);
    }
    final selectedIds = ref.watch(P.chat.sharingSelectedMsgIds);
    final selected = selectedIds.contains(msg.id);

    void toggle() async {
      final ids = P.chat.sharingSelectedMsgIds.q;
      final messages = P.msg.list.q;
      final index = messages.indexOf(msg);
      final previous = index > 0 ? messages[index - 1] : null;
      final next = index < messages.length - 1 ? messages[index + 1] : null;
      final pair = msg.isMine ? next : previous;
      if (selected) {
        P.chat.sharingSelectedMsgIds.q = ids.where((id) => id != msg.id && id != pair?.id).toSet();
      } else {
        P.chat.sharingSelectedMsgIds.q = {...ids, msg.id, ?pair?.id};
      }
    }

    return GestureDetector(
      onTap: () => toggle(),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (checked) => toggle(),
          ),
          Exp(
            child: IgnorePointer(
              child: Message(msg, finalIndex, selectMode: true),
            ),
          ),
        ],
      ),
    );
  }
}
