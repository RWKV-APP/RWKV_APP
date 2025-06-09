import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/cell_type.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/menu.dart';
import 'package:zone/widgets/pager.dart';

class PageOthello extends StatelessWidget {
  const PageOthello({super.key});

  @override
  Widget build(BuildContext context) {
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
    final paddingTop = ref.watch(P.app.paddingTop);
    final usePortrait = ref.watch(P.othello.usePortrait);
    final playerShouldAtSameColumnWithSettings = ref.watch(P.othello.playerShouldAtSameColumnWithSettings);
    final settingsAndPlayersShouldAtDifferentColumnIsHorizontal = ref.watch(
      P.othello.settingsAndPlayersShouldAtDifferentColumnIsHorizontal,
    );
    final screenWidth = ref.watch(P.app.screenWidth);
    final paddingRight = ref.watch(P.app.paddingRight);
    final qw = ref.watch(P.app.qw);

    return Scaffold(
      backgroundColor: qw,
      body: usePortrait
          ? Column(
              children: [
                paddingTop.h,
                12.h,
                const _Title(),
                12.h,
                const _Score(),
                4.h,
                Row(
                  crossAxisAlignment: CAA.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const _ModelSettings(),
                          if (playerShouldAtSameColumnWithSettings) const _Players(),
                        ],
                      ),
                    ),
                    const _Othello(),
                    8.w,
                  ],
                ),
                if (!playerShouldAtSameColumnWithSettings) const _Players(),
                const Expanded(child: _Console()),
              ],
            )
          : Row(
              children: [
                const Expanded(child: _Console()),
                Column(
                  crossAxisAlignment: CAA.center,
                  children: [
                    const _Title(),
                    4.h,
                    const _Score(),
                    4.h,
                    Row(
                      children: [
                        Column(
                          children: [
                            const _Othello(),
                            if (!settingsAndPlayersShouldAtDifferentColumnIsHorizontal) const _ModelSettings(),
                            if (!settingsAndPlayersShouldAtDifferentColumnIsHorizontal) const _Players(),
                          ],
                        ),
                        if (settingsAndPlayersShouldAtDifferentColumnIsHorizontal)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: screenWidth * .33,
                            ),
                            child: const Column(
                              crossAxisAlignment: CAA.center,
                              mainAxisAlignment: MAA.center,
                              children: [
                                _ModelSettings(),
                                _Players(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                paddingRight.w,
              ],
            ),
    );
  }
}

class _Title extends ConsumerWidget {
  const _Title();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final version = ref.watch(P.app.version);
    final buildNumber = ref.watch(P.app.buildNumber);
    final usePortrait = ref.watch(P.othello.usePortrait);
    final qb = ref.watch(P.app.qb);
    return Row(
      mainAxisAlignment: MAA.center,
      children: [
        12.w,
        T("$version($buildNumber)", s: TS(c: qb.q(.0), s: 10)),
        if (usePortrait) const Spacer(),
        T(
          s.rwkv_othello,
          s: const TS(s: 20, w: FW.w700),
        ),
        if (usePortrait) const Spacer(),
        if (!usePortrait) 32.w,
        T("$version($buildNumber)", s: TS(c: qb.q(.5), s: 10)),
        if (!usePortrait) 32.w,
        12.w,
      ],
    );
  }
}

class _ModelSettings extends ConsumerWidget {
  const _ModelSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final usePortrait = ref.watch(P.othello.usePortrait);
    final searchDepth = ref.watch(P.othello.searchDepth);
    final searchBreadth = ref.watch(P.othello.searchBreadth);

    final searchDepthAddAvailable = searchDepth < 5;
    final searchDepthRemoveAvailable = searchDepth > 1;
    final searchBreadthAddAvailable = searchBreadth < 5;
    final searchBreadthRemoveAvailable = searchBreadth > 1;

    final searchDepthControls = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MAA.center,
      children: [
        SB(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EI.zero,
            onPressed: searchDepthRemoveAvailable
                ? () {
                    P.othello.searchDepth.ua(-1);
                  }
                : null,
            icon: const Icon(Icons.remove),
            iconSize: 14,
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(16, 16)),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
            ),
          ),
        ),
        T(searchDepth.toString()),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            onPressed: searchDepthAddAvailable
                ? () {
                    P.othello.searchDepth.ua(1);
                  }
                : null,
            icon: const Icon(Icons.add),
            iconSize: 14,
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(16, 16)),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
            ),
          ),
        ),
      ],
    );

    final searchBreadthControls = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MAA.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            onPressed: searchBreadthRemoveAvailable
                ? () {
                    P.othello.searchBreadth.ua(-1);
                  }
                : null,
            icon: const Icon(Icons.remove),
            iconSize: 14,
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(16, 16)),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
            ),
          ),
        ),
        T(searchBreadth.toString()),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            onPressed: searchBreadthAddAvailable
                ? () {
                    P.othello.searchBreadth.ua(1);
                  }
                : null,
            icon: const Icon(Icons.add),
            iconSize: 14,
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(16, 16)),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
            ),
          ),
        ),
      ],
    );
    final qb = ref.watch(P.app.qb);

    return Material(
      color: qb.q(.0),
      textStyle: const TS(ff: "monospace", s: 10),
      child: C(
        padding: const EI.a(4),
        margin: const EI.a(4),
        decoration: BD(
          color: qb.q(.0),
          borderRadius: 4.r,
          border: Border.all(color: qb.q(.5), width: .5),
        ),
        child: Column(
          crossAxisAlignment: CAA.start,
          mainAxisAlignment: MAA.center,
          children: [
            T(
              s.model_settings,
              s: const TS(w: FW.w700),
            ),
            8.h,
            T(s.in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2, s: TS(c: qb.q(.5), s: 10)),
            8.h,
            usePortrait
                ? Column(
                    crossAxisAlignment: CAA.stretch,
                    children: [
                      T(s.search_depth, textAlign: TextAlign.center),
                      searchDepthControls,
                      4.h,
                      T(s.search_breadth, textAlign: TextAlign.center),
                      searchBreadthControls,
                    ],
                  )
                : Wrap(
                    children: [
                      Row(
                        children: [
                          T(s.search_depth, textAlign: TextAlign.center),
                          searchDepthControls,
                        ],
                      ),
                      Row(
                        children: [
                          T(s.search_breadth, textAlign: TextAlign.center),
                          searchBreadthControls,
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _Players extends ConsumerWidget {
  const _Players();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final blackIsAI = ref.watch(P.othello.blackIsAI);
    final whiteIsAI = ref.watch(P.othello.whiteIsAI);
    final playerShouldAtSameColumnWithSettings = ref.watch(P.othello.playerShouldAtSameColumnWithSettings);
    final settingsAndPlayersShouldAtDifferentColumnIsHorizontal = ref.watch(
      P.othello.settingsAndPlayersShouldAtDifferentColumnIsHorizontal,
    );
    final usePortrait = ref.watch(P.othello.usePortrait);
    final qb = ref.watch(P.app.qb);

    final blackOptions = C(
      decoration: BD(
        color: kC,
        borderRadius: 4.r,
        border: Border.all(color: qb.q(.5), width: .5),
      ),
      padding: const EI.o(l: 8, r: 8, t: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          T(
            s.black + ":",
            textAlign: TextAlign.center,
            s: const TS(w: FW.w700),
          ),
          Wrap(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio(
                    value: false,
                    groupValue: blackIsAI,
                    onChanged: (value) {
                      P.othello.blackIsAI.q = false;
                    },
                  ),
                  T(s.human),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio(
                    value: true,
                    groupValue: blackIsAI,
                    onChanged: (value) {
                      P.othello.blackIsAI.q = true;
                    },
                  ),
                  T(s.rwkv),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final whiteOptions = C(
      decoration: BD(
        color: kC,
        borderRadius: 4.r,
        border: Border.all(color: qb.q(.5), width: .5),
      ),
      padding: const EI.o(l: 8, r: 8, t: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          T(
            s.white + ":",
            textAlign: TextAlign.center,
            s: const TS(w: FW.w700),
          ),
          Wrap(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio(
                    value: false,
                    groupValue: whiteIsAI,
                    onChanged: (value) {
                      P.othello.whiteIsAI.q = false;
                    },
                  ),
                  T(s.human),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio(
                    value: true,
                    groupValue: whiteIsAI,
                    onChanged: (value) {
                      P.othello.whiteIsAI.q = true;
                    },
                  ),
                  T(s.rwkv),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return Material(
      color: qb.q(.0),
      textStyle: const TS(ff: "monospace", s: 10),
      child: C(
        margin: const EI.a(4),
        padding: const EI.a(4),
        decoration: BD(
          color: qb.q(.0),
          borderRadius: 4.r,
          border: Border.all(color: qb.q(.5), width: .5),
        ),
        child: Column(
          crossAxisAlignment: CAA.start,
          children: [
            T(
              s.players,
              s: const TS(w: FW.w700),
            ),
            12.h,
            if (usePortrait && !playerShouldAtSameColumnWithSettings && !settingsAndPlayersShouldAtDifferentColumnIsHorizontal)
              Row(
                mainAxisAlignment: MAA.center,
                children: [
                  Expanded(
                    child: blackOptions,
                  ),
                  16.w,
                  Expanded(
                    child: whiteOptions,
                  ),
                ],
              ),
            if (settingsAndPlayersShouldAtDifferentColumnIsHorizontal)
              Row(
                mainAxisAlignment: MAA.center,
                children: [
                  Expanded(
                    child: blackOptions,
                  ),
                  16.w,
                  Expanded(
                    child: whiteOptions,
                  ),
                ],
              ),
            if (playerShouldAtSameColumnWithSettings && !settingsAndPlayersShouldAtDifferentColumnIsHorizontal)
              Column(
                children: [
                  blackOptions,
                  4.h,
                  whiteOptions,
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Score extends ConsumerWidget {
  const _Score();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final blackScore = ref.watch(P.othello.blackScore);
    final whiteScore = ref.watch(P.othello.whiteScore);
    final blackTurn = ref.watch(P.othello.blackTurn);
    final thinking = ref.watch(P.othello.receivingTokens);
    final usePortrait = ref.watch(P.othello.usePortrait);
    final prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final decodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final qb = ref.watch(P.app.qb);

    final thinkingWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          opacity: thinking ? 1.0 : .5,
          duration: const Duration(milliseconds: 150),
          child: T(
            s.thinking,
            s: TS(s: 10, w: thinking ? FW.w400 : FW.w400),
          ),
        ),
        T(
          "${s.prefill}: ${prefillSpeed.toStringAsFixed(1)} t/s",
          s: const TS(s: 10, w: FW.w400),
        ),
        T(
          "${s.decode}: ${decodeSpeed.toStringAsFixed(1)} t/s",
          s: const TS(s: 10, w: FW.w400),
        ),
      ],
    );

    final newGameButton = TextButton(
      onPressed: thinking
          ? null
          : () {
              P.othello.start();
            },
      child: T(
        s.new_game,
        s: const TS(s: 10, w: FW.w500),
      ),
    );

    return Row(
      crossAxisAlignment: CAA.center,
      children: [
        if (usePortrait) Expanded(child: thinkingWidget),
        if (!usePortrait) thinkingWidget,
        if (!usePortrait) 16.w,
        T(
          "${s.black}\n$blackScore",
          textAlign: TextAlign.center,
        ),
        16.w,
        C(
          padding: const EI.o(t: 0, b: 8, l: 8, r: 8),
          decoration: BD(
            color: kC,
            borderRadius: 8.r,
            border: Border.all(color: qb.q(.5), width: .5),
          ),
          child: Column(
            children: [
              T(s.current_turn),
              4.h,
              if (blackTurn) const _Black(minSize: 5, maxSize: 25),
              if (!blackTurn) const _White(minSize: 5, maxSize: 25),
            ],
          ),
        ),
        16.w,
        T(
          "${s.white}\n$whiteScore",
          textAlign: TextAlign.center,
        ),
        if (usePortrait) Expanded(child: newGameButton),
        if (!usePortrait) 16.w,
        if (!usePortrait) newGameButton,
      ],
    );
  }
}

class _Othello extends ConsumerWidget {
  const _Othello();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    return Row(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth * .65,
            maxHeight: screenHeight * .65,
          ),
          child: const _Grid(),
        ),
      ],
    );
  }
}

class _Grid extends ConsumerWidget {
  const _Grid();

  static final double _sepWidth = 2.0;
  static final int _cellPerLine = 8;
  static final int _sepPerLine = _cellPerLine - 1;

  void _onCellTap({required int row, required int col}) async {
    await P.othello.onCellTap(row: row, col: col);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(P.othello.state);
    final blackTurn = ref.watch(P.othello.blackTurn);
    final eatCountMatrixForBlack = ref.watch(P.othello.eatCountMatrixForBlack);
    final eatCountMatrixForWhite = ref.watch(P.othello.eatCountMatrixForWhite);
    final rulesHorizontalNames = ["a", "b", "c", "d", "e", "f", "g", "h"];
    final rulesVerticalNames = ["1", "2", "3", "4", "5", "6", "7", "8"];
    final labelSize = 16.0;
    final qb = ref.watch(P.app.qb);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final size = min(width, height);
        final sizeForCells = size - labelSize - _sepPerLine * _sepWidth;
        final sizeForCell = sizeForCells / _cellPerLine;

        final cells = state
            .indexMap((row, line) {
              return line.indexMap((col, cellType) {
                final left = col * sizeForCell + col * _sepWidth;
                final top = row * sizeForCell + row * _sepWidth;
                final available = blackTurn ? eatCountMatrixForBlack[row][col] > 0 : eatCountMatrixForWhite[row][col] > 0;
                return Positioned(
                  left: left + labelSize,
                  top: top + labelSize,
                  width: sizeForCell,
                  height: sizeForCell,
                  child: GD(
                    onTap: () {
                      _onCellTap(row: row, col: col);
                    },
                    child: C(
                      decoration: BD(color: const Color(0xFF808080).q(.5)),
                      child: _Cell(
                        row: row,
                        col: col,
                        cellType: cellType,
                        available: available,
                      ),
                    ),
                  ),
                );
              });
            })
            .expand((e) => e)
            .toList();

        final rulesHorizontal = rulesHorizontalNames.indexMap((col, e) {
          final left = col * sizeForCell + col * _sepWidth + labelSize;
          return Positioned(
            left: left,
            top: 0,
            width: sizeForCell,
            height: labelSize,
            child: Center(
              child: T(
                e,
                s: const TS(s: 10, w: FW.w700),
              ),
            ),
          );
        }).toList();

        final rulesVertical = rulesVerticalNames.indexMap((row, e) {
          final top = row * sizeForCell + row * _sepWidth + labelSize;
          return Positioned(
            left: 0,
            top: top,
            height: sizeForCell,
            width: labelSize,
            child: Center(
              child: T(
                e,
                s: const TS(s: 10, w: FW.w700),
              ),
            ),
          );
        }).toList();

        return C(
          width: size,
          height: size,
          decoration: const BD(color: kC),
          child: Stack(
            children: [
              ...cells,
              ...rulesHorizontal,
              ...rulesVertical,
            ],
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.row,
    required this.col,
    required this.cellType,
    required this.available,
  });

  final int row;
  final int col;
  final CellType cellType;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = min(constraints.maxWidth, constraints.maxHeight) * .7;
        final minSize = 5.0;

        final maxAvailableSize = min(constraints.maxWidth, constraints.maxHeight) * .2;
        final minAvailableSize = minSize - 2;

        if (available) {
          return Center(
            child: Stack(
              children: [
                C(
                  constraints: BoxConstraints(
                    minWidth: minAvailableSize,
                    minHeight: minAvailableSize,
                    maxWidth: maxAvailableSize,
                    maxHeight: maxAvailableSize,
                  ),
                  decoration: BD(color: Colors.green, borderRadius: 100.r),
                ),
              ],
            ),
          );
        }

        switch (cellType) {
          case CellType.empty:
            return const Center(
              child: SizedBox.shrink(),
            );
          case CellType.black:
            return Center(
              child: _Black(minSize: minSize, maxSize: maxSize),
            );
          case CellType.white:
            return Center(
              child: _White(minSize: minSize, maxSize: maxSize),
            );
        }
      },
    );
  }
}

class _White extends StatelessWidget {
  const _White({
    required this.minSize,
    required this.maxSize,
  });

  final double minSize;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    return C(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
        maxWidth: maxSize,
        maxHeight: maxSize,
      ),
      decoration: BD(
        boxShadow: [
          BoxShadow(
            color: Colors.black.q(.3),
            offset: const Offset(1, 1),
            blurRadius: 3,
          ),
        ],
        gradient: RadialGradient(
          center: const Alignment(-.5, -.5),
          colors: [
            Colors.white,
            Colors.grey[300]!,
          ],
        ),
        borderRadius: 100.r,
      ),
    );
  }
}

class _Black extends StatelessWidget {
  const _Black({
    required this.minSize,
    required this.maxSize,
  });

  final double minSize;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    return C(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
        maxWidth: maxSize,
        maxHeight: maxSize,
      ),
      decoration: BD(
        boxShadow: [
          BoxShadow(
            color: Colors.black.q(.3),
            offset: const Offset(1, 1),
            blurRadius: 3,
          ),
        ],
        gradient: RadialGradient(
          center: const Alignment(-.5, -.5),
          colors: [
            Colors.grey[700]!,
            Colors.black,
          ],
        ),
        borderRadius: 100.r,
      ),
    );
  }
}

class _Console extends ConsumerWidget {
  const _Console();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = P.othello.receivedScrollController;
    final received = (ref.watch(P.othello.received)).split("\n");
    final usePortrait = ref.watch(P.othello.usePortrait);
    final paddingTop = ref.watch(P.app.paddingTop);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final paddingLeft = ref.watch(P.app.paddingLeft);
    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);

    return Material(
      color: qb,
      textStyle: TS(ff: (Platform.isIOS || Platform.isMacOS) ? "Menlo" : "Monospace", c: qw, s: 10),
      child: ListView.builder(
        padding: EI.o(
          t: 8 + (usePortrait ? 0 : paddingTop),
          b: 8 + (usePortrait ? paddingBottom : paddingBottom),
          l: 8 + (usePortrait ? 0 : paddingLeft),
          r: 8,
        ),
        controller: controller,
        itemCount: received.length,
        itemBuilder: (context, index) {
          final List<CellType> girds = [];

          final line = received[index];
          final chars = line.split("");

          for (var i = 0; i < chars.length; i++) {
            final e = chars[i];
            if (e == "●") {
              girds.add(CellType.black);
            } else if (e == "○") {
              girds.add(CellType.white);
            } else if (e == "·") {
              girds.add(CellType.empty);
            } else {}
          }

          final text = line.replaceAll("● ", "").replaceAll("○ ", "").replaceAll("· ", "").trim();

          // qqq("girds: $girds");

          // return T(received[index]);

          return Text.rich(
            TextSpan(
              children: [
                if (text.isNotEmpty) TextSpan(text: text),
                if (girds.isNotEmpty)
                  ...girds.map((e) {
                    if (e == CellType.black) {
                      return const WidgetSpan(child: _ConsoleCell(cellType: CellType.black));
                    } else if (e == CellType.white) {
                      return const WidgetSpan(child: _ConsoleCell(cellType: CellType.white));
                    } else {
                      return const WidgetSpan(child: _ConsoleCell(cellType: CellType.empty));
                    }
                  }),
              ],
            ),
            style: TS(c: qw, s: 12, w: FW.w500),
          );
        },
      ),
    );
  }
}

class _ConsoleCell extends ConsumerWidget {
  const _ConsoleCell({required this.cellType});

  final CellType cellType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qw = ref.watch(P.app.qw);
    Color color = kC;
    switch (cellType) {
      case CellType.black:
        color = Colors.black;
        break;
      case CellType.white:
        color = Colors.white;
        break;
      case CellType.empty:
        color = kC;
        break;
    }
    return C(
      height: 12,
      width: 12,
      margin: const EI.s(h: 1),
      decoration: BD(color: qw.q(.33)),
      child: Center(
        child: Icon(
          Icons.circle,
          size: 10,
          color: color,
        ),
      ),
    );
  }
}
