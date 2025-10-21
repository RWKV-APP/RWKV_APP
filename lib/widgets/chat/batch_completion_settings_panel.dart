import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/argument_value.dart';
import 'package:zone/widgets/form_item.dart';

class BatchCompletionSettings {
  final bool enabled;
  final int batchCount;
  final int width;

  final int row = 1;

  int get col => enabled ? batchCount : 1;

  double get colWidthPercent => width / 100.0;

  int get batchSize => row * col;

  factory BatchCompletionSettings.initial() => BatchCompletionSettings(enabled: false, batchCount: 2, width: 65);

  BatchCompletionSettings({required this.enabled, required this.batchCount, required this.width});

  BatchCompletionSettings copyWith({
    bool? enabled,
    int? batchCount,
    int? width,
  }) {
    return BatchCompletionSettings(
      enabled: enabled ?? this.enabled,
      batchCount: batchCount ?? this.batchCount,
      width: width ?? this.width,
    );
  }
}

class BatchCompletionSettingsPanel extends ConsumerWidget {
  static final _shown = qs(false);
  static final settings = qs(BatchCompletionSettings.initial());

  static Future<BatchCompletionSettings> show() async {
    qq;
    if (_shown.q) return settings.q;
    _shown.q = true;
    final context = getContext();
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
    final customTheme = ref.watch(P.app.customTheme);
    final settings = ref.watch(BatchCompletionSettingsPanel.settings);
    final batchCount = settings.batchCount;
    final batchInference = settings.enabled;
    final batchVW = settings.width;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Scaffold(
        backgroundColor: customTheme.setting,
        appBar: AppBar(
          title: T(s.batch_completion_settings),
          automaticallyImplyLeading: false,
          backgroundColor: customTheme.setting,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
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
          padding: const EI.o(
            l: 12,
            r: 12,
          ),
          children: [
            FormItem(
              isSectionStart: true,
              isSectionEnd: !batchInference,
              title: s.batch_completion,
              subtitle: s.batch_inference_detail,
              info: batchInference ? s.enabled : s.disabled,
              showArrow: false,
              trailing: Switch.adaptive(
                value: batchInference,
                onChanged: _onBatchInferenceSwitchChanged,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: batchInference ? const SizedBox.shrink() : 8.h,
            ),
            IgnorePointer(
              ignoring: !batchInference,
              child: AnimatedOpacity(
                opacity: batchInference ? 1 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: FormItem(
                  showArrow: false,
                  isSectionStart: !batchInference,
                  title: s.batch_inference_count,
                  subtitle: s.batch_inference_count_detail_2(batchCount),
                  info: batchCount.toString(),
                  onTap: () {},
                  bottom: ArgumentValue(
                    Argument.batchCount,
                    // TODO: @wangce Handle batch count get from backend
                    _onChanged,
                    defaultValue: batchCount,
                    showTitle: false,
                    showValue: false,
                    padding: const EI.o(l: 4, r: 4, t: 12, b: 8),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !batchInference,
              child: AnimatedOpacity(
                opacity: batchInference ? 1 : 0.5,
                duration: const Duration(milliseconds: 300),
                child: FormItem(
                  showArrow: false,
                  isSectionEnd: true,
                  title: s.batch_inference_width_2,
                  subtitle: s.batch_inference_width_detail_2,
                  info: batchVW.toString() + "% " + s.screen_width,
                  onTap: () {},
                  bottom: ArgumentValue(
                    Argument.batchVW,
                    _onChanged,
                    defaultValue: batchVW,
                    showTitle: false,
                    showValue: false,
                    padding: const EI.o(l: 4, r: 4, t: 12, b: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
