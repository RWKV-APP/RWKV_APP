// Flutter imports:
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/model/message.dart' as model;
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat_app_bar.dart';
import 'package:zone/widgets/input_bar.dart';
import 'package:zone/widgets/message.dart';

class PageWebDemo extends ConsumerWidget {
  const PageWebDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final selectMessageMode = ref.watch(P.chat.isSharing);

    return Scaffold(
      body: Stack(
        children: [
          const _WebDemoMessageList(),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatAppBar(),
          ),
          const Positioned(
            top: kToolbarHeight,
            left: 0,
            right: 0,
            child: _WebDemoControls(),
          ),
          if (!selectMessageMode) const InputBar(),
        ],
      ),
    );
  }
}

class _WebDemoMessageList extends ConsumerWidget {
  const _WebDemoMessageList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final messages = ref.watch(P.msg.list);
    final paddingTop = ref.watch(P.app.paddingTop);
    final paddingLeft = ref.watch(P.app.paddingLeft);
    final paddingRight = ref.watch(P.app.paddingRight);
    final inputHeight = ref.watch(P.chat.inputHeight);
    final qb = ref.watch(P.app.qb);
    final isMobile = ref.watch(P.app.isMobile);
    final top = paddingTop + kToolbarHeight + 148;
    final bottom = inputHeight;

    return Positioned.fill(
      child: GestureDetector(
        onTap: P.chat.onTapMessageList,
        child: RawScrollbar(
          radius: const Radius.circular(100),
          thickness: 4,
          thumbColor: qb.withValues(alpha: .4),
          padding: .only(top: top, right: 4, bottom: bottom + 4),
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
              return _WebDemoMessageWrap(msg: msg, finalIndex: finalIndex);
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

class _WebDemoMessageWrap extends ConsumerWidget {
  final model.Message msg;
  final int finalIndex;

  const _WebDemoMessageWrap({
    required this.msg,
    required this.finalIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    return Message(msg, finalIndex, selectMode: false);
  }
}

class _WebDemoControls extends ConsumerWidget {
  const _WebDemoControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final useCloud = ref.watch(P.webDemo.useOfficialCloud);
    final pendingHtmlContext = ref.watch(P.webDemo.pendingHtmlContext);
    final promptTemplate = ref.watch(P.webDemo.promptTemplate);
    final configured = P.webDemo.officialCloudConfigured;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const .symmetric(horizontal: 12),
        child: Container(
          decoration: BoxDecoration(
            color: appTheme.settingBg.withValues(alpha: .94),
            borderRadius: .circular(8),
            border: Border.all(color: appTheme.qb12, width: .5),
          ),
          padding: const .all(10),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.web_asset_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      "Web Demo",
                      style: TextStyle(fontWeight: .w700),
                    ),
                  ),
                  Text(
                    configured ? "Official cloud" : "Cloud key missing",
                    style: TextStyle(color: appTheme.qb5, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: useCloud,
                    onChanged: configured ? P.webDemo.setUseOfficialCloud : null,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Cloud mode sends prompts and selected HTML to the official RWKV endpoint.",
                style: TextStyle(color: appTheme.qb5, fontSize: 12),
              ),
              if (pendingHtmlContext != null) const SizedBox(height: 6),
              if (pendingHtmlContext != null)
                Text(
                  "Selected HTML is attached to the next Web request.",
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: .w600),
                ),
              const SizedBox(height: 8),
              _WebDemoTemplateField(promptTemplate: promptTemplate),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebDemoTemplateField extends ConsumerStatefulWidget {
  final String promptTemplate;

  const _WebDemoTemplateField({required this.promptTemplate});

  @override
  ConsumerState<_WebDemoTemplateField> createState() => _WebDemoTemplateFieldState();
}

class _WebDemoTemplateFieldState extends ConsumerState<_WebDemoTemplateField> {
  late final TextEditingController _controller = TextEditingController(text: widget.promptTemplate);

  @override
  void didUpdateWidget(covariant _WebDemoTemplateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text == widget.promptTemplate) return;
    _controller.text = widget.promptTemplate;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _controller,
      minLines: 2,
      maxLines: 4,
      onChanged: P.webDemo.setPromptTemplate,
      style: theme.textTheme.bodySmall,
      decoration: InputDecoration(
        labelText: "Prompt template",
        border: OutlineInputBorder(borderRadius: .circular(6)),
        suffixIcon: IconButton(
          tooltip: "Reset template",
          onPressed: P.webDemo.resetPromptTemplate,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ),
    );
  }
}
