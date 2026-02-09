import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/page/completion/_completion_state.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/argument_value.dart';
import 'package:zone/widgets/form_item.dart';

class BatchCompletionSettingsPanel extends ConsumerWidget {
  static final _shown = qs(false);
  static final settings = qs(BatchCompletionSettings.initial());

  static Future<BatchCompletionSettings> show({BuildContext? ctx}) async {
    qq;
    if (_shown.q) return settings.q;
    _shown.q = true;
    final context = ctx ?? getContext();
    if (context == null || !context.mounted) {
      _shown.q = false;
      return settings.q;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: .6,
          maxChildSize: .65,
          minChildSize: .45,
          expand: false,
          snap: false,
          builder: (context, scrollController) {
            return BatchCompletionSettingsPanel(scrollController: scrollController);
          },
        );
      },
    );
    _shown.q = false;
    return settings.q;
  }

  final ScrollController? scrollController;

  const BatchCompletionSettingsPanel({super.key, required this.scrollController});

  void _onBatchInferenceSwitchChanged(bool value) {
    P.app.hapticLight();
    settings.q = settings.q.copyWith(enabled: value);
  }

  void _onChanged(Argument argument, double value) {
    int rawNewValue = int.parse(value.toStringAsFixed(argument.fixedDecimals));
    if (argument.step != null) rawNewValue = (rawNewValue / argument.step!).round() * argument.step!.toInt();
    final currentValue = switch (argument) {
      Argument.batchCount => settings.q.batchCount,
      Argument.batchVW => settings.q.width,
      _ => 0,
    };
    if (currentValue == rawNewValue) return;
    if (argument.enableGaimon) P.app.hapticLight();
    switch (argument) {
      case Argument.batchCount:
        settings.q = settings.q.copyWith(batchCount: rawNewValue);
      case Argument.batchVW:
        settings.q = settings.q.copyWith(width: rawNewValue);
      default:
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final customTheme = ref.watch(P.app.theme);
    final settings = ref.watch(BatchCompletionSettingsPanel.settings);
    final batchCount = settings.batchCount;
    final batchInference = settings.enabled;
    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Scaffold(
        backgroundColor: customTheme.setting,
        appBar: AppBar(
          title: Text(s.batch_completion_settings),
          automaticallyImplyLeading: false,
          backgroundColor: customTheme.setting,
          actions: [
            Padding(
              padding: const .only(right: 8),
              child: IconButton(
                onPressed: () {
                  pop();
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
        body: ListView(
          controller: scrollController,
          padding: const .only(left: 12, right: 12),
          children: [
            FormItem(
              isSectionStart: true,
              isSectionEnd: !batchInference,
              title: s.batch_completion,
              subtitle: s.batch_inference_detail,
              infoText: batchInference ? s.enabled : s.disabled,
              showArrow: false,
              trailing: Switch.adaptive(
                value: batchInference,
                onChanged: _onBatchInferenceSwitchChanged,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: batchInference ? const SizedBox.shrink() : const SizedBox(height: 8),
            ),
            IgnorePointer(
              ignoring: !batchInference,
              child: AnimatedOpacity(
                opacity: batchInference ? 1 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: FormItem(
                  showArrow: false,
                  isSectionEnd: true,
                  isSectionStart: !batchInference,
                  title: s.batch_inference_count,
                  subtitle: s.batch_inference_count_detail_2(batchCount),
                  infoText: batchCount.toString(),
                  onTap: () {},
                  bottom: ArgumentValue(
                    Argument.batchCount,
                    _onChanged,
                    defaultValue: batchCount,
                    showTitle: false,
                    showValue: false,
                    padding: const .only(left: 4, top: 12, right: 4, bottom: 8),
                  ),
                ),
              ),
            ),
            // IgnorePointer(
            //   ignoring: !batchInference,
            //   child: AnimatedOpacity(
            //     opacity: batchInference ? 1 : 0.5,
            //     duration: const Duration(milliseconds: 300),
            //     child: FormItem(
            //       showArrow: false,
            //       isSectionEnd: true,
            //       title: s.batch_inference_width_2,
            //       subtitle: s.batch_inference_width_detail_2,
            //       infoText: batchVW.toString() + "% " + s.screen_width,
            //       onTap: () {},
            //       bottom: ArgumentValue(
            //         Argument.batchVW,
            //         _onChanged,
            //         defaultValue: batchVW,
            //         showTitle: false,
            //         showValue: false,
            //         padding: const .only(left: 4, top: 12, right: 4, bottom: 8),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
