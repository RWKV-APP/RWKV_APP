import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/web_search_mode.dart';
import 'package:zone/model/web_search_provider.dart';
import 'package:zone/model/app_theme.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/ask_question_button.dart';
import 'package:zone/widgets/chat/batch_button.dart';
import 'package:zone/widgets/chat/chat_interaction_button.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/chat/decode_param_button.dart';
import 'package:zone/widgets/chat/thinking_mode_button.dart';
import 'package:zone/widgets/chat/web_search_mode_button.dart';
import 'package:zone/widgets/chat/web_search_settings_panel.dart';
import 'package:zone/widgets/chat/web_search_provider_icon.dart';
import 'package:zone/widgets/chat/web_search_provider_sheet.dart';

void main() {
  setUp(() async {
    P.chat.webSearchChecks.q = {};
    P.rwkvGeneration.generating.q = false;
    P.rwkvModel.loadingStatus.q = {};
    P.chat.webSearchApiKeys.q = {};
  });

  tearDown(() {
    P.chat.onWebSearchSettingsClosed();
    P.chat.webSearchChecks.q = {};
    P.chat.webSearchApiKeys.q = {};
    P.chat.webSearchMode.q = .off;
    P.chat.webSearchProvider.q = .zhihuGlobal;
    P.rwkvGeneration.generating.q = false;
    P.chat.localWebSearchPanelEnabled.q = false;
  });

  testWidgets('all five input actions share one rendering component and height', (tester) async {
    for (final brightness in Brightness.values) {
      for (final narrow in [false, true]) {
        await _pumpSettings(
          tester,
          brightness: brightness,
          narrow: narrow,
          child: const Wrap(
            children: [DecodeParamButton(), ThinkingModeButton(), BatchButton(), WebSearchModeButton(), AskQuestionButton()],
          ),
        );
        final controls = find.byType(ChatInteractionButton);
        expect(controls, findsNWidgets(5));
        final heights = tester.elementList(controls).map((element) => tester.getSize(find.byWidget(element.widget)).height).toSet();
        expect(heights, hasLength(1));
        expect(find.descendant(of: find.byType(WebSearchModeButton), matching: find.byType(IconButton)), findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('Search has central settings and ordered selection-only actions', (tester) async {
    await _pumpSettings(tester, child: const WebSearchModeButton());
    await tester.tap(find.byType(WebSearchModeButton));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text(S.current.web_search_settings), findsOneWidget);
    final labels = [
      'AnySearch',
      'DeepSeek',
      S.current.web_search_zhihu_global,
      S.current.web_search_zhihu_site,
      'Tavily',
      'Brave Search',
      'Exa',
      'Serper',
      'SerpApi',
      'SearchApi',
      'Firecrawl',
      S.current.web_search_browser,
      S.current.web_search_settings,
      S.current.off,
    ];
    final positions = labels.map((label) => tester.getTopLeft(find.text(label)).dy).toList();
    expect(positions, orderedEquals([...positions]..sort()));
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(P.chat.webSearchProvider.q, WebSearchProvider.zhihuGlobal);
    await tester.tap(find.text(S.current.cancel));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(P.chat.webSearchProvider.q, WebSearchProvider.zhihuGlobal);
    await tester.tap(find.byType(WebSearchModeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AnySearch'));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchProvider.q, WebSearchProvider.anysearch);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    expect(find.byType(WebSearchSettingsPanel), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(DropdownButtonFormField<WebSearchProvider>), findsNothing);
    await tester.tap(find.byType(WebSearchModeButton));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    await tester.ensureVisible(find.text(S.current.off));
    await tester.tap(find.text(S.current.off));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(P.chat.localWebSearchPanelEnabled.q, isFalse);
  });

  testWidgets('missing configuration opens focused setup and verified providers enable directly', (tester) async {
    await _pumpSettings(tester, child: const WebSearchModeButton());
    await tester.tap(find.byType(WebSearchModeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DeepSeek'));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(find.byType(WebSearchSettingsPanel), findsOneWidget);
    expect(tester.widget<WebSearchSettingsPanel>(find.byType(WebSearchSettingsPanel)).provider, WebSearchProvider.deepseek);
    expect(P.chat.webSearchProvider.q, WebSearchProvider.deepseek);
    expect(tester.widget<FilledButton>(find.byWidgetPredicate((widget) => widget is FilledButton)).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'fixture-personal-key');
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    await _verifyProvider(tester, .deepseek);
    expect(find.text(S.current.web_search_validation_success), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.text(S.current.close));
    await tester.pumpAndSettle();
    P.chat.onSwitchWebSearchMode(.off);
    await tester.tap(find.byType(WebSearchModeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DeepSeek'));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchProvider.q, WebSearchProvider.deepseek);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    expect(find.byType(WebSearchSettingsPanel), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('keyboard opens Search and generation disables provider changes', (tester) async {
    await _pumpSettings(tester, child: const WebSearchModeButton());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    P.rwkvGeneration.generating.q = true;
    await tester.pumpAndSettle();
    await tester.tap(find.byType(WebSearchModeButton));
    await tester.pumpAndSettle();
    expect(find.byType(WebSearchProviderSheet), findsNothing);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
  });

  testWidgets('adaptive provider choices and per-provider setup fit narrow large-text screens', (tester) async {
    for (final platform in [TargetPlatform.macOS, TargetPlatform.android]) {
      for (final brightness in Brightness.values) {
        await _pumpSettings(tester, platform: platform, brightness: brightness, narrow: true, child: const WebSearchModeButton());
        await tester.tap(find.byType(WebSearchModeButton));
        await tester.pumpAndSettle();
        expect(find.byType(CupertinoActionSheet), platform == TargetPlatform.macOS ? findsOneWidget : findsNothing);
        expect(find.byType(BottomSheet), platform == TargetPlatform.android ? findsOneWidget : findsNothing);
        for (final provider in [WebSearchProvider.zhihuGlobal, WebSearchProvider.zhihuSite]) {
          final icon = tester.getRect(find.byWidgetPredicate((widget) => widget is WebSearchProviderIcon && widget.provider == provider));
          final title = tester.getRect(find.text(P.chat.searchProviderLabel(provider)));
          final description = tester.getRect(find.text(P.chat.searchProviderDescription(provider)));
          expect(title.left - icon.right, closeTo(10, 0.1));
          expect(title.center.dy, closeTo(icon.center.dy, 0.1));
          expect(description.top, greaterThanOrEqualTo(title.bottom + 4));
          expect(description.top, greaterThanOrEqualTo(icon.bottom + 4));
        }
        expect(find.text(S.current.web_search_settings), findsOneWidget);
        expect(find.text(S.current.web_search_browser), platform == TargetPlatform.macOS ? findsOneWidget : findsNothing);
        await tester.ensureVisible(find.text(S.current.web_search_settings));
        await tester.tap(find.text(S.current.web_search_settings));
        await tester.pumpAndSettle();
        expect(find.byType(WebSearchSettingsPanel), findsOneWidget);
        expect(P.chat.webSearchMode.q, WebSearchMode.off);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(S.current.close));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('provider-bound controls mask keys, share the Zhihu key and enable only that provider', (tester) async {
    await _pumpSettings(tester);
    final field = find.byType(TextField);
    await tester.enterText(field, 'fixture-session-key');
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText, isTrue);
    expect(P.chat.webSearchApiKeys.q['zhihu'], 'fixture-session-key');
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    await _verifyProvider(tester, .zhihuGlobal);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    await _pumpSettings(tester, provider: WebSearchProvider.zhihuSite);
    expect(find.byType(DropdownButtonFormField<WebSearchProvider>), findsOneWidget);
    expect(P.chat.webSearchApiKeys.q['zhihu'], 'fixture-session-key');
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await _verifyProvider(tester, .zhihuSite);
    expect(P.chat.webSearchProvider.q, WebSearchProvider.zhihuSite);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings fit a narrow phone with large text in both themes', (tester) async {
    for (final provider in WebSearchProvider.values.where((value) => value != .browser)) {
      P.chat.webSearchProvider.q = provider;
      for (final brightness in Brightness.values) {
        await _pumpSettings(tester, brightness: brightness, narrow: true, provider: provider);
        expect(find.text(P.chat.searchProviderLabel(provider)), findsWidgets);
        expect(find.byType(TextField), provider.credentialId.isNotEmpty ? findsOneWidget : findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('personal key instructions and official links follow the selected provider', (tester) async {
    final openedUrls = <String>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch') openedUrls.add((call.arguments as Map)['url'] as String);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    for (final provider in WebSearchProvider.values.where((value) => value.credentialId.isNotEmpty)) {
      P.chat.webSearchProvider.q = provider;
      await _pumpSettings(tester, provider: provider);
      expect(find.text(S.current.web_search_own_key_notice), findsOneWidget);
      expect(
        find.text(switch (provider) {
          .deepseek => S.current.web_search_deepseek_key_steps,
          .zhihuGlobal || .zhihuSite => S.current.web_search_zhihu_key_steps,
          _ => S.current.web_search_generic_key_steps,
        }),
        findsOneWidget,
      );
      expect(find.text(S.current.web_search_key_auto_apply), findsOneWidget);
      await tester.ensureVisible(find.text(S.current.web_search_get_key));
      await tester.tap(find.text(S.current.web_search_get_key));
      await tester.pumpAndSettle();
      expect(openedUrls.last, provider.keyManagementUrl.toString());
      await tester.ensureVisible(find.text(S.current.web_search_official_docs));
      await tester.tap(find.text(S.current.web_search_official_docs));
      await tester.pumpAndSettle();
      expect(openedUrls.last, provider.documentationUrl.toString());
      if (provider.pricingUrl != null) {
        expect(find.text(P.chat.searchProviderAllowance(provider)), findsOneWidget);
        await tester.ensureVisible(find.text(S.current.web_search_pricing));
        await tester.tap(find.text(S.current.web_search_pricing));
        await tester.pumpAndSettle();
        expect(openedUrls.last, provider.pricingUrl.toString());
      }
      expect(P.chat.webSearchApiKeys.q, isEmpty);
    }
  });

  testWidgets('clearing a personal key removes it from the current session', (tester) async {
    await _pumpSettings(tester);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'fixture-personal-key');
    expect(P.chat.webSearchApiKeys.q['zhihu'], 'fixture-personal-key');
    await _verifyProvider(tester, .zhihuGlobal);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    await tester.ensureVisible(find.byType(TextField));
    await tester.tap(find.byTooltip(S.current.clear));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchApiKeys.q['zhihu'], isEmpty);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('choosing a different provider keeps its configuration and keys separate', (tester) async {
    P.chat.webSearchProvider.q = .anysearch;
    P.chat.webSearchMode.q = .search;
    P.chat.webSearchApiKeys.q = {'zhihu': 'fixture-zhihu-key'};
    await _pumpSettings(tester, child: const WebSearchModeButton());
    await tester.tap(find.byType(WebSearchModeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DeepSeek'));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(S.current.web_search_deepseek_key_steps), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'fixture-deepseek-key');
    expect(P.chat.webSearchApiKeys.q['deepseek'], 'fixture-deepseek-key');
    expect(P.chat.webSearchApiKeys.q['zhihu'], 'fixture-zhihu-key');
    await tester.tap(find.text(S.current.close));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  test('key-management and guide URLs are fixed official HTTPS destinations', () {
    expect(WebSearchProvider.deepseek.keyManagementUrl.toString(), 'https://platform.deepseek.com/api_keys');
    expect(WebSearchProvider.zhihuGlobal.keyManagementUrl.toString(), 'https://developer.zhihu.com/profile');
    expect(WebSearchProvider.zhihuSite.keyManagementUrl, WebSearchProvider.zhihuGlobal.keyManagementUrl);
    for (final provider in [
      WebSearchProvider.deepseek,
      WebSearchProvider.zhihuGlobal,
      WebSearchProvider.zhihuSite,
      WebSearchProvider.anysearch,
      ...WebSearchProvider.values.where((provider) => provider.pricingUrl != null),
    ]) {
      expect(provider.documentationUrl.scheme, 'https');
      expect(provider.documentationUrl.userInfo, isEmpty);
    }
    expect(() => WebSearchProvider.anysearch.keyManagementUrl, throwsStateError);
    expect(() => WebSearchProvider.browser.keyManagementUrl, throwsStateError);
  });

  testWidgets('AnySearch owns its anonymous allowance and no-key settings', (tester) async {
    await _pumpSettings(tester, provider: WebSearchProvider.anysearch);
    expect(find.byType(TextField), findsNothing);
    expect(find.text(S.current.web_search_anysearch_notice), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchProvider.q, WebSearchProvider.anysearch);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    expect(P.chat.webSearchApiKeys.q, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('service icons are bundled and are also used by the active input button', (tester) async {
    for (final entry in {
      WebSearchProvider.deepseek: 'assets/img/chat/search_deepseek.png',
      WebSearchProvider.zhihuGlobal: 'assets/img/chat/search_zhihu.png',
      WebSearchProvider.zhihuSite: 'assets/img/chat/search_zhihu.png',
      WebSearchProvider.anysearch: 'assets/img/chat/search_anysearch.png',
      for (final provider in WebSearchProvider.values.where((value) => value.pricingUrl != null))
        provider: 'assets/img/chat/search_${provider.name}.png',
    }.entries) {
      P.chat.webSearchProvider.q = entry.key;
      P.chat.webSearchMode.q = .search;
      await _pumpSettings(tester, child: const WebSearchModeButton());
      final icon = find.descendant(of: find.byType(WebSearchModeButton), matching: find.byType(WebSearchProviderIcon));
      expect(tester.widget<WebSearchProviderIcon>(icon).provider, entry.key);
      final image = tester.widget<Image>(find.descendant(of: icon, matching: find.byType(Image)));
      expect((image.image as AssetImage).assetName, entry.value);
      if (entry.key == WebSearchProvider.anysearch) expect(image.color, isNotNull);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('DeepSeek button uses white and light whale variants while lists keep blue', (tester) async {
    final originalTheme = P.app.theme.q;
    addTearDown(() => P.app.theme.q = originalTheme);
    for (final appTheme in AppTheme.values) {
      P.app.theme.q = appTheme;
      for (final generating in [false, true]) {
        P.rwkvGeneration.generating.q = generating;
        P.chat.webSearchProvider.q = .deepseek;
        P.chat.webSearchMode.q = .search;
        await _pumpSettings(tester, child: const WebSearchModeButton());
        final image = tester.widget<Image>(find.byType(Image));
        final colors = interactionVisualColors(appTheme: appTheme, state: generating ? .unavailable : .enabled);
        expect(image.color, generating && !appTheme.isLight ? appTheme.qb4 : colors.foreground);
        expect(image.color, isNotNull);
      }
    }
    P.rwkvGeneration.generating.q = false;
    await _pumpSettings(tester, child: const WebSearchProviderIcon(provider: .deepseek));
    expect(tester.widget<Image>(find.byType(Image)).color, isNull);
  });

  testWidgets('browsing central configuration preserves active service and isolates keys', (tester) async {
    P.chat.webSearchProvider.q = .anysearch;
    P.chat.webSearchMode.q = .search;
    P.chat.webSearchApiKeys.q = {'zhihu': 'fixture-zhihu'};
    await _pumpSettings(tester);
    expect(find.text('${S.current.web_search_zhihu_global}: ${S.current.web_search_zhihu_web_description}'), findsOneWidget);
    expect(find.text('${S.current.web_search_zhihu_site}: ${S.current.web_search_zhihu_site_description}'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<WebSearchProvider>));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tavily').last);
    await tester.tap(find.text('Tavily').last);
    await tester.pumpAndSettle();
    expect(P.chat.webSearchProvider.q, WebSearchProvider.anysearch);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'fixture-tavily');
    expect(P.chat.webSearchApiKeys.q, {'zhihu': 'fixture-zhihu', 'tavily': 'fixture-tavily'});
    await _verifyProvider(tester, .tavily);
    expect(P.chat.webSearchProvider.q, WebSearchProvider.tavily);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
  });

  testWidgets('Firecrawl supports anonymous search and an optional personal key', (tester) async {
    await _pumpSettings(tester, provider: .firecrawl);
    expect(find.text(S.current.web_search_optional_key_notice), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).decoration!.hintText, isNull);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchProvider.q, WebSearchProvider.firecrawl);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'fixture-firecrawl');
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    await _verifyProvider(tester, .firecrawl);
    await tester.ensureVisible(find.byTooltip(S.current.clear));
    await tester.tap(find.byTooltip(S.current.clear));
    await tester.pumpAndSettle();
    expect(P.chat.webSearchApiKeys.q['firecrawl'], isEmpty);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
  });

  testWidgets('validation displays progress, blocks edits and reports retryable errors inline', (tester) async {
    await _pumpSettings(tester, provider: .deepseek);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'fixture-personal-key');
    final response = Completer<http.Response>();
    final pending = P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: MockClient((_) => response.future));
    await tester.pump();
    expect(find.text(S.current.web_search_validating), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(tester.widget<FilledButton>(find.byWidgetPredicate((widget) => widget is FilledButton)).onPressed, isNull);
    expect(
      tester.widget<DropdownButtonFormField<WebSearchProvider>>(find.byType(DropdownButtonFormField<WebSearchProvider>)).onChanged,
      isNull,
    );
    response.complete(http.Response('fixture-personal-key', 401));
    await tester.pumpAndSettle();
    await pending;
    expect(find.text(S.current.web_search_unauthorized), findsOneWidget);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(tester.widget<FilledButton>(find.byWidgetPredicate((widget) => widget is FilledButton)).onPressed, isNotNull);
    await _verifyProvider(tester, .deepseek);
    expect(find.text(S.current.web_search_validation_success), findsOneWidget);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
  });
}

Future<void> _verifyProvider(WidgetTester tester, WebSearchProvider provider) async {
  await tester.pump();
  final client = MockClient((_) async {
    final Map<String, dynamic> payload = switch (provider) {
      .zhihuGlobal || .zhihuSite => {
        'Code': 0,
        'Data': {'Items': []},
      },
      .firecrawl => {
        'success': true,
        'data': {'web': []},
      },
      _ => {'results': []},
    };
    return http.Response(jsonEncode(payload), 200);
  });
  final pending = P.chat.onVerifyAndEnableWebSearchProvider(provider, client: client);
  await tester.pumpAndSettle();
  await pending;
  await tester.pumpAndSettle();
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  bool narrow = false,
  WebSearchProvider provider = WebSearchProvider.zhihuGlobal,
  TargetPlatform platform = TargetPlatform.macOS,
  Widget? child,
}) async {
  tester.view.physicalSize = narrow ? const Size(320, 640) : const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: rc,
      child: ProviderScope(
        overrides: [P.app.isDesktop.overrideWithValue(platform == TargetPlatform.macOS)],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness, platform: platform),
          locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(narrow ? 2 : 1)),
            child: child!,
          ),
          home: Scaffold(
            body: child ?? WebSearchSettingsPanel(key: ValueKey(provider), provider: provider),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
