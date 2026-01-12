// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/message_type.dart' as model;
import 'package:zone/model/world_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/app_scaffold.dart';
import 'package:zone/widgets/chat/app_bar.dart';
import 'package:zone/widgets/chat/bottom_bar.dart';
import 'package:zone/widgets/chat/empty.dart';
import 'package:zone/widgets/chat/message.dart';
import 'package:zone/widgets/chat/share_chat.dart';
import 'package:zone/widgets/model_selector.dart';

class PageChat extends StatefulWidget {
  const PageChat({super.key});

  @override
  State<PageChat> createState() => _PageChatState();
}

class _PageChatState extends State<PageChat> {
  @override
  void initState() {
    super.initState();

    // 自动展示模型选择器
    if (P.app.demoType.q == .chat) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        final loaded = P.rwkv.latestModel.q != null;
        if (!loaded) {
          await Future.delayed(const Duration(milliseconds: 200));
          ModelSelector.show(showNeko: P.app.pageKey.q == .neko);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: const _Page(),
    );
  }

  void _onPopInvokedWithResult(bool didPop, _) {
    if (!didPop) return;
    P.chat.isSharing.q = false;
    P.chat.onStopButtonPressed(wantHaptic: false);
  }
}

class _Page extends ConsumerWidget {
  const _Page();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectMessageMode = ref.watch(P.chat.isSharing);

    return Scaffold(
      body: Stack(
        children: [
          const AppGradientBackground(child: SizedBox()),
          const _List(),
          const Empty(),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatAppBar(),
          ),
          if (selectMessageMode) const Positioned.fill(child: ShareChatSheet()),
          if (!selectMessageMode)
            const Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: BottomBar(),
            ),
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

    final currentWorldType = ref.watch(P.rwkv.currentWorldType);

    switch (currentWorldType) {
      case null:
        break;
      case WorldType.reasoningQA:
      case WorldType.ocr:
      case WorldType.modrwkvV2:
      case WorldType.modrwkvV3:
        if (messages.length == 1 && messages.first.type == model.MessageType.userImage) {
          bottom += 46;
        }
        break;
    }

    final qb = ref.watch(P.app.qb);

    // return Positioned.fill(child: Container());

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
              return _MessageWrap(msg: msg, finalIndex: finalIndex);
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
        crossAxisAlignment: .start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (checked) => toggle(),
          ),
          Expanded(
            child: IgnorePointer(
              child: Message(msg, finalIndex, selectMode: true),
            ),
          ),
        ],
      ),
    );
  }
}
