import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/page/completion/_completion_controller.dart';
import 'package:zone/page/completion/_completion_item_batch.dart';
import 'package:zone/page/completion/_completion_state.dart';
import 'package:zone/page/completion/_completion_titlebar.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/arguments_panel.dart';

import '../../gen/l10n.dart' show S;
import '_completion_list_item.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = theme.colorScheme.primary;
    Color backgroundColor = isDark ? const Color(0xFF242424) : const Color(0xFFFDFBF7);
    Color dividerColor = isDark ? const Color(0x99FFFFFF) : const Color(0x26000000);
    if (isDark && P.preference.preferredDarkCustomTheme.q == .lightsOut) {
      backgroundColor = Colors.black;
      dividerColor = const Color(0x44ffffff);
    }
    final themeV2 = ThemeData(
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
        onPrimary: Colors.white,
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
          backgroundColor: WidgetStatePropertyAll(primaryColor.withAlpha(0x2B)),
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

    return Theme(
      data: themeV2,
      child: Scaffold(
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(90 + kToolbarHeight), //
          child: CompletionTitleBar(),
        ),
        resizeToAvoidBottomInset: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Platform.isAndroid || Platform.isIOS
            ? _FloatButton()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _FloatButton(),
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: SizedBox(),
                  ),
                ],
              ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    bool autoScrolling = true;
    final list = Listener(
      child: const _ContentList(),
      onPointerDown: (_) {
        if (CompletionState.autoScrolling) {
          CompletionState.autoScrolling = false;
          autoScrolling = true;
        } else {
          autoScrolling = false;
        }
      },
      onPointerUp: (_) async {
        if (autoScrolling) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            CompletionState.autoScrolling = true;
          });
        }
      },
    );

    if (Platform.isAndroid || Platform.isIOS) {
      return list;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: list,
        ),
        const VerticalDivider(),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const .symmetric(horizontal: 12, vertical: 12),
                  child: Text(
                    S.current.decode_param,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
                const Expanded(
                  child: ArgumentsPanel(showTitleBar: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generating = ref.watch(CompletionState.generating);
    final enabled = ref.watch(CompletionState.generateButtonEnabled);

    VoidCallback? onTap;

    if (enabled) {
      onTap =
          generating //
          ? () => CompletionController.current.onStopTap()
          : () => CompletionController.current.onCompletionTap();
    }

    return FilledButton.icon(
      icon: !generating
          ? null
          : SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 3, color: Theme.of(context).colorScheme.onPrimary),
            ),
      onPressed: onTap,
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
      padding: const EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 100),
      itemBuilder: (ctx, index) {
        final last = index == items.length - 1;
        final input = index == items.length;

        if (input) {
          return _UserInputArea(textStyle);
        }
        final item = items[index];
        // root item, do not show
        if (item.isRoot) {
          return const SizedBox();
        }
        // user input is empty, do not show
        if (item.content.isEmpty && item.isUser) {
          return const SizedBox();
        }
        if (!item.isUser && item.siblingCount > 1) {
          return CompletionItemBatch(
            item: item,
            isLast: last,
            textStyle: textStyle,
            footer: Row(
              children: [
                if (last) CompletionRegenerationButton(item: item),
                const Spacer(),
                CompletionSpeed(item: last ? null : item),
              ],
            ),
          );
        }
        return CompletionListItem(
          item: item,
          isLast: last,
          textStyle: textStyle,
          footer: item.isUser ? null : CompletionListItemFooter(item: item, isLast: last),
        );
      },
    );
  }
}

class _UserInputArea extends ConsumerWidget {
  final TextStyle testStyle;

  const _UserInputArea(this.testStyle);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generating = ref.watch(CompletionState.generating);
    final controller = ref.watch(CompletionState.controllerInput);
    final showSuggestions = ref.watch(CompletionState.showSuggestionButton);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 16),
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
            style: testStyle,
            scrollPadding: const EdgeInsets.only(bottom: 100),
            minLines: 1,
            maxLines: null,
          ),
          if (showSuggestions)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: OutlinedButton(
                  onPressed: () {
                    CompletionController.current.onSuggestionTap(context);
                  },
                  style: ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const WidgetStatePropertyAll(Size.zero),
                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                    backgroundColor: WidgetStatePropertyAll(theme.dividerColor.withAlpha(0x2B)),
                    side: WidgetStatePropertyAll(BorderSide(color: theme.dividerColor, width: 1)),
                  ),
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
