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

  CompletionItemState({required this.isUser, required this.chooses, this.index = 0});

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

class CompletionState {
  static final tipsDisabled = qs(false);

  static final model = P.rwkv.currentModel;

  static final generating = qs(false);

  static final decodeParamType = P.rwkv.decodeParamType;

  static final items = qs<List<CompletionItemState>>([]);

  static final controllerList = qs<ScrollController?>(null);
  static final controllerInput = qs<TextEditingController?>(null);
}
