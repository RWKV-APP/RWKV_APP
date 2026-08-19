// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/func/thinking_prefix.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/thinking_mode.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/chat/thinking_mode_button.dart';
import 'package:zone/widgets/see/floating_suggestions.dart';
import 'package:zone/widgets/suggestion_chips.dart';
import 'package:zone/widgets/world_group_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VL thinking capability catalog', () {
    test('marks only the complete 260815 Thinking Preview cohort among all VL models', () {
      final modelConfigs = _worldModelConfigs();
      final thinkingPreview = modelConfigs.where((entry) {
        final url = entry['url'] as String;
        return url.contains('finevisionmax-thinking-preview-260815');
      }).toList();
      final allVisionConfigs = modelConfigs.where((entry) {
        return FileInfo.fromJSON(entry).worldType != null;
      }).toList();
      final taggedVisionConfigs = allVisionConfigs.where((entry) {
        return (entry['tags'] as List<dynamic>).contains(configurableVisionThinkingTag);
      }).toList();

      expect(thinkingPreview, hasLength(3));
      expect(
        thinkingPreview.every((entry) => (entry['tags'] as List<dynamic>).contains(configurableVisionThinkingTag)),
        isTrue,
      );
      expect(taggedVisionConfigs, hasLength(3));
      expect(
        taggedVisionConfigs.every((entry) {
          final url = entry['url'] as String;
          return url.contains('finevisionmax-thinking-preview-260815');
        }),
        isTrue,
      );
    });

    test('uses the exact enabled and disabled prefixes for a tagged VL model', () {
      final fileInfo = _thinkingPreviewCore();

      expect(supportsConfigurableVisionThinking(fileInfo), isTrue);
      expect(
        thinkingTokenForModel(
          thinkingMode: ThinkingMode.fastWithSpacePrefix,
          configuredThinkingToken: ThinkingMode.fastWithSpacePrefix.header,
          fileInfo: fileInfo,
        ),
        visionThinkingDisabledPrefix,
      );
      expect(
        thinkingTokenForModel(
          thinkingMode: ThinkingMode.free,
          configuredThinkingToken: ThinkingMode.free.header,
          fileInfo: fileInfo,
        ),
        visionThinkingEnabledPrefix,
      );
      expect(toggledVisionThinkingMode(ThinkingMode.fastWithSpacePrefix), ThinkingMode.free);
      expect(toggledVisionThinkingMode(ThinkingMode.free), ThinkingMode.fastWithSpacePrefix);
    });
  });

  group('VL thinking capability UI', () {
    testWidgets('aligns Fast first with suggested prompts and shares idle visuals', (tester) async {
      await S.load(const Locale('en'));
      final tagged = _thinkingPreviewCore();
      final untagged = _earlierFineVisionMaxCore();
      final originalUseBackdropFilter = P.ui.useBackdropFilterForInputOptions.q;
      P.app.theme.q = .light;
      P.app.qb.q = Colors.black;
      P.app.qw.q = Colors.white;
      P.app.demoType.q = .see;
      P.rwkvGeneration.generating.q = false;
      P.rwkvModel.loadingStatus.q = {};
      P.ui.useBackdropFilterForInputOptions.q = false;
      await P.rwkvParams.setModelConfig(thinkingMode: ThinkingMode.fastWithSpacePrefix, setPrompt: false);
      addTearDown(() async {
        P.rwkvModel.allLoaded.q = const <FileInfo, int>{};
        P.remote.seeWeights.q = const <FileInfo>{};
        P.rwkvContext.currentWorldType.q = null;
        P.ui.useBackdropFilterForInputOptions.q = originalUseBackdropFilter;
        await P.rwkvParams.setModelConfig(thinkingMode: ThinkingMode.fastWithSpacePrefix, setPrompt: false);
      });

      P.remote.seeWeights.q = <FileInfo>{untagged};
      P.rwkvModel.allLoaded.q = <FileInfo, int>{untagged: 1};
      P.rwkvContext.currentWorldType.q = untagged.worldType;
      await tester.pumpWidget(_testApp());
      await tester.pump();

      expect(find.byType(ThinkingModeButton), findsNothing);
      expect(find.byType(SuggestionChips), findsOneWidget);
      expect(find.text('Please describe this image for me~'), findsOneWidget);

      P.remote.seeWeights.q = <FileInfo>{tagged};
      P.rwkvModel.allLoaded.q = <FileInfo, int>{tagged: 2};
      P.rwkvContext.currentWorldType.q = tagged.worldType;
      await tester.pump();

      expect(find.byType(ThinkingModeButton), findsOneWidget);
      expect(find.text('Fast'), findsOneWidget);
      expect(
        find.ancestor(of: find.byType(ThinkingModeButton), matching: find.byType(SuggestionChips)),
        findsOneWidget,
      );
      final suggestionCenter = tester.getCenter(find.text('Please describe this image for me~'));
      final fastCenter = tester.getCenter(find.text('Fast'));
      expect((suggestionCenter.dy - fastCenter.dy).abs(), lessThan(1));
      expect(
        tester.getTopLeft(find.byType(ThinkingModeButton)).dx,
        lessThan(tester.getTopLeft(find.text('Please describe this image for me~')).dx),
      );

      final appTheme = P.app.theme.q;
      final expectedColors = interactionVisualColors(
        appTheme: appTheme,
        state: .available,
      );
      final suggestionContainer = tester.widget<Container>(find.byKey(const Key('_SuggestionChip-0')));
      final decoration = suggestionContainer.decoration! as BoxDecoration;
      final suggestionText = tester.widget<Text>(find.text('Please describe this image for me~'));
      expect(decoration.color, expectedColors.background);
      expect(decoration.border!.top.color, expectedColors.border);
      expect(suggestionText.style!.color, expectedColors.foreground);
      expect(suggestionText.style!.fontWeight, FontWeight.w500);

      await tester.tap(find.byType(ThinkingModeButton));
      await tester.pump();

      expect(P.rwkvParams.thinkingMode.q, ThinkingMode.free);
      expect(find.text('High'), findsOneWidget);

      await tester.tap(find.byType(ThinkingModeButton));
      await tester.pump();

      expect(P.rwkvParams.thinkingMode.q, ThinkingMode.fastWithSpacePrefix);
      expect(find.text('Fast'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows an independent model-list tag only for the tagged VL core', (tester) async {
      P.app.theme.q = .light;
      P.app.qb.q = Colors.black;
      P.app.qw.q = Colors.white;

      await tester.pumpWidget(_worldTagsApp(_thinkingPreviewCore()));
      expect(find.text('Thinking'), findsOneWidget);

      await tester.pumpWidget(_worldTagsApp(_earlierFineVisionMaxCore()));
      expect(find.text('Thinking'), findsNothing);
    });
  });
}

Widget _testApp() {
  return StateWrapper(
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: FloatingSuggestions(),
        ),
      ),
    ),
  );
}

Widget _worldTagsApp(FileInfo fileInfo) {
  return StateWrapper(
    child: MaterialApp(
      home: Scaffold(
        body: WorldModelTags(
          socPair: ('', fileInfo.fileName),
          fileInfo: fileInfo,
        ),
      ),
    ),
  );
}

List<Map<String, dynamic>> _worldModelConfigs() {
  final config = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
  final world = config['world'] as Map<String, dynamic>;
  return (world['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();
}

FileInfo _thinkingPreviewCore() {
  final entry = _worldModelConfigs().singleWhere((entry) {
    final url = entry['url'] as String;
    return url.endsWith('finevisionmax-thinking-preview-260815-Q8_0.gguf');
  });
  return FileInfo.fromJSON(entry);
}

FileInfo _earlierFineVisionMaxCore() {
  final entry = _worldModelConfigs().singleWhere((entry) {
    final url = entry['url'] as String;
    return url.endsWith('rwkv-vl-1.5v100m-finevisionmax-Q8_0.gguf');
  });
  return FileInfo.fromJSON(entry);
}
