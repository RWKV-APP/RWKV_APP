# README

本文件夹描述了 RWKV Chat 简体中文预置问题的整理方案。

当前的目标不是只保留一批“看起来真实”的问题，而是把新旧两批问题统一整理成一个可评测、可筛选、可直接供 App 使用的中文题库。

## 当前文件说明

- 旧问题来源: [suggestions.json](./suggestions.json)
  - 当前只使用其中 `zh.chat`
- 新问题来源: [chat_real_user_queries_zh_mixed.json](./chat_real_user_queries_zh_mixed.json)
  - 当前是 `225` 条简体中文 `string[]`
- 合成结果: [prebuilt-prompt-zh-hans.json](./prebuilt-prompt-zh-hans.json)
  - 当前仅包含简体中文
  - 供后续 eval 和 App 预置问题展示使用
- 生成脚本: [tools/build_prebuilt_prompt_zh_hans.py](./tools/build_prebuilt_prompt_zh_hans.py)
  - 用于可重复生成 `prebuilt-prompt-zh-hans.json`

## 当前需求口径

- 新旧问题都要进入同一批评测
- 旧问题不能直接保留，答得不好的也要删
- 每个类别至少保留 `30` 题
- 每个问题应让 RWKV 跑多次，当前按 `5` 次理解
- 后续根据 eval 得分筛出更适合展示在 RWKV Chat 界面中的问题

## prebuilt-prompt-zh-hans.json Schema

```json
[
  {
    "category": "life",
    "display_name": "日常生活",
    "items": [
      {
        "rendering_name": "努力了很久却感觉看不到回报，怎么调整心态？",
        "prompt": "完整 prompt",
        "score": 0
      }
    ]
  }
]
```

字段说明:

- `category`
  - 固定分类 key
- `display_name`
  - 该分类在 RWKV Chat 中的简体中文显示名称
- `items`
  - 该分类下的所有问题
- `rendering_name`
  - 渲染在 RWKV Chat 中的可点击按钮文案
- `prompt`
  - 实际提交给 RWKV 模型的问题全文
- `score`
  - eval 之后写回的综合评分
  - 当前生成阶段统一为 `0`

## 当前分类

当前固定分类为 `8` 个，顺序如下：

1. `life` / `日常生活`
2. `career` / `职场学业`
3. `family` / `家庭亲子`
4. `creation` / `创作`
5. `role_play` / `角色扮演`
6. `encyclopedia` / `百科`
7. `code` / `代码`
8. `mathematics` / `数学`

## prebuilt-prompt-zh-hans.json 当前分布

当前共 `340` 条，来自两个来源合并去重后生成，并对原本不足 `30` 题的分类补充了测试题。

| 分类         | 中文名   | 新问题 | 旧问题 | 合计    |
| ------------ | -------- | ------ | ------ | ------- |
| life         | 日常生活 | 50     | 5      | 55      |
| career       | 职场学业 | 68     | 0      | 68      |
| family       | 家庭亲子 | 48     | 0      | 48      |
| creation     | 创作     | 34     | 7      | 41      |
| role_play    | 角色扮演 | 26     | 7      | 33      |
| encyclopedia | 百科     | 24     | 7      | 31      |
| code         | 代码     | 25     | 7      | 32      |
| mathematics  | 数学     | 25     | 7      | 32      |
| **合计**     |          | **300**| **40** | **340** |

## 当前进度

1. 合并新旧问题并生成预置文件
2. 统一分类为 8 个固定类别，并补齐每类至少 30 题
3. 后续基于 eval 结果筛题并回写 `score`
4. 再决定 App 中如何优先展示高分问题

## 备注

- 当前 `prebuilt-prompt-zh-hans.json` 中不再保留来源字段
- 新旧问题的来源区分只在生成脚本内部使用，不作为最终 JSON schema 的一部分
