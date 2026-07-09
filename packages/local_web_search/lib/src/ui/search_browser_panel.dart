// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:local_web_search/src/browser/search_browser_controller.dart';
import 'package:local_web_search/src/browser/search_browser_view.dart';
import 'package:local_web_search/src/models/search_deep_result.dart';
import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_engine_availability.dart';
import 'package:local_web_search/src/models/search_extraction_result.dart';
import 'package:local_web_search/src/models/search_query_generation_result.dart';
import 'package:local_web_search/src/models/search_reference_bundle.dart';
import 'package:local_web_search/src/models/search_reference_source.dart';
import 'package:local_web_search/src/query/search_query_generator.dart';
import 'package:local_web_search/src/reachability/search_engine_reachability_probe.dart';
import 'package:local_web_search/src/reference/search_reference_builder.dart';
import 'package:local_web_search/src/reference/search_reference_service.dart';

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
  final SearchEngine initialSearchEngine;
  final List<String>? messages;
  final bool initialDeepResultsEnabled;
  final ValueChanged<SearchEngine>? onSearchEngineChanged;
  final ValueChanged<bool>? onDeepResultsEnabledChanged;
  final ValueChanged<SearchReferenceBundle>? onReferenceBundleChanged;

  const SearchBrowserPanel({
    super.key,
    this.controller,
    this.reachabilityProbe,
    this.simulatedUnavailableEngineIds = const <String>{},
    this.initialSearchEngine = SearchEngines.bing,
    this.messages,
    this.initialDeepResultsEnabled = false,
    this.onSearchEngineChanged,
    this.onDeepResultsEnabledChanged,
    this.onReferenceBundleChanged,
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
  late final TextEditingController _inputController;
  late final TextEditingController _messagesController;
  late final bool _ownsController;
  late Map<String, SearchEngineAvailability> _engineAvailability;
  List<_EngineDiagnosticResult> _engineDiagnostics =
      const <_EngineDiagnosticResult>[];
  SearchExtractionResult _result = const SearchExtractionResult.empty();
  SearchReferenceBundle _referenceBundle = const SearchReferenceBundle.empty();
  late SearchQueryGenerationResult _queryGenerationResult;
  late SearchEngine _selectedEngine;
  bool _extracting = false;
  late bool _deepResultsEnabled;
  final bool _probingEngines = false;
  bool _runningEngineDiagnostics = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? SearchBrowserController();
    _engineAvailability = _initialEngineAvailability(
      widget.simulatedUnavailableEngineIds,
    );
    _selectedEngine = widget.initialSearchEngine;
    _messagesController = TextEditingController(text: _initialMessagesText());
    _queryGenerationResult = SearchQueryGenerator.build(_currentMessages());
    _inputController = TextEditingController(
      text: _queryGenerationResult.query,
    );
    _controller.addListener(_onBrowserChanged);
    _messagesController.addListener(_onMessagesChanged);
    _deepResultsEnabled = widget.initialDeepResultsEnabled;
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

  @override
  void didUpdateWidget(covariant SearchBrowserPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSearchEngine != oldWidget.initialSearchEngine &&
        widget.initialSearchEngine != _selectedEngine) {
      _selectedEngine = widget.initialSearchEngine;
    }
    if (widget.initialDeepResultsEnabled !=
            oldWidget.initialDeepResultsEnabled &&
        widget.initialDeepResultsEnabled != _deepResultsEnabled) {
      _deepResultsEnabled = widget.initialDeepResultsEnabled;
    }

    final nextMessagesText = _messagesText(widget.messages);
    final oldMessagesText = _messagesText(oldWidget.messages);
    if (nextMessagesText == null || nextMessagesText == oldMessagesText) {
      return;
    }
    if (nextMessagesText == _messagesController.text) return;

    _messagesController.text = nextMessagesText;
    _queryGenerationResult = SearchQueryGenerator.build(_currentMessages());
    _inputController.text = _queryGenerationResult.query;
  }

  void _onBrowserChanged() {
    if (!mounted) return;
    setState(() {
      _referenceBundle = _controller.latestReferenceBundle;
    });
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

  String _initialMessagesText() {
    return _messagesText(widget.messages) ?? _defaultMessages.trim();
  }

  static String? _messagesText(List<String>? messages) {
    if (messages == null) return null;
    final normalized = <String>[];
    for (final message in messages) {
      final trimmed = message.trim();
      if (trimmed.isEmpty) continue;
      normalized.add(trimmed);
    }
    return normalized.join('\n');
  }

  static Map<String, SearchEngineAvailability> _initialEngineAvailability(
    Set<String> simulatedUnavailableEngineIds,
  ) {
    return <String, SearchEngineAvailability>{
      for (final engine in SearchEngines.all)
        engine.id: simulatedUnavailableEngineIds.contains(engine.id)
            ? SearchEngineAvailability.unavailable(
                engine: engine,
                error: 'Simulated unavailable request.',
              )
            : SearchEngineAvailability.unknown(engine),
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

  void _buildQueryFromMessages() {
    final queryGeneration = SearchQueryGenerator.build(_currentMessages());
    setState(() {
      _queryGenerationResult = queryGeneration;
      _inputController.text = queryGeneration.query;
    });
  }

  void _setDeepResultsEnabled(bool enabled) {
    if (_deepResultsEnabled == enabled) return;
    setState(() {
      _deepResultsEnabled = enabled;
      _referenceBundle = const SearchReferenceBundle.empty();
    });
    _controller.clearReferenceBundle();
    widget.onDeepResultsEnabledChanged?.call(enabled);
    widget.onReferenceBundleChanged?.call(const SearchReferenceBundle.empty());
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
    _controller.clearReferenceBundle();
    widget.onReferenceBundleChanged?.call(const SearchReferenceBundle.empty());
  }

  Future<void> _loadAsUrl() async {
    await _controller.loadUrl(_inputController.text);
  }

  Future<void> _loadSelectedEngineSearch() async {
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

  Future<void> _selectSearchEngine(SearchEngine engine) async {
    final availability = _availabilityFor(engine);
    setState(() {
      _selectedEngine = engine;
      _result = const SearchExtractionResult.empty();
      _referenceBundle = const SearchReferenceBundle.empty();
    });
    _controller.clearReferenceBundle();
    widget.onSearchEngineChanged?.call(engine);
    widget.onReferenceBundleChanged?.call(const SearchReferenceBundle.empty());

    if (!availability.canSearch) {
      _controller.markError(availability.tooltipMessage);
      return;
    }

    final query = _inputController.text.trim();
    if (query.isEmpty) return;

    await _controller.loadSearch(engine: engine, query: query);
  }

  Future<void> _runReferenceSearchFromMessages() async {
    if (!_canUseSelectedEngine()) {
      _controller.markError(_selectedEngineUnavailableMessage());
      return;
    }

    final messages = _currentMessages();
    final queryGeneration = SearchQueryGenerator.build(messages);
    final query = queryGeneration.query;
    if (query.isEmpty) {
      final extraction = SearchExtractionResult.failure(queryGeneration.reason);
      final bundle = SearchReferenceBuilder.buildBundle(
        messages: messages,
        searchEngine: _selectedEngine,
        query: '',
        extraction: extraction,
        enableDeepResults: _deepResultsEnabled,
      );
      setState(() {
        _queryGenerationResult = queryGeneration;
        _inputController.text = query;
        _result = extraction;
        _referenceBundle = bundle;
      });
      _controller.markReferenceBundle(bundle);
      widget.onReferenceBundleChanged?.call(bundle);
      return;
    }

    setState(() {
      _queryGenerationResult = queryGeneration;
      _inputController.text = query;
      _result = const SearchExtractionResult.empty();
      _referenceBundle = const SearchReferenceBundle.empty();
      _extracting = true;
    });

    final bundle = await SearchReferenceService.searchWithBrowser(
      controller: _controller,
      messages: messages,
      searchEngine: _selectedEngine,
      enableDeepResults: _deepResultsEnabled,
    );
    final result = _resultFromBundle(bundle);
    if (!mounted) return;
    setState(() {
      _selectedEngine = bundle.searchEngine;
      _result = result;
      _referenceBundle = bundle;
      _extracting = false;
    });
    widget.onReferenceBundleChanged?.call(bundle);
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
    final bundle = SearchReferenceBuilder.buildBundle(
      messages: _currentMessages(),
      searchEngine: _selectedEngine,
      query: _inputController.text,
      extraction: result,
      enableDeepResults: _deepResultsEnabled,
    );
    final hydratedBundle =
        await SearchReferenceService.hydrateDeepResultsForBundle(
          controller: _controller,
          bundle: bundle,
          detailPageLoadDelay: const Duration(seconds: 2),
          detailPageLoadTimeout: const Duration(seconds: 12),
        );
    if (!mounted) return;
    setState(() {
      _result = result;
      _referenceBundle = hydratedBundle;
      _extracting = false;
    });
    _controller.markReferenceBundle(hydratedBundle);
    widget.onReferenceBundleChanged?.call(hydratedBundle);
  }

  SearchExtractionResult _resultFromBundle(SearchReferenceBundle bundle) {
    if (bundle.rawJson.isNotEmpty) {
      return SearchExtractionResult.fromJavaScriptResult(bundle.rawJson);
    }
    if (bundle.hasError) {
      return SearchExtractionResult.failure(bundle.error!);
    }
    return const SearchExtractionResult.empty();
  }

  Future<void> _runAllEngineDiagnostics() async {
    if (_runningEngineDiagnostics) return;
    final messages = _currentMessages();
    final queryGeneration = SearchQueryGenerator.build(messages);
    final query = queryGeneration.query;
    if (query.isEmpty) {
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
      _controller.markReferenceBundle(bundle);
      widget.onReferenceBundleChanged?.call(bundle);
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
    final grayscaleTheme = _searchBrowserGrayscaleTheme(theme);
    final latestBundle = _controller.latestReferenceBundle;
    final visibleReferenceBundle =
        latestBundle.hasSources ||
            latestBundle.hasError ||
            latestBundle.rawJson.isNotEmpty
        ? latestBundle
        : _referenceBundle;

    return Theme(
      data: grayscaleTheme,
      child: Scaffold(
        backgroundColor: grayscaleTheme.colorScheme.surface,
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
                deepResultsEnabled: _deepResultsEnabled,
                onLoadUrl: _loadAsUrl,
                onSelectedEngineSearch: _loadSelectedEngineSearch,
                onExtract: _extractSearchResults,
                onRunAllEngines: _runAllEngineDiagnostics,
                onEngineChanged: _selectSearchEngine,
                onDeepResultsChanged: _setDeepResultsEnabled,
              ),
              Expanded(
                child: _SearchBrowserBody(
                  controller: _controller,
                  messagesController: _messagesController,
                  referenceBundle: visibleReferenceBundle,
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
      ),
    );
  }
}

ThemeData _searchBrowserGrayscaleTheme(ThemeData theme) {
  final scheme = _searchBrowserGrayscaleScheme(theme.brightness);
  final disabledColor = theme.brightness == Brightness.dark
      ? const Color(0xFF777777)
      : const Color(0xFFB8B8B8);

  return theme.copyWith(
    colorScheme: scheme,
    disabledColor: disabledColor,
    scaffoldBackgroundColor: scheme.surface,
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.onSurface),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return disabledColor;
        if (states.contains(WidgetState.selected)) return scheme.surface;
        return scheme.surface;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.surfaceContainerHighest;
        }
        if (states.contains(WidgetState.selected)) return scheme.onSurface;
        return scheme.surfaceContainerHighest;
      }),
      trackOutlineColor: WidgetStatePropertyAll(scheme.outlineVariant),
    ),
  );
}

ColorScheme _searchBrowserGrayscaleScheme(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF808080),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFE8E8E8),
      onPrimary: const Color(0xFF111111),
      primaryContainer: const Color(0xFF3A3A3A),
      onPrimaryContainer: const Color(0xFFF2F2F2),
      secondary: const Color(0xFFD0D0D0),
      onSecondary: const Color(0xFF181818),
      secondaryContainer: const Color(0xFF303030),
      onSecondaryContainer: const Color(0xFFF0F0F0),
      surface: const Color(0xFF101010),
      onSurface: const Color(0xFFF0F0F0),
      surfaceContainerHighest: const Color(0xFF303030),
      onSurfaceVariant: const Color(0xFFC0C0C0),
      outline: const Color(0xFF707070),
      outlineVariant: const Color(0xFF444444),
      error: const Color(0xFFE0E0E0),
      onError: const Color(0xFF101010),
    );
  }

  return ColorScheme.fromSeed(seedColor: const Color(0xFF808080)).copyWith(
    primary: const Color(0xFF202020),
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFE0E0E0),
    onPrimaryContainer: const Color(0xFF202020),
    secondary: const Color(0xFF404040),
    onSecondary: const Color(0xFFFFFFFF),
    secondaryContainer: const Color(0xFFE8E8E8),
    onSecondaryContainer: const Color(0xFF202020),
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF202020),
    surfaceContainerHighest: const Color(0xFFE0E0E0),
    onSurfaceVariant: const Color(0xFF666666),
    outline: const Color(0xFF8A8A8A),
    outlineVariant: const Color(0xFFC8C8C8),
    error: const Color(0xFF202020),
    onError: const Color(0xFFFFFFFF),
  );
}

class _SearchBrowserToolbar extends StatelessWidget {
  final SearchBrowserController controller;
  final TextEditingController inputController;
  final SearchEngine selectedEngine;
  final Map<String, SearchEngineAvailability> engineAvailability;
  final bool extracting;
  final bool probingEngines;
  final bool runningEngineDiagnostics;
  final bool deepResultsEnabled;
  final VoidCallback onLoadUrl;
  final VoidCallback onSelectedEngineSearch;
  final VoidCallback onExtract;
  final VoidCallback onRunAllEngines;
  final ValueChanged<SearchEngine> onEngineChanged;
  final ValueChanged<bool> onDeepResultsChanged;

  const _SearchBrowserToolbar({
    required this.controller,
    required this.inputController,
    required this.selectedEngine,
    required this.engineAvailability,
    required this.extracting,
    required this.probingEngines,
    required this.runningEngineDiagnostics,
    required this.deepResultsEnabled,
    required this.onLoadUrl,
    required this.onSelectedEngineSearch,
    required this.onExtract,
    required this.onRunAllEngines,
    required this.onEngineChanged,
    required this.onDeepResultsChanged,
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
        ? 'Search the query field with ${selectedEngine.label}, then extract result titles, links, and snippets.'
        : selectedAvailability.tooltipMessage;
    final neutralButtonStyle = IconButton.styleFrom(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      foregroundColor: theme.colorScheme.onSurface,
      disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
      disabledForegroundColor: theme.disabledColor,
    );
    final strongButtonStyle = IconButton.styleFrom(
      backgroundColor: theme.colorScheme.onSurface,
      foregroundColor: theme.colorScheme.surface,
      disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
      disabledForegroundColor: theme.disabledColor,
    );
    final textFieldBorder = OutlineInputBorder(
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
    );
    final focusedTextFieldBorder = OutlineInputBorder(
      borderSide: BorderSide(color: theme.colorScheme.onSurface),
    );

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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Tooltip(
                message: 'Read result pages before building prompt data.',
                child: Switch.adaptive(
                  value: deepResultsEnabled,
                  onChanged: loading ? null : onDeepResultsChanged,
                  activeThumbColor: theme.colorScheme.surface,
                  activeTrackColor: theme.colorScheme.onSurface,
                  inactiveThumbColor: theme.colorScheme.surface,
                  inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                  trackOutlineColor: WidgetStatePropertyAll(
                    theme.colorScheme.outlineVariant,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Text(
                'Deep results',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: inputController,
                  onSubmitted: (_) => onSelectedEngineSearch(),
                  decoration: InputDecoration(
                    hintText: 'Query or URL',
                    isDense: true,
                    border: textFieldBorder,
                    enabledBorder: textFieldBorder,
                    focusedBorder: focusedTextFieldBorder,
                    suffixIcon: loading
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                style: neutralButtonStyle,
                tooltip:
                    'Open the query field as a URL in the embedded browser.',
                onPressed: canRun && !loading ? onLoadUrl : null,
                icon: const Icon(Icons.open_in_browser),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                style: neutralButtonStyle,
                tooltip: searchTooltip,
                onPressed: canSearch ? onSelectedEngineSearch : null,
                icon: const Icon(Icons.search),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                style: strongButtonStyle,
                tooltip:
                    'Extract result titles, links, and snippets from the current search page into Reference Data.',
                onPressed: canExtract ? onExtract : null,
                icon: const Icon(Icons.data_object),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                style: neutralButtonStyle,
                tooltip: probingEngines
                    ? 'Checking search engine availability.'
                    : 'Diagnostic: run the generated query on every search engine and compare extraction results.',
                onPressed: canRunDiagnostics ? onRunAllEngines : null,
                icon: runningEngineDiagnostics
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onSurface,
                        ),
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
                      color: theme.colorScheme.onSurfaceVariant,
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
    final selectedColor = theme.colorScheme.onSurface;
    final unselectedColor = theme.colorScheme.surface;
    final disabledColor = theme.colorScheme.surfaceContainerHighest;
    final selectedLabelColor = theme.colorScheme.surface;
    final normalLabelColor = theme.colorScheme.onSurface;
    final disabledLabelColor = theme.disabledColor;
    final labelColor = !canSelect && !selected
        ? disabledLabelColor
        : selected
        ? selectedLabelColor
        : normalLabelColor;
    final borderColor = selected
        ? theme.colorScheme.onSurface
        : theme.colorScheme.outlineVariant;
    final icon = _engineTagIcon(availability: availability, selected: selected);
    final iconColor = selected
        ? selectedLabelColor
        : canSelect
        ? _statusColor(theme, availability)
        : theme.disabledColor;

    return Tooltip(
      message: availability.tooltipMessage,
      child: ChoiceChip(
        selected: selected,
        onSelected: canSelect ? (_) => onSelected(engine) : null,
        avatar: icon == null ? null : Icon(icon, size: 14, color: iconColor),
        label: Text(engine.label, overflow: TextOverflow.ellipsis),
        labelStyle: theme.textTheme.labelMedium?.copyWith(color: labelColor),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        showCheckmark: false,
        checkmarkColor: selectedLabelColor,
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
    final neutralButtonStyle = IconButton.styleFrom(
      foregroundColor: theme.colorScheme.onSurfaceVariant,
      disabledForegroundColor: theme.disabledColor,
    );
    final strongButtonStyle = IconButton.styleFrom(
      backgroundColor: theme.colorScheme.onSurface,
      foregroundColor: theme.colorScheme.surface,
      disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
      disabledForegroundColor: theme.disabledColor,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface,
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
                style: neutralButtonStyle,
                tooltip:
                    'Build the search query from Input Messages without opening a browser page.',
                onPressed: onBuildQuery,
                icon: const Icon(Icons.manage_search),
              ),
              IconButton.filled(
                style: strongButtonStyle,
                tooltip:
                    'Build the query, search with the selected engine, extract sources, and update Reference Data.',
                onPressed: canRun ? onRunReferenceSearch : null,
                icon: extracting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onSurface,
                        ),
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
                    avatar: Icon(
                      Icons.bolt,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    label: Text(sample.label),
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
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
    final deepResults = bundle.deepResults;
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
    final deepPromptContext = bundle.deepPromptContext.isEmpty
        ? 'No deep prompt context yet.'
        : bundle.deepPromptContext;
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
        color: theme.colorScheme.surface,
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
                  icon: Icons.travel_explore,
                  title: 'Deep Results',
                ),
                if (deepResults.isEmpty)
                  const _DebugTextBlock(text: 'No deep results yet.')
                else
                  for (final result in deepResults)
                    _DeepResultTile(result: result),
                _DebugSectionLabel(
                  icon: Icons.article_outlined,
                  title: 'Prompt Context',
                ),
                _DebugTextBlock(text: promptContext),
                _DebugSectionLabel(
                  icon: Icons.article,
                  title: 'Deep Prompt Context',
                ),
                _DebugTextBlock(text: deepPromptContext),
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
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;
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

IconData? _engineTagIcon({
  required SearchEngineAvailability availability,
  required bool selected,
}) {
  if (selected) return Icons.check;
  if (availability.isAvailable) return Icons.check_circle_outline;
  if (availability.isUnavailable) return Icons.block;
  if (availability.isChecking) return Icons.sync;
  return null;
}

IconData _statusIcon(SearchEngineAvailability availability) {
  if (availability.isAvailable) return Icons.check_circle_outline;
  if (availability.isUnavailable) return Icons.block;
  if (availability.isChecking) return Icons.sync;
  return Icons.help_outline;
}

Color _statusColor(ThemeData theme, SearchEngineAvailability availability) {
  if (availability.isAvailable) return theme.colorScheme.onSurface;
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
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
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
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
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
                  color: theme.colorScheme.onSurfaceVariant,
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
              color: theme.colorScheme.onSurfaceVariant,
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

class _DeepResultTile extends StatelessWidget {
  final SearchDeepResult result;

  const _DeepResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = result.hasContent
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;
    final detail = result.hasError
        ? result.error!
        : '${result.markdown.length}/${result.markdownLength} chars';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                result.hasContent
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${result.rank}. ${result.title}',
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result.url,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: theme.textTheme.labelMedium?.copyWith(color: color),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (result.markdown.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              result.markdown,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
