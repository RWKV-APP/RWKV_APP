// ignore: unused_import
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/conversation.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/pager.dart';

class ConversationList extends ConsumerWidget {
  const ConversationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    qq;
    final conversations = ref.watch(P.conversation.sorted);

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        P.app.hapticLight();
        await P.conversation.load();
      },
      child: ListView.builder(
        padding: const EI.a(8),
        itemCount: conversations.isEmpty ? 1 : conversations.length,
        itemBuilder: (context, index) {
          if (conversations.isEmpty) {
            return const _Empty();
          }
          final conversation = conversations[index];
          return _Item(conversation: conversation);
        },
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  void _onPressed() {
    Pager.toggle();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    return Column(
      mainAxisAlignment: MAA.center,
      crossAxisAlignment: CAA.stretch,
      children: [
        IconButton(
          onPressed: _onPressed,
          icon: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CAA.center,
            children: [
              const Icon(Icons.add),
              T(s.new_chat, s: const TS(s: 20)),
              T(s.create_a_new_one_by_clicking_the_button_above, s: TS(s: 10, c: qb.q(.5))),
            ],
          ),
        ),
      ],
    );
  }
}

class _Item extends ConsumerWidget {
  const _Item({required this.conversation});

  final Conversation conversation;

  void _onTap() async {
    await P.conversation.onTapInList(conversation);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final current = ref.watch(P.conversation.current);
    final isCurrent = current?.id == conversation.id;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);
    return CupertinoContextMenu(
      actions: [
        CupertinoContextMenuAction(
          child: T(s.delete),
          onPressed: () {},
        ),
      ],
      enableHapticFeedback: true,
      child: Material(
        color: qw,
        child: GD(
          onTap: _onTap,
          child: C(
            decoration: BD(
              color: isCurrent ? primaryContainer : qw,
              borderRadius: 8.r,
            ),
            padding: const EI.a(8),
            child: T(
              conversation.name,
              s: TS(s: 16, w: FW.w600, c: isCurrent ? primary : qb),
            ),
          ),
        ),
      ),
    );
  }
}
