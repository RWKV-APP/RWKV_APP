bool isExplicitLocalFileActionRequest(String input) {
  final normalized = input.trim().toLowerCase();
  if (normalized.isEmpty) return false;

  const chineseActions = <String>[
    "创建",
    "新建",
    "写入",
    "写到",
    "读取",
    "读一下",
    "修改",
    "更新",
    "替换",
    "删除",
    "移除",
  ];
  final englishAction = RegExp(
    r"\b(create|make|write|read|edit|update|replace|delete|remove)\b",
  );
  final hasAction = chineseActions.any(normalized.contains) || englishAction.hasMatch(normalized);
  if (!hasAction) return false;

  const chineseTargets = <String>[
    "文件",
    "文档",
    "文本",
    "桌面",
    "工作区",
  ];
  final englishTarget = RegExp(
    r"\b(file|document|text file|desktop|workspace)\b",
  );
  final extensionTarget = RegExp(
    r"(?:^|[\s/\\])[^/\\\s]+\.[a-z0-9]{1,10}\b",
  );
  return chineseTargets.any(normalized.contains) || englishTarget.hasMatch(normalized) || extensionTarget.hasMatch(normalized);
}
