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
import 'package:zone/model/wenyan_mode.dart';
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
        P.chat.wenYanWen.q = WenyanMode.off;
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
                      const Icon(Icons.info_outline),
                    ],
                  ),
                ),
                bottom: const _DecodeParams(),
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
    final frontendBatchParams = ref.watch(P.rwkv.frontendBatchParams);
    final batchCount = ref.watch(P.chat.batchCount);
    final paramsToShow = frontendBatchParams.take(batchCount).toList();
    final qb = ref.watch(P.app.qb);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 500 ? 3 : 2;

        final List<Widget> rows = [];
        for (int i = 0; i < paramsToShow.length; i += crossAxisCount) {
          final chunk = paramsToShow.skip(i).take(crossAxisCount).toList();
          rows.add(
            Row(
              crossAxisAlignment: .start,
              children: [
                for (int j = 0; j < crossAxisCount; j++) ...[
                  if (j > 0) 8.w,
                  Expanded(
                    child: j < chunk.length ? _DecodeParam(index: i + j, param: chunk[j]) : const SizedBox(),
                  ),
                ],
              ],
            ),
          );
          if (i + crossAxisCount < paramsToShow.length) {
            rows.add(8.h);
          }
        }

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            4.h,
            ...rows,
            Divider(color: qb.q(.2)),
            const Align(
              alignment: .centerLeft,
              child: _DecodeParam(
                forAll: true,
                index: -1,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DecodeParam extends ConsumerWidget {
  final int index;
  final SamplerAndPenaltyParam? param;
  final bool forAll;

  const _DecodeParam({
    required this.index,
    this.param,
    this.forAll = false,
  });

  void _onTap() async {
    final context = getContext()!;
    final s = S.of(context);
    final selectedType = param?.decodeParamType;
    final result = await showModalActionSheet<DecodeParamType>(
      context: context,
      title: forAll
          ? s.please_select_the_sampler_and_penalty_parameters_to_set_for_all_messages
          : s.please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index(index + 1),
      message: s.select_the_decode_parameters_to_set_all_to_for_index,
      actions: [
        ...[
          DecodeParamType.defaults,
          DecodeParamType.comprehensive,
          DecodeParamType.creative,
          DecodeParamType.fixed,
          DecodeParamType.conservative,
          DecodeParamType.custom,
        ].map(
          (e) {
            if (e == DecodeParamType.custom) {
              String label = s.decode_param_custom;
              if (param?.isCustom ?? false) label = "✅ $label";
              return SheetAction(
                label: label,
                key: DecodeParamType.custom,
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

    late final SamplerAndPenaltyParam newParam;

    if (result == DecodeParamType.custom) {
      final res = await ArgumentsPanel.show(
        getContext()!,
        isEditingBatchParams: true,
        title: forAll
            ? s.please_select_the_sampler_and_penalty_parameters_to_set_for_all_messages
            : s.please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index(index + 1),
        // 临时选用当前的 param
        temporarySamplerAndPenaltyParam: forAll ? SamplerAndPenaltyParam.fromDecodeParamType(DecodeParamType.defaults) : param,
      );
      if (res == null) return;
      newParam = res;
    } else {
      newParam = SamplerAndPenaltyParam.fromDecodeParamType(result);
    }

    final newValue = forAll
        ? List.generate(P.rwkv.frontendBatchParams.q.length, (index) => newParam)
        : [
            ...P.rwkv.frontendBatchParams.q.sublist(0, index),
            newParam,
            ...P.rwkv.frontendBatchParams.q.sublist(index + 1),
          ];

    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }

    P.rwkv.frontendBatchParams.q = newValue;
    P.rwkv.send(
      SetSamplerAndPenaltyParams(
        temperatures: newValue.map((e) => e.temperature).toList(),
        topKs: newValue.map((e) => 500.0).toList(),
        topPs: newValue.map((e) => e.topP).toList(),
        presencePenalties: newValue.map((e) => e.presencePenalty).toList(),
        frequencyPenalties: newValue.map((e) => e.frequencyPenalty).toList(),
        penaltyDecays: newValue.map((e) => e.penaltyDecay).toList(),
        modelID: modelID,
      ),
    );
    P.rwkv.send(GetSamplerAndPenaltyParams(batchSize: P.chat.batchCount.q, modelID: modelID));
  }

  String _fmt(double value) {
    return double.parse(value.toStringAsFixed(3)).toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);

    return GD(
      onTap: _onTap,
      child: Container(
        width: forAll ? double.infinity : null,
        decoration: BD(
          color: qb.q(.08),
          border: Border.all(color: qb.q(.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const .all(12),
        child: forAll
            ? Center(
                child: Text(s.set_all_batch_params, style: const TS(w: .bold)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const .symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: qb.q(.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("#${index + 1}", style: const TS(w: .bold, s: 12)),
                      ),
                      8.w,
                      Flexible(
                        child: Text(
                          param?.displayName ?? "",
                          style: const TS(w: .bold, s: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  8.h,
                  if (param != null) ...[
                    _infoRow("Temp", _fmt(param!.temperature), "Top_P", _fmt(param!.topP), qb),
                    2.h,
                    _infoRow("PP", _fmt(param!.presencePenalty), "FP", _fmt(param!.frequencyPenalty), qb),
                    2.h,
                    Text("Decay: ${_fmt(param!.penaltyDecay)}", style: TS(s: 11, c: qb.q(.7))),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _infoRow(String k1, String v1, String k2, String v2, Color qb) {
    final style = TS(s: 11, c: qb.q(.7));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$k1: $v1", style: style),
        8.w,
        Text("$k2: $v2", style: style),
      ],
    );
  }
}
