import 'package:flutter/material.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/store/p.dart';

class CompletionResultState {
  final String content;
  final bool completed;

  CompletionResultState({required this.content, required this.completed});

  CompletionResultState copyWith({
    String? content,
    bool? completed,
  }) {
    return CompletionResultState(
      content: content ?? this.content,
      completed: completed ?? this.completed,
    );
  }
}

class CompletionItemState {
  final bool isUser;
  final int index;
  final List<CompletionResultState> chooses;

  String get content => chooses[index].content;

  CompletionItemState({required this.isUser, required this.chooses, this.index = 0});

  factory CompletionItemState.user(String prompt) {
    return CompletionItemState(
      isUser: true,
      chooses: [
        CompletionResultState(
          content: prompt,
          completed: true,
        ),
      ],
    );
  }

  factory CompletionItemState.ai({
    required List<String> output,
    required List<bool> completed,
  }) {
    return CompletionItemState(
      isUser: false,
      chooses: [
        for (var i = 0; i < output.length; i++)
          CompletionResultState(
            content: output[i],
            completed: completed[i],
          ),
      ],
    );
  }

  CompletionItemState copyWith({
    bool? isUser,
    int? index,
    List<CompletionResultState>? chooses,
  }) {
    return CompletionItemState(
      isUser: isUser ?? this.isUser,
      index: index ?? this.index,
      chooses: chooses ?? this.chooses,
    );
  }
}

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

class CompletionState {
  static final tipsDisabled = qs(false);

  static final model = P.rwkv.currentModel;

  static final generating = qs(false);

  static final generateButtonEnabled = qs(false);

  static final decodeParamType = P.rwkv.decodeParamType;

  static final batchSettings = qs(BatchCompletionSettings.initial());

  static final items = qs<List<CompletionItemState>>([]);

  static final controllerInputScroll = qs<ScrollController?>(null);

  static final controllerInput = qs<TextEditingController?>(null);

  static final showSuggestionButton = qs(true);
}
