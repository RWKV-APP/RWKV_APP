# README

本文件夹描述了为 RWKV Chat 整理预置提示词的新需求草案。

- 旧有的提示词文件为: [suggestions.json](./suggestions.json)
- 我们新生成了一批更加日常、更加生活化的提示词: [chat_real_user_queries_zh_mixed.json](./chat_real_user_queries_zh_mixed.json), 目前仅包含中文
- 我们将这两批提示词合成了一个文件: [prebuilt-prompt-zh-hans.json](./prebuilt-prompt-zh-hans.json)
  - 该文件目前仅包含简体中文的问题
  - 这份文件是上面两个提到文件的合体
  - 我们打算遍历该文件中的所有问题，并且测试我们的2.9B模型在这些问题中的表现。我们会根据多个维度的评分选取一些较好的问题，并且优先展示在 RWKV 的界面中

目前对 prebuilt-prompt-zh-hans.json 文件中不同字段的解释如下

```
category: 类目名称,
display_name: 类目在 RWKV Chat 中的渲染名称 (会随着应用程序语言改变)
item: 该类目下所有的问题
  {
    rendering_name: 渲染在 RWKV Chat 的可点击按钮的文案
    prompt: 最终实际提交给 RWKV7 g1 系列模型的问题
    score: 我们运行了测评之后的评分, 最终我们会根据这个评分来决定优先展示哪些问题
    is_old_prompt: 是否来自老的 suggestions.json
      如果为 false, 则我们会跑测评, 并有可能优先展示给用户, 表示来自于 chat_real_user_queries_zh_mixed.json
      如果为 true, 因为目前被反馈说不足以体现 RWKV 的能力, 所以我们不对这些问题进行测试, 也不会优先展示这些问题在用户界面上, 表示来自于 suggestions.json
  }
```
