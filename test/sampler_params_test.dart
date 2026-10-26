import 'package:flutter_test/flutter_test.dart';

import 'package:zone/model/argument.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/model/sampler_and_penalty_param.dart';
import 'package:zone/store/p.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final reasoning in [false, true]) {
    test('sampler Reset updates visible Fixed parameters, reasoning=$reasoning', () async {
      await P.rwkvParams.syncSamplerParamsFromDefault(DecodeParamType.fixed);
      expect(P.rwkvParams.decodeParamType.q, DecodeParamType.fixed);

      await P.rwkvParams.resetSamplerParams(enableReasoning: reasoning);

      expect(
        P.rwkvParams.currentSamplerAndPenaltyParam(),
        SamplerAndPenaltyParam.fromDecodeParamType(DecodeParamType.defaults),
      );
      expect(P.rwkvParams.decodeParamType.q, DecodeParamType.defaults);
      expect(P.rwkvParams.arguments(Argument.topK).q, 500);
    });
  }

  test('sampler Reset updates custom values as well as preset controls', () async {
    await P.rwkvParams.syncSamplerParams(
      temperature: .4,
      topP: .7,
      presencePenalty: 1.6,
      frequencyPenalty: .4,
      penaltyDecay: .995,
    );
    expect(P.rwkvParams.decodeParamType.q, DecodeParamType.custom);

    await P.rwkvParams.resetSamplerParams(enableReasoning: false);

    expect(
      P.rwkvParams.currentSamplerAndPenaltyParam(),
      SamplerAndPenaltyParam.fromDecodeParamType(DecodeParamType.defaults),
    );
  });
}
