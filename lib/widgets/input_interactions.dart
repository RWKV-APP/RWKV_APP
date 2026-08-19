// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/ask_question_button.dart';
import 'package:zone/widgets/chat/batch_button.dart';
import 'package:zone/widgets/chat/decode_param_button.dart';
import 'package:zone/widgets/chat/response_style_button.dart';
import 'package:zone/widgets/chat/secondary_options_button.dart';
import 'package:zone/widgets/chat/thinking_mode_button.dart';
import 'package:zone/widgets/chat/web_search_mode_button.dart';

class InputInteractions extends ConsumerWidget {
  final DemoType preferredDemoType;

  static double calculateButtonHeight(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context);
    return textScaleFactor.scale(14) + 20;
  }

  const InputInteractions({
    super.key,
    required this.preferredDemoType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: _ItemList(preferredDemoType: preferredDemoType),
    );
  }
}

class _ItemList extends ConsumerWidget {
  final DemoType preferredDemoType;

  const _ItemList({this.preferredDemoType = .chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final currentLangIsZh = ref.watch(P.preference.currentLangIsZh);
    final currentModelIsBefore20250922 = ref.watch(P.rwkvParams.currentModelIsBefore20250922);
    final isDesktop = ref.watch(P.app.isDesktop);

    final children = [
      if (preferredDemoType == .chat) const DecodeParamButton(),
      if (preferredDemoType == .chat && currentLangIsZh && currentModelIsBefore20250922) const SecondaryOptionsButton(),
      if (preferredDemoType == .chat) ThinkingModeButton(preferredDemoType: preferredDemoType),
      if (preferredDemoType == .chat) const BatchButton(),
      if (preferredDemoType == .chat && currentLangIsZh) const ResponseStyleButton(),
      if (preferredDemoType == .chat && isDesktop) const WebSearchModeButton(),
      if (preferredDemoType == .chat) const AskQuestionButton(),
    ];

    final appTheme = ref.watch(P.app.theme);
    final inputBarHorizontalPadding = appTheme.inputBarHorizontalPadding;

    if (children.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: InputInteractions.calculateButtonHeight(context),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: .symmetric(horizontal: inputBarHorizontalPadding),
        scrollDirection: .horizontal,
        itemBuilder: (context, index) {
          return children[index];
        },
        itemCount: children.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 4);
        },
      ),
    );
  }
}
