// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/form_item.dart';

class ExperimentalFeatures extends ConsumerWidget {
  final ScrollController? scrollController;

  const ExperimentalFeatures({super.key, this.scrollController});

  static Future<void> show() async {
    await P.ui.showPanel<void>(
      key: "experimental-features",
      initialChildSize: .5,
      maxChildSize: .75,
      builder: (scrollController) {
        return ExperimentalFeatures(scrollController: scrollController);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final pausedReplyGuidanceEnabled = ref.watch(P.preference.pausedReplyGuidanceEnabled);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Scaffold(
        backgroundColor: appTheme.settingBg,
        appBar: AppBar(
          title: Text(s.experimental_features),
          automaticallyImplyLeading: false,
          backgroundColor: appTheme.settingBg,
          actions: [
            Padding(
              padding: const .only(right: 8),
              child: IconButton(
                onPressed: pop,
                tooltip: s.close,
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
        body: ListView(
          controller: scrollController,
          padding: const .only(left: 12, right: 12, bottom: 12),
          children: [
            Padding(
              padding: const .only(left: 4, right: 4, bottom: 12),
              child: Text(
                s.experimental_features_description,
                style: TextStyle(
                  color: qb.withValues(alpha: .72),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
            FormItem(
              key: const ValueKey("paused-reply-guidance-experimental-feature"),
              icon: Icon(Icons.edit_note_outlined, color: qb.withValues(alpha: .667), size: 16),
              title: s.paused_reply_guidance_feature,
              subtitle: s.paused_reply_guidance_feature_description,
              showArrow: false,
              isSectionStart: true,
              isSectionEnd: true,
              trailing: Switch.adaptive(
                key: const ValueKey("paused-reply-guidance-experimental-switch"),
                value: pausedReplyGuidanceEnabled,
                onChanged: P.preference.setPausedReplyGuidanceEnabled,
                activeThumbColor: appTheme.themePrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
