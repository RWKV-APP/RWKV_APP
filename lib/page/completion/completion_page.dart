import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/page/completion/_completion_controller.dart';
import 'package:zone/page/completion/_completion_state.dart';
import 'package:zone/page/completion/_completion_titlebar.dart';

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
    CompletionController.current.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? Color(0xFF9E7C59) : Color(0xFF8C3A3A);
    final themeV2 = ThemeData(
      cardColor: Colors.white,
      bottomSheetTheme: theme.bottomSheetTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      dividerTheme: DividerThemeData(
        space: 0,
        thickness: 1,
        color: isDark ? Color(0x99FFFFFF) : Color(0x26000000),
      ),
      scaffoldBackgroundColor: isDark ? Color(0xFF242424) : Color(0xFFFDFBF7),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(120, 50),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: WidgetStatePropertyAll(Size.zero),
          backgroundColor: WidgetStatePropertyAll(primaryColor.withAlpha(0x2B)),
          side: WidgetStatePropertyAll(BorderSide(color: primaryColor, width: 1)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: WidgetStatePropertyAll(Size.zero),
        ),
      ),
    );

    return Theme(
      data: themeV2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80 + kToolbarHeight), //
          child: CompletionTitleBar(),
        ),
        resizeToAvoidBottomInset: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _FloatButton(),
        body: SafeArea(child: _PageBody()),
      ),
    );
  }
}

class _FloatButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FloatButton> createState() => _FloatButtonState();
}

class _FloatButtonState extends ConsumerState<_FloatButton> with WidgetsBindingObserver {
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final keyboardHeight = View.of(context).viewInsets.bottom;
    final bool isNowVisible = keyboardHeight > 0.0;
    if (isNowVisible != _isKeyboardVisible) {
      _isKeyboardVisible = isNowVisible;
      setState(() {});
      // CompletionController.current.onKeyboardVisibleChanged(isNowVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    final generating = ref.watch(CompletionState.generating);
    return Visibility(
      visible: !_isKeyboardVisible,
      child: FilledButton(
        onPressed: generating ? null : () => CompletionController.current.onCompletionTap(),
        child: Text("续写"),
      ),
    );
  }
}

class _PageBody extends ConsumerWidget {
  const _PageBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(CompletionState.items);
    final controller = ref.watch(CompletionState.controllerList);
    return Stack(
      children: [
        Positioned.fill(
          child: ListView.builder(
            controller: controller,
            itemCount: items.length + 1,
            padding: EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 100),
            itemBuilder: (ctx, index) {
              if (index == items.length) {
                return _UserInputArea();
              }
              final item = items[index];
              return CompletionListItem(
                item: item,
                footer: index == items.length - 1 ? CompletionListItemFooter(item: item) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserInputArea extends ConsumerWidget {
  const _UserInputArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generating = ref.watch(CompletionState.generating);
    final controller = ref.watch(CompletionState.controllerInput);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      padding: EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 16),
      child: TextField(
        controller: controller,
        enabled: !generating,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          hintText: "输入要续写的段落",
          border: InputBorder.none,
        ),
        onTapUpOutside: (details) {
          //
        },
        minLines: 1,
        maxLines: 999999999,
      ),
    );
  }
}
