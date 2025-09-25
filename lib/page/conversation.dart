import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart' show RoleplayManage;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/app_scaffold.dart';
import 'package:zone/widgets/chat/conversation_list.dart';

final _roleplayConvList = qs<List<ConversationListItemData>>([]);

final _compositedConversations = qp<List<ConversationListItemData>>((ref) {
  qqq('updating');
  final chat = ref.watch(P.conversation.conversations).map((e) => ConversationListItemData.fromConv(e));
  final roleplay = ref.watch(_roleplayConvList);
  final composed = [...chat, ...roleplay];
  composed.sort((a, b) => b.sortKey.compareTo(a.sortKey));
  return composed;
});

void updateRolePlayConversations() async {
  qqq('load role play conversation list');
  final roleplaySessions = await RoleplayManage.getRolePlayListSession();
  List<ConversationListItemData> data = [];
  for (var rs in roleplaySessions) {
    data.add(ConversationListItemData.fromRoleplay(rs.values.first, rs.keys.first));
  }
  _roleplayConvList.q = data;
}

class PageConversation extends ConsumerStatefulWidget {
  const PageConversation({super.key});

  @override
  ConsumerState<PageConversation> createState() => _PageConversationState();
}

class _PageConversationState extends ConsumerState<PageConversation> {
  final ScrollController controller = ScrollController();
  int appBarAlpha = 0;
  List<ConversationListItemData> roleplayConversations = [];

  @override
  void initState() {
    super.initState();

    P.conversation.load();

    controller.addListener(() {
      final offset = controller.offset;
      final alpha = offset.clamp(0, 255).toInt();
      if (alpha != appBarAlpha) {
        appBarAlpha = alpha;
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateRolePlayConversations();
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
    final conversations = ref.watch(_compositedConversations);
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
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 60),
                itemCount: conversations.length,
                separatorBuilder: (context, index) {
                  return Divider(
                    height: 0,
                    indent: 68,
                    endIndent: 12,
                    color: Theme.of(context).dividerColor.q(.2),
                  );
                },
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

  Widget buildConversationItem(ConversationListItemData item, int index) {
    return Dismissible(
      key: Key(item.id),
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
        if (item.isRoleplay) {
          await RoleplayManage.deleteRolePlaySession(item.roleName!);
          return;
        }
        await P.conversation.onDeleteClicked(context, item.conv!);
      },
      child: ConversationItem(conversation: item),
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
        Text(S.of(context).no_conversations_yet, style: const TextStyle(fontSize: 16)),
        16.h,
        FilledButton.icon(
          onPressed: _onPressed,
          label: Text(S.of(context).new_conversation),
          icon: const FaIcon(FontAwesomeIcons.plus),
          style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
        ),
      ],
    );
  }
}
