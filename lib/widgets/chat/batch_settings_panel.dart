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

class BatchSettingsPanel extends ConsumerWidget {
  static final _shown = qs(false);

  static Future<void> show() async {
    qq;
    if (_shown.q) return;
    _shown.q = true;
    final context = getContext();
    if (context == null || !context.mounted) {
      _shown.q = false;
      return;
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
            return BatchSettingsPanel(scrollController: scrollController);
          },
        );
      },
    );
    _shown.q = false;
  }

  final ScrollController? scrollController;

  const BatchSettingsPanel({super.key, required this.scrollController});

  void _onBatchInferenceSwitchChanged(bool value) {
    P.app.hapticLight();
    P.chat.batchInference.q = value;
  }

  void _onChanged(Argument argument, double value) {
    int rawNewValue = int.parse(value.toStringAsFixed(argument.fixedDecimals));
    if (argument.step != null) rawNewValue = (rawNewValue / argument.step!).round() * argument.step!.toInt();
    final currentValue = switch (argument) {
      Argument.batchCount => P.chat.batchCount.q,
      Argument.batchVW => P.chat.batchVW.q,
      _ => 0,
    };
    if (currentValue == rawNewValue) return;
    if (argument.enableGaimon) P.app.hapticLight();
    switch (argument) {
      case Argument.batchCount:
        P.chat.batchCount.q = rawNewValue;
      case Argument.batchVW:
        P.chat.batchVW.q = rawNewValue;
      default:
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final batchCount = ref.watch(P.chat.batchCount);
    final customTheme = ref.watch(P.app.customTheme);
    final batchInference = ref.watch(P.chat.batchInference);
    final batchVW = ref.watch(P.chat.batchVW);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Scaffold(
        backgroundColor: customTheme.setting,
        appBar: AppBar(
          title: T(s.batch_inference_settings),
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
              title: s.batch_inference,
              subtitle: s.batch_inference,
              info: batchInference ? "开启" : "关闭",
              showArrow: false,
              trailing: Switch.adaptive(
                value: P.chat.batchInference.q,
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
                  subtitle: s.batch_inference_count_detail(batchCount),
                  info: batchCount.toString(),
                  onTap: () {},
                  bottom: ArgumentValue(
                    Argument.batchCount,
                    _onChanged,
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
                  title: s.batch_inference_width,
                  subtitle: s.batch_inference_width_detail,
                  info: batchVW.toString() + "% " + s.screen_width,
                  onTap: () {},
                  bottom: ArgumentValue(
                    Argument.batchVW,
                    _onChanged,
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
