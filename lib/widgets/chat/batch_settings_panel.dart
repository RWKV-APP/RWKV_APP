import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_mobile_flutter/to_rwkv.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/model/sampler_and_penalty_param.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/argument_value.dart';
import 'package:zone/widgets/arguments_panel.dart';
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
    final isMobile = P.app.isMobile.q;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: isMobile ? .6 : .75,
          maxChildSize: isMobile ? .65 : .8,
          minChildSize: isMobile ? .45 : .6,
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

  void _onTapInfo() {
    final context = getContext();
    if (context == null) return;
    showOkAlertDialog(
      context: context,
      title: S.of(context).parameter_description,
      message: S.of(context).parameter_description_detail,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final batchCount = ref.watch(P.chat.batchCount);
    final customTheme = ref.watch(P.app.customTheme);
    final batchInference = ref.watch(P.chat.batchEnabled);
    final batchVW = ref.watch(P.chat.batchVW);
    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Scaffold(
        backgroundColor: customTheme.setting,
        appBar: AppBar(
          title: T(s.batch_inference_settings),
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
          padding: const .only(left: 12, right: 12, bottom: 12),
          children: [
            FormItem(
              isSectionStart: true,
              isSectionEnd: !batchInference,
              title: s.batch_inference,
              subtitle: s.batch_inference_detail,
              infoText: batchInference ? s.enabled : s.disabled,
              showArrow: false,
              trailing: Switch.adaptive(
                value: P.chat.batchEnabled.q,
                onChanged: P.chat.onBatchInferenceSwitchChanged,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: batchInference ? const SizedBox.shrink() : 8.h,
            ),
            DimmedWhenInactive(
              ignoring: !batchInference,
              child: FormItem(
                showArrow: false,
                isSectionStart: !batchInference,
                title: s.batch_inference_count,
                subtitle: s.batch_inference_count_detail(batchCount),
                infoWidget: Container(
                  padding: const .only(right: 4),
                  child: Text(batchCount.toString(), style: const TS(w: .bold, s: 16)),
                ),
                onTap: () {},
                bottom: ArgumentValue(
                  Argument.batchCount,
                  enabled: batchInference,
                  _onChanged,
                  showTitle: false,
                  showValue: false,
                  padding: const .only(left: 4, top: 12, right: 4, bottom: 8),
                ),
              ),
            ),
            DimmedWhenInactive(
              ignoring: !batchInference,
              child: FormItem(
                title: s.decode_params_for_each_message,
                subtitle: s.decode_params_for_each_message_detail,
                showArrow: false,
                infoWidget: IconButton(
                  onPressed: _onTapInfo,
                  icon: Row(
                    children: [
                      Text(s.decode_param),
                      4.w,
                      Icon(Icons.info_outline),
                    ],
                  ),
                ),
                bottom: _DecodeParams(),
              ),
            ),
            DimmedWhenInactive(
              ignoring: !batchInference,
              child: FormItem(
                showArrow: false,
                isSectionEnd: true,
                title: s.batch_inference_width,
                subtitle: s.batch_inference_width_detail,
                infoText: batchVW.toString() + "% " + s.screen_width,
                onTap: () {},
                bottom: ArgumentValue(
                  Argument.batchVW,
                  enabled: batchInference,
                  _onChanged,
                  showTitle: false,
                  showValue: false,
                  padding: const .only(left: 4, top: 12, right: 4, bottom: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DimmedWhenInactive extends StatelessWidget {
  final bool ignoring;
  final Widget child;
  final Duration duration;

  const DimmedWhenInactive({
    super.key,
    required this.ignoring,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: ignoring,
      child: AnimatedOpacity(
        opacity: ignoring ? 0.5 : 1,
        duration: duration,
        child: child,
      ),
    );
  }
}

class _DecodeParams extends ConsumerWidget {
  const _DecodeParams();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final frontendBatchParams = ref.watch(P.rwkv.frontendBatchParams);
    final backendBatchParams = ref.watch(P.rwkv.backendBatchParams);
    final frontendBatchParamsAreAllSame = ref.watch(P.rwkv.frontendBatchParamsAreAllSame);
    final syncingBatchParams = ref.watch(P.rwkv.syncingBatchParams);
    final batchCount = ref.watch(P.chat.batchCount);
    final paramsToShow = frontendBatchParams.take(batchCount).toList();

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (frontendBatchParamsAreAllSame) T(s.all_the_same) else T(s.not_all_the_same),
        if (syncingBatchParams) T(s.syncing) else T(s.not_syncing),
        T(batchCount.toString()),
        T(s.set_all_to_question_mark),
        Wrap(
          alignment: .start,
          crossAxisAlignment: .start,
          runSpacing: 4,
          spacing: 4,
          children: [
            for (int index = 0; index < paramsToShow.length; index++) _DecodeParam(index: index, param: paramsToShow[index]),
          ],
        ),
      ],
    );
  }
}

class _DecodeParam extends ConsumerWidget {
  final int index;
  final SamplerAndPenaltyParam param;

  const _DecodeParam({required this.index, required this.param});

  void _onTap() async {
    final context = getContext()!;
    final s = S.of(context);
    final selectedType = param.decodeParamType;
    final result = await showModalActionSheet<DecodeParamType>(
      context: context,
      title: s.please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index(index),
      message: s.select_the_decode_parameters_to_set_all_to_for_index(index),
      actions: [
        ...[
          DecodeParamType.defaults,
          DecodeParamType.comprehensive,
          DecodeParamType.creative,
          DecodeParamType.fixed,
          DecodeParamType.conservative,
          DecodeParamType.unknown,
        ].map(
          (e) {
            if (e == DecodeParamType.unknown) {
              return SheetAction(
                label: s.custom,
                key: DecodeParamType.unknown,
              );
            }

            String label = SamplerAndPenaltyParam.fromDecodeParamType(e).displayName;
            if (selectedType == e) label = "✅ $label";
            return SheetAction(label: label, key: e);
          },
        ),
      ],
    );

    if (result == null) return;

    SamplerAndPenaltyParam? newParam;

    if (result == DecodeParamType.unknown) {
      final res = await ArgumentsPanel.show(
        getContext()!,
        isEditingBatchParams: true,
        title: s.please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index(index),
        // 临时选用当前的 param
        temporarySamplerAndPenaltyParam: param,
      );
      if (res == null) return;
      newParam = res;
    } else {
      newParam = SamplerAndPenaltyParam.fromDecodeParamType(result);
    }

    final newValue = [
      ...P.rwkv.frontendBatchParams.q.sublist(0, index),
      newParam,
      ...P.rwkv.frontendBatchParams.q.sublist(index + 1),
    ];
    P.rwkv.frontendBatchParams.q = newValue;
    P.rwkv.send(
      SetSamplerAndPenaltyParams(
        temperatures: newValue.map((e) => e.temperature).toList(),
        topKs: newValue.map((e) => 500.0).toList(),
        topPs: newValue.map((e) => e.topP).toList(),
        presencePenalties: newValue.map((e) => e.presencePenalty).toList(),
        frequencyPenalties: newValue.map((e) => e.frequencyPenalty).toList(),
        penaltyDecays: newValue.map((e) => e.penaltyDecay).toList(),
      ),
    );
    P.rwkv.send(GetSamplerAndPenaltyParams(batchSize: P.chat.batchCount.q));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    return GD(
      onTap: _onTap,
      child: Container(
        decoration: BD(
          color: qb.q(.1),
          border: Border.all(color: qb.q(.5)),
          borderRadius: .circular(4),
        ),
        padding: const .all(4),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            T(s.prebuilt + s.colon + param.displayName),
            T(s.temperature_with_value(param.temperature)),
            T(s.top_p_with_value(param.topP)),
            T(s.presence_penalty_with_value(param.presencePenalty)),
            T(s.frequency_penalty_with_value(param.frequencyPenalty)),
            T(s.penalty_decay_with_value(param.penaltyDecay)),
          ],
        ),
      ),
    );
  }
}
