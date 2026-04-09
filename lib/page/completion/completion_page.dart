// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/page/completion/_completion_controller.dart';
import 'package:zone/page/completion/_completion_item_batch.dart';
import 'package:zone/page/completion/_completion_list_item.dart';
import 'package:zone/page/completion/_completion_state.dart';
import 'package:zone/page/completion/_completion_titlebar.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/arguments_panel.dart';

class CompletionPage extends StatefulWidget {
  const CompletionPage({super.key});

  @override
  State<CompletionPage> createState() => _CompletionPageState();
}

class _CompletionPageState extends State<CompletionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CompletionController.current.init();
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CompletionController.current.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildCompletionTheme(context),
      child: const _Page(),
    );
  }
}

ThemeData _buildCompletionTheme(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final primaryColor = theme.colorScheme.primary;
  Color backgroundColor = isDark ? const Color(0xFF242424) : const Color(0xFFFDFBF7);
  Color dividerColor = isDark ? const Color(0x99FFFFFF) : const Color(0x26000000);

  if (isDark && P.preference.preferredDarkCustomTheme.q == .lightsOut) {
    backgroundColor = Colors.black;
    dividerColor = const Color(0x44FFFFFF);
  }

  return ThemeData(
    cardColor: Colors.white,
    bottomSheetTheme: theme.bottomSheetTheme,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    dividerTheme: DividerThemeData(
      space: 0,
      thickness: 1,
      color: dividerColor,
    ),
    fontFamily: theme.textTheme.bodyMedium?.fontFamily,
    fontFamilyFallback: theme.textTheme.bodyMedium?.fontFamilyFallback,
    scaffoldBackgroundColor: backgroundColor,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(120, 50),
        disabledBackgroundColor: Colors.grey.shade400,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      onPrimary: isDark ? Colors.black : Colors.white,
      brightness: theme.brightness,
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: .circular(8)),
      menuPadding: .zero,
      color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        backgroundColor: WidgetStatePropertyAll(primaryColor.q(0.17)),
        side: WidgetStatePropertyAll(BorderSide(color: primaryColor, width: 1)),
      ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: WidgetStatePropertyAll(Size.zero),
      ),
    ),
  );
}

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useHorizontalLayout = constraints.maxWidth > constraints.maxHeight;

        return Scaffold(
          appBar: const PreferredSize(
            preferredSize: Size.fromHeight(90 + kToolbarHeight),
            child: CompletionTitleBar(),
          ),
          resizeToAvoidBottomInset: true,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: useHorizontalLayout ? const _HorizontalFloatingAction() : const _BottomActions(),
          body: SafeArea(
            child: _Body(useHorizontalLayout: useHorizontalLayout),
          ),
        );
      },
    );
  }
}

class _HorizontalFloatingAction extends StatelessWidget {
  const _HorizontalFloatingAction();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Align(
            alignment: .bottomCenter,
            child: _BottomActions(),
          ),
        ),
        Expanded(
          flex: 2,
          child: SizedBox(),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final decodeParamForegroundColor = isDark ? Colors.white : Colors.black;
    final decodeParamBackgroundColor = isDark ? Colors.transparent : Colors.white;

    final decodeParamButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 50),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      foregroundColor: decodeParamForegroundColor,
      backgroundColor: decodeParamBackgroundColor,
      side: BorderSide(color: decodeParamForegroundColor, width: 1),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );

    return Row(
      mainAxisSize: .min,
      children: [
        const _FloatButton(),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: CompletionDecodeParamButton(
            filled: true,
            buttonStyle: decodeParamButtonStyle,
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final bool useHorizontalLayout;

  const _Body({required this.useHorizontalLayout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!useHorizontalLayout) {
      return const _ContentArea();
    }

    return Row(
      crossAxisAlignment: .stretch,
      children: [
        const Expanded(
          flex: 2,
          child: _ContentArea(),
        ),
        Container(
          width: 0.5,
          color: theme.dividerColor,
        ),
        const Expanded(
          child: _SideArgumentsPanel(),
        ),
      ],
    );
  }
}

class _ContentArea extends StatefulWidget {
  const _ContentArea();

  @override
  State<_ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<_ContentArea> {
  bool _resumeAutoScrolling = false;

  void _onPointerDown(PointerDownEvent event) {
    if (!CompletionState.autoScrolling) {
      _resumeAutoScrolling = false;
      return;
    }

    CompletionState.autoScrolling = false;
    _resumeAutoScrolling = true;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_resumeAutoScrolling) {
      return;
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) {
        return;
      }
      CompletionState.autoScrolling = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: const _ContentList(),
    );
  }
}

class _SideArgumentsPanel extends StatelessWidget {
  const _SideArgumentsPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const .symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const .symmetric(horizontal: 12, vertical: 12),
            child: Text(
              S.current.decode_param,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const Expanded(
            child: ArgumentsPanel(showTitleBar: false),
          ),
        ],
      ),
    );
  }
}

class _FloatButton extends ConsumerWidget {
  const _FloatButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final generating = ref.watch(CompletionState.generating);
    final enabled = ref.watch(CompletionState.generateButtonEnabled);
    VoidCallback? onPressed;

    if (enabled) {
      onPressed =
          generating //
          ? CompletionController.current.onStopTap
          : CompletionController.current.onCompletionTap;
    }

    return FilledButton.icon(
      icon: !generating
          ? null
          : SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.onPrimary,
              ),
            ),
      onPressed: onPressed,
      label: Text(generating ? S.current.stop : S.current.completion),
    );
  }
}

class _ContentList extends ConsumerWidget {
  const _ContentList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(CompletionState.items);
    final isEng = !ref.watch(P.preference.currentLangIsZh);
    final textStyle = TextStyle(
      fontSize: 14,
      height: isEng ? 1.2 : 2,
      letterSpacing: 1,
      overflow: TextOverflow.ellipsis,
    );

    return ListView.builder(
      itemCount: items.length + 1,
      padding: const EdgeInsets.only(left: 32, top: 16, right: 32, bottom: 100),
      itemBuilder: (context, index) {
        final isInput = index == items.length;

        if (isInput) {
          return _UserInputArea(textStyle: textStyle);
        }

        final item = items[index];
        return _CompletionTimelineItem(
          item: item,
          isLast: index == items.length - 1,
          textStyle: textStyle,
        );
      },
    );
  }
}

class _CompletionTimelineItem extends StatelessWidget {
  final CompletionItemNode item;
  final bool isLast;
  final TextStyle textStyle;

  const _CompletionTimelineItem({
    required this.item,
    required this.isLast,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (item.isRoot) {
      return const SizedBox();
    }

    if (item.content.isEmpty && item.isUser) {
      return const SizedBox();
    }

    if (!item.isUser && item.siblingCount > 1) {
      return CompletionItemBatch(
        item: item,
        isLast: isLast,
        textStyle: textStyle,
        footer: Row(
          children: [
            if (isLast) CompletionRegenerationButton(item: item),
            const Spacer(),
            CompletionSpeed(item: isLast ? null : item),
          ],
        ),
      );
    }

    return CompletionListItem(
      item: item,
      isLast: isLast,
      textStyle: textStyle,
      footer: item.isUser ? null : CompletionListItemFooter(item: item, isLast: isLast),
    );
  }
}

class _UserInputArea extends ConsumerWidget {
  final TextStyle textStyle;

  const _UserInputArea({required this.textStyle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final generating = ref.watch(CompletionState.generating);
    final controller = ref.watch(CompletionState.controllerInput);
    final showSuggestions = ref.watch(CompletionState.showSuggestionButton);
    final suggestionButtonStyle = ButtonStyle(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const WidgetStatePropertyAll(Size.zero),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
      backgroundColor: WidgetStatePropertyAll(theme.dividerColor.q(0.17)),
      side: WidgetStatePropertyAll(BorderSide(color: theme.dividerColor, width: 1)),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            enabled: !generating,
            autofocus: false,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              hintText: S.current.enter_text_to_expand,
              border: InputBorder.none,
            ),
            style: textStyle,
            scrollPadding: const EdgeInsets.only(bottom: 100),
            minLines: 1,
            maxLines: null,
          ),
          if (showSuggestions)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: OutlinedButton(
                  onPressed: () {
                    CompletionController.current.onSuggestionTap(context);
                  },
                  style: suggestionButtonStyle,
                  child: Text(
                    S.current.suggest,
                    style: TextStyle(fontSize: 10, color: theme.dividerColor),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
