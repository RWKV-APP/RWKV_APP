// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/model/agent.dart';

void main() {
  group('Agent sampler configuration', () {
    test('uses the supported deterministic evaluation preset', () {
      agentEvaluationSamplerConfig.validate();

      expect(
        agentEvaluationSamplerConfig.toManifest(seed: 42),
        <String, Object?>{
          "seed": 42,
          "temperature": .2,
          "topK": 500,
          "topP": 0,
          "presencePenalty": 0,
          "frequencyPenalty": 0,
          "penaltyDecay": .99,
        },
      );
    });

    test('rejects zero temperature before native generation', () {
      const config = AgentSamplerConfig(
        temperature: 0,
        topK: 500,
        topP: 0,
        presencePenalty: 0,
        frequencyPenalty: 0,
        penaltyDecay: .99,
      );

      expect(
        config.validate,
        throwsA(
          isA<AgentInfrastructureException>().having(
            (error) => error.code,
            "code",
            "invalid_sampler_config",
          ),
        ),
      );
    });

    test('rejects zero top-k before native generation', () {
      const config = AgentSamplerConfig(
        temperature: .2,
        topK: 0,
        topP: 0,
        presencePenalty: 0,
        frequencyPenalty: 0,
        penaltyDecay: .99,
      );

      expect(
        config.validate,
        throwsA(
          isA<AgentInfrastructureException>().having(
            (error) => error.code,
            "code",
            "invalid_sampler_config",
          ),
        ),
      );
    });
  });

  group('Agent response isolation', () {
    test('ignores stale content and preserves the new prompt prefix', () {
      final gate = AgentResponseBufferGate(
        staleContent: "old output",
        replacementPrefix: "new prompt",
      );

      expect(gate.freshContent("old output"), isEmpty);
      expect(
        gate.freshContent("old output first token"),
        "new prompt first token",
      );
      expect(
        gate.freshContent("old output first token second token"),
        "new prompt first token second token",
      );
    });

    test('accepts replacement content after the backend clears its buffer', () {
      final gate = AgentResponseBufferGate(staleContent: "old output");

      expect(gate.freshContent(""), isEmpty);
      expect(gate.freshContent("new output"), "new output");
    });

    test('accepts only active-model Agent-owned polling responses once', () {
      final tracker = AgentResponsePollTracker(modelID: 13);
      tracker.register(101);

      expect(tracker.consume(modelID: 12, requestId: 101), isFalse);
      expect(tracker.consume(modelID: 13, requestId: 999), isFalse);
      expect(tracker.consume(modelID: 13, requestId: 101), isTrue);
      expect(tracker.consume(modelID: 13, requestId: 101), isFalse);
    });
  });
}
