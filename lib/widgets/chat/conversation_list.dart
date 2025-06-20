// ignore: unused_import
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/db/db.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/pager.dart';

class ConversationList extends ConsumerWidget {
  const ConversationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(P.conversation.conversations);
    final isEmpty = conversations.isEmpty;

    if (isEmpty) {
      return _HeaderWrapper(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: const _Empty(),
              ),
            );
          },
        ),
      );
    }

    return _HeaderWrapper(
      child: RefreshIndicator.adaptive(
        onRefresh: () async {
          P.app.hapticLight();
          await P.conversation.load();
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          shrinkWrap: isEmpty,
          padding: const EI.o(
            t: 8,
            b: 8,
            l: 8,
            r: 8,
          ),
          itemCount: isEmpty ? 0 : conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _Item(conversation: conversation);
          },
        ),
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  void _onPressed() {
    Pager.toggle();
    if (!checkModelSelection()) return;
    P.chat.startNewChat();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Spacer(),
          IconButton(
            onPressed: _onPressed,
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CAA.stretch,
              children: [
                12.h,
                const Icon(Icons.add),
                T(s.new_chat, s: const TS(s: 20), textAlign: TextAlign.center),
                T(
                  s.create_a_new_one_by_clicking_the_button_above,
                  s: TS(s: 10, c: qb.q(.5)),
                  textAlign: TextAlign.center,
                ),
                12.h,
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Item extends ConsumerWidget {
  const _Item({required this.conversation});

  final ConversationData conversation;

  void _onTap() async {
    await P.conversation.onTapInList(conversation);
  }

  void _onLongPressStart(LongPressStartDetails details, BuildContext context) async {
    // 在长按开始时显示菜单

    P.conversation.interactingCreatedAtUS.q = conversation.createdAtUS;

    P.app.hapticLight();

    final s = S.of(context);

    // 使用showMenu在特定位置显示菜单
    final res = await showMenu<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).colorScheme.surface,
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx, // 菜单的左侧位置
        details.globalPosition.dy + 10, // 菜单的顶部位置
        MediaQuery.sizeOf(context).width - details.globalPosition.dx, // 菜单的右侧位置 (这里只是一个占位符，实际会根据菜单宽度调整)
        MediaQuery.sizeOf(context).height - details.globalPosition.dy, // 菜单的底部位置
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SB(
                width: 8,
              ),
              Text(s.rename),
            ],
          ),
        ),
        const PopupMenuDivider(indent: 8, endIndent: 8),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              const SB(
                width: 8,
              ),
              Text(
                s.delete_conversation,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(indent: 8, endIndent: 8),
        PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              const Icon(Icons.download_outlined),
              const SB(
                width: 8,
              ),
              Text(s.export_data),
            ],
          ),
        ),
      ],
      elevation: 8.0,
    );

    // if (res == 'rename') {
    //   await P.conversation.rename(conversation.createdAtUS);
    // } else if (res == 'delete') {
    //   await P.conversation.delete(conversation.createdAtUS);
    // }

    if (!context.mounted) {
      return;
    }

    switch (res) {
      case 'rename':
        await P.conversation.onRenameClicked(context, conversation);
      case 'delete':
        await P.conversation.onDeleteClicked(context, conversation);
      case 'export':
        await P.conversation.onExportClicked(context, conversation);
      default:
        break;
    }

    P.conversation.interactingCreatedAtUS.q = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final currentCreatedAtUS = ref.watch(P.conversation.currentCreatedAtUS);
    final interactingCreatedAtUS = ref.watch(P.conversation.interactingCreatedAtUS);
    final isCurrent = currentCreatedAtUS == conversation.createdAtUS;
    final shouldDim = interactingCreatedAtUS != null && interactingCreatedAtUS != conversation.createdAtUS;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
    final qb = ref.watch(P.app.qb);
    final customTheme = ref.watch(P.app.customTheme);

    return Material(
      color: customTheme.scaffold,
      child: GD(
        onLongPressStart: (details) => _onLongPressStart(details, context),
        onTap: _onTap,
        child: AnimatedOpacity(
          opacity: shouldDim ? 0.2 : 1,
          duration: const Duration(milliseconds: 200),
          child: C(
            decoration: BD(
              color: isCurrent ? primaryContainer : customTheme.scaffold,
              borderRadius: 8.r,
            ),
            child: Stack(
              children: [
                C(
                  padding: const EI.a(8),
                  child: T(
                    conversation.title,
                    s: TS(s: 16, w: FW.w600, c: isCurrent ? primary : qb),
                    overflow: TextOverflow.ellipsis,
                    // maxLines: 10,
                  ),
                ),
                if (kDebugMode)
                  IgnorePointer(
                    child: T(
                      conversation.createdAtUS.toString(),
                      s: TS(s: 10, c: kCR.q(.5)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderWrapper extends ConsumerWidget {
  const _HeaderWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final paddingTop = ref.watch(P.app.paddingTop);
    return Material(
      color: kC,
      child: Column(
        children: [
          (paddingTop + 12).h,
          Row(
            mainAxisAlignment: MAA.start,
            children: [
              12.w,
              T(s.chat_history),
            ],
          ),
          8.h,
          Expanded(child: child),
        ],
      ),
    );
  }
}
