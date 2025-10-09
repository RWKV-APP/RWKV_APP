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
import 'package:zone/widgets/conversation_item.dart';

class PageConversation extends ConsumerStatefulWidget {
  const PageConversation({super.key});

  @override
  ConsumerState<PageConversation> createState() => _PageConversationState();
}

class _PageConversationState extends ConsumerState<PageConversation> {
  late final ScrollController _scrollController;
  int _appBarAlpha = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    P.conversation.load();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      final alpha = (offset * 0.5).clamp(0, 255).toInt();
      if (alpha != _appBarAlpha) {
        setState(() => _appBarAlpha = alpha);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(P.conversation.conversations);
    final isEmpty = conversations.isEmpty;

    return AppScaffold(
      body: Column(
        children: [
          _ConversationAppBar(alpha: _appBarAlpha),
          isEmpty ? const Expanded(child: _EmptyState()) : Expanded(child: _ConversationList()),
        ],
      ),
    );
  }
}

class _ConversationAppBar extends ConsumerWidget {
  const _ConversationAppBar({required this.alpha});

  final int alpha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(P.app.customTheme);

    return AppBar(
      title: Text(S.of(context).conversations),
      backgroundColor: Colors.transparent,
      systemOverlayStyle: theme.light ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark,
      primary: true,
      actions: [
        IconButton(
          onPressed: _handleNewChat,
          icon: const FaIcon(FontAwesomeIcons.squarePlus),
        ),
      ],
    );
  }

  Future<void> _handleNewChat() async {
    await P.chat.startNewChat();
    push(PageKey.chat);
  }
}

class _ConversationList extends ConsumerWidget {
  const _ConversationList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(P.conversation.conversations);
    return ListView.separated(
      controller: context.findAncestorStateOfType<_PageConversationState>()?._scrollController,
      padding: const EdgeInsets.only(bottom: 60),
      itemCount: conversations.length,
      cacheExtent: 200,
      separatorBuilder: (context, index) => _ConversationSeparator(),
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

class _ConversationDismissible extends StatelessWidget {
  const _ConversationDismissible({required this.conversation});

  final ConversationData conversation;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(conversation.createdAtUS),
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
    await P.conversation.onDeleteClicked(context, conversation);
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      padding: const EdgeInsets.only(right: 24),
      alignment: Alignment.centerRight,
      child: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.white),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          S.of(context).no_conversations_yet,
          style: const TextStyle(fontSize: 16),
        ),
        16.h,
        _NewChatButton(),
      ],
    );
  }
}

class _NewChatButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _handleNewChat,
      label: Text(S.of(context).new_conversation),
      icon: const FaIcon(FontAwesomeIcons.plus),
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _handleNewChat() async {
    await P.chat.startNewChat();
    push(PageKey.chat);
  }
}
