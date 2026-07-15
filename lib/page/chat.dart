// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_web_search/local_web_search.dart';

// Project imports:
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/message_type.dart' as model;
import 'package:zone/model/world_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/empty.dart';
import 'package:zone/widgets/chat/share_chat_sheet.dart';
import 'package:zone/widgets/chat_app_bar.dart';
import 'package:zone/widgets/input_bar.dart';
import 'package:zone/widgets/message.dart';

class PageChat extends StatefulWidget {
  const PageChat({super.key});

  @override
  State<PageChat> createState() => _PageChatState();
}

class _PageChatState extends State<PageChat> {
  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: const _Page(),
    );
  }

  void _onPopInvokedWithResult(bool didPop, _) {
    if (!didPop) return;
    P.chat.isSharing.q = false;
    P.chat.cancelEditing(clearInput: true);
    P.chat.onStopButtonPressed(wantHaptic: false);
  }
}

class _Page extends ConsumerWidget {
  const _Page();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final localWebSearchPanelEnabled = ref.watch(P.chat.localWebSearchPanelEnabled);
    final localWebSearchPanelSplitRatio = ref.watch(P.chat.localWebSearchPanelSplitRatio);
    final isDesktop = ref.watch(P.app.isDesktop);
    final showLocalWebSearchPanel = localWebSearchPanelEnabled && isDesktop;

    return Scaffold(
      body: showLocalWebSearchPanel
          ? _ChatSearchSplitPane(
              splitRatio: localWebSearchPanelSplitRatio,
            )
          : const _ChatPane(),
    );
  }
}

class _ChatSearchSplitPane extends StatelessWidget {
  final double splitRatio;

  const _ChatSearchSplitPane({required this.splitRatio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth - _ResizableVerticalSeparator.hitWidth;
        if (totalWidth <= 0) return const _ChatPane();

        final chatWidth = totalWidth * splitRatio;
        final searchWidth = totalWidth - chatWidth;

        return Row(
          children: [
            SizedBox(width: chatWidth, child: const _ChatPane()),
            _ResizableVerticalSeparator(totalWidth: totalWidth),
            SizedBox(width: searchWidth, child: const _LocalWebSearchPane()),
          ],
        );
      },
    );
  }
}

class _ChatPane extends ConsumerWidget {
  const _ChatPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final selectMessageMode = ref.watch(P.chat.isSharing);

    return Stack(
      children: [
        const _List(),
        const Empty(),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ChatAppBar(),
        ),
        if (!selectMessageMode) const InputBar(),
        if (selectMessageMode) const Positioned.fill(child: ShareChatSheet()),
      ],
    );
  }
}

class _ResizableVerticalSeparator extends ConsumerWidget {
  static const double hitWidth = 12;
  final double totalWidth;

  const _ResizableVerticalSeparator({required this.totalWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final _ = theme;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: P.chat.resetLocalWebSearchPanelSplitRatio,
        onHorizontalDragUpdate: (details) {
          P.chat.onLocalWebSearchPanelSplitDragged(
            totalWidth: totalWidth,
            deltaX: details.delta.dx,
          );
        },
        child: SizedBox(
          width: hitWidth,
          child: Center(
            child: Container(width: 0.5, color: qb),
          ),
        ),
      ),
    );
  }
}

class _LocalWebSearchPane extends ConsumerWidget {
  const _LocalWebSearchPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final messages = ref.watch(P.chat.localWebSearchMessages);
    final engine = ref.watch(P.chat.localWebSearchEngine);
    final deepResultsEnabled = ref.watch(P.chat.localWebSearchDeepResultsEnabled);

    return SearchBrowserPanel(
      controller: P.chat.localWebSearchController,
      initialSearchEngine: engine,
      messages: messages,
      initialDeepResultsEnabled: deepResultsEnabled,
      onSearchEngineChanged: P.chat.onLocalWebSearchEngineChanged,
      onDeepResultsEnabledChanged: P.chat.onLocalWebSearchDeepResultsEnabledChanged,
      onReferenceBundleChanged: P.chat.onLocalWebSearchBundleChanged,
    );
  }
}

class _List extends ConsumerWidget {
  const _List();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final messages = ref.watch(P.msg.list);
    final paddingTop = ref.watch(P.app.paddingTop);
    final paddingLeft = ref.watch(P.app.paddingLeft);
    final paddingRight = ref.watch(P.app.paddingRight);
    final inputHeight = ref.watch(P.chat.inputHeight);

    double top = paddingTop + kToolbarHeight + 4;
    double bottom = inputHeight;
    double scrollBarBottom = inputHeight + 4;

    final currentWorldType = ref.watch(P.rwkvContext.currentWorldType);

    switch (currentWorldType) {
      case null:
        break;
      case WorldType.reasoningQA:
      case WorldType.ocr:
      case WorldType.modrwkvV2:
      case WorldType.modrwkvV3:
        if (messages.length == 1 && messages.first.type == model.MessageType.userImage) {
          bottom += 46;
        }
        break;
    }

    final qb = ref.watch(P.app.qb);

    final isMobile = ref.watch(P.app.isMobile);

    return Positioned.fill(
      child: GestureDetector(
        onTap: P.chat.onTapMessageList,
        child: RawScrollbar(
          radius: const Radius.circular(100),
          thickness: 4,
          thumbColor: qb.withValues(alpha: .4),
          padding: .only(top: top, right: 4, bottom: scrollBarBottom),
          controller: P.chat.scrollController,
          child: ListView.separated(
            reverse: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: .only(left: paddingLeft, top: top, right: paddingRight, bottom: bottom),
            controller: P.chat.scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final finalIndex = messages.length - 1 - index;
              final msg = messages[finalIndex];
              return _MessageWrap(msg: msg, finalIndex: finalIndex);
            },
            separatorBuilder: (context, index) {
              return isMobile ? const SizedBox(height: 12) : const SizedBox(height: 4);
            },
          ),
        ),
      ),
    );
  }
}

class _MessageWrap extends ConsumerWidget {
  final model.Message msg;
  final int finalIndex;

  const _MessageWrap({required this.msg, required this.finalIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final selectMessageMode = ref.watch(P.chat.isSharing);

    if (!selectMessageMode) {
      return Message(msg, finalIndex, selectMode: false);
    }

    final selectedIds = ref.watch(P.chat.sharingSelectedMsgIds);
    final selected = selectedIds.contains(msg.id);

    void toggle() async {
      final ids = P.chat.sharingSelectedMsgIds.q;
      final messages = P.msg.list.q;
      final index = messages.indexOf(msg);
      final previous = index > 0 ? messages[index - 1] : null;
      final next = index < messages.length - 1 ? messages[index + 1] : null;
      final pair = msg.isMine ? next : previous;
      if (selected) {
        P.chat.sharingSelectedMsgIds.q = ids.where((id) => id != msg.id && id != pair?.id).toSet();
      } else {
        P.chat.sharingSelectedMsgIds.q = {...ids, msg.id, ?pair?.id};
      }
    }

    return GestureDetector(
      onTap: () => toggle(),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (checked) => toggle(),
          ),
          Expanded(
            child: IgnorePointer(
              child: Message(msg, finalIndex, selectMode: true),
            ),
          ),
        ],
      ),
    );
  }
}
