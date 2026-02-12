// ignore: unused_import
import 'dart:developer';
import 'dart:math';

import 'package:zone/config.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/all_suggestion_dialog.dart';
import 'package:zone/widgets/dev_options_dialog.dart';
import 'package:zone/widgets/model_selector.dart';

class Empty extends ConsumerWidget {
  const Empty({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final messages = ref.watch(P.msg.list);
    if (messages.isNotEmpty) return Positioned.fill(child: IgnorePointer(child: Container()));
    final loaded = ref.watch(P.rwkv.loaded);
    final currentModel = ref.watch(P.rwkv.latestModel);

    final demoType = ref.watch(P.app.demoType);
    final currentWorldType = ref.watch(P.rwkv.currentWorldType);
    String logoPath = "assets/img/${demoType.name}/logo.square.png";

    final hasSpecificEmpty = demoType == .see && currentWorldType != null;

    final primary = Theme.of(context).colorScheme.primary;

    final inputHeight = ref.watch(P.chat.inputHeight);
    final version = ref.watch(P.app.version);

    return AnimatedPositioned(
      duration: 200.ms,
      curve: Curves.easeInOutBack,
      bottom: hasSpecificEmpty ? -2000 : 0,
      left: 0,
      right: 0,
      top: 0,
      child: AnimatedOpacity(
        opacity: hasSpecificEmpty ? 0 : 1,
        duration: 200.ms,
        curve: Curves.easeInOutBack,
        child: GestureDetector(
          onTap: () {
            P.chat.focusNode.unfocus();
            P.talk.dismissAllShown();
          },
          child: Stack(
            children: [
              if (demoType == .chat)
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .stretch,
                    children: [
                      const SizedBox(height: 90),
                      const Flexible(
                        child: Scrollbar(
                          thumbVisibility: false,
                          trackVisibility: false,
                          child: SingleChildScrollView(
                            child: _EmptyV2(),
                          ),
                        ),
                      ),
                      SizedBox(height: inputHeight.toDouble()),
                    ],
                  ),
                ),
              if (demoType != .chat)
                Positioned.fill(
                  left: 32,
                  right: 32,
                  child: Column(
                    crossAxisAlignment: .center,
                    children: [
                      const Spacer(),
                      WithDevOption(child: Image.asset(logoPath, width: 140)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 4,
                        crossAxisAlignment: .end,
                        children: [
                          Opacity(
                            opacity: 0.0,
                            child: Text(version, style: const TS(s: 10)),
                          ),
                          Text(s.chat_welcome_to_use(Config.appTitle), style: const TS(s: 18, w: .w600)),
                          Opacity(
                            opacity: 0.5,
                            child: Padding(
                              padding: const .only(bottom: 4),
                              child: Text(version, style: const TS(s: 10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Text(s.intro),
                      ),
                      const SizedBox(height: 12),
                      if (!loaded) Text(s.start_a_new_chat_by_clicking_the_button_below),
                      if (!loaded) const SizedBox(height: 12),
                      if (!loaded)
                        TextButton(
                          onPressed: () async {
                            ModelSelector.show();
                          },
                          child: Text(
                            demoType == .see ? s.select_a_world_type : s.select_a_model,
                            style: const TS(s: 16, w: .w600),
                          ),
                        ),
                      if (!loaded) const SizedBox(height: 12),
                      if (loaded) Text(s.you_are_now_using("")),
                      const SizedBox(height: 4),
                      if (loaded)
                        Container(
                          padding: const .symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            border: .all(color: primary),
                            borderRadius: .circular(4),
                          ),
                          child: Text(
                            currentModel?.name ?? "",
                            style: TS(s: 16, w: .w600, c: primary),
                          ),
                        ),
                      const Spacer(),
                      if (demoType == .tts) (inputHeight / 1.5).h,
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyV2 extends ConsumerWidget {
  const _EmptyV2();

  Color _rndColor() {
    return HSLColor.fromAHSL(1, Random().nextDouble() * 360, .6, 0.7).toColor();
  }

  void _onTap(dynamic suggestion) {
    if (!checkModelSelection(preferredDemoType: .chat)) return;
    final s = (suggestion as Suggestion);
    P.chat.send(s.prompt.isEmpty ? s.display : s.prompt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final suggestions = ref.watch(P.suggestion.suggestion);

    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      children: [
        const SizedBox(height: 16),
        Text(
          s.hello_ask_me_anything,
          style: const TextStyle(fontSize: 32, fontWeight: .bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        for (final item in suggestions) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const .symmetric(horizontal: 24),
            child: _buildSuggestion(item),
          ),
        ],
        if (suggestions.isNotEmpty) const SizedBox(height: 12),
        if (suggestions.isNotEmpty)
          Material(
            borderRadius: .circular(60),
            color: kG.q(.1),
            child: InkWell(
              borderRadius: .circular(60),
              onTap: () async {
                final suggestion = await AllSuggestionDialog.show(context);
                if (suggestion != null) _onTap(suggestion);
              },
              child: Padding(
                padding: const .symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  S.current.more_questions,
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSuggestion(dynamic item) {
    return Material(
      borderRadius: .circular(60),
      color: kG.q(.1),
      child: InkWell(
        borderRadius: .circular(60),
        onTap: () => _onTap(item),
        child: Padding(
          padding: const .symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: .min,
            children: [
              Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  color: _rndColor(),
                  borderRadius: .circular(60),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  item is Suggestion ? item.display : item.toString(),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
