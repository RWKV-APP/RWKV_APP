import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart' show RoleplayManage;
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/conversation_item.dart';

const String _chatAi3LineSvg = r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M12 1.99996C12.8632 1.99996 13.701 2.10973 14.5 2.31539L14 4.25192C13.3608 4.0874 12.6906 3.99997 12 3.99997C7.58174 3.99997 4.00002 7.58172 4 12C4 13.3344 4.3255 14.6174 4.93945 15.7656L5.28906 16.4189L4.63379 19.3662L7.58105 18.7109L8.23438 19.0605C9.38255 19.6745 10.6656 20 12 20C16.4183 20 20 16.4183 20 12C20 11.6771 19.9805 11.3587 19.9434 11.0459L21.9297 10.8095C21.976 11.1999 22 11.5972 22 12C22 17.5228 17.5228 22 12 22C10.2975 22 8.69425 21.5746 7.29102 20.8242L2 22L3.17578 16.709C2.42541 15.3057 2 13.7025 2 12C2.00002 6.47714 6.47717 1.99996 12 1.99996ZM19.5293 1.3193C19.7058 0.893513 20.2942 0.8935 20.4707 1.3193L20.7236 1.93063C21.1555 2.97343 21.9615 3.80614 22.9746 4.2568L23.6914 4.57614C24.1022 4.75882 24.1022 5.35635 23.6914 5.53903L22.9326 5.87692C21.945 6.3162 21.1534 7.11943 20.7139 8.1279L20.4668 8.69333C20.2863 9.10747 19.7136 9.10747 19.5332 8.69333L19.2861 8.1279C18.8466 7.11942 18.0551 6.3162 17.0674 5.87692L16.3076 5.53903C15.8974 5.35618 15.8974 4.75895 16.3076 4.57614L17.0254 4.2568C18.0384 3.80614 18.8445 2.97343 19.2764 1.93063L19.5293 1.3193Z"></path></svg>
''';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
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
        child: const Icon(RemixIcon.deleteBinLine, color: Colors.white, size: 20),
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
    final theme = ref.watch(P.app.customTheme);
    final isBatchMode = ref.watch(P.conversation.isBatchMode);
    final selectedConversations = ref.watch(P.conversation.selectedConversations);
    final selectedCount = selectedConversations.length;
    final conversations = ref.watch(P.conversation.conversations);
    final isEmpty = conversations.isEmpty;
    final isDesktop = ref.watch(P.app.isDesktop);
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black;

    return AppBar(
      centerTitle: true, // iOS style centered title
      title: Text(
        isBatchMode ? s.selected_count(selectedCount) : s.conversations,
        style: const TextStyle(
          fontSize: 17, // iOS Navigation Bar Title
          fontWeight: .w600,
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: theme.light ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark,
      primary: true,
      leading: isBatchMode
          ? TextButton(
              onPressed: selectedCount == conversations.length
                  ? () => P.conversation.clearSelection()
                  : () => P.conversation.selectAllConversations(),
              child: Text(
                selectedCount == conversations.length ? s.cancel_all_selection : s.select_all,
                style: TextStyle(
                  fontSize: 15, // Smaller than title
                  color: textColor,
                ),
              ),
            )
          : (!isEmpty
              ? TextButton(
                  onPressed: () => P.conversation.toggleBatchMode(),
                  child: Text(
                    s.conversation_management,
                    style: TextStyle(
                      fontSize: 15, // Smaller than title
                      color: textColor,
                    ),
                  ),
                )
              : null),
      leadingWidth: 80,
      actions: [
        if (isDesktop && !isBatchMode)
          IconButton(
            onPressed: _openDatabaseFolder,
            icon: Icon(RemixIcon.folderOpenLine, size: 20, color: textColor),
            tooltip: s.open_database_folder,
          ),
        if (!isBatchMode)
          IconButton(
            onPressed: _handleNewChat,
            icon: SvgPicture.string(
              _chatAi3LineSvg,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
            ),
          ),
        if (isBatchMode)
          TextButton(
            onPressed: () => P.conversation.toggleBatchMode(),
            child: Text(
              s.cancel,
              style: TextStyle(
                fontSize: 15, // Smaller than title
                color: textColor,
              ),
            ),
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

      if (Platform.isMacOS) {
        await Process.run('open', [dbPath]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [dbPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [dbPath]);
      }
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
      padding: const .only(bottom: 100),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 56,
      endIndent: 0,
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA), // Lighter separator
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
      color: const Color(0xFFFF3B30), // Apple Red
      padding: const .only(right: 24),
      alignment: .centerRight,
      child: const Icon(RemixIcon.deleteBinLine, color: Colors.white, size: 20),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: .center,
      children: [
        Text(
          s.no_conversations_yet,
          style: TextStyle(
            fontSize: 17, // iOS Body
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93), // Apple Gray
          ),
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
      icon: SvgPicture.string(
        _chatAi3LineSvg,
        width: 16,
        height: 16,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF007AFF), // Apple Blue
        foregroundColor: Colors.white,
        padding: const .symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: .circular(12)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: .w600),
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
    final selectedConversations = ref.watch(P.conversation.selectedConversations);
    final hasSelection = selectedConversations.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const .symmetric(horizontal: 16, vertical: 12),
      margin: const .only(bottom: 80),
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: .end,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasSelection
                    ? const Color(0xFFFF3B30) // Apple Red
                    : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6)),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: hasSelection ? () => _handleDelete(context) : null,
                icon: const Icon(RemixIcon.deleteBinLine, size: 20, color: Colors.white),
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
