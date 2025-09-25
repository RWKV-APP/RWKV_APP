// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_roleplay/flutter_roleplay.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:sprintf/sprintf.dart';
import 'package:zone/db/db.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';

class ConversationListItemData {
  final String id;
  final String? avatar;
  final ConversationData? conv;
  final String? roleName;

  final String title;
  final String subtitle;
  final String displayTime;
  final int sortKey;

  bool get isRoleplay => roleName != null;

  static final _today = DateTime.now().copyWith(hour: 23, minute: 59);

  ConversationListItemData({
    required this.id,
    required this.sortKey,
    required this.title,
    required this.subtitle,
    required this.displayTime,
    this.avatar,
    this.conv,
    this.roleName,
  });

  static ConversationListItemData fromConv(ConversationData cov) {
    return ConversationListItemData(
      conv: cov,
      sortKey: cov.updatedAtUS ?? cov.createdAtUS,
      id: cov.createdAtUS.toString(),
      title: cov.title,
      subtitle: cov.subtitle ?? '-',
      displayTime: getDisplayTime(cov.updatedAtUS ?? cov.createdAtUS),
    );
  }

  static ConversationListItemData fromRoleplay(ChatMessage cm, String avatar) {
    return ConversationListItemData(
      sortKey: cm.timestamp.microsecondsSinceEpoch,
      id: cm.timestamp.microsecondsSinceEpoch.toString(),
      avatar: avatar,
      title: cm.roleName,
      subtitle: cm.content,
      roleName: cm.roleName,
      displayTime: getDisplayTime(cm.timestamp.microsecondsSinceEpoch),
    );
  }

  static String getDisplayTime(int microsecondsSinceEpoch) {
    final datetime = DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch);
    String showTime = sprintf('%02d:%02d', [datetime.hour, datetime.minute]);
    final diff = datetime.difference(_today);
    final span = diff.inDays;
    if (span == 0) {
      showTime = showTime;
    } else {
      showTime = sprintf('%02d-%02d', [datetime.month, datetime.day]);
    }
    return showTime;
  }
}

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
            return ConversationItem(conversation: ConversationListItemData.fromConv(conversation));
          },
        ),
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  void _onPressed() {
    if (!checkModelSelection()) return;
    push(PageKey.chat);
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

class ConversationItem extends ConsumerWidget {
  const ConversationItem({super.key, required this.conversation});

  final ConversationListItemData conversation;

  void _onTap(BuildContext context) async {
    if (conversation.isRoleplay) {
      push(PageKey.rolePlaying, extra: {'roleName': conversation.roleName!});
      return;
    }
    await P.conversation.onTapInList(conversation.conv!);
  }

  void _onLongPressStart(LongPressStartDetails details, BuildContext context) async {
    // 在长按开始时显示菜单
    if (conversation.isRoleplay) {
      return;
    }

    P.conversation.interactingCreatedAtUS.q = conversation.conv!.createdAtUS;

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
        MediaQuery.sizeOf(context).width - details.globalPosition.dx,
        // 菜单的右侧位置 (这里只是一个占位符，实际会根据菜单宽度调整)
        MediaQuery.sizeOf(context).height - details.globalPosition.dy, // 菜单的底部位置
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SizedBox(
                width: 8,
              ),
              Text(s.rename),
            ],
          ),
        ),
        const PopupMenuDivider(indent: 8, endIndent: 8),
        PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              const Icon(Icons.download_outlined),
              const SizedBox(
                width: 8,
              ),
              Text(s.export_data),
            ],
          ),
        ),
        const PopupMenuDivider(indent: 8, endIndent: 8),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline),
              const SizedBox(
                width: 8,
              ),
              Text(s.delete_conversation),
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
        await P.conversation.onRenameClicked(context, conversation.conv!);
      case 'delete':
        await P.conversation.onDeleteClicked(context, conversation.conv!);
      case 'export':
        await P.conversation.onExportClicked(context, conversation.conv!);
      default:
        break;
    }

    P.conversation.interactingCreatedAtUS.q = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    final color = P.conversation.getConversationColor(conversation.sortKey);
    return Material(
      child: GestureDetector(
        onLongPressStart: (details) => _onLongPressStart(details, context),
        child: InkWell(
          onTap: () => _onTap(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 40,
                    width: 40,
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: buildAvatar(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CAA.stretch,
                    children: [
                      T(
                        conversation.title,
                        s: TS(s: 16, w: FontWeight.w500, c: qb),
                        overflow: TextOverflow.ellipsis,
                      ),
                      4.h,
                      T(
                        conversation.subtitle ?? '-',
                        s: const TS(s: 12, c: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(conversation.displayTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAvatar() {
    if (conversation.avatar == null) {
      return const FaIcon(FontAwesomeIcons.message, size: 16, color: Colors.white);
    }
    if (!conversation.avatar!.startsWith('http')) {
      return Image.asset(conversation.avatar!, height: 40, width: 40);
    }
    return Image.network(conversation.avatar!, fit: BoxFit.cover, height: 40, width: 40);
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
