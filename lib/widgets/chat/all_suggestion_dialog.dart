// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

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
    final s = S.of(context);
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          16.h,
          T(s.all_prompt, s: const TS(s: 16, w: FontWeight.w600)),
          16.h,
          SizedBox(
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
    final s = S.of(context);
    if (suggestions.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: T(s.no_data, s: const TS(s: 16)),
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
            child: T(s.display, s: const TS(s: 14, w: FontWeight.w500)),
          ),
          onTap: () {
            Navigator.pop(context, s);
          },
        );
      },
    );
  }
}
