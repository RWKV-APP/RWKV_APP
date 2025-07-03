part of 'p.dart';

const _kMaxStackDepth = 10;

class _Sudoku {
  /// Stop token
  static const tokenStop = 105;

  static String merged = '';
  final staticData = qs<List<List<int>>>([]);
  final dynamicData = qs<List<List<int>>>([]);
  final logs = qs<List<String>>([]);
  final difficulty = qs<int?>(null);

  late final hasPuzzle = qp<bool>((ref) {
    final puzzle = ref.watch(staticData);
    for (final row in puzzle) {
      for (final grid in row) {
        if (grid != 0) return true;
      }
    }
    return false;
  });

  final running = qs<bool>(false);

  // final streamController = StreamController<(int output, String decoded)>.broadcast();

  bool _recordingTagBoard = false;
  bool _recordingTagStack = false;

  final List<(int, String)> _tempBoardEvents = [];
  final List<(int, String)> _tempStackEvents = [];

  final tokensCount = qs<int>(0);
  int _hiddenCounter = 0;
  late final _random = Random();
  final widgetPosition = qs<Map<String, Offset>>(const {});
  final uiOffset = qs<Offset>(Offset.zero);

  final showStack = qs<bool>(true);

  final currentStack = qs<List<(int, int)>>([]);

  // late final File _file;
  // late IOSink _fileSink;

  late final scrollController = ScrollController();
}

/// Public methods
extension $Sudoku on _Sudoku {
  (func_sudoku.SudokuGrid solved, func_sudoku.SudokuGrid puzzle) generate({required int difficulty}) {
    final solved = func_sudoku.genSolved();
    final puzzle = func_sudoku.genPuzzle(solved, difficulty: difficulty);
    return (solved, puzzle);
  }

  FV onGeneratePressed(BuildContext context) async {
    final _running = running.q;
    if (_running) {
      await showOkAlertDialog(
        context: context,
        title: S.current.inference_is_running,
        message: S.current.please_wait_for_it_to_finish,
      );
      return;
    }

    final difficulty = await showConfirmationDialog<int?>(
      context: context,
      title: S.current.generate_random_sudoku_puzzle,
      message: S.current.please_select_the_difficulty,
      actions: [
        AlertDialogAction(
          label: S.current.sudoku_easy,
          key: HF.randomInt(min: 19, max: 25),
        ),
        AlertDialogAction(
          label: S.current.sudoku_medium,
          key: HF.randomInt(min: 26, max: 35),
        ),
        AlertDialogAction(
          label: S.current.sudoku_hard,
          key: HF.randomInt(min: 36, max: 45),
        ),
        AlertDialogAction(
          label: S.current.custom_difficulty,
          key: -1,
        ),
      ],
    );

    if (difficulty == null) return;

    if (difficulty == -1) {
      if (context.mounted) {
        await onCustomDifficultyPressed(context);
      }
      return;
    }

    clear();
    final (solved, puzzle) = generate(difficulty: difficulty);
    staticData.q = puzzle;
    this.difficulty.q = difficulty;
  }

  FV onInferencePressed(BuildContext context) async {
    qq;
    final _running = running.q;
    if (_running) {
      await showOkAlertDialog(
        context: context,
        title: S.current.inference_is_running,
        message: S.current.please_wait_for_it_to_finish,
      );
      return;
    }

    tokensCount.q = 0;
    _hiddenCounter = 0;
    running.q = true;

    func_sudoku.SudokuGrid grid = staticData.q;
    final prompt = _genPrompt(grid);
    P.rwkv.send(to_rwkv.ClearStates());
    P.rwkv.send(
      to_rwkv.SudokuOthelloGenerate(
        prompt,
        decodeStream: false,
        wantRawJSON: false,
      ),
    );
  }

  FV onCustomDifficultyPressed(BuildContext context) async {
    final _running = running.q;
    if (_running) {
      await showOkAlertDialog(
        context: context,
        title: S.current.inference_is_running,
        message: S.current.please_wait_for_it_to_finish,
      );
      return;
    }

    final difficulty = await showTextInputDialog(
      context: context,
      title: S.current.generate_random_sudoku_puzzle,
      message: S.current.please_enter_the_difficulty,
      textFields: [
        DialogTextField(
          hintText: S.current.difficulty,
          initialText: kDebugMode ? "40" : "10",
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
        ),
      ],
    );
    if (difficulty == null) return;
    if (difficulty.isEmpty) return;
    final value = difficulty.first;
    final difficultyInt = int.tryParse(value);
    if (difficultyInt == null) return;

    if (difficultyInt < 1) {
      if (context.mounted) {
        await showOkAlertDialog(
          context: context,
          title: S.current.can_not_generate,
          message: S.current.difficulty_must_be_greater_than_0,
        );
      }
      return;
    }

    if (difficultyInt > 81) {
      if (context.mounted) {
        await showOkAlertDialog(
          context: context,
          title: S.current.can_not_generate,
          message: S.current.difficulty_must_be_less_than_81,
        );
      }
      return;
    }

    clear();
    final (solved, puzzle) = generate(difficulty: difficultyInt);
    staticData.q = puzzle;
  }

  void clear() {
    final newValue = func_sudoku.genEmpty();
    staticData.q = func_sudoku.deepCopyList(newValue);
    dynamicData.q = func_sudoku.deepCopyList(newValue);
    logs.q = [];
    tokensCount.q = 0;
    _hiddenCounter = 0;
    currentStack.q = [];
    _recordingTagBoard = false;
    _recordingTagStack = false;
    _tempStackEvents.clear();
    difficulty.q = null;
  }

  void debugRenderingRandom() {
    final solvedGrid = func_sudoku.genSolved();
    final difficulty = HF.randomInt(min: 1, max: 1);
    final newValue = func_sudoku.genPuzzle(solvedGrid, difficulty: difficulty);
    staticData.q = newValue;
    this.difficulty.q = difficulty;
  }

  void onGridPressed(BuildContext context, int col, int row) async {
    if (kDebugMode) print("💬 onGridPressed: $col, $row");
    final _running = running.q;
    if (_running) {
      await showOkAlertDialog(
        context: context,
        title: S.current.inference_is_running,
        message: S.current.please_wait_for_it_to_finish,
      );
      return;
    }

    final currentPuzzle = staticData.q;
    final currentValue = currentPuzzle[row][col];

    final value = await showTextInputDialog(
      context: context,
      title: S.current.set_the_value_of_grid,
      message: S.current.please_enter_a_number_0_means_empty,
      textFields: [
        DialogTextField(
          hintText: S.current.number,
          initialText: currentValue.toString(),
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
        ),
      ],
    );

    if (value == null) return;
    if (value.isEmpty) return;
    final valueInt = int.tryParse(value.first);
    if (valueInt == null) return;
    if (valueInt < 0 || valueInt > 9) {
      if (context.mounted) {
        await showOkAlertDialog(
          context: context,
          title: S.current.invalid_value,
          message: S.current.value_must_be_between_0_and_9,
        );
      }
      return;
    }

    final newPuzzle = func_sudoku.deepCopyList(currentPuzzle);
    newPuzzle[row][col] = valueInt;

    final isValid = func_sudoku.isValid(newPuzzle, solved: false);
    if (!isValid) {
      if (context.mounted) {
        await showOkAlertDialog(
          context: context,
          title: S.current.invalid_puzzle,
          message: S.current.the_puzzle_is_not_valid,
        );
      }
      return;
    }

    staticData.q = newPuzzle;
    // debugger();
  }

  void onClearPressed(BuildContext context) async {
    final _running = running.q;
    if (_running) {
      await showOkAlertDialog(
        context: context,
        title: S.current.inference_is_running,
        message: S.current.please_wait_for_it_to_finish,
      );
      return;
    }
    clear();
  }

  void onToggleShowStack(BuildContext context) {
    showStack.q = !showStack.q;
  }

  void loadHardestSudoku() {
    clear();

    // "hardest"
    // https://abcnews.go.com/blogs/headlines/2012/06/can-you-solve-the-hardest-ever-sudoku
    const puzzle = [
      [8, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 3, 6, 0, 0, 0, 0, 0],
      [0, 7, 0, 0, 9, 0, 2, 0, 0],
      [0, 5, 0, 0, 0, 7, 0, 0, 0],
      [0, 0, 0, 0, 4, 5, 7, 0, 0],
      [0, 0, 0, 1, 0, 0, 0, 3, 0],
      [0, 0, 1, 0, 0, 0, 0, 6, 8],
      [0, 0, 8, 5, 0, 0, 0, 1, 0],
      [0, 9, 0, 0, 0, 0, 4, 0, 0],
    ];

    // moderate
    // https://www.7sudoku.com/moderate
    // const puzzle = [
    //   [0, 0, 1, 0, 0, 3, 0, 0, 0],
    //   [0, 0, 0, 0, 9, 0, 7, 0, 5],
    //   [8, 2, 5, 0, 6, 0, 0, 9, 0],
    //   [4, 0, 9, 0, 1, 0, 0, 0, 0],
    //   [2, 5, 0, 0, 0, 0, 0, 1, 7],
    //   [0, 0, 0, 0, 5, 0, 9, 0, 4],
    //   [0, 6, 0, 0, 4, 0, 8, 7, 3],
    //   [9, 0, 3, 0, 2, 0, 0, 0, 0],
    //   [0, 0, 0, 3, 0, 0, 2, 0, 0],
    // ];

    // https://www.7sudoku.com/difficult
    // https://www.7sudoku.com/view-puzzle?p=a7383154d89311efb2a7509a4c9d0656
    // 600100385000000007000028009901003070000000000080500903500240000100000000823005006
    // const puzzle = [
    //   [6, 0, 0, 1, 0, 0, 3, 8, 5],
    //   [0, 0, 0, 0, 0, 0, 0, 0, 7],
    //   [0, 0, 0, 0, 2, 8, 0, 0, 9],
    //   [9, 0, 1, 0, 0, 3, 0, 7, 0],
    //   [0, 0, 0, 0, 0, 0, 0, 0, 0],
    //   [0, 8, 0, 5, 0, 0, 9, 0, 3],
    //   [5, 0, 0, 2, 4, 0, 0, 0, 0],
    //   [1, 0, 0, 0, 0, 0, 0, 0, 0],
    //   [8, 2, 3, 0, 0, 5, 0, 0, 6],
    // ];

    staticData.q = puzzle;
  }

  void _parseStack() {
    final events = _tempStackEvents;
    List<(int, int)> stack = events
        .where((e) {
          final token = e.$1;
          return _kStackMap.containsKey(token);
        })
        .map((e) {
          final token = e.$1;
          return _kStackMap[token]!;
        })
        .toList();
    // debugger();

    // 最大深度为 10
    // 如果超过最大深度，则只保留最后的 10 个
    if (stack.length > _kMaxStackDepth) {
      stack = stack.sublist(stack.length - _kMaxStackDepth);
    }

    currentStack.q = stack;
  }

  void _parseBoard() {
    final events = _tempBoardEvents;
    const gridValues = ["0 ", "1 ", "2 ", "3 ", "4 ", "5 ", "6 ", "7 ", "8 ", "9 "];
    final grids = events
        .map((e) => e.$2)
        .toList()
        .where((e) => gridValues.contains(e))
        .toList()
        .map((e) => int.parse(e.replaceAll(" ", "")))
        .toList();
    final grid = func_sudoku.genFromList(grids);
    dynamicData.q = grid;
    if (kDebugMode) {
      final staticData = this.staticData.q;
      final dynamicData = this.dynamicData.q;
      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          final staticValue = staticData[i][j];
          final dynamicValue = dynamicData[i][j];
          if (staticValue != 0) {
            if (dynamicValue != staticValue) {
              if (kDebugMode) print("🔥 $i $j $staticValue $dynamicValue");
              // throw "似乎是推理错误了, 生成的结果篡改了原始 puzzle";
            }
          }
        }
      }
    }
  }

  Future<void> copyToCache(String assetPath, String cachePath) async {
    final rawAssetFile = await rootBundle.load(assetPath);
    final bytes = rawAssetFile.buffer.asUint8List();
    final libFile = File(cachePath);
    await libFile.writeAsBytes(bytes);
  }
}

/// Private methods
extension _$Sudoku on _Sudoku {
  FV _init() async {
    switch (P.app.demoType.q) {
      case DemoType.sudoku:
        break;
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.chat:
      case DemoType.tts:
      case DemoType.world:
        return;
    }

    qq;

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/output_log.txt';
    final file = File(filePath);

    // 先清除文件内容
    await file.writeAsString('', mode: FileMode.write);

    // 然后再以追加模式打开文件流
    // _fileSink = file.openWrite(mode: FileMode.append);
    // _file = file;

    clear();
    _loadDefaultPuzzle();

    P.rwkv.broadcastStream.listen(_onStreamEvent, onDone: _onStreamDone, onError: _onStreamError);
  }

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    switch (event) {
      case from_rwkv.StreamResponse res:
        _handleStreamResponse(res);
      default:
        break;
    }
  }

  void _showInferenceDone() async {
    await showOkAlertDialog(
      context: getContext()!,
      title: S.current.inference_is_done,
      message: S.current.please_check_the_result,
    );
  }

  void _handleStreamResponse(from_rwkv.StreamResponse res) {
    final decoded = res.streamResponseNewText;
    final output = res.streamResponseToken;

    _hiddenCounter += 1;

    if (_random.nextDouble() * 100 <= 3) {
      tokensCount.q = _hiddenCounter;
    }

    if (output == _Sudoku.tokenStop) {
      // _closeFileSink();

      _showInferenceDone();

      running.q = false;

      HF.wait(1000).then((_) {
        logs.q = [...logs.q, "✅ stop token got\n\n\n"];
        final c = scrollController;
        c.animateTo(
          c.position.maxScrollExtent,
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
        );
      });

      return;
    }

    // _fileSink.write(decoded);

    if (decoded == '\n') {
      logs.q = [...logs.q, _Sudoku.merged];
      _Sudoku.merged = '';
      final c = scrollController;
      c.animateTo(
        c.position.maxScrollExtent,
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
      return;
    }

    _Sudoku.merged += decoded;

    final isBoardStart = output == 108;
    final isBoardEnd = output == 109;

    final isStackStart = output == 110;
    final isStackEnd = output == 111;

    if (isBoardStart) {
      _recordingTagBoard = true;
      _tempBoardEvents.clear();
      return;
    }

    if (isBoardEnd) {
      _recordingTagBoard = false;
      _parseBoard();
      _tempBoardEvents.clear();
      return;
    }

    if (isStackStart) {
      _recordingTagStack = true;
      _tempStackEvents.clear();
      return;
    }

    if (isStackEnd) {
      _recordingTagStack = false;
      _parseStack();
      _tempStackEvents.clear();
      return;
    }

    if (_recordingTagBoard) {
      _tempBoardEvents.add((output, decoded));
    }

    if (_recordingTagStack) {
      _tempStackEvents.add((output, decoded));
    }
  }

  void _onStreamDone() {
    qq;
  }

  void _onStreamError(dynamic error, StackTrace stackTrace) {
    qq;
  }

  String _genPrompt(func_sudoku.SudokuGrid grid) {
    final newPrompt =
        '''<input>
${grid.map((row) => row.join(' ') + " \n").join("")}</input>

''';
    return newPrompt;
  }

  void _loadDefaultPuzzle() {
    const defaultPuzzle = [
      [0, 0, 8, 1, 6, 7, 0, 2, 0],
      [5, 0, 0, 2, 3, 0, 0, 0, 0],
      [7, 6, 0, 0, 5, 4, 8, 0, 1],
      [8, 7, 0, 0, 4, 0, 0, 0, 0],
      [0, 2, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 4, 0, 0, 3, 0, 9, 0],
      [0, 0, 0, 0, 0, 0, 3, 7, 0],
      [0, 4, 0, 0, 0, 0, 0, 8, 0],
      [3, 1, 0, 8, 0, 6, 9, 0, 4],
    ];

    staticData.q = defaultPuzzle;
  }

  // ignore: unused_element
  Future<void> _closeFileSink() async {
    // await _fileSink.flush();
    // await _fileSink.close();
  }

  // ignore: unused_element
  void _initializeFileSink() {
    // final file = File('your_fileqpath');
    // _fileSink = file.openWrite(mode: FileMode.append);
  }
}

/// 仅仅记录 stack 标签中的 grid 坐标
const _kStackMap = {
  11: (0, 0),
  12: (0, 1),
  13: (0, 2),
  14: (0, 3),
  15: (0, 4),
  16: (0, 5),
  17: (0, 6),
  18: (0, 7),
  19: (0, 8),
  20: (1, 0),
  21: (1, 1),
  22: (1, 2),
  23: (1, 3),
  24: (1, 4),
  25: (1, 5),
  26: (1, 6),
  27: (1, 7),
  28: (1, 8),
  29: (2, 0),
  30: (2, 1),
  31: (2, 2),
  32: (2, 3),
  33: (2, 4),
  34: (2, 5),
  35: (2, 6),
  36: (2, 7),
  37: (2, 8),
  38: (3, 0),
  39: (3, 1),
  40: (3, 2),
  41: (3, 3),
  42: (3, 4),
  43: (3, 5),
  44: (3, 6),
  45: (3, 7),
  46: (3, 8),
  47: (4, 0),
  48: (4, 1),
  49: (4, 2),
  50: (4, 3),
  51: (4, 4),
  52: (4, 5),
  53: (4, 6),
  54: (4, 7),
  55: (4, 8),
  56: (5, 0),
  57: (5, 1),
  58: (5, 2),
  59: (5, 3),
  60: (5, 4),
  61: (5, 5),
  62: (5, 6),
  63: (5, 7),
  64: (5, 8),
  65: (6, 0),
  66: (6, 1),
  67: (6, 2),
  68: (6, 3),
  69: (6, 4),
  70: (6, 5),
  71: (6, 6),
  72: (6, 7),
  73: (6, 8),
  74: (7, 0),
  75: (7, 1),
  76: (7, 2),
  77: (7, 3),
  78: (7, 4),
  79: (7, 5),
  80: (7, 6),
  81: (7, 7),
  82: (7, 8),
  83: (8, 0),
  84: (8, 1),
  85: (8, 2),
  86: (8, 3),
  87: (8, 4),
  88: (8, 5),
  89: (8, 6),
  90: (8, 7),
  91: (8, 8),
};

class SandboxFileHandler {
  IOSink? _fileSink;
  String? _filePath;

  // Initialize and open the file
  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _filePath = '${directory.path}/output_log.txt';
      final file = File(_filePath!);
      _fileSink = file.openWrite(mode: FileMode.append);
      if (kDebugMode) print('File opened for writing: $_filePath');
    } catch (e) {
      if (kDebugMode) print('Error initializing file: $e');
    }
  }

  // Append content to the file
  void appendContent(String content) {
    if (_fileSink != null) {
      _fileSink!.write(content);
    } else {
      if (kDebugMode) print('Warning: File sink not initialized. Call init() first.');
    }
  }

  // Close the file
  Future<void> close() async {
    if (_fileSink != null) {
      await _fileSink!.flush();
      await _fileSink!.close();
      _fileSink = null;
      if (kDebugMode) print('File closed: $_filePath');
    }
  }
}
