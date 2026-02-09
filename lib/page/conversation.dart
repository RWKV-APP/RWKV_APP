import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:zone/func/open_folder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart' show RoleplayManage;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/conversation_item.dart';

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
  List<ConversationListItemData> roleplayConversations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateRolePlayConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(_compositedConversations);
    final isEmpty = conversations.isEmpty;
    final isBatchMode = ref.watch(P.conversation.isBatchMode);

    return Scaffold(
      body: Column(
        children: [
          const _ConversationAppBar(),
          isEmpty ? const Expanded(child: _EmptyState()) : const Expanded(child: _ConversationList()),
          if (isBatchMode) const _BatchActionBar(),
        ],
      ),
    );
  }

  Widget buildConversationItem(ConversationListItemData item, int index) {
    return Dismissible(
      key: Key(item.id.toString()),
      background: Container(
        color: Colors.redAccent,
        padding: const .only(right: 24),
        alignment: .centerRight,
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

class _ConversationAppBar extends ConsumerWidget {
  const _ConversationAppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(P.app.theme);
    final isBatchMode = ref.watch(P.conversation.isBatchMode);
    final selectedConversations = ref.watch(P.conversation.selectedConversations);
    final selectedCount = selectedConversations.length;
    final conversations = ref.watch(P.conversation.conversations);
    final isEmpty = conversations.isEmpty;
    final isDesktop = ref.watch(P.app.isDesktop);
    final s = S.of(context);

    return AppBar(
      title: isBatchMode ? Text(s.selected_count(selectedCount)) : Text(s.conversations),
      backgroundColor: Colors.transparent,
      systemOverlayStyle: theme.isLight ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark,
      primary: true,
      actions: [
        if (isDesktop && !isBatchMode)
          IconButton(
            onPressed: _openDatabaseFolder,
            icon: const FaIcon(FontAwesomeIcons.folderOpen, size: 18),
            tooltip: s.open_database_folder,
          ),
        if (!isBatchMode)
          IconButton(
            onPressed: _handleNewChat,
            icon: const FaIcon(FontAwesomeIcons.squarePlus),
          ),
        if (!isEmpty && !isBatchMode)
          TextButton(
            onPressed: () => P.conversation.toggleBatchMode(),
            child: Text(s.conversation_management),
          ),
        if (isBatchMode)
          TextButton(
            onPressed: selectedCount == conversations.length
                ? () => P.conversation.clearSelection()
                : () => P.conversation.selectAllConversations(),
            child: Text(
              selectedCount == conversations.length ? s.cancel_all_selection : s.select_all,
            ),
          ),
        if (isBatchMode)
          TextButton(
            onPressed: () => P.conversation.toggleBatchMode(),
            child: Text(s.cancel),
          ),
      ],
    );
  }

  Future<void> _handleNewChat() async {
    await P.chat.startNewChat();
    push(.chat);
  }

  Future<void> _openDatabaseFolder() async {
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final dbPath = appSupportDir.path;
      await openFolder(dbPath);
    } catch (e) {
      qqe(e);
    }
  }
}

class _ConversationList extends ConsumerWidget {
  const _ConversationList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(_compositedConversations);
    return ListView.separated(
      padding: const .only(bottom: 60),
      itemCount: conversations.length,
      cacheExtent: 200,
      physics: const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const _ConversationSeparator(),
      itemBuilder: (context, index) => _ConversationDismissible(conversation: conversations[index]),
    );
  }
}

class _ConversationSeparator extends StatelessWidget {
  const _ConversationSeparator();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0,
      indent: 68,
      endIndent: 12,
      color: Theme.of(context).dividerColor.q(.2),
    );
  }
}

class _ConversationDismissible extends ConsumerWidget {
  final ConversationListItemData conversation;

  const _ConversationDismissible({required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBatchMode = ref.watch(P.conversation.isBatchMode);
    if (isBatchMode) return ConversationItem(conversation: conversation);
    return Dismissible(
      key: ValueKey(conversation.id),
      background: const _DismissBackground(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _confirmDismiss(context, direction),
      onDismissed: (direction) => _handleDismiss(context, direction),
      child: ConversationItem(conversation: conversation),
    );
  }

  Future<bool?> _confirmDismiss(BuildContext context, DismissDirection direction) async {
    final s = S.of(context);

    final result = await showOkCancelAlertDialog(
      context: context,
      title: s.delete_conversation,
      message: s.delete_conversation_message,
      okLabel: s.delete,
      cancelLabel: s.cancel,
      isDestructiveAction: true,
    );

    return result == OkCancelResult.ok;
  }

  Future<void> _handleDismiss(BuildContext context, DismissDirection direction) async {
    if (conversation.isRoleplay) {
      await RoleplayManage.deleteRolePlaySession(conversation.roleName!);
    } else {
      await P.conversation.onDeleteClicked(context, conversation.conv!);
    }
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      padding: const .only(right: 24),
      alignment: .centerRight,
      child: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.white),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Column(
      mainAxisAlignment: .center,
      children: [
        Text(
          s.no_conversations_yet,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        _NewChatButton(),
      ],
    );
  }
}

class _NewChatButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return FilledButton.icon(
      onPressed: _handleNewChat,
      label: Text(s.new_conversation),
      icon: const FaIcon(FontAwesomeIcons.plus),
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(
          .symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _handleNewChat() async {
    await P.chat.startNewChat();
    push(.chat);
  }
}

class _BatchActionBar extends ConsumerWidget {
  const _BatchActionBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final selectedConversations = ref.watch(P.conversation.selectedConversations);
    final selectedCount = selectedConversations.length;
    final hasSelection = selectedConversations.isNotEmpty;
    final theme = Theme.of(context);

    return Container(
      padding: const .symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.q(.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '已选择: $selectedCount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: .w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: hasSelection ? () => _handleDelete(context) : null,
              icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16),
              label: Text(s.delete),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    await P.conversation.deleteSelectedConversations(context);
  }
}
