part of 'p.dart';

class _Lambada {
  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final testItems = qs<List<LambadaTestItem>>([]);
  late final waitingItems = qs<List<LambadaTestItem>>([]);

  late final progress = qs<double>(0.0);
  late final totalFinishCount = qs<int>(0);
  late final correctCount = qs<int>(0);
  late final totalLogits = qs<double>(0.0);

  late final ppl = qs<double>(0.0);
  late final acc = qs<double>(0.0);

  late final currentItem = qs<LambadaTestItem?>(null);
  late final currentRequest = qs<to_rwkv.RunEvaluation?>(null);

  /// 是否在收到 engine 的测试结果后, 自动执行下一个 lambada 测试项目
  late final autoStartNextTest = qs(false);
}

extension _$Lambada on _Lambada {
  Future<void> _init() async {
    qq;
  }

  void _onResultsReceived(from_rwkv.EvaluationResults res) async {
    final req = res.req;
    if (req != currentRequest.q) {
      qqe("Received results for unexpected request: $req");
      return;
    }

    totalFinishCount.q++;

    final logits = res.logits.first;
    totalLogits.q += logits;
    final correct = res.corrects.first;
    if (correct) correctCount.q++;

    // 困惑度就是拿logits values做平均之后exp(-average)
    ppl.q = math.exp(-totalLogits.q / totalFinishCount.q);

    acc.q = correctCount.q / totalFinishCount.q;

    if (!autoStartNextTest.q) return;

    final item = waitingItems.q.first;
    waitingItems.q = waitingItems.q.skip(1).toList();

    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }

    final newRequest = to_rwkv.RunEvaluation(item.sourceText, item.targetText, modelID: modelID);
    currentItem.q = item;
    currentRequest.q = newRequest;
    P.rwkv.send(newRequest);
  }
}

extension $Lambada on _Lambada {
  Future<void> loadTestData() async {
    try {
      final jsonlContent = await rootBundle.loadString('assets/lambada_test.jsonl');
      final lines = jsonlContent.split('\n').where((line) => line.trim().isNotEmpty);

      final items = <LambadaTestItem>[];
      for (final line in lines) {
        final json = jsonDecode(line) as Map<String, dynamic>;
        items.add(LambadaTestItem.fromJson(json));
      }

      testItems.q = items;
      qqr('Loaded ${items.length} LAMBADA test items');
    } catch (e) {
      qqe('Failed to load LAMBADA test data: $e');
    }
  }

  Future<void> startTest() async {
    // 检查是否有模型被加载
    if (!checkModelSelection(showAlert: true, showModelSelector: true, preferredDemoType: DemoType.chat)) {
      return;
    }

    if (testItems.q.isEmpty) {
      await loadTestData();
    }

    if (testItems.q.isEmpty) {
      qqe('No test data available');
      return;
    }

    progress.q = 0.0;
    totalFinishCount.q = 0;
    correctCount.q = 0;
    ppl.q = 0.0;
    acc.q = 0.0;
    totalLogits.q = 0.0;
    autoStartNextTest.q = true;

    waitingItems.q = testItems.q;
    final item = waitingItems.q.first;
    currentItem.q = item;
    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }
    final request = to_rwkv.RunEvaluation(item.sourceText, item.targetText, modelID: modelID);
    currentRequest.q = request;
    waitingItems.q = waitingItems.q.skip(1).toList();
    P.rwkv.send(request);
  }

  void reset() {
    progress.q = 0.0;
  }

  void clearTestData() {
    testItems.q = [];
    progress.q = 0.0;
  }

  Future<void> reselectModel() async {
    // 清除测试数据
    clearTestData();

    // 弹出模型选择面板
    ModelSelector.show();
  }

  void stopTest() {
    autoStartNextTest.q = false;
  }
}
