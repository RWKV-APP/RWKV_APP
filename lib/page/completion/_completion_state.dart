import 'package:flutter/material.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/batch_completion_settings_panel.dart';

class CompletionState {
  static final tipsDisabled = qs(false);

  static final model = P.rwkv.latestModel;

  static final generating = qs(false);

  static final generateButtonEnabled = qs(false);

  static final decodeParamType = P.rwkv.decodeParamType;

  static final batchSettings = BatchCompletionSettingsPanel.settings;

  static final items = qs<List<CompletionItemNode>>([]);

  static final controllerInputScroll = qs<ScrollController?>(null);

  static final controllerInput = qs<TextEditingController?>(null);

  static final showSuggestionButton = qs(true);

  static final generatingItem = qs<CompletionItemNode?>(null);

  static bool autoScrolling = true;
}

class CompletionItemNode {
  final int id;
  final bool isUser;

  String content;
  bool completed;

  List<CompletionItemNode> children;
  CompletionItemNode? _next;
  CompletionItemNode? _parent;

  int get index => _parent?.children.indexOf(this) ?? 0;

  int get siblingCount => _parent?.children.length ?? 0;

  set next(CompletionItemNode? value) {
    if (value == null) {
      _next = null;
      return;
    }
    _next = value;
    value._parent = this;
    if (!children.any((element) => element.id == value.id)) {
      children.add(value);
    }
  }

  bool get isTail => _next == null;

  List<CompletionItemNode> get list => [this, if (_next != null) ..._next!.list];

  String get joinedContent => list.map((e) => e.content).join();

  CompletionItemNode get tail => _next == null ? this : _next!.tail;

  CompletionItemNode? find(int id) {
    if (this.id == id) return this;
    return _next?.find(id);
  }

  set tail(CompletionItemNode? value) {
    if (value == null) {
      tail._parent?.next = null;
      return;
    }
    if (_next == null) {
      next = value;
    } else {
      _next?.tail = value;
    }
  }

  void replaceToSibling(int index) {
    // if (index >= siblingCount) return;
    _parent?.next = _parent?.children[index];
  }

  static int _incrementId = 0;

  CompletionItemNode({
    required this.id,
    required this.isUser,
    required this.children,
    required this.content,
    required this.completed,
  });

  factory CompletionItemNode.user(String prompt) {
    return CompletionItemNode(
      id: _incrementId++,
      isUser: true,
      children: [],
      content: prompt,
      completed: true,
    );
  }

  static List<CompletionItemNode> fromResult({
    required List<String> outputs,
    required List<bool> completed,
  }) {
    return [
      for (var i = 0; i < outputs.length; i++)
        CompletionItemNode(
          id: _incrementId++,
          isUser: false,
          children: [],
          content: outputs[i],
          completed: completed[i],
        ),
    ];
  }

  CompletionItemNode copyWith() {
    return CompletionItemNode(
        id: id,
        isUser: isUser,
        children: children,
        content: content,
        completed: completed,
      )
      ..next = _next
      .._parent = _parent;
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
