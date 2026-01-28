// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_roleplay/models/chat_message_model.dart' show ChatMessage;
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';
import 'package:sprintf/sprintf.dart';
import 'package:zone/config.dart';
import 'package:zone/db/db.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ConversationListItemData {
  final int id;
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
      id: cov.createdAtUS,
      title: _processTitle(cov.title),
      subtitle: cov.subtitle ?? '-',
      displayTime: getDisplayTime(cov.updatedAtUS ?? cov.createdAtUS),
    );
  }

  factory ConversationListItemData.empty() {
    return ConversationListItemData(
      id: 0,
      sortKey: 0,
      title: 'A',
      subtitle: 'BB' * 100,
      displayTime: '',
    );
  }

  static ConversationListItemData fromRoleplay(ChatMessage cm, String avatar) {
    return ConversationListItemData(
      sortKey: cm.timestamp.microsecondsSinceEpoch,
      id: cm.timestamp.microsecondsSinceEpoch,
      avatar: avatar,
      title: _processTitle(cm.roleName),
      subtitle: cm.content,
      roleName: cm.roleName,
      displayTime: getDisplayTime(cm.timestamp.microsecondsSinceEpoch),
    );
  }

  static String _processTitle(String title) {
    String processed = title.replaceAll(Config.userMsgModifierSep, '').trim();
    processed = processed.replaceAll(
        Config.userMsgModifierSep.substring(0, Config.userMsgModifierSep.length - 1),
        '');
    return processed;
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

class ConversationItem extends ConsumerWidget {
  const ConversationItem({super.key, required this.conversation});

  final ConversationListItemData conversation;

  void _onTap(BuildContext context) async {
    if (conversation.isRoleplay) {
      push(.rolePlaying, extra: {'roleName': conversation.roleName!});
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 使用showMenu在特定位置显示菜单
    final res = await showMenu<String>(
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12), // iOS corner radius
      ),
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
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
          height: 44,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20, color: isDark ? Colors.white : Colors.black),
              const SizedBox(width: 12),
              Text(s.rename, style: const TextStyle(fontSize: 17)),
            ],
          ),
        ),
        PopupMenuDivider(height: 1, color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8)),
        PopupMenuItem(
          value: 'export',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.download_outlined, size: 20, color: isDark ? Colors.white : Colors.black),
              const SizedBox(width: 12),
              Text(s.export_data, style: const TextStyle(fontSize: 17)),
            ],
          ),
        ),
        PopupMenuDivider(height: 1, color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8)),
        PopupMenuItem(
          value: 'delete',
          height: 44,
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 20, color: Color(0xFFFF3B30)), // Apple Red
              const SizedBox(width: 12),
              Text(s.delete_conversation, style: const TextStyle(fontSize: 17, color: Color(0xFFFF3B30))),
            ],
          ),
        ),
      ],
      elevation: 4.0,
    );

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = P.conversation.getConversationColor(conversation.id);
    final isBatchMode = ref.watch(P.conversation.isBatchMode);
    final isSelected = ref.watch(P.conversation.selectedConversations).contains(conversation.id);

    return GestureDetector(
      onTap: isBatchMode ? () => _handleBatchSelection() : () => _onTap(context),
      onLongPressStart: isBatchMode ? null : (details) => _onLongPressStart(details, context),
      child: Container(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        padding: const .symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: .center,
          children: [
            isBatchMode ? _buildSelectionCircle(isSelected) : _buildAvatar(color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.title,
                          style: TextStyle(
                            fontSize: 17, // iOS Body
                            fontWeight: .w600, // Semibold for title
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          overflow: .ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        conversation.displayTime,
                        style: TextStyle(
                          fontSize: 13, // Smaller time
                          fontWeight: .w400,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93), // Apple Gray
                        ),
                      ),
                      if (!isBatchMode) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: isDark ? const Color(0xFF48484A) : const Color(0xFFC7C7CC), // Apple Gray 3
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.subtitle,
                    style: TextStyle(
                      fontSize: 15, // iOS Subhead
                      fontWeight: .w400,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93), // Apple Gray
                    ),
                    overflow: .ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCircle(bool isSelected) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
        border: Border.all(
          color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFC7C7CC),
          width: isSelected ? 0 : 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : null,
    );
  }

  Widget _buildAvatar(Color color) {
    if (conversation.avatar == null) {
      return Icon(RemixIcon.message3Line, size: 28, color: color);
    }
    if (!conversation.avatar!.startsWith('http')) {
      return ClipRRect(
        borderRadius: .circular(8),
        child: Image.asset(conversation.avatar!, height: 44, width: 44, fit: BoxFit.cover),
      );
    }
    return ClipRRect(
      borderRadius: .circular(8),
      child: CachedNetworkImage(imageUrl: conversation.avatar!, fit: BoxFit.cover, height: 44, width: 44),
    );
  }

  void _handleBatchSelection() {
    P.conversation.toggleConversationSelection(conversation.id);
  }
}
