import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/cell_type.dart';
import 'package:zone/store/p.dart';
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
                const SizedBox(height: 12),
                const _Title(),
                const SizedBox(height: 12),
                const _Score(),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: .center,
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
                    const SizedBox(width: 8),
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
                  crossAxisAlignment: .center,
                  children: [
                    const _Title(),
                    const SizedBox(height: 4),
                    const _Score(),
                    const SizedBox(height: 4),
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
                              crossAxisAlignment: .center,
                              mainAxisAlignment: .center,
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
      mainAxisAlignment: .center,
      children: [
        const SizedBox(width: 12),
        Text("$version($buildNumber)", style: TS(c: qb.q(.0), s: 10)),
        if (usePortrait) const Spacer(),
        Text(
          s.rwkv_othello,
          style: const TS(s: 20, w: .w700),
        ),
        if (usePortrait) const Spacer(),
        if (!usePortrait) const SizedBox(width: 32),
        Text("$version($buildNumber)", style: TS(c: qb.q(.5), s: 10)),
        if (!usePortrait) const SizedBox(width: 32),
        const SizedBox(width: 12),
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
      mainAxisSize: .min,
      mainAxisAlignment: .center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: .zero,
            onPressed: searchDepthRemoveAvailable
                ? () {
                    P.othello.searchDepth.ua(-1);
                  }
                : null,
            icon: const Icon(Icons.remove),
            iconSize: 14,
            style: ButtonStyle(
              minimumSize: .all(const Size(16, 16)),
              padding: .all(.zero),
            ),
          ),
        ),
        Text(searchDepth.toString()),
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
              minimumSize: .all(const Size(16, 16)),
              padding: .all(.zero),
            ),
          ),
        ),
      ],
    );

    final searchBreadthControls = Row(
      mainAxisSize: .min,
      mainAxisAlignment: .center,
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
              minimumSize: .all(const Size(16, 16)),
              padding: .all(.zero),
            ),
          ),
        ),
        Text(searchBreadth.toString()),
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
              minimumSize: .all(const Size(16, 16)),
              padding: .all(.zero),
            ),
          ),
        ),
      ],
    );
    final qb = ref.watch(P.app.qb);

    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);

    return Material(
      color: qb.q(.0),
      textStyle: TS(ff: monospaceFF, s: 10),
      child: Container(
        padding: const .all(4),
        margin: const .all(4),
        decoration: BoxDecoration(
          color: qb.q(.0),
          borderRadius: .circular(4),
          border: .all(color: qb.q(.5), width: .5),
        ),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisAlignment: .center,
          children: [
            Text(
              s.model_settings,
              style: const TS(w: .w700),
            ),
            const SizedBox(height: 8),
            Text(s.in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2, style: TS(c: qb.q(.5), s: 10)),
            const SizedBox(height: 8),
            usePortrait
                ? Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      Text(s.search_depth, textAlign: TextAlign.center),
                      searchDepthControls,
                      const SizedBox(height: 4),
                      Text(s.search_breadth, textAlign: TextAlign.center),
                      searchBreadthControls,
                    ],
                  )
                : Wrap(
                    children: [
                      Row(
                        children: [
                          Text(s.search_depth, textAlign: TextAlign.center),
                          searchDepthControls,
                        ],
                      ),
                      Row(
                        children: [
                          Text(s.search_breadth, textAlign: TextAlign.center),
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

    final blackOptions = Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: .circular(4),
        border: .all(color: qb.q(.5), width: .5),
      ),
      padding: const .only(left: 8, top: 8, right: 8),
      child: Wrap(
        crossAxisAlignment: .center,
        children: [
          Text(
            s.black + ":",
            textAlign: TextAlign.center,
            style: const TS(w: .w700),
          ),
          Wrap(
            children: [
              Row(
                mainAxisSize: .min,
                children: [
                  Radio(
                    value: false,
                    groupValue: blackIsAI,
                    onChanged: (value) {
                      P.othello.blackIsAI.q = false;
                    },
                  ),
                  Text(s.human),
                ],
              ),
              Row(
                mainAxisSize: .min,
                children: [
                  Radio(
                    value: true,
                    groupValue: blackIsAI,
                    onChanged: (value) {
                      P.othello.blackIsAI.q = true;
                    },
                  ),
                  Text(s.rwkv),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final whiteOptions = Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: .circular(4),
        border: .all(color: qb.q(.5), width: .5),
      ),
      padding: const .only(left: 8, top: 8, right: 8),
      child: Wrap(
        crossAxisAlignment: .center,
        children: [
          Text(
            s.white + ":",
            textAlign: TextAlign.center,
            style: const TS(w: .w700),
          ),
          Wrap(
            children: [
              Row(
                mainAxisSize: .min,
                children: [
                  Radio(
                    value: false,
                    groupValue: whiteIsAI,
                    onChanged: (value) {
                      P.othello.whiteIsAI.q = false;
                    },
                  ),
                  Text(s.human),
                ],
              ),
              Row(
                mainAxisSize: .min,
                children: [
                  Radio(
                    value: true,
                    groupValue: whiteIsAI,
                    onChanged: (value) {
                      P.othello.whiteIsAI.q = true;
                    },
                  ),
                  Text(s.rwkv),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);

    return Material(
      color: qb.q(.0),
      textStyle: TS(ff: monospaceFF, s: 10),
      child: Container(
        margin: const .all(4),
        padding: const .all(4),
        decoration: BoxDecoration(
          color: qb.q(.0),
          borderRadius: .circular(4),
          border: .all(color: qb.q(.5), width: .5),
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              s.players,
              style: const TS(w: .w700),
            ),
            const SizedBox(height: 12),
            if (usePortrait && !playerShouldAtSameColumnWithSettings && !settingsAndPlayersShouldAtDifferentColumnIsHorizontal)
              Row(
                mainAxisAlignment: .center,
                children: [
                  Expanded(
                    child: blackOptions,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: whiteOptions,
                  ),
                ],
              ),
            if (settingsAndPlayersShouldAtDifferentColumnIsHorizontal)
              Row(
                mainAxisAlignment: .center,
                children: [
                  Expanded(
                    child: blackOptions,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: whiteOptions,
                  ),
                ],
              ),
            if (playerShouldAtSameColumnWithSettings && !settingsAndPlayersShouldAtDifferentColumnIsHorizontal)
              Column(
                children: [
                  blackOptions,
                  const SizedBox(height: 4),
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
    final generating = ref.watch(P.rwkv.generating);
    final usePortrait = ref.watch(P.othello.usePortrait);
    final prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final decodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final qb = ref.watch(P.app.qb);

    final thinkingWidget = Column(
      mainAxisSize: .min,
      children: [
        AnimatedOpacity(
          opacity: generating ? 1.0 : .5,
          duration: const Duration(milliseconds: 150),
          child: Text(
            s.thinking,
            style: TS(s: 10, w: generating ? .w400 : .w400),
          ),
        ),
        Text(
          "${s.prefill}: ${prefillSpeed.toStringAsFixed(1)} t/s",
          style: const TS(s: 10, w: .w400),
        ),
        Text(
          "${s.decode}: ${decodeSpeed.toStringAsFixed(1)} t/s",
          style: const TS(s: 10, w: .w400),
        ),
      ],
    );

    final newGameButton = TextButton(
      onPressed: generating
          ? null
          : () {
              P.othello.start();
            },
      child: Text(
        s.new_game,
        style: const TS(s: 10, w: .w500),
      ),
    );

    return Row(
      crossAxisAlignment: .center,
      children: [
        if (usePortrait) Expanded(child: thinkingWidget),
        if (!usePortrait) thinkingWidget,
        if (!usePortrait) const SizedBox(width: 16),
        Text(
          "${s.black}\n$blackScore",
          textAlign: TextAlign.center,
        ),
        const SizedBox(width: 16),
        Container(
          padding: const .only(left: 8, right: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: .circular(8),
            border: .all(color: qb.q(.5), width: .5),
          ),
          child: Column(
            children: [
              Text(s.current_turn),
              const SizedBox(height: 4),
              if (blackTurn) const _Black(minSize: 5, maxSize: 25),
              if (!blackTurn) const _White(minSize: 5, maxSize: 25),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          "${s.white}\n$whiteScore",
          textAlign: TextAlign.center,
        ),
        if (usePortrait) Expanded(child: newGameButton),
        if (!usePortrait) const SizedBox(width: 16),
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
                  child: GestureDetector(
                    onTap: () {
                      _onCellTap(row: row, col: col);
                    },
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFF808080).q(.5)),
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
              child: Text(
                e,
                style: const TS(s: 10, w: .w700),
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
              child: Text(
                e,
                style: const TS(s: 10, w: .w700),
              ),
            ),
          );
        }).toList();

        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: Colors.transparent),
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
                Container(
                  constraints: BoxConstraints(
                    minWidth: minAvailableSize,
                    minHeight: minAvailableSize,
                    maxWidth: maxAvailableSize,
                    maxHeight: maxAvailableSize,
                  ),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: 100.r),
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
    return Container(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
        maxWidth: maxSize,
        maxHeight: maxSize,
      ),
      decoration: BoxDecoration(
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
        borderRadius: .circular(100),
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
    return Container(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
        maxWidth: maxSize,
        maxHeight: maxSize,
      ),
      decoration: BoxDecoration(
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
        borderRadius: .circular(100),
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
        padding: .only(
          left: 8 + (usePortrait ? 0 : paddingLeft),
          top: 8 + (usePortrait ? 0 : paddingTop),
          right: 8,
          bottom: 8 + (usePortrait ? paddingBottom : paddingBottom),
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

          // return Text(received[index]);

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
            style: TS(c: qw, s: 12, w: .w500),
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
    Color color = Colors.transparent;
    switch (cellType) {
      case CellType.black:
        color = Colors.black;
        break;
      case CellType.white:
        color = Colors.white;
        break;
      case CellType.empty:
        color = Colors.transparent;
        break;
    }
    return Container(
      height: 12,
      width: 12,
      margin: const .symmetric(horizontal: 1),
      decoration: BoxDecoration(color: qw.q(.33)),
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
