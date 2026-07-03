// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:local_web_search/src/browser/search_browser_controller.dart';
import 'package:local_web_search/src/browser/search_browser_view.dart';
import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_engine_availability.dart';
import 'package:local_web_search/src/models/search_extraction_result.dart';
import 'package:local_web_search/src/models/search_query_generation_result.dart';
import 'package:local_web_search/src/models/search_reference_bundle.dart';
import 'package:local_web_search/src/models/search_reference_source.dart';
import 'package:local_web_search/src/query/search_query_generator.dart';
import 'package:local_web_search/src/reachability/search_engine_reachability_probe.dart';
import 'package:local_web_search/src/reference/search_reference_builder.dart';

const JsonEncoder _debugJsonEncoder = JsonEncoder.withIndent('  ');

const List<_SearchDebugSample> _debugSamples = <_SearchDebugSample>[
  _SearchDebugSample(
    label: 'History',
    messages: '''
User: RWKV Chat local web search uses Google and Bing result pages.
Assistant: We can extract URLs and snippets from the DOM.
User: 这个在 macOS 上有什么坑？''',
  ),
  _SearchDebugSample(
    label: 'Direct',
    messages: '''
User: I want a concise explanation of RWKV.
Assistant: We should cite reliable sources before answering.
User: Find reliable sources about RWKV Chat and the RWKV language model.''',
  ),
  _SearchDebugSample(
    label: 'Chinese',
    messages: '''
User: 解释发布-订阅（Publish-Subscribe）设计模式。用代码实现一个简单的事件总线，包含 on, off, emit 方法。''',
  ),
  _SearchDebugSample(
    label: 'Weak History',
    messages: '''
User: 打游戏的网站
Assistant: 你想做哪类游戏网站？
User: 这个有什么坑？''',
  ),
  _SearchDebugSample(
    label: 'No Search',
    messages: '''
User: 你好
Assistant: 你好！
User: 哈哈哈''',
  ),
];

class _SearchDebugSample {
  final String label;
  final String messages;

  const _SearchDebugSample({required this.label, required this.messages});
}

class SearchBrowserPanel extends StatefulWidget {
  final SearchBrowserController? controller;
  final SearchEngineReachabilityProbe? reachabilityProbe;
  final Set<String> simulatedUnavailableEngineIds;

  const SearchBrowserPanel({
    super.key,
    this.controller,
    this.reachabilityProbe,
    this.simulatedUnavailableEngineIds = const <String>{},
  });

  @override
  State<SearchBrowserPanel> createState() => _SearchBrowserPanelState();
}

class _SearchBrowserPanelState extends State<SearchBrowserPanel> {
  static const String _defaultMessages = '''
User: I want a concise explanation of RWKV.
Assistant: We should cite reliable sources before answering.
User: Find reliable sources about RWKV Chat and the RWKV language model.''';

  late final SearchBrowserController _controller;
  late final SearchEngineReachabilityProbe _reachabilityProbe;
  late final TextEditingController _inputController;
  late final TextEditingController _messagesController;
  late final bool _ownsController;
  Map<String, SearchEngineAvailability> _engineAvailability =
      _initialEngineAvailability();
  List<_EngineDiagnosticResult> _engineDiagnostics =
      const <_EngineDiagnosticResult>[];
  SearchExtractionResult _result = const SearchExtractionResult.empty();
  SearchReferenceBundle _referenceBundle = const SearchReferenceBundle.empty();
  late SearchQueryGenerationResult _queryGenerationResult;
  SearchEngine _selectedEngine = SearchEngines.google;
  bool _extracting = false;
  bool _probingEngines = false;
  bool _runningEngineDiagnostics = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? SearchBrowserController();
    _reachabilityProbe =
        widget.reachabilityProbe ?? const SearchEngineReachabilityProbe();
    _messagesController = TextEditingController(text: _defaultMessages.trim());
    _queryGenerationResult = SearchQueryGenerator.build(_currentMessages());
    _inputController = TextEditingController(
      text: _queryGenerationResult.query,
    );
    _controller.addListener(_onBrowserChanged);
    _messagesController.addListener(_onMessagesChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _probeSearchEngines();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onBrowserChanged);
    _messagesController.removeListener(_onMessagesChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    _inputController.dispose();
    _messagesController.dispose();
    super.dispose();
  }

  void _onBrowserChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onMessagesChanged() {
    if (!mounted) return;
    setState(() {
      _queryGenerationResult = SearchQueryGenerator.build(_currentMessages());
    });
  }

  List<String> _currentMessages() {
    return SearchReferenceBuilder.parseMessageLines(_messagesController.text);
  }

  static Map<String, SearchEngineAvailability> _initialEngineAvailability() {
    return <String, SearchEngineAvailability>{
      for (final engine in SearchEngines.all)
        engine.id: SearchEngineAvailability.unknown(engine),
    };
  }

  SearchEngineAvailability _availabilityFor(SearchEngine engine) {
    return _engineAvailability[engine.id] ??
        SearchEngineAvailability.unknown(engine);
  }

  bool _canUseSelectedEngine() {
    return _availabilityFor(_selectedEngine).canSearch;
  }

  String _selectedEngineUnavailableMessage() {
    return _availabilityFor(_selectedEngine).tooltipMessage;
  }

  Future<void> _probeSearchEngines() async {
    if (_probingEngines) return;
    setState(() {
      _probingEngines = true;
      _engineAvailability = <String, SearchEngineAvailability>{
        for (final engine in SearchEngines.all)
          engine.id: widget.simulatedUnavailableEngineIds.contains(engine.id)
              ? SearchEngineAvailability.unavailable(
                  engine: engine,
                  error: 'Simulated unavailable request.',
                )
              : SearchEngineAvailability.checking(engine),
      };
    });

    final futures = <Future<SearchEngineAvailability>>[];
    for (final engine in SearchEngines.all) {
      if (widget.simulatedUnavailableEngineIds.contains(engine.id)) {
        futures.add(
          Future<SearchEngineAvailability>.value(
            SearchEngineAvailability.unavailable(
              engine: engine,
              error: 'Simulated unavailable request.',
            ),
          ),
        );
        continue;
      }
      futures.add(_reachabilityProbe.probe(engine));
    }

    final results = await Future.wait(futures);
    for (final result in results) {
      debugPrint(
        '[local_web_search] reachability ${result.engine.id}: '
        '${result.status.name}, status=${result.statusCode}, error=${result.error}',
      );
    }

    if (!mounted) return;
    setState(() {
      _engineAvailability = <String, SearchEngineAvailability>{
        for (final result in results) result.engine.id: result,
      };
      _probingEngines = false;
    });
  }

  void _buildQueryFromMessages() {
    final queryGeneration = SearchQueryGenerator.build(_currentMessages());
    setState(() {
      _queryGenerationResult = queryGeneration;
      _inputController.text = queryGeneration.query;
    });
  }

  void _loadDebugSample(_SearchDebugSample sample) {
    _messagesController.text = sample.messages.trim();
    final queryGeneration = SearchQueryGenerator.build(_currentMessages());
    setState(() {
      _queryGenerationResult = queryGeneration;
      _inputController.text = queryGeneration.query;
      _result = const SearchExtractionResult.empty();
      _referenceBundle = const SearchReferenceBundle.empty();
      _engineDiagnostics = const <_EngineDiagnosticResult>[];
    });
  }

  Future<void> _loadAsUrl() async {
    await _controller.loadUrl(_inputController.text);
  }

  Future<void> _loadGoogleSearch() async {
    if (!_canUseSelectedEngine()) {
      _controller.markError(_selectedEngineUnavailableMessage());
      return;
    }

    await _controller.loadSearch(
      engine: _selectedEngine,
      query: _inputController.text,
    );
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    await _extractSearchResults();
  }

  Future<void> _runReferenceSearchFromMessages() async {
    if (!_canUseSelectedEngine()) {
      _controller.markError(_selectedEngineUnavailableMessage());
      return;
    }

    final messages = _currentMessages();
    final queryGeneration = SearchQueryGenerator.build(messages);
    final query = queryGeneration.query;
    if (!queryGeneration.shouldSearch || query.isEmpty) {
      final extraction = SearchExtractionResult.failure(queryGeneration.reason);
      setState(() {
        _queryGenerationResult = queryGeneration;
        _inputController.text = query;
        _result = extraction;
        _referenceBundle = SearchReferenceBuilder.buildBundle(
          messages: messages,
          searchEngine: _selectedEngine,
          query: '',
          extraction: extraction,
        );
      });
      return;
    }

    setState(() {
      _queryGenerationResult = queryGeneration;
      _inputController.text = query;
      _result = const SearchExtractionResult.empty();
      _referenceBundle = const SearchReferenceBundle.empty();
      _extracting = true;
    });

    await _controller.loadSearch(engine: _selectedEngine, query: query);
    await Future<void>.delayed(const Duration(seconds: 3));
    final result = await _runExtractionWithRetry(_selectedEngine);
    if (!mounted) return;
    setState(() {
      _result = result;
      _referenceBundle = SearchReferenceBuilder.buildBundle(
        messages: messages,
        searchEngine: _selectedEngine,
        query: query,
        extraction: result,
      );
      _extracting = false;
    });
  }

  Future<SearchExtractionResult> _runExtractionWithRetry(
    SearchEngine expectedEngine,
  ) async {
    SearchExtractionResult result = const SearchExtractionResult.empty();
    for (int attempt = 0; attempt < 5; attempt += 1) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      result = (await _controller.runSerpExtraction()).validatedForEngine(
        expectedEngine,
      );
      debugPrint(
        '[local_web_search] extraction attempt ${attempt + 1}: '
        '${result.items.length} items, page=${result.pageUrl}, error=${result.error}',
      );
      if (result.hasItems || result.hasError) break;
    }
    return result;
  }

  Future<void> _extractSearchResults() async {
    setState(() {
      _extracting = true;
    });
    final result = await _runExtractionWithRetry(_selectedEngine);
    if (!mounted) return;
    setState(() {
      _result = result;
      _referenceBundle = SearchReferenceBuilder.buildBundle(
        messages: _currentMessages(),
        searchEngine: _selectedEngine,
        query: _inputController.text,
        extraction: result,
      );
      _extracting = false;
    });
  }

  Future<void> _runAllEngineDiagnostics() async {
    if (_runningEngineDiagnostics) return;
    final messages = _currentMessages();
    final queryGeneration = SearchQueryGenerator.build(messages);
    final query = queryGeneration.query;
    if (!queryGeneration.shouldSearch || query.isEmpty) {
      setState(() {
        _queryGenerationResult = queryGeneration;
        _inputController.text = query;
      });
      _controller.markError(queryGeneration.reason);
      return;
    }

    setState(() {
      _queryGenerationResult = queryGeneration;
      _inputController.text = query;
      _engineDiagnostics = const <_EngineDiagnosticResult>[];
      _runningEngineDiagnostics = true;
    });

    for (final engine in SearchEngines.all) {
      final availability = _availabilityFor(engine);
      if (!availability.canSearch) {
        final diagnostic = _EngineDiagnosticResult.skipped(
          engine: engine,
          availability: availability,
        );
        if (!mounted) return;
        setState(() {
          _engineDiagnostics = <_EngineDiagnosticResult>[
            ..._engineDiagnostics,
            diagnostic,
          ];
        });
        continue;
      }

      if (!mounted) return;
      setState(() {
        _selectedEngine = engine;
        _result = const SearchExtractionResult.empty();
        _referenceBundle = const SearchReferenceBundle.empty();
        _extracting = true;
      });

      final stopwatch = Stopwatch()..start();
      await _controller.loadSearch(engine: engine, query: query);
      await Future<void>.delayed(const Duration(seconds: 3));
      final result = await _runExtractionWithRetry(engine);
      stopwatch.stop();
      final bundle = SearchReferenceBuilder.buildBundle(
        messages: messages,
        searchEngine: engine,
        query: query,
        extraction: result,
      );

      if (!mounted) return;
      setState(() {
        _result = result;
        _referenceBundle = bundle;
        _engineDiagnostics = <_EngineDiagnosticResult>[
          ..._engineDiagnostics,
          _EngineDiagnosticResult.completed(
            engine: engine,
            availability: availability,
            currentUrl: _controller.currentUrl,
            pageUrl: result.pageUrl,
            pageTitle: result.pageTitle,
            itemCount: result.items.length,
            error: result.error,
            elapsed: stopwatch.elapsed,
          ),
        ];
      });
    }

    if (!mounted) return;
    setState(() {
      _extracting = false;
      _runningEngineDiagnostics = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBrowserToolbar(
              controller: _controller,
              inputController: _inputController,
              selectedEngine: _selectedEngine,
              engineAvailability: _engineAvailability,
              extracting: _extracting,
              probingEngines: _probingEngines,
              runningEngineDiagnostics: _runningEngineDiagnostics,
              onLoadUrl: _loadAsUrl,
              onGoogleSearch: _loadGoogleSearch,
              onExtract: _extractSearchResults,
              onRunAllEngines: _runAllEngineDiagnostics,
              onEngineChanged: (engine) {
                setState(() {
                  _selectedEngine = engine;
                });
              },
            ),
            Expanded(
              child: _SearchBrowserBody(
                controller: _controller,
                messagesController: _messagesController,
                referenceBundle: _referenceBundle,
                result: _result,
                queryGenerationResult: _queryGenerationResult,
                selectedEngine: _selectedEngine,
                engineAvailability: _engineAvailability,
                engineDiagnostics: _engineDiagnostics,
                query: _inputController.text,
                extracting: _extracting,
                runningEngineDiagnostics: _runningEngineDiagnostics,
                samples: _debugSamples,
                onBuildQuery: _buildQueryFromMessages,
                onSampleSelected: _loadDebugSample,
                onRunReferenceSearch: _runReferenceSearchFromMessages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBrowserToolbar extends StatelessWidget {
  final SearchBrowserController controller;
  final TextEditingController inputController;
  final SearchEngine selectedEngine;
  final Map<String, SearchEngineAvailability> engineAvailability;
  final bool extracting;
  final bool probingEngines;
  final bool runningEngineDiagnostics;
  final VoidCallback onLoadUrl;
  final VoidCallback onGoogleSearch;
  final VoidCallback onExtract;
  final VoidCallback onRunAllEngines;
  final ValueChanged<SearchEngine> onEngineChanged;

  const _SearchBrowserToolbar({
    required this.controller,
    required this.inputController,
    required this.selectedEngine,
    required this.engineAvailability,
    required this.extracting,
    required this.probingEngines,
    required this.runningEngineDiagnostics,
    required this.onLoadUrl,
    required this.onGoogleSearch,
    required this.onExtract,
    required this.onRunAllEngines,
    required this.onEngineChanged,
  });

  SearchEngineAvailability _availabilityFor(SearchEngine engine) {
    return engineAvailability[engine.id] ??
        SearchEngineAvailability.unknown(engine);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loading =
        controller.loading || extracting || runningEngineDiagnostics;
    final canRun = controller.canRunBrowserActions;
    final selectedAvailability = _availabilityFor(selectedEngine);
    final selectedEngineAvailable = selectedAvailability.canSearch;
    final canSearch = canRun && selectedEngineAvailable && !loading;
    final canExtract = canRun && selectedEngineAvailable && !loading;
    final canRunDiagnostics = canRun && !loading && !probingEngines;
    final searchTooltip = selectedEngineAvailable
        ? 'Search with ${selectedEngine.label}'
        : selectedAvailability.tooltipMessage;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final engine in SearchEngines.all)
                _SearchEngineTag(
                  engine: engine,
                  availability: _availabilityFor(engine),
                  selected: engine == selectedEngine,
                  enabled: canRun && !loading,
                  onSelected: onEngineChanged,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: inputController,
                  onSubmitted: (_) => onGoogleSearch(),
                  decoration: InputDecoration(
                    hintText: 'Query or URL',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Load URL',
                onPressed: canRun ? onLoadUrl : null,
                icon: const Icon(Icons.open_in_browser),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: searchTooltip,
                onPressed: canSearch ? onGoogleSearch : null,
                icon: const Icon(Icons.search),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                tooltip: 'Extract search results',
                onPressed: canExtract ? onExtract : null,
                icon: const Icon(Icons.data_object),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: probingEngines
                    ? 'Checking search engine availability.'
                    : 'Run all search engines',
                onPressed: canRunDiagnostics ? onRunAllEngines : null,
                icon: runningEngineDiagnostics
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.playlist_play),
              ),
              if (controller.error != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    controller.error!,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchEngineTag extends StatelessWidget {
  final SearchEngine engine;
  final SearchEngineAvailability availability;
  final bool selected;
  final bool enabled;
  final ValueChanged<SearchEngine> onSelected;

  const _SearchEngineTag({
    required this.engine,
    required this.availability,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSelect = enabled && availability.canSearch;
    final selectedColor = theme.colorScheme.primaryContainer;
    final unselectedColor = theme.colorScheme.surfaceContainerHighest;
    final disabledColor = theme.colorScheme.surfaceContainerHighest;
    final selectedLabelColor = theme.colorScheme.onPrimaryContainer;
    final normalLabelColor = theme.colorScheme.onSurface;
    final disabledLabelColor = theme.disabledColor;
    final labelColor = !canSelect && !selected
        ? disabledLabelColor
        : selected
        ? selectedLabelColor
        : normalLabelColor;
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final iconColor = canSelect || selected
        ? _statusColor(theme, availability)
        : theme.disabledColor;

    return Tooltip(
      message: availability.tooltipMessage,
      child: ChoiceChip(
        selected: selected,
        onSelected: canSelect ? (_) => onSelected(engine) : null,
        avatar: Icon(_statusIcon(availability), size: 14, color: iconColor),
        label: Text(engine.label, overflow: TextOverflow.ellipsis),
        labelStyle: theme.textTheme.labelMedium?.copyWith(color: labelColor),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: unselectedColor,
        selectedColor: selectedColor,
        disabledColor: disabledColor,
        side: BorderSide(color: borderColor),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

class _SearchBrowserBody extends StatelessWidget {
  final SearchBrowserController controller;
  final TextEditingController messagesController;
  final SearchReferenceBundle referenceBundle;
  final SearchExtractionResult result;
  final SearchQueryGenerationResult queryGenerationResult;
  final SearchEngine selectedEngine;
  final Map<String, SearchEngineAvailability> engineAvailability;
  final List<_EngineDiagnosticResult> engineDiagnostics;
  final String query;
  final bool extracting;
  final bool runningEngineDiagnostics;
  final List<_SearchDebugSample> samples;
  final VoidCallback onBuildQuery;
  final ValueChanged<_SearchDebugSample> onSampleSelected;
  final VoidCallback onRunReferenceSearch;

  const _SearchBrowserBody({
    required this.controller,
    required this.messagesController,
    required this.referenceBundle,
    required this.result,
    required this.queryGenerationResult,
    required this.selectedEngine,
    required this.engineAvailability,
    required this.engineDiagnostics,
    required this.query,
    required this.extracting,
    required this.runningEngineDiagnostics,
    required this.samples,
    required this.onBuildQuery,
    required this.onSampleSelected,
    required this.onRunReferenceSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1200;
        final selectedAvailability =
            engineAvailability[selectedEngine.id] ??
            SearchEngineAvailability.unknown(selectedEngine);
        final messagePane = _MessageInputPane(
          controller: messagesController,
          canRun:
              controller.canRunBrowserActions &&
              !extracting &&
              !runningEngineDiagnostics &&
              selectedAvailability.canSearch,
          extracting: extracting,
          samples: samples,
          onBuildQuery: onBuildQuery,
          onSampleSelected: onSampleSelected,
          onRunReferenceSearch: onRunReferenceSearch,
        );
        final browserPane = _BrowserPane(controller: controller);
        final referencePane = _ReferenceDebugPane(
          bundle: referenceBundle,
          result: result,
          queryGenerationResult: queryGenerationResult,
          selectedEngine: selectedEngine,
          engineAvailability: engineAvailability,
          engineDiagnostics: engineDiagnostics,
          query: query,
          messages: SearchReferenceBuilder.parseMessageLines(
            messagesController.text,
          ),
        );

        if (wide) {
          return Row(
            children: [
              SizedBox(
                width: 330,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 8, 12),
                  child: messagePane,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 8, 12),
                  child: browserPane,
                ),
              ),
              SizedBox(
                width: 430,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 12, 12),
                  child: referencePane,
                ),
              ),
            ],
          );
        }

        final outputWidth = constraints.maxWidth >= 760
            ? constraints.maxWidth * 0.42
            : 320.0;

        return Column(
          children: [
            SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: messagePane,
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 8, 12),
                      child: browserPane,
                    ),
                  ),
                  SizedBox(
                    width: outputWidth,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 12, 12),
                      child: referencePane,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrowserPane extends StatelessWidget {
  final SearchBrowserController controller;

  const _BrowserPane({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SearchBrowserView(controller: controller),
    );
  }
}

class _MessageInputPane extends StatelessWidget {
  final TextEditingController controller;
  final bool canRun;
  final bool extracting;
  final List<_SearchDebugSample> samples;
  final VoidCallback onBuildQuery;
  final ValueChanged<_SearchDebugSample> onSampleSelected;
  final VoidCallback onRunReferenceSearch;

  const _MessageInputPane({
    required this.controller,
    required this.canRun,
    required this.extracting,
    required this.samples,
    required this.onBuildQuery,
    required this.onSampleSelected,
    required this.onRunReferenceSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = SearchReferenceBuilder.parseMessageLines(controller.text);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: Icons.forum_outlined,
            title: 'Input Messages',
            trailing: '${messages.length}',
            actions: [
              IconButton(
                tooltip: 'Build query',
                onPressed: onBuildQuery,
                icon: const Icon(Icons.manage_search),
              ),
              IconButton.filled(
                tooltip: 'Run reference search',
                onPressed: canRun ? onRunReferenceSearch : null,
                icon: extracting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.travel_explore),
              ),
            ],
          ),
          Container(height: 0.5, color: theme.colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final sample in samples)
                  ActionChip(
                    avatar: const Icon(Icons.bolt, size: 14),
                    label: Text(sample.label),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onPressed: () => onSampleSelected(sample),
                  ),
              ],
            ),
          ),
          Container(height: 0.5, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: TextField(
              controller: controller,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText: 'User: ...',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Container(height: 0.5, color: theme.colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'List<String>',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceDebugPane extends StatelessWidget {
  final SearchReferenceBundle bundle;
  final SearchExtractionResult result;
  final SearchQueryGenerationResult queryGenerationResult;
  final SearchEngine selectedEngine;
  final Map<String, SearchEngineAvailability> engineAvailability;
  final List<_EngineDiagnosticResult> engineDiagnostics;
  final String query;
  final List<String> messages;

  const _ReferenceDebugPane({
    required this.bundle,
    required this.result,
    required this.queryGenerationResult,
    required this.selectedEngine,
    required this.engineAvailability,
    required this.engineDiagnostics,
    required this.query,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sources = bundle.sources;
    final inputJson = _debugJsonEncoder.convert(messages);
    final queryGenerationJson = _debugJsonEncoder.convert(
      queryGenerationResult.toJson(),
    );
    final engineJson = _debugJsonEncoder.convert(selectedEngine.toJson());
    final availability =
        engineAvailability[selectedEngine.id] ??
        SearchEngineAvailability.unknown(selectedEngine);
    final outputJson = _debugJsonEncoder.convert(bundle.toJson());
    final promptContext = bundle.promptContext.isEmpty
        ? 'No prompt context yet.'
        : bundle.promptContext;
    final rawOutput = bundle.rawJson.isEmpty && !bundle.hasSources
        ? 'No output yet.'
        : outputJson;
    final diagnosticsSummary = engineDiagnostics.isEmpty
        ? 'No diagnostics yet.'
        : engineDiagnostics
              .map((diagnostic) => diagnostic.summaryLine)
              .join('\n');

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: Icons.format_list_bulleted,
            title: 'Reference Data',
            trailing: '${sources.length}',
            actions: const <Widget>[],
          ),
          Container(height: 0.5, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DebugSectionLabel(
                  icon: Icons.playlist_play,
                  title: 'Diagnostics Summary',
                ),
                _DebugTextBlock(text: diagnosticsSummary),
                _DebugSectionLabel(
                  icon: Icons.input,
                  title: 'Input List<String>',
                ),
                _DebugTextBlock(text: inputJson),
                _DebugSectionLabel(
                  icon: Icons.psychology_alt_outlined,
                  title: 'Query Generation',
                ),
                _DebugTextBlock(text: queryGenerationJson),
                _DebugSectionLabel(icon: Icons.search, title: 'Search Engine'),
                _DebugTextBlock(text: engineJson),
                _DebugSectionLabel(
                  icon: Icons.wifi_tethering,
                  title: 'Selected Availability',
                ),
                _DebugTextBlock(
                  text: _debugJsonEncoder.convert(availability.toJson()),
                ),
                _DebugSectionLabel(
                  icon: Icons.checklist,
                  title: 'Engine Availability',
                ),
                for (final engine in SearchEngines.all)
                  _AvailabilityTile(
                    availability:
                        engineAvailability[engine.id] ??
                        SearchEngineAvailability.unknown(engine),
                  ),
                _DebugSectionLabel(
                  icon: Icons.playlist_play,
                  title: 'Engine Diagnostics',
                ),
                if (engineDiagnostics.isEmpty)
                  const _DebugTextBlock(text: 'No diagnostics yet.')
                else
                  for (final diagnostic in engineDiagnostics)
                    _EngineDiagnosticTile(diagnostic: diagnostic),
                _DebugSectionLabel(
                  icon: Icons.manage_search,
                  title: 'Generated Query',
                ),
                _DebugTextBlock(text: query.isEmpty ? 'No query yet.' : query),
                if (bundle.hasError || result.hasError) ...[
                  _DebugSectionLabel(icon: Icons.error_outline, title: 'Error'),
                  _DebugTextBlock(text: bundle.error ?? result.error ?? ''),
                ],
                _DebugSectionLabel(icon: Icons.link, title: 'Sources'),
                if (sources.isEmpty)
                  const _DebugTextBlock(text: 'No sources yet.')
                else
                  for (final source in sources)
                    _ReferenceSourceTile(source: source),
                _DebugSectionLabel(
                  icon: Icons.article_outlined,
                  title: 'Prompt Context',
                ),
                _DebugTextBlock(text: promptContext),
                _DebugSectionLabel(
                  icon: Icons.data_object,
                  title: 'Raw Output JSON',
                ),
                _DebugTextBlock(text: rawOutput),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EngineDiagnosticResult {
  final SearchEngine engine;
  final SearchEngineAvailability availability;
  final String currentUrl;
  final String pageUrl;
  final String pageTitle;
  final int itemCount;
  final String? error;
  final Duration? elapsed;
  final bool skipped;

  const _EngineDiagnosticResult({
    required this.engine,
    required this.availability,
    required this.currentUrl,
    required this.pageUrl,
    required this.pageTitle,
    required this.itemCount,
    required this.error,
    required this.elapsed,
    required this.skipped,
  });

  factory _EngineDiagnosticResult.skipped({
    required SearchEngine engine,
    required SearchEngineAvailability availability,
  }) {
    return _EngineDiagnosticResult(
      engine: engine,
      availability: availability,
      currentUrl: '',
      pageUrl: '',
      pageTitle: '',
      itemCount: 0,
      error: availability.tooltipMessage,
      elapsed: null,
      skipped: true,
    );
  }

  factory _EngineDiagnosticResult.completed({
    required SearchEngine engine,
    required SearchEngineAvailability availability,
    required String currentUrl,
    required String pageUrl,
    required String pageTitle,
    required int itemCount,
    required String? error,
    required Duration elapsed,
  }) {
    return _EngineDiagnosticResult(
      engine: engine,
      availability: availability,
      currentUrl: currentUrl,
      pageUrl: pageUrl,
      pageTitle: pageTitle,
      itemCount: itemCount,
      error: error,
      elapsed: elapsed,
      skipped: false,
    );
  }

  bool get usable =>
      !skipped && itemCount > 0 && (error == null || error!.isEmpty);

  String get statusLabel {
    if (skipped) return 'Skipped';
    if (usable) return 'Usable';
    if (error != null && error!.contains('verification')) return 'Blocked';
    if (error != null && error!.contains('did not match')) return 'Mismatch';
    if (error != null && error!.isNotEmpty) return 'Error';
    return 'No results';
  }

  String get summaryLine {
    final detail = error != null && error!.isNotEmpty
        ? error!
        : pageTitle.isNotEmpty
        ? pageTitle
        : pageUrl;
    if (detail.isEmpty) return '${engine.label}: $statusLabel ($itemCount)';
    return '${engine.label}: $statusLabel ($itemCount) - $detail';
  }
}

class _AvailabilityTile extends StatelessWidget {
  final SearchEngineAvailability availability;

  const _AvailabilityTile({required this.availability});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(theme, availability);
    final elapsed = availability.elapsed == null
        ? ''
        : ' ${availability.elapsed!.inMilliseconds}ms';
    final statusCode = availability.statusCode == null
        ? ''
        : ' HTTP ${availability.statusCode}';

    return Tooltip(
      message: availability.tooltipMessage,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(_statusIcon(availability), size: 16, color: statusColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                availability.engine.label,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${availability.statusLabel}$statusCode$elapsed',
              style: theme.textTheme.labelMedium?.copyWith(color: statusColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _EngineDiagnosticTile extends StatelessWidget {
  final _EngineDiagnosticResult diagnostic;

  const _EngineDiagnosticTile({required this.diagnostic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = diagnostic.usable
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final elapsed = diagnostic.elapsed == null
        ? ''
        : ' ${diagnostic.elapsed!.inMilliseconds}ms';
    final detailLines = <String>[
      if (diagnostic.error != null && diagnostic.error!.isNotEmpty)
        'Error: ${diagnostic.error}',
      if (diagnostic.pageTitle.isNotEmpty)
        'Page title: ${diagnostic.pageTitle}',
      if (diagnostic.pageUrl.isNotEmpty) 'Page URL: ${diagnostic.pageUrl}',
      if (diagnostic.currentUrl.isNotEmpty &&
          diagnostic.currentUrl != diagnostic.pageUrl)
        'Controller URL: ${diagnostic.currentUrl}',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                diagnostic.usable
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  diagnostic.engine.label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                '${diagnostic.statusLabel} · ${diagnostic.itemCount}$elapsed',
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
          if (detailLines.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final detail in detailLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

IconData _statusIcon(SearchEngineAvailability availability) {
  if (availability.isAvailable) return Icons.check_circle_outline;
  if (availability.isUnavailable) return Icons.block;
  if (availability.isChecking) return Icons.sync;
  return Icons.help_outline;
}

Color _statusColor(ThemeData theme, SearchEngineAvailability availability) {
  if (availability.isAvailable) return theme.colorScheme.primary;
  if (availability.isUnavailable) return theme.colorScheme.error;
  return theme.colorScheme.onSurfaceVariant;
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;
  final List<Widget> actions;

  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(trailing, style: theme.textTheme.labelMedium),
          if (actions.isNotEmpty) const SizedBox(width: 4),
          for (final action in actions) action,
        ],
      ),
    );
  }
}

class _DebugSectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;

  const _DebugSectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _DebugTextBlock extends StatelessWidget {
  final String text;

  const _DebugTextBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SelectableText(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _ReferenceSourceTile extends StatelessWidget {
  final SearchReferenceSource source;

  const _ReferenceSourceTile({required this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${source.rank}.',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  source.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            source.url,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (source.summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              source.summary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
