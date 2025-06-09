// ignore: unused_import
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/scheduler/ticker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/func/is_chinese.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/state/p.dart';

class Suggestions extends ConsumerWidget {
  static const defaultHeight = 46.0;

  const Suggestions({super.key});

  void _onSuggestionTap(dynamic suggestion) {
    switch (P.app.demoType.q) {
      case DemoType.chat:
        final s = (suggestion as Suggestion);
        P.chat.send(s.prompt.isEmpty ? s.display : s.prompt);
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
      case DemoType.world:
        P.chat.send(suggestion);
      case DemoType.tts:
        final current = P.chat.textEditingController.text;
        if (current.isEmpty) {
          P.chat.textEditingController.text = suggestion;
        } else {
          final last = current.characters.last;
          final lastIsChinese = containsChineseCharacters(last);
          final lastIsEnglish = isEnglish(last);
          if (lastIsChinese) {
            P.chat.textEditingController.text = "$current。$suggestion";
          } else if (lastIsEnglish) {
            P.chat.textEditingController.text = "$current. $suggestion";
          } else {
            P.chat.textEditingController.text = "$current$suggestion";
          }
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoType = ref.watch(P.app.demoType);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final inputHeight = ref.watch(P.chat.inputHeight);

    List<dynamic> suggestions = ref.watch(P.suggestion.suggestion);
    final config = ref.watch(P.suggestion.config);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    double bottom = paddingBottom + 114;

    if (demoType == DemoType.tts) {
      bottom += inputHeight - 114 - paddingBottom;
    }

    final showAllPromptButton = demoType == DemoType.chat && config.chat.length > 1;

    return Positioned(
      bottom: bottom,
      left: 0,
      right: 0,
      height: Suggestions.defaultHeight,
      child: Row(
        children: [
          Expanded(
            child: _buildRndPromptList(context, suggestions),
          ),
          if (showAllPromptButton) 8.w,
          if (showAllPromptButton) _buildAllButton(context),
          if (showAllPromptButton) 8.w,
        ],
      ),
    );
  }

  Widget _buildRndPromptList(
    BuildContext context,
    List suggestions,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListView(
      padding: const EI.o(l: 8, b: 8, t: 2),
      scrollDirection: Axis.horizontal,
      children: suggestions.map((e) {
        String displayText = '';
        if (e is Suggestion) {
          displayText = e.display;
        } else {
          displayText = e.toString();
        }
        return _buildTag(
          displayText,
          color: primary,
          onTap: () => _onSuggestionTap(e),
        );
      }).toList(),
    );
  }

  Widget _buildAllButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final prompt = await AllSuggestionDialog.show(context);
        if (prompt != null) {
          await Future.delayed(const Duration(milliseconds: 200));
          _onSuggestionTap(prompt);
        }
      },
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EI.s(v: 0, h: 8),
        shape: OutlinedBorder.lerp(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          0,
        ),
      ),
      child: Text(S.of(context).all),
    );
  }

  Widget _buildTag(String text, {required Color color, required VoidCallback? onTap}) {
    final qw = P.app.qw.q;
    final qb = P.app.qb.q;
    final customTheme = P.app.customTheme.q;
    return GD(
      onTap: onTap,
      child: C(
        alignment: Alignment.center,
        decoration: BD(
          color: Platform.isIOS ? qw.q(.9) : qw,
          borderRadius: 6.r,
          border: Border.all(
            color: color,
            width: .5,
          ),
          boxShadow: [
            BoxShadow(
              color: customTheme.scaffold,
              blurRadius: 10,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        margin: const EI.o(r: 8, t: 4),
        padding: const EI.s(v: 4, h: 8),
        child: T(text, s: const TS(s: 16)),
      ),
    );
  }
}

class AllSuggestionDialog extends StatefulWidget {
  final ScrollController scrollController;

  const AllSuggestionDialog({
    super.key,
    required this.scrollController,
  });

  static Future<Suggestion?> show(BuildContext context) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => DraggableScrollableSheet(
        initialChildSize: .8,
        maxChildSize: .9,
        expand: false,
        snap: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return AllSuggestionDialog(
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  @override
  State<AllSuggestionDialog> createState() => _AllSuggestionDialogState();
}

class _AllSuggestionDialogState extends State<AllSuggestionDialog> implements TickerProvider {
  late final allCategories = P.suggestion.config.q.chat;
  late final categoryCount = allCategories.length;

  late final TabController tabController = TabController(length: categoryCount, vsync: this);
  late final PageController pageController = PageController(initialPage: 0, viewportFraction: 1);
  bool isChangingIndex = false;

  @override
  void initState() {
    super.initState();
    pageController.addListener(() async {
      if (isChangingIndex) {
        await Future.delayed(const Duration(milliseconds: 200));
        isChangingIndex = false;
        return;
      }
      final pageIndex = pageController.page!.round();
      if (tabController.index != pageIndex) {
        tabController.animateTo(pageIndex);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
    tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qb = P.app.qb.q;
    return SB(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          16.h,
          T(S.of(context).all_prompt, s: const TS(s: 16, w: FW.w600)),
          16.h,
          SB(
            height: 50,
            child: TabBar(
              isScrollable: true,
              unselectedLabelStyle: const TS(s: 12),
              labelPadding: const EI.s(v: 0, h: 12),
              tabAlignment: TabAlignment.start,
              controller: tabController,
              onTap: (i) {
                if (i != pageController.page!.round()) {
                  isChangingIndex = true;
                  pageController.animateToPage(i, duration: const Duration(milliseconds: 200), curve: Curves.ease);
                }
              },
              tabs: [
                for (final category in allCategories) Tab(text: category.name),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: categoryCount,
              itemBuilder: (ctx, page) {
                final category = allCategories[page];
                return _SuggestionList(
                  scrollController: widget.scrollController,
                  suggestions: category.items,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}

class _SuggestionList extends StatelessWidget {
  final ScrollController scrollController;
  final List<Suggestion> suggestions;

  const _SuggestionList({
    required this.scrollController,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: T(S.of(context).no_data, s: const TS(s: 16)),
      );
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: suggestions.length,
      padding: const EI.o(t: 8, b: 40),
      itemBuilder: (c, i) {
        final s = suggestions[i];
        return InkWell(
          child: Container(
            padding: const EI.s(v: 8, h: 12),
            child: T(s.display, s: const TS(s: 14, w: FW.w500)),
          ),
          onTap: () {
            Navigator.pop(context, s);
          },
        );
      },
    );
  }
}
