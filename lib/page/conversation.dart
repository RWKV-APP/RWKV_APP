import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:zone/db/db.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/app_scaffold.dart';
import 'package:zone/widgets/chat/conversation_list.dart';

class PageConversation extends ConsumerStatefulWidget {
  const PageConversation({super.key});

  @override
  ConsumerState<PageConversation> createState() => _PageConversationState();
}

class _PageConversationState extends ConsumerState<PageConversation> {
  final ScrollController controller = ScrollController();
  int appBarAlpha = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      final offset = controller.offset;
      final alpha = offset.clamp(0, 255).toInt();
      if (alpha != appBarAlpha) {
        appBarAlpha = alpha;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(P.app.customTheme);
    final conversations = ref.watch(P.conversation.conversations);
    final isEmpty = conversations.isEmpty;

    return AppScaffold(
      body: Column(
        children: [
          AppBar(
            title: Text(S.of(context).conversations),
            backgroundColor: Colors.transparent,
            // backgroundColor: P.app.qw.q.withAlpha(appBarAlpha),
            systemOverlayStyle: theme.light ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark,
            // floating: true,
            // pinned: true,
            primary: true,
            actions: [
              IconButton(
                onPressed: () async {
                  await P.chat.startNewChat();
                  push(PageKey.chat);
                },
                icon: const FaIcon(FontAwesomeIcons.squarePlus),
              ),
            ],
          ),

          if (isEmpty) const Expanded(child: _Empty()),
          if (!isEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 60),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index % conversations.length];
                  return buildConversationItem(conversation, index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget buildConversationItem(ConversationData conversation, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(top: 8, left: 12, right: 12),
      child: Dismissible(
        key: Key(conversation.createdAtUS.toString()),
        background: Container(
          color: Colors.redAccent,
          padding: const EdgeInsets.only(right: 24),
          alignment: Alignment.centerRight,
          child: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (d) async {
          final s = S.of(context);
          final res = await showOkCancelAlertDialog(
            context: context,
            title: s.delete_conversation,
            message: s.delete_conversation_message,
            okLabel: s.delete,
            cancelLabel: s.cancel,
            isDestructiveAction: true,
          );
          return res == OkCancelResult.ok;
        },
        onDismissed: (d) async {
          await P.conversation.onDeleteClicked(context, conversation);
        },
        child: ConversationItem(conversation: conversation),
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  void _onPressed() async {
    P.chat.startNewChat();
    push(PageKey.chat);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        const Text('No Conversations Yet', style: TextStyle(fontSize: 16)),
        16.h,
        FilledButton.icon(
          onPressed: _onPressed,
          label: const Text('New Conversation'),
          icon: const FaIcon(FontAwesomeIcons.plus),
          style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
        ),
      ],
    );
  }
}
