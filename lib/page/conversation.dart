// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';

// Project imports:
import 'package:zone/func/debug_trace.dart';
import 'package:zone/func/open_folder.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/app_presentation.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat_history_width_limit.dart';
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
  final data = <ConversationListItemData>[];
  for (final rs in roleplaySessions) {
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
    final theme = Theme.of(context);
    final _ = theme;
    final conversations = ref.watch(_compositedConversations);
    final isEmpty = conversations.isEmpty;
    final isBatchMode = ref.watch(P.conversation.isBatchMode);
    final appTheme = ref.watch(P.app.theme);
    final presentation = AppPresentation.forStyle(ref.watch(P.preference.appStyle));
    if (presentation != null) {
      final contents = Column(
        children: [
          Expanded(child: isEmpty ? const _EmptyState() : const _ConversationList()),
          if (isBatchMode) const ChatHistoryWidthLimit(child: _BatchActionBar()),
        ],
      );
      final colors = theme.colorScheme;
      final workspace = presentation.workspace;
      const header = _ConversationAppBar(themed: true);
      return Scaffold(
        backgroundColor: appTheme.settingBg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: presentation.readingWidth),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if ((workspace == .split || workspace == .console) && constraints.maxWidth >= 800) {
                    return Row(
                      crossAxisAlignment: .stretch,
                      children: [
                        SizedBox(
                          width: 248,
                          child: ColoredBox(color: colors.surfaceContainerLow, child: header),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: contents),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      header,
                      Expanded(
                        child: workspace == .framed
                            ? Padding(
                                padding: const .fromLTRB(12, 0, 12, 12),
                                child: Material(
                                  color: colors.surfaceContainerLowest,
                                  borderRadius: const .all(Radius.circular(16)),
                                  clipBehavior: .antiAlias,
                                  child: contents,
                                ),
                              )
                            : contents,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: appTheme.settingBg,
      body: Column(
        children: [
          const ChatHistoryWidthLimit(child: _ConversationAppBar()),
          isEmpty ? const Expanded(child: ChatHistoryWidthLimit(child: _EmptyState())) : const Expanded(child: _ConversationList()),
          if (isBatchMode) const ChatHistoryWidthLimit(child: _BatchActionBar()),
        ],
      ),
    );
  }
}

class _ConversationAppBar extends ConsumerWidget {
  const _ConversationAppBar({this.themed = false});

  final bool themed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(P.app.theme);
    final isBatchMode = ref.watch(P.conversation.isBatchMode);
    final selectedConversations = ref.watch(P.conversation.selectedConversations);
    final selectedCount = selectedConversations.length;
    final conversations = ref.watch(P.conversation.conversations);
    final isDesktop = ref.watch(P.app.isDesktop);
    final s = S.of(context);

    final title = isBatchMode ? s.selected_count(selectedCount) : s.conversations;
    final leading = isBatchMode
        ? TextButton(
            onPressed: () => P.conversation.toggleBatchMode(),
            child: Text(s.cancel),
          )
        : IconButton(
            onPressed: () => P.conversation.toggleBatchMode(),
            // child: Text(s.conversation_management),
            icon: const Icon(Icons.list),
            tooltip: s.conversation_management,
          );
    final actions = [
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
          tooltip: themed ? s.new_conversation : null,
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
    ];
    if (themed) {
      final textTheme = Theme.of(context).textTheme;
      return Padding(
        padding: const .fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(title, style: textTheme.headlineSmall),
            Wrap(crossAxisAlignment: .center, children: [leading, ...actions]),
            Container(height: .5, color: Theme.of(context).colorScheme.outlineVariant),
          ],
        ),
      );
    }
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.transparent,
      systemOverlayStyle: theme.isLight ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark,
      primary: true,
      automaticallyImplyLeading: false,
      centerTitle: true,
      leading: leading,
      leadingWidth: isBatchMode ? 80 : null,
      actions: actions,
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
    final theme = Theme.of(context);
    final _ = theme;
    final conversations = ref.watch(_compositedConversations);
    final appTheme = ref.watch(P.app.theme);
    final paddingBottom = ref.watch(P.app.paddingBottom);
    final useBottomTabBar = ref.watch(P.app.useBottomTabBar);
    final isClassic = ref.watch(P.preference.appStyle).isClassic;
    final tabBarReservedHeight = useBottomTabBar && isClassic ? appTheme.tabBarHeight : 0.0;
    return ListView.separated(
      padding: .only(bottom: max(paddingBottom, 12) + tabBarReservedHeight + 12),
      itemCount: conversations.length,
      scrollCacheExtent: const ScrollCacheExtent.pixels(200),
      physics: const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const ChatHistoryWidthLimit(child: _ConversationSeparator()),
      itemBuilder: (context, index) {
        return ChatHistoryWidthLimit(
          child: _ConversationDismissible(conversation: conversations[index]),
        );
      },
    );
  }
}

class _ConversationSeparator extends StatelessWidget {
  const _ConversationSeparator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: .5,
      margin: const .only(left: 68),
      color: theme.dividerColor.withValues(alpha: .2),
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
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final paddingBottom = ref.watch(P.app.paddingBottom);
    final selectedConversations = ref.watch(P.conversation.selectedConversations);
    final selectedCount = selectedConversations.length;
    final hasSelection = selectedConversations.isNotEmpty;
    final useBottomTabBar = ref.watch(P.app.useBottomTabBar);
    final isClassic = ref.watch(P.preference.appStyle).isClassic;
    final tabBarReservedHeight = useBottomTabBar && isClassic ? appTheme.tabBarHeight : 0.0;

    final bottomReserved = max(paddingBottom, 12) + tabBarReservedHeight + 24;

    return Container(
      padding: .only(
        left: 16,
        right: 16,
        top: 12,
        bottom: bottomReserved,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: .2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.selected_count(selectedCount),
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
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    await P.conversation.deleteSelectedConversations(context);
  }
}
