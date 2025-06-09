// ignore: unused_import
import 'dart:developer';
import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'dart:math' as math;

import 'package:zone/state/p.dart';
import 'package:zone/widgets/menu.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/widgets/pager.dart';

const _kStaticGridColor = Color.fromARGB(255, 159, 255, 121);
const _kDynamicGridColor = Color.fromARGB(255, 190, 158, 255);
const _kEmptyGridColor = Color.fromARGB(255, 150, 150, 150);
const _kGridBGColor = Color.fromARGB(255, 50, 50, 50);
const _kStackColor = Color.fromARGB(200, 255, 100, 86);
const _kStackPointSize = 2.0;
const _kStackPointOffsetX = 20.0;
const _kStackPointOffsetY = 20.0;
const _kStackPointerStrokeWidth = 2.0;

const _kButtonHeight = 32.0;
const _kButtomSizeHeight = 32.0;
const _kButtonPadding = 2.0;

class PageSudoku extends ConsumerWidget {
  const PageSudoku({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(P.app.screenHeight);
    ref.watch(P.app.screenWidth);
    ref.watch(P.app.paddingBottom);
    ref.watch(P.app.paddingTop);

    return const Pager(
      drawer: Menu(),
      child: _Page(),
    );
  }
}

class _Page extends ConsumerWidget {
  const _Page();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    final isPortrait = (screenHeight - kToolbarHeight) > screenWidth;
    final paddingTop = ref.watch(P.app.paddingTop);
    final qw = ref.watch(P.app.qw);

    return Scaffold(
      backgroundColor: qw,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          Pager.toggle();
        },
        child: const Icon(Icons.menu),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      body: isPortrait
          ? Column(
              children: [
                paddingTop.h,
                const _UI(),
                const Expanded(child: _Terminal()),
              ],
            )
          : const Row(
              children: [
                Expanded(child: _Terminal()),
                _UI(),
              ],
            ),
    );
  }
}

class _ButtonGenerate extends ConsumerWidget {
  const _ButtonGenerate();

  void _onPressed(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    if (!P.rwkv.loaded.q) {
      Alert.info(s.please_load_model_first);
      ModelSelector.show();
      return;
    }
    await P.sudoku.onGeneratePressed(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final running = ref.watch(P.sudoku.running);
    return C(
      padding: const EI.o(b: _kButtonPadding),
      child: SB(
        height: _kButtonHeight,
        child: FilledButton(
          style: ButtonStyle(
            maximumSize: WidgetStateProperty.all(const Size(double.infinity, _kButtomSizeHeight)),
            minimumSize: WidgetStateProperty.all(const Size(double.infinity, _kButtomSizeHeight)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0)),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          onPressed: running ? null : () => _onPressed(context, ref),
          child: T(s.generate),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ButtonGenerateHardest extends ConsumerWidget {
  const _ButtonGenerateHardest();

  void _onPressed(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    if (!P.rwkv.loaded.q) {
      Alert.info(s.please_load_model_first);
      ModelSelector.show();
      return;
    }

    if (P.sudoku.running.q) {
      await showOkAlertDialog(
        context: context,
        title: s.inference_is_running,
        message: s.please_wait_for_it_to_finish,
      );
      return;
    }

    P.sudoku.loadHardestSudoku();
    await showOkAlertDialog(
      context: context,
      title: s.just_watch_me,
      message: s.this_is_the_hardest_sudoku_in_the_world,
      okLabel: s.its_your_turn,
    );
    if (context.mounted) await P.sudoku.onInferencePressed(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final running = ref.watch(P.sudoku.running);
    return C(
      padding: const EI.o(b: _kButtonPadding),
      child: SB(
        height: 48,
        child: FilledButton(
          style: ButtonStyle(
            maximumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
            minimumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0)),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          onPressed: running ? null : () => _onPressed(context, ref),
          child: T(
            s.generate_hardest_sudoku_in_the_world,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ButtonInference extends ConsumerWidget {
  const _ButtonInference();

  void _onPressed(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    if (!P.rwkv.loaded.q) {
      Alert.info(s.please_load_model_first);
      ModelSelector.show();
      return;
    }

    await P.sudoku.onInferencePressed(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final running = ref.watch(P.sudoku.running);
    final hasPuzzle = ref.watch(P.sudoku.hasPuzzle);
    return C(
      padding: const EI.o(b: _kButtonPadding),
      child: SB(
        height: _kButtonHeight,
        child: FilledButton(
          style: ButtonStyle(
            maximumSize: WidgetStateProperty.all(const Size(double.infinity, _kButtomSizeHeight)),
            minimumSize: WidgetStateProperty.all(const Size(double.infinity, _kButtomSizeHeight)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          onPressed: !hasPuzzle || running ? null : () => _onPressed(context, ref),
          child: running
              ? Row(
                  mainAxisAlignment: MAA.center,
                  children: [
                    SB(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SB(width: 8, height: 8),
                    T(s.thinking),
                  ],
                )
              : hasPuzzle
              ? T(s.start_to_inference, textAlign: TextAlign.center)
              : T(s.no_puzzle, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _ButtonClear extends ConsumerWidget {
  const _ButtonClear();

  void _onPressed(BuildContext context, WidgetRef ref) async {
    P.sudoku.onClearPressed(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final running = ref.watch(P.sudoku.running);
    return C(
      padding: const EI.o(b: _kButtonPadding),
      child: SB(
        height: _kButtonHeight,
        child: FilledButton(
          style: ButtonStyle(
            maximumSize: WidgetStateProperty.all(const Size(double.infinity, _kButtomSizeHeight)),
            minimumSize: WidgetStateProperty.all(const Size(double.infinity, _kButtomSizeHeight)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          onPressed: running ? null : () => _onPressed(context, ref),
          child: T(s.clear),
        ),
      ),
    );
  }
}

class _ButtonShowStack extends ConsumerWidget {
  const _ButtonShowStack();

  void _onPressed(BuildContext context, WidgetRef ref) async {
    P.sudoku.onToggleShowStack(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final showStack = ref.watch(P.sudoku.showStack);
    final currentStack = ref.watch(P.sudoku.currentStack);
    final enable = currentStack.isNotEmpty;
    return C(
      padding: const EI.o(b: _kButtonPadding),
      child: SB(
        height: _kButtonHeight,
        child: FilledButton(
          style: ButtonStyle(
            maximumSize: WidgetStateProperty.all(const Size(double.infinity, _kButtomSizeHeight)),
            minimumSize: WidgetStateProperty.all(const Size(double.infinity, _kButtomSizeHeight)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          onPressed: !enable ? null : () => _onPressed(context, ref),
          child: showStack ? T(s.hide_stack) : T(s.show_stack),
        ),
      ),
    );
  }
}

class _UI extends ConsumerWidget {
  const _UI();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final Offset position = renderBox.localToGlobal(Offset.zero);
      P.sudoku.uiOffset.q = Offset(position.dx, 0);
    });

    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    final isPortrait = (screenHeight - kToolbarHeight) > screenWidth;

    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final paddingTop = ref.watch(P.app.paddingTop);
    final min = math.min(screenWidth, screenHeight - paddingBottom - paddingTop);

    final ratio = screenWidth / screenHeight;
    final isDesktop = ref.watch(P.app.isDesktop);
    final double magnification = isDesktop ? 2 : 1;

    final shouldUseVerticalLayout = isDesktop && ratio < 1.9 && !isPortrait;

    final List<Widget> buttons = [
      const SB(width: 12, height: 12),
      T(
        "RWKV Chat",
        textAlign: TextAlign.center,
        s: TS(s: 14 * magnification, w: FontWeight.w500),
      ),
      C(
        height: 1,
        width: 1,
        decoration: BD(color: const Color(0xFF888888).q(0.33)),
        margin: const EI.s(v: 4, h: 4),
      ),
      const _TokensInfo(),
      4.h,
      if (shouldUseVerticalLayout)
        Column(
          children: [
            Row(
              children: [
                8.w,
                const Expanded(child: _ButtonGenerate()),
                8.w,
                const Expanded(child: _ButtonInference()),
                8.w,
              ],
            ),
            4.h,
            Row(
              children: [
                8.w,
                const Expanded(child: _ButtonClear()),
                4.w,
                const Expanded(child: _ButtonShowStack()),
                8.w,
              ],
            ),
          ],
        ),
      if (!shouldUseVerticalLayout) ...[
        const Padding(padding: EI.o(h: 12, v: 0), child: _ButtonGenerate()),
        if (isDesktop) const SB(width: 6, height: 6),
        const Padding(padding: EI.s(h: 12, v: 0), child: _ButtonInference()),
        if (isDesktop) const SB(width: 6, height: 6),
        const Padding(padding: EI.s(h: 12, v: 0), child: _ButtonClear()),
        if (isDesktop) const SB(width: 6, height: 6),
        const Padding(padding: EI.s(h: 12, v: 0), child: _ButtonShowStack()),
      ],
    ];

    final qw = ref.watch(P.app.qw);
    return C(
      width: shouldUseVerticalLayout ? min / 1.428 : min * (isPortrait ? 1 : 1.428),
      height: shouldUseVerticalLayout ? min : min * (isPortrait ? 0.7 : 1),
      decoration: BD(color: qw),
      margin: !isPortrait ? EI.o(t: paddingTop) : null,
      child: shouldUseVerticalLayout
          ? Column(
              children: [
                const Expanded(flex: 7, child: _Sudoku()),
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CAA.stretch, children: buttons),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CAA.stretch,
              children: [
                const Expanded(flex: 7, child: _Sudoku()),
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CAA.stretch, children: buttons),
                ),
              ],
            ),
    );
  }
}

class _Sudoku extends ConsumerWidget {
  const _Sudoku();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ref.watch(P.app.isDesktop);
    final double magnification = isDesktop ? 4 : 1;
    return C(
      decoration: const BD(color: _kGridBGColor),
      padding: EI.a(4 * magnification.toDouble()),
      child: const Stack(
        children: [
          _Board(),
          Positioned.fill(child: _Stack()),
        ],
      ),
    );
  }
}

class _Board extends ConsumerWidget {
  const _Board();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(P.sudoku.staticData);
    final dynamicData = ref.watch(P.sudoku.dynamicData);
    final isDesktop = ref.watch(P.app.isDesktop);
    final double magnification = isDesktop ? 2 : 1;
    return Column(
      children:
          List.generate(9, (rowIndex) {
            return Expanded(
              child: Row(
                children:
                    List.generate(9, (colIndex) {
                      final staticValue = staticData[rowIndex][colIndex];
                      final dynamicValue = dynamicData[rowIndex][colIndex];
                      final isStatic = dynamicValue == 0 || dynamicValue == staticValue;
                      final value = isStatic ? staticValue : dynamicValue;
                      return Expanded(
                        child: _Grid(
                          value: value,
                          isStatic: isStatic,
                          col: colIndex,
                          row: rowIndex,
                        ),
                      );
                    }).widgetJoin((e) {
                      return e % 3 == 2 ? (4 * magnification).w : (2 * magnification).w;
                    }),
              ),
            );
          }).widgetJoin((e) {
            return e % 3 == 2 ? (4 * magnification).h : (2 * magnification).h;
          }),
    );
  }
}

class _Stack extends ConsumerWidget {
  const _Stack();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showStack = ref.watch(P.sudoku.showStack);
    if (!showStack) {
      return const IgnorePointer(
        child: Stack(children: []),
      );
    }
    final widgetPosition = ref.watch(P.sudoku.widgetPosition);
    final uiOffset = ref.watch(P.sudoku.uiOffset);
    final padding = MediaQuery.of(context).padding;
    final _ = MediaQuery.of(context).orientation == Orientation.portrait;
    final currentStack = ref.watch(P.sudoku.currentStack);
    ref.watch(P.app.screenHeight);
    ref.watch(P.app.screenWidth);
    ref.watch(Pager.atMainPage);

    // debugger();
    return IgnorePointer(
      child: Stack(
        children: [
          ...currentStack
              .m((e) {
                final col = e.$2;
                final row = e.$1;
                final position = widgetPosition["$col-$row"];
                if (position == null) return C();
                return Positioned(
                  left: _kStackPointOffsetX + position.dx - uiOffset.dx,
                  top: _kStackPointOffsetY + position.dy - uiOffset.dy - padding.top,
                  child: C(
                    height: _kStackPointSize,
                    width: _kStackPointSize,
                    decoration: BD(
                      color: _kStackColor,
                      borderRadius: 100.r,
                    ),
                  ),
                );
              })
              .widgetJoin((e) {
                final start = currentStack[e];
                final end = currentStack[e + 1];
                final colStart = start.$2;
                final rowStart = start.$1;
                final startOffset = widgetPosition["$colStart-$rowStart"];
                final colEnd = end.$2;
                final rowEnd = end.$1;
                final endOffset = widgetPosition["$colEnd-$rowEnd"];
                if (startOffset == null || endOffset == null) return C();

                return AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 300),
                  child: CustomPaint(
                    painter: _ArrowPainter(
                      start: (startOffset - uiOffset).translate(
                        _kStackPointOffsetX + _kStackPointSize / 2,
                        _kStackPointOffsetY + _kStackPointSize / 2 - padding.top,
                      ),
                      end: (endOffset - uiOffset).translate(
                        _kStackPointOffsetX + _kStackPointSize / 2,
                        _kStackPointOffsetY + _kStackPointSize / 2 - padding.top,
                      ),
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }
}

class _TokensInfo extends ConsumerWidget {
  const _TokensInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenCount = ref.watch(P.sudoku.tokensCount);
    final tokensPerSecond = ref.watch(P.rwkv.decodeSpeed);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final ratio = screenWidth / screenHeight;
    final isDesktop = ref.watch(P.app.isDesktop);
    final shouldUseVerticalLayout = isDesktop && ratio < 2.2 && !isPortrait;
    final difficulty = ref.watch(P.sudoku.difficulty);
    return shouldUseVerticalLayout
        ? Row(
            mainAxisAlignment: MAA.center,
            children: [
              T(
                "$tokenCount ${tokenCount > 1 ? "tokens" : "token"}",
                textAlign: TextAlign.center,
                s: const TS(s: 10, c: Color(0xFF888888)),
              ),
              const SB(width: 4, height: 4),
              T(
                "${tokensPerSecond.toStringAsFixed(2)} tokens/s",
                textAlign: TextAlign.center,
                s: const TS(s: 10, c: Color(0xFF888888)),
              ),
              if (difficulty != null) ...[
                const SB(width: 4, height: 4),
                T(
                  "Unknown grid count: $difficulty",
                  textAlign: TextAlign.center,
                  s: const TS(s: 10, c: Color(0xFF888888)),
                ),
              ],
            ],
          )
        : Column(
            children: [
              T(
                "$tokenCount ${tokenCount > 1 ? "tokens" : "token"}",
                textAlign: TextAlign.center,
                s: const TS(s: 10, c: Color(0xFF888888)),
              ),
              T(
                "${tokensPerSecond.toStringAsFixed(2)} tokens/s",
                textAlign: TextAlign.center,
                s: const TS(s: 10, c: Color(0xFF888888)),
              ),
            ],
          );
  }
}

class _Grid extends ConsumerWidget {
  final int value;
  final bool isStatic;
  final int col;
  final int row;

  const _Grid({
    required this.value,
    required this.isStatic,
    required this.col,
    required this.row,
  });

  void _onPressed(BuildContext context, WidgetRef ref) async {
    P.sudoku.onGridPressed(context, col, row);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    late final Color bg;

    if (value == 0) {
      bg = _kEmptyGridColor;
    } else {
      if (isStatic) {
        bg = _kStaticGridColor;
      } else {
        bg = _kDynamicGridColor;
      }
    }

    final isDesktop = ref.watch(P.app.isDesktop);
    ref.watch(P.app.screenHeight);
    ref.watch(P.app.screenWidth);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      Offset position = renderBox.localToGlobal(Offset.zero);
      final atMainPage = Pager.atMainPage.q;
      // position = Offset(position.dx - (atMainPage ? drawerWidth : 0), position.dy);
      position = Offset(position.dx - (atMainPage ? 0 : 0), position.dy);

      P.sudoku.widgetPosition.q = {
        ...P.sudoku.widgetPosition.q,
        "$col-$row": position,
      };
    });

    final double magnification = isDesktop ? 2 : 1;
    return GD(
      onTap: () => _onPressed(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BD(color: bg, borderRadius: (2 * magnification).r),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            double textSize = maxWidth / 2;
            return Center(
              child: T(
                value != 0 ? value.toString() : "",
                s: TS(
                  c: kB,
                  s: textSize,
                  w: isDesktop ? FontWeight.w600 : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Terminal extends ConsumerWidget {
  const _Terminal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(P.sudoku.logs);
    final padding = MediaQuery.of(context).padding;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final isDesktop = ref.watch(P.app.isDesktop);
    final qw = ref.watch(P.app.qw);
    return SelectionArea(
      child: C(
        decoration: const BD(color: _kGridBGColor),
        child: ListView.builder(
          controller: P.sudoku.scrollController,
          padding: EI.o(
            t: !isPortrait ? padding.top + 8 : 8,
            l: isDesktop ? 16 : 8,
            r: isDesktop ? 16 : 8,
            b: padding.bottom + 16,
          ),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            return T(
              logs[index],
              s: TS(
                ff: "monospace",
                s: isDesktop ? 16 : 10,
                letterSpacing: 0,
                height: 1.2,
                c: kW.q(0.8),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Offset start;
  final Offset end;

  _ArrowPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kStackColor
      ..strokeWidth = _kStackPointerStrokeWidth
      ..style = PaintingStyle.stroke;

    // 画箭头线
    canvas.drawLine(start, end, paint);

    // 计算箭头的方向
    const arrowLength = 10.0;
    const arrowAngle = 0.33; // 弧度

    final angle = (end - start).direction;
    final arrow1 = Offset(
      end.dx - arrowLength * cos(angle - arrowAngle),
      end.dy - arrowLength * sin(angle - arrowAngle),
    );
    final arrow2 = Offset(
      end.dx - arrowLength * cos(angle + arrowAngle),
      end.dy - arrowLength * sin(angle + arrowAngle),
    );

    // 画箭头
    canvas.drawLine(end, arrow1, paint);
    canvas.drawLine(end, arrow2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
