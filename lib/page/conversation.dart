import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
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
        setState(() {
          appBarAlpha = alpha;
        });
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
    final conversations = ref.watch(P.conversation.conversations);
    final isEmpty = conversations.isEmpty;

    return AppScaffold(
      body: CustomScrollView(
        controller: controller,
        slivers: [
          SliverAppBar(
            title: const Text('Conversation'),
            // backgroundColor: P.app.qw.q.withAlpha(appBarAlpha),
            floating: true,
            pinned: true,
            primary: true,
            actions: [
              IconButton(
                onPressed: () async {
                  await P.chat.startNewChat();
                  push(PageKey.chat);
                },
                icon: FaIcon(FontAwesomeIcons.squarePlus),
              ),
            ],
          ),
          if (isEmpty) SliverFillRemaining(child: _Empty()),
          if (!isEmpty)
            SliverList.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index % conversations.length];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.only(top: index == 0 ? 12 : 8, left: 12, right: 12),
                  child: Dismissible(
                    key: Key(conversation.createdAtUS.toString()),
                    background: Container(
                      color: Colors.red,
                      padding: const EdgeInsets.only(right: 24),
                      alignment: Alignment.centerRight,
                      child: FaIcon(FontAwesomeIcons.trashCan, color: Colors.white),
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
              },
            ),
          if (!isEmpty) const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
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
        Text('No Conversations Yet', style: TextStyle(fontSize: 16)),
        16.h,
        FilledButton(onPressed: _onPressed, child: Text('New Conversation')),
      ],
    );
  }
}
