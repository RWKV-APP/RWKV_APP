part of 'p.dart';

class _Othello {
  late final state = qs<List<List<CellType>>>(List.generate(8, (_) => List.filled(8, CellType.empty)));

  late final blackScore = qp((ref) {
    final state = ref.watch(P.othello.state);
    final l0 = state.fold<List<CellType>>([], (previousValue, element) => previousValue + element);
    final score = l0.where((e) => e == CellType.black).length;
    return score;
  });

  late final whiteScore = qp((ref) {
    final state = ref.watch(P.othello.state);
    final l0 = state.fold<List<CellType>>([], (previousValue, element) => previousValue + element);
    final score = l0.where((e) => e == CellType.white).length;
    return score;
  });

  /// row, col
  late final eatCountMatrixForBlack = qs<List<List<int>>>(List.generate(8, (_) => List.filled(8, 0)));

  /// row, col
  late final eatCountMatrixForWhite = qs<List<List<int>>>(List.generate(8, (_) => List.filled(8, 0)));

  @Deprecated("Use P.rwkv.receiving instead")
  late final receivingTokens = qs(false);

  late final blackTurn = qs(_blackFirst);

  static final _blackFirst = true;

  late final received = qs("");

  late final searchDepth = qs(1);

  late final searchBreadth = qs(1);

  late final receivedScrollController = ScrollController();

  bool _receivingPlacing = false;

  late final modelPlacingController = StreamController<(int col, int row)>();

  late final latestPlacing = qs<(int col, int row)?>(null);

  late final usePortrait = qs(true);

  late final playerShouldAtSameColumnWithSettings = qs(true);

  late final settingsAndPlayersShouldAtDifferentColumnIsHorizontal = qs(false);

  late final blackIsAI = qs(false);

  late final whiteIsAI = qs(true);
}

/// Public methods
extension $Othello on _Othello {
  void start() {
    _clear();
  }

  FV onCellTap({required int row, required int col}) async {
    final thinking = receivingTokens.q;
    if (thinking) return;
    final eatCountMatrixForBlack = this.eatCountMatrixForBlack.q;
    final eatCountMatrixForWhite = this.eatCountMatrixForWhite.q;
    bool blackTurn = this.blackTurn.q;
    final eatCount = blackTurn ? eatCountMatrixForBlack[row][col] : eatCountMatrixForWhite[row][col];
    if (eatCount == 0) {
      return;
    }

    _eat(row: row, col: col, dryRun: false, forBlack: blackTurn);

    blackTurn = this.blackTurn.q;

    final allZeroForBlack = this.eatCountMatrixForBlack.q.every((row) => row.every((col) => col == 0));
    final allZeroForWhite = this.eatCountMatrixForWhite.q.every((row) => row.every((col) => col == 0));
    final allZero = allZeroForBlack && allZeroForWhite;

    if (allZero) {
      _showGameOverDialog();
      return;
    }

    bool noCellAvailable = false;

    if (blackTurn && allZeroForBlack) {
      this.blackTurn.q = false;
      noCellAvailable = true;
    }

    if (!blackTurn && allZeroForWhite) {
      this.blackTurn.q = true;
      noCellAvailable = true;
    }

    if (noCellAvailable) {
      final title = (allZeroForBlack ? S.current.black : S.current.white) + ": " + S.current.no_cell_available;
      final message = S.current.turn_transfer + ": " + (allZeroForBlack ? S.current.white : S.current.black);
      await showOkAlertDialog(
        context: getContext()!,
        title: title,
        message: message,
      );
    }

    final blackAuto = blackIsAI.q && (this.blackTurn.q);
    final whiteAuto = whiteIsAI.q && !(this.blackTurn.q);

    if (blackAuto || whiteAuto) {
      qqr("Auto placing!");

      receivingTokens.q = true;

      final prompt = _generatePrompt();

      P.rwkv.generate(prompt);
      receivingTokens.q = false;
    }
  }
}

/// Private methods
extension _$Othello on _Othello {
  FV _init() async {
    switch (P.app.demoType.q) {
      case DemoType.fifthteenPuzzle:
      case DemoType.sudoku:
      case DemoType.chat:
      case DemoType.tts:
      case DemoType.world:
        return;
      case DemoType.othello:
    }
    qq;

    P.app.pageKey.lb((_, next) {
      if (next == PageKey.othello) {
        start();
      }
    }, fireImmediately: true);

    P.rwkv.oldBroadcastStream.listen(_onOldStreamEvent, onDone: _onStreamDone, onError: _onStreamError);
    P.rwkv.broadcastStream.listen(_onStreamEvent, onDone: _onStreamDone, onError: _onStreamError);

    blackTurn.lv(_onBlackTurnChanged, fireImmediately: true);
    state.lv(_onStateChanged, fireImmediately: true);

    modelPlacingController.stream.listen(_onPlacingEventReceived);

    P.app.screenWidth.lv(_syncLayout, fireImmediately: true);
    P.app.screenHeight.lv(_syncLayout, fireImmediately: true);
    P.app.paddingTop.lv(_syncLayout, fireImmediately: true);
    P.app.paddingBottom.lv(_syncLayout, fireImmediately: true);
    P.app.paddingLeft.lv(_syncLayout, fireImmediately: true);
    P.app.paddingRight.lv(_syncLayout, fireImmediately: true);

    if (Config.firstPage == PageKey.othello.name) {
      HF.wait(1000).then((_) {
        P.rwkv.loadOthello();
      });
    }
  }

  void _onPlacingEventReceived((int row, int col) event) async {
    latestPlacing.q = event;

    final isBlackTurn = blackTurn.q;
    final blackIsAI = this.blackIsAI.q;
    final whiteIsAI = this.whiteIsAI.q;

    if (isBlackTurn && !blackIsAI) {
      return;
    }

    if (!isBlackTurn && !whiteIsAI) {
      return;
    }

    for (var i = 0; i < 1000; i++) {
      await HF.wait(10);
      final thinking = receivingTokens.q;
      if (!thinking) break;
    }

    qqq("Placing event received: $event, thinking: ${receivingTokens.q}");
    await onCellTap(row: event.$1, col: event.$2);
  }

  void _syncLayout() {
    final screenWidth = P.app.screenWidth.q;
    final screenHeight = P.app.screenHeight.q;
    final paddingTop = P.app.paddingTop.q;
    final paddingBottom = P.app.paddingBottom.q;
    final paddingLeft = P.app.paddingLeft.q;
    final paddingRight = P.app.paddingRight.q;

    final availableWidth = screenWidth - paddingLeft - paddingRight;
    final availableHeight = screenHeight - paddingTop - paddingBottom;
    final usePortrait = availableWidth < availableHeight;
    this.usePortrait.q = usePortrait;

    final ratio = availableWidth / availableHeight;

    playerShouldAtSameColumnWithSettings.q = ratio > .7;
    final settingsAndPlayersShouldAtDifferentColumnIsHorizontal = ratio > 1.4;
    this.settingsAndPlayersShouldAtDifferentColumnIsHorizontal.q = settingsAndPlayersShouldAtDifferentColumnIsHorizontal;
  }

  void _clear() {
    eatCountMatrixForBlack.q = List.generate(8, (_) => List.filled(8, 0));
    eatCountMatrixForWhite.q = List.generate(8, (_) => List.filled(8, 0));
    final state = List.generate(8, (_) => List.filled(8, CellType.empty));

    state[3][3] = CellType.white;
    state[3][4] = CellType.black;
    state[4][3] = CellType.black;
    state[4][4] = CellType.white;
    blackTurn.q = _Othello._blackFirst;
    this.state.q = [...state];

    switch (Args.othelloTestCase) {
      case 0:
        _testCase0();
        break;
      case 1:
        _testCase1();
        break;
      default:
        break;
    }

    blackIsAI.q = false;
    whiteIsAI.q = true;
    receivingTokens.q = false;
    received.q = "";
    searchDepth.q = 1;
    searchBreadth.q = 1;
    latestPlacing.q = null;
  }

  @Deprecated("Use _onStreamEvent instead")
  void _onOldStreamEvent(LLMEvent event) async {
    switch (event.type) {
      case _RWKVMessageType.responseBufferIds:
        final ids = event.responseBufferIds;
        if (ids != null) {
          for (var i = 0; i < ids.length; i++) {
            final id = ids[i];
            await _onStreamingToken(id);
          }
        }
        break;
      case _RWKVMessageType.isGenerating:
        final isGenerating = event.content == "true";
        receivingTokens.q = isGenerating;
        break;
      case _RWKVMessageType.sudokuOthelloResponse:
        received.q = event.content;
        break;
      case _RWKVMessageType.streamResponse:
        received.q = event.content;
        final token = event.token;
        _onStreamingToken(token);
        break;
    }

    HF.wait(200).then((_) {
      receivedScrollController.jumpTo(receivedScrollController.position.maxScrollExtent);
    });
  }

  FV _onStreamingToken(int? token) async {
    if (token == null) return;

    if (token == _kOutputStartToken) {
      _receivingPlacing = true;
      return;
    }

    if (_receivingPlacing) {
      final placing = _kTokenPair[token];
      // modelPlacingController.add((placing?[0] ?? 0, placing?[1] ?? 0));
      if (placing != null) {
        modelPlacingController.add((placing[0], placing[1]));
      }

      if (placing == null) {
        if (token != _kPsToken) {
          qqe("Placing is null:${token.toString()}");
          if (!kDebugMode) Sentry.captureException(Exception("Placing is null:${token.toString()}"), stackTrace: StackTrace.current);
        } else {
          qqq("Game over!");
        }

        await _showGameOverDialog();
      }

      _receivingPlacing = false;
      return;
    }
  }

  FV _showGameOverDialog() async {
    final blackScore = this.blackScore.q;
    final whiteScore = this.whiteScore.q;

    late final String winnerMessage;

    if (blackScore > whiteScore) {
      winnerMessage = S.current.black_wins;
    } else if (blackScore < whiteScore) {
      winnerMessage = S.current.white_wins;
    } else {
      winnerMessage = S.current.draw;
    }

    await showOkAlertDialog(
      context: getContext()!,
      title: S.current.game_over,
      message: "${S.current.black}: $blackScore\n${S.current.white}: $whiteScore\n$winnerMessage",
      okLabel: S.current.ok,
    );
  }

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    switch (event) {
      case from_rwkv.ResponseBufferContent res:
        received.q = res.responseBufferContent;
        break;

      case from_rwkv.GenerateStart _:
        receivingTokens.q = true;
        received.q = "";
        break;

      case from_rwkv.GenerateStop _:
        receivingTokens.q = false;
        break;

      default:
        break;
    }
  }

  void _onStreamDone() async {
    final pageKey = P.app.pageKey.q;
    if (pageKey != PageKey.othello) return;
    qqq("_onStreamDone");
    receivingTokens.q = false;
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    final pageKey = P.app.pageKey.q;
    if (pageKey != PageKey.othello) return;
    qqq("_onStreamError");
    qqe("error: $error");
    if (!kDebugMode) Sentry.captureException(error, stackTrace: stackTrace);
    receivingTokens.q = false;
  }

  void _onBlackTurnChanged() {
    _calculateAvailableCells();
  }

  void _onStateChanged() {
    _calculateAvailableCells();
  }

  void _calculateAvailableCells() async {
    qq;

    final state = this.state.q;
    final blackTurn = this.blackTurn.q;

    late final CellType targetCellType;
    late final CellType currentCellType;

    if (blackTurn) {
      targetCellType = CellType.white;
      currentCellType = CellType.black;
    } else {
      targetCellType = CellType.black;
      currentCellType = CellType.white;
    }

    final eatCountMatrixForBlack = List.generate(8, (_) => List.filled(8, 0));
    final eatCountMatrixForWhite = List.generate(8, (_) => List.filled(8, 0));

    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        if (state[row][col] != CellType.empty) {
          eatCountMatrixForBlack[row][col] = 0;
          eatCountMatrixForWhite[row][col] = 0;
          continue;
        }

        final eatCountForBlack = _eat(
          row: row,
          col: col,
          dryRun: true,
          forBlack: true,
        );
        eatCountMatrixForBlack[row][col] = eatCountForBlack[8];

        final eatCountForWhite = _eat(
          row: row,
          col: col,
          dryRun: true,
          forBlack: false,
        );
        eatCountMatrixForWhite[row][col] = eatCountForWhite[8];
      }
    }

    this.eatCountMatrixForBlack.q = eatCountMatrixForBlack;
    this.eatCountMatrixForWhite.q = eatCountMatrixForWhite;
  }

  /// top-left, top, top-right, left, right, bottom-left, bottom, bottom-right
  List<int> _eat({
    required int row,
    required int col,
    required bool dryRun,
    required bool forBlack,
  }) {
    assert(row >= 0 && row < 8);
    assert(col >= 0 && col < 8);
    assert(dryRun == true || dryRun == false);

    final state = this.state.q;
    late final CellType targetCellType;
    late final CellType currentCellType;

    if (forBlack) {
      targetCellType = CellType.white;
      currentCellType = CellType.black;
    } else {
      targetCellType = CellType.black;
      currentCellType = CellType.white;
    }

    // top-left, top, top-right, left, right, bottom-left, bottom, bottom-right, total
    var result = List.filled(9, 0);

    int leftIndex = col;
    int rightIndex = col;
    int topIndex = row;
    int bottomIndex = row;

    int targetCount = 0;
    bool canEat = false;
    List<(int row, int col)> eatPositions = [];

    // top-left
    targetCount = 0;
    canEat = false;
    eatPositions = [];
    leftIndex = col - 1;
    rightIndex = col;
    topIndex = row - 1;
    bottomIndex = row;
    while (leftIndex >= 0 && topIndex >= 0) {
      final calculatingCellType = state[topIndex][leftIndex];
      if (calculatingCellType == targetCellType) {
        eatPositions.add((topIndex, leftIndex));
        targetCount++;
      } else if (calculatingCellType == currentCellType) {
        if (!dryRun) {
          eatPositions.forEach((e) {
            state[e.$1][e.$2] = currentCellType;
          });
          state[row][col] = currentCellType;
        }
        canEat = true;
        break;
      } else if (calculatingCellType == CellType.empty) {
        break;
      }
      leftIndex--;
      topIndex--;
    }

    if (canEat) {
      result[0] = targetCount;
      result[8] += targetCount;
    }

    // top
    targetCount = 0;
    canEat = false;
    eatPositions = [];
    leftIndex = col;
    rightIndex = col;
    topIndex = row - 1;
    bottomIndex = row;
    while (topIndex >= 0) {
      final calculatingCellType = state[topIndex][col];
      if (calculatingCellType == targetCellType) {
        eatPositions.add((topIndex, col));
        targetCount++;
      } else if (calculatingCellType == currentCellType) {
        if (!dryRun) {
          eatPositions.forEach((e) {
            state[e.$1][e.$2] = currentCellType;
          });
          state[row][col] = currentCellType;
        }
        canEat = true;
        break;
      } else if (calculatingCellType == CellType.empty) {
        break;
      }
      topIndex--;
    }

    if (canEat) {
      result[1] = targetCount;
      result[8] += targetCount;
    }

    // top-right
    targetCount = 0;
    canEat = false;
    eatPositions = [];
    leftIndex = col;
    rightIndex = col + 1;
    topIndex = row - 1;
    bottomIndex = row;
    while (rightIndex < 8 && topIndex >= 0) {
      final calculatingCellType = state[topIndex][rightIndex];
      if (calculatingCellType == targetCellType) {
        eatPositions.add((topIndex, rightIndex));
        targetCount++;
      } else if (calculatingCellType == currentCellType) {
        if (!dryRun) {
          eatPositions.forEach((e) {
            state[e.$1][e.$2] = currentCellType;
          });
          state[row][col] = currentCellType;
        }
        canEat = true;
        break;
      } else if (calculatingCellType == CellType.empty) {
        break;
      }
      rightIndex++;
      topIndex--;
    }

    if (canEat) {
      result[2] = targetCount;
      result[8] += targetCount;
    }

    // left
    targetCount = 0;
    canEat = false;
    eatPositions = [];
    leftIndex = col - 1;
    rightIndex = col;
    topIndex = row;
    bottomIndex = row;
    while (leftIndex >= 0) {
      final calculatingCellType = state[row][leftIndex];
      if (calculatingCellType == targetCellType) {
        eatPositions.add((row, leftIndex));
        targetCount++;
      } else if (calculatingCellType == currentCellType) {
        if (!dryRun) {
          eatPositions.forEach((e) {
            state[e.$1][e.$2] = currentCellType;
          });
          state[row][col] = currentCellType;
        }
        canEat = true;
        break;
      } else if (calculatingCellType == CellType.empty) {
        break;
      }
      leftIndex--;
    }
    if (canEat) {
      result[3] = targetCount;
      result[8] += targetCount;
    }

    // right
    targetCount = 0;
    canEat = false;
    eatPositions = [];
    leftIndex = col;
    rightIndex = col + 1;
    topIndex = row;
    bottomIndex = row;
    while (rightIndex < 8) {
      final calculatingCellType = state[row][rightIndex];
      if (calculatingCellType == targetCellType) {
        eatPositions.add((row, rightIndex));
        targetCount++;
      } else if (calculatingCellType == currentCellType) {
        if (!dryRun) {
          eatPositions.forEach((e) {
            state[e.$1][e.$2] = currentCellType;
          });
          state[row][col] = currentCellType;
        }
        canEat = true;
        break;
      } else if (calculatingCellType == CellType.empty) {
        break;
      }
      rightIndex++;
    }
    if (canEat) {
      result[4] = targetCount;
      result[8] += targetCount;
    }

    // bottom-left
    targetCount = 0;
    canEat = false;
    eatPositions = [];
    leftIndex = col - 1;
    rightIndex = col;
    topIndex = row;
    bottomIndex = row + 1;
    while (leftIndex >= 0 && bottomIndex < 8) {
      final calculatingCellType = state[bottomIndex][leftIndex];
      if (calculatingCellType == targetCellType) {
        eatPositions.add((bottomIndex, leftIndex));
        targetCount++;
      } else if (calculatingCellType == currentCellType) {
        if (!dryRun) {
          eatPositions.forEach((e) {
            state[e.$1][e.$2] = currentCellType;
          });
          state[row][col] = currentCellType;
        }
        canEat = true;
        break;
      } else if (calculatingCellType == CellType.empty) {
        break;
      }
      leftIndex--;
      bottomIndex++;
    }
    if (canEat) {
      result[5] = targetCount;
      result[8] += targetCount;
    }

    // bottom
    targetCount = 0;
    canEat = false;
    eatPositions = [];
    leftIndex = col;
    rightIndex = col;
    topIndex = row;
    bottomIndex = row + 1;
    while (bottomIndex < 8) {
      final calculatingCellType = state[bottomIndex][col];
      if (calculatingCellType == targetCellType) {
        eatPositions.add((bottomIndex, col));
        targetCount++;
      } else if (calculatingCellType == currentCellType) {
        if (!dryRun) {
          eatPositions.forEach((e) {
            state[e.$1][e.$2] = currentCellType;
          });
          state[row][col] = currentCellType;
        }
        canEat = true;
        break;
      } else if (calculatingCellType == CellType.empty) {
        break;
      }
      bottomIndex++;
    }
    if (canEat) {
      result[6] = targetCount;
      result[8] += targetCount;
    }

    // bottom-right
    targetCount = 0;
    canEat = false;
    eatPositions = [];
    leftIndex = col;
    rightIndex = col + 1;
    topIndex = row;
    bottomIndex = row + 1;
    while (rightIndex < 8 && bottomIndex < 8) {
      final calculatingCellType = state[bottomIndex][rightIndex];
      if (calculatingCellType == targetCellType) {
        eatPositions.add((bottomIndex, rightIndex));
        targetCount++;
      } else if (calculatingCellType == currentCellType) {
        if (!dryRun) {
          eatPositions.forEach((e) {
            state[e.$1][e.$2] = currentCellType;
          });
          state[row][col] = currentCellType;
        }
        canEat = true;
        break;
      } else if (calculatingCellType == CellType.empty) {
        break;
      }
      rightIndex++;
      bottomIndex++;
    }
    if (canEat) {
      result[7] = targetCount;
      result[8] += targetCount;
    }

    if (!dryRun) {
      final newState = state.map((e) => e.map((f) => f).toList()).toList();
      this.state.q = newState;
      blackTurn.q = !forBlack;
    }

    return result;
  }

  String _generatePrompt() {
    final state = this.state.q;
    final blackTurn = this.blackTurn.q;
    final searchDepth = this.searchDepth.q;
    final searchBreadth = this.searchBreadth.q;
    final prompt =
        """<input>
${state.map((e) => e.map((f) => f.prompt).join()).join("\n")}
NEXT ${blackTurn ? CellType.black.prompt : CellType.white.prompt}
MAX_WIDTH-$searchBreadth
MAX_DEPTH-$searchDepth
</input>

""";
    qqq(prompt.length);

    assert(prompt.length == 186);

    if (kDebugMode) {
      Clipboard.setData(ClipboardData(text: prompt));
    }

    if (kDebugMode) {
      qq;
      print("✅ Original prompt:");
      print(prompt);
      print("✅ Formated prompt:");
      prompt.split("\n").indexMap((index, e) {
        if (e.trim().isEmpty) return;
        if (kDebugMode) print(e.replaceAll("·", "· "));
      });
    }
    return prompt;
  }

  void _testCase0() {
    final state = List.generate(8, (_) => List.filled(8, CellType.empty));
    state[2][2] = CellType.white;
    state[3][4] = CellType.black;
    state[4][3] = CellType.black;
    state[4][4] = CellType.white;
    blackTurn.q = _Othello._blackFirst;
    this.state.q = [...state];
  }

  void _testCase1() {
    final state = List.generate(8, (_) => List.filled(8, CellType.empty));

    state[0][0] = CellType.white;
    // state[0][1] = CellType.black;
    state[0][3] = CellType.white;

    state[1][0] = CellType.white;
    state[1][1] = CellType.white;
    state[1][2] = CellType.white;
    state[1][3] = CellType.black;
    state[1][4] = CellType.black;
    state[1][5] = CellType.black;

    state[2][0] = CellType.white;
    state[2][1] = CellType.white;
    state[2][2] = CellType.black;
    state[2][3] = CellType.black;
    state[2][4] = CellType.black;

    state[3][0] = CellType.white;
    state[3][1] = CellType.white;
    state[3][2] = CellType.black;
    state[3][3] = CellType.black;
    state[3][4] = CellType.black;

    state[4][0] = CellType.white;
    state[4][2] = CellType.black;
    state[4][3] = CellType.black;
    state[4][4] = CellType.black;

    state[5][1] = CellType.black;
    state[5][2] = CellType.black;
    state[5][3] = CellType.black;
    state[5][4] = CellType.black;

    // state[4][2] = CellType.white;
    // state[4][3] = CellType.black;
    // state[4][4] = CellType.black;

    // state[5][1] = CellType.black;
    // state[5][2] = CellType.white;
    // state[5][4] = CellType.black;

    blackTurn.q = true;
    this.state.q = [...state];
  }
}

const _kOutputStartToken = 6;

const _kPsToken = 97;

const _kTokenPair = {
  // a1-h1
  33: [0, 0], 41: [0, 1], 49: [0, 2], 57: [0, 3], 65: [0, 4], 73: [0, 5], 81: [0, 6], 89: [0, 7],
  // a2-h2
  34: [1, 0], 42: [1, 1], 50: [1, 2], 58: [1, 3], 66: [1, 4], 74: [1, 5], 82: [1, 6], 90: [1, 7],
  // a3-h3
  35: [2, 0], 43: [2, 1], 51: [2, 2], 59: [2, 3], 67: [2, 4], 75: [2, 5], 83: [2, 6], 91: [2, 7],
  // a4-h4
  36: [3, 0], 44: [3, 1], 52: [3, 2], 60: [3, 3], 68: [3, 4], 76: [3, 5], 84: [3, 6], 92: [3, 7],
  // a5-h5
  37: [4, 0], 45: [4, 1], 53: [4, 2], 61: [4, 3], 69: [4, 4], 77: [4, 5], 85: [4, 6], 93: [4, 7],
  // a6-h6
  38: [5, 0], 46: [5, 1], 54: [5, 2], 62: [5, 3], 70: [5, 4], 78: [5, 5], 86: [5, 6], 94: [5, 7],
  // a7-h7
  39: [6, 0], 47: [6, 1], 55: [6, 2], 63: [6, 3], 71: [6, 4], 79: [6, 5], 87: [6, 6], 95: [6, 7],
  // a8-h8
  40: [7, 0], 48: [7, 1], 56: [7, 2], 64: [7, 3], 72: [7, 4], 80: [7, 5], 88: [7, 6], 96: [7, 7],
};
