// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat_app_bar.dart';
import 'package:zone/widgets/model_selector.dart';

class ToolIntro extends ConsumerWidget {
  const ToolIntro({super.key, required this.demoType, required this.suggestionsHeight});

  final DemoType demoType;
  final double suggestionsHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final messages = ref.watch(P.msg.list);
    if (messages.isNotEmpty) return const SizedBox.shrink();

    final colors = theme.colorScheme;
    final s = S.of(context);
    final image = demoType == .see;
    final pageKey = ref.watch(P.app.pageKey);
    final activeModel = P.rwkvAutoLoad.visibleCurrentModelForPage(
      fileInfo: ref.watch(P.rwkvModel.latest),
      pageKey: pageKey,
      preferredDemoType: demoType,
    );
    final loaded = ref.watch(P.rwkvModel.loaded);
    final modelName = loaded ? activeModel?.name : null;
    final inputHeight = ref.watch(P.chat.inputHeight);
    return Positioned.fill(
      child: Padding(
        padding: .only(
          top: ref.watch(P.app.paddingTop) + ChatAppBar.themedToolbarHeight(context),
          bottom: inputHeight + suggestionsHeight,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const .all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                margin: .zero,
                elevation: 0,
                child: Padding(
                  padding: const .all(24),
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      Icon(image ? Icons.image_outlined : Icons.record_voice_over_outlined, size: 34, color: colors.primary),
                      const SizedBox(height: 14),
                      Text(image ? s.see : s.tts, textAlign: .center, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                        image ? s.visual_understanding_and_ocr : s.tts_detail,
                        textAlign: .center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      if (modelName case final name?)
                        Text(
                          name,
                          textAlign: .center,
                          style: theme.textTheme.labelLarge?.copyWith(color: colors.primary),
                        )
                      else
                        FilledButton(
                          onPressed: () => ModelSelector.show(preferredDemoType: demoType),
                          child: Text(s.select_a_model),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
