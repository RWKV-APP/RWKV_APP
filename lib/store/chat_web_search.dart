part of 'p.dart';

extension $ChatWebSearch on _Chat {
  void onSwitchWebSearchMode(WebSearchMode mode) async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    webSearchMode.q = mode;
  }

  Future<void> onWebSearchModeTapped() async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final context = getContext();
    if (context == null) return;

    P.app.hapticLight();

    final s = S.current;
    final current = webSearchMode.q;
    final actionPairs = <({String label, WebSearchMode key})>[
      (label: s.off, key: .off),
      (label: s.web_search, key: .search),
      (label: s.deep_web_search, key: .deepSearch),
    ];

    final actions = actionPairs.map((entry) {
      final isCurrent = entry.key == current;
      final label = isCurrent ? "☑ ${entry.label}" : entry.label;
      final key = entry.key;
      return SheetAction(label: label, key: key);
    }).toList();

    final selectedMode = await showModalActionSheet<WebSearchMode>(
      context: context,
      title: s.web_search,
      message: "${s.web_search} / ${s.deep_web_search}",
      cancelLabel: s.cancel,
      actions: actions,
    );

    if (selectedMode == null) return;

    onSwitchWebSearchMode(selectedMode);
  }

  Future<List<String>> _historyWithWebSearch(int receiveId, List<String> allMessage) async {
    RefInfo ref = RefInfo.empty();
    final isZh = P.preference.currentLangIsZh.q;

    if (webSearchMode.q != WebSearchMode.off) {
      ref = ref.copyWith(enable: true);
      try {
        final prompt = allMessage.last;
        final deepSearch = webSearchMode.q == WebSearchMode.deepSearch;
        _updateMessageById(id: receiveId, reference: ref);
        final resp =
            await _post(
                  'https://auth.rwkvos.com/api/internet_search',
                  token: 'x8rYbL3KfGp2Nq1zT9wVvJ0iQ5sUoAeX7HcM4',
                  body: {
                    "query": prompt,
                    "top_n": 3,
                    'is_deepsearch': deepSearch,
                  },
                ).timeout(const Duration(seconds: 10))
                as dynamic;
        qqq('web search mode: ${webSearchMode.q}');
        final refs = (resp['data'] as Iterable).map((e) => Reference.fromJson(e)).toList();
        ref = ref.copyWith(list: refs);
        final searchResult = refs.map((e) => e.summary).join("\n");
        allMessage.removeLast();
        final template = P.preference.promptTemplate;
        final msg = sprintf(isZh ? template.webSearchChineseTemplate : template.webSearchTemplate, [searchResult, prompt]);
        allMessage.add(msg);
      } catch (e) {
        ref = ref.copyWith(error: e.toString());
        qqe(e);
      }
    }
    unawaited(_updateWebSearchReferenceAfterDelay(receiveId: receiveId, ref: ref));

    return allMessage;
  }

  Future<void> _updateWebSearchReferenceAfterDelay({
    required int receiveId,
    required RefInfo ref,
  }) async {
    await 50.msLater;
    _updateMessageById(id: receiveId, reference: ref);
  }
}
