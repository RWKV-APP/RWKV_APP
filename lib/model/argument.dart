import 'package:zone/args.dart';

enum Argument {
  temperature,
  topK,
  topP,
  presencePenalty,
  frequencyPenalty,
  penaltyDecay,
  maxLength,
  batchCount,
  batchVW;

  bool get configureable => switch (this) {
    temperature => true,
    topK => false,
    topP => true,
    presencePenalty => true,
    frequencyPenalty => true,
    penaltyDecay => true,
    maxLength => true,
    batchCount => true,
    batchVW => true,
  };

  bool get show => switch (this) {
    temperature => true,
    topK => false,
    topP => true,
    presencePenalty => true,
    frequencyPenalty => true,
    penaltyDecay => true,
    maxLength => true,
    batchCount => true,
    batchVW => true,
  };

  int get fixedDecimals => switch (this) {
    temperature => 1,
    topK => 0,
    topP => 2,
    presencePenalty => 1,
    frequencyPenalty => 1,
    penaltyDecay => 3,
    maxLength => 0,
    batchCount => 0,
    batchVW => 0,
  };

  double? get step => switch (this) {
    temperature => .1,
    topK => null,
    topP => .05,
    presencePenalty => null,
    frequencyPenalty => null,
    penaltyDecay => .001,
    maxLength => 100,
    batchCount => 1,
    batchVW => 5,
  };

  double get min => switch (this) {
    temperature => .2,
    topK => 0,
    topP => .0,
    presencePenalty => .0,
    frequencyPenalty => .0,
    penaltyDecay => .99,
    maxLength => 100,
    batchCount => 2,
    batchVW => 40,
  };

  double get max => switch (this) {
    temperature => 2.0,
    topK => 0,
    topP => 1.0,
    presencePenalty => 1.0,
    frequencyPenalty => 1.0,
    penaltyDecay => .999,
    maxLength => 10000,
    batchCount => 8,
    batchVW => 80,
  };

  double get reasonDefaults => switch (this) {
    temperature => 1.0,
    topK => 500,
    topP => .3,
    presencePenalty => .5,
    frequencyPenalty => .5,
    penaltyDecay => .996,
    maxLength => Args.maxTokens > 0 ? Args.maxTokens.toDouble() : 4000,
    batchCount => 4,
    batchVW => 70,
  };

  double get defaults => switch (this) {
    temperature => 1.0,
    topK => 500,
    topP => .3,
    presencePenalty => .5,
    frequencyPenalty => .5,
    penaltyDecay => .996,
    maxLength => Args.maxTokens > 0 ? Args.maxTokens.toDouble() : 2000,
    batchCount => 4,
    batchVW => 70,
  };

  bool get enableGaimon => switch (this) {
    Argument.temperature => true,
    Argument.topK => true,
    Argument.topP => true,
    Argument.presencePenalty => true,
    Argument.frequencyPenalty => true,
    Argument.penaltyDecay => true,
    Argument.maxLength => false,
    Argument.batchCount => true,
    Argument.batchVW => true,
  };
}
