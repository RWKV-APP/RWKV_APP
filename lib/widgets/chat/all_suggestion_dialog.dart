// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';

const _maxRadius = 12.0;

class AllSuggestionDialog extends ConsumerStatefulWidget {
  static const String panelKey = 'AllSuggestionDialog';

  final ScrollController scrollController;

  const AllSuggestionDialog({
    super.key,
    required this.scrollController,
  });

  static Future<Suggestion?> show(BuildContext context) async {
    return await P.ui.showPanel<Suggestion>(
      key: panelKey,
      initialChildSize: .78,
      maxChildSize: .94,
      builder: (scrollController) => AllSuggestionDialog(
        scrollController: scrollController,
      ),
    );
  }

  @override
  ConsumerState<AllSuggestionDialog> createState() => _AllSuggestionDialogState();
}

class _AllSuggestionDialogState extends ConsumerState<AllSuggestionDialog> with SingleTickerProviderStateMixin {
  late final List<SuggestionCategory> allCategories;
  late final TabController tabController;
  late final PageController pageController;
  bool _isSyncingTab = false;

  @override
  void initState() {
    super.initState();
    allCategories = P.suggestion.useHighScoreApi.q
        ? P.suggestion.highScoreCategories.q
        : P.suggestion.config.q.chat;
    tabController = TabController(length: allCategories.length, vsync: this);
    pageController = PageController();
    pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    pageController.removeListener(_onPageScroll);
    pageController.dispose();
    tabController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    if (_isSyncingTab) return;
    final pageIndex = pageController.page?.round();
    if (pageIndex == null) return;
    if (tabController.index != pageIndex) {
      tabController.animateTo(pageIndex);
    }
  }

  void _onTabTap(int index) {
    if (index == pageController.page?.round()) return;
    _isSyncingTab = true;
    pageController
        .animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.ease)
        .then((_) => _isSyncingTab = false);
  }

  void _onSuggestionTap(Suggestion suggestion) {
    Navigator.pop(context, suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(_maxRadius),
        topRight: .circular(_maxRadius),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _PanelHeader(scrollController: widget.scrollController),
          _CategoryTabs(
            tabController: tabController,
            categories: allCategories,
            onTap: _onTabTap,
          ),
          Container(
            height: .5,
            color: theme.dividerColor.q(.3),
          ),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: allCategories.length,
              itemBuilder: (ctx, page) {
                final category = allCategories[page];
                return _SuggestionList(
                  suggestions: category.items,
                  onTap: _onSuggestionTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends ConsumerStatefulWidget {
  const _PanelHeader({required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<_PanelHeader> createState() => _PanelHeaderState();
}

class _PanelHeaderState extends ConsumerState<_PanelHeader> {
  double _opacity = .0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    double opacity = widget.scrollController.position.pixels / 100.0;
    if (opacity < 0) opacity = 0;
    if (opacity > 1) opacity = 1;
    if (opacity == _opacity) return;
    _opacity = opacity;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      constraints: const BoxConstraints(minHeight: kToolbarHeight - 4),
      padding: const .only(top: 4),
      decoration: BoxDecoration(
        color: appTheme.settingItem.q(_opacity * _opacity),
        border: Border(
          bottom: BorderSide(color: qb.q(.2 * _opacity * _opacity), width: .5),
        ),
      ),
      child: Row(
        crossAxisAlignment: .center,
        children: [
          (12 + (8 * _opacity)).w,
          Expanded(
            child: Text(
              s.all_prompt,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: .w600,
              ),
            ),
          ),
          const IconButton(
            onPressed: pop,
            icon: Icon(Icons.close),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _CategoryTabs extends ConsumerWidget {
  final TabController tabController;
  final List<SuggestionCategory> categories;
  final ValueChanged<int> onTap;

  const _CategoryTabs({
    required this.tabController,
    required this.categories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);

    return SizedBox(
      height: 44,
      child: TabBar(
        isScrollable: true,
        controller: tabController,
        tabAlignment: TabAlignment.start,
        labelPadding: const .symmetric(horizontal: 14),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: .w600),
        unselectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: .w400,
          color: qb.q(.6),
        ),
        indicatorWeight: 2.5,
        dividerHeight: 0,
        onTap: onTap,
        tabs: [
          for (final category in categories) Tab(text: category.name),
        ],
      ),
    );
  }
}

class _SuggestionList extends ConsumerWidget {
  final List<Suggestion> suggestions;
  final ValueChanged<Suggestion> onTap;

  const _SuggestionList({
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);

    if (suggestions.isEmpty) {
      return Center(
        child: Text(s.no_data, style: theme.textTheme.bodyLarge),
      );
    }

    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);

    return ListView.separated(
      padding: .fromLTRB(12, 8, 12, 12 + paddingBottom),
      itemCount: suggestions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final item = suggestions[i];
        return GD(
          onTap: () => onTap(item),
          child: Container(
            width: double.infinity,
            padding: const .symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: appTheme.settingItem,
              borderRadius: .circular(8),
              border: .all(color: qb.q(.12), width: .5),
            ),
            child: Text(
              item.display,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: qb.q(.94),
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }
}
