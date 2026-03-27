# Eval 问题-结果映射 Spec

## 概述

本文档描述 RWKV 预置问题评测的完整数据链路：从 340 道预置问题出发，经过模型生成 → Judge 评分 → 聚合筛选，最终产出一份"问题 ↔ 分数"映射，用于决定哪些问题适合展示在 App 前端

## 数据源

| 项目          | 值                                                                                     |
| ------------- | -------------------------------------------------------------------------------------- |
| 预置问题集    | `docs/requirements/prompt/prebuilt-prompt-zh-hans.json`                                |
| 问题总数      | 340                                                                                    |
| 类别数        | 8（life / career / family / creation / role_play / encyclopedia / code / mathematics） |
| 模型          | rwkv7-2.9B-g1e-20260312-ctx8192-mlx-6bit                                               |
| 设备          | MacBook Pro 16-inch, Apple M4 Pro, 48GB                                                |
| 每题生成次数  | 5                                                                                      |
| 总 attempt 数 | 1700                                                                                   |

## 评分体系

### 四维度 + 固定权重

| 维度       | key            | 权重 | 含义                 |
| ---------- | -------------- | ---- | -------------------- |
| 切题度     | `relevance`    | 20%  | 回答是否紧扣问题     |
| 内容质量   | `quality`      | 35%  | 内容是否有实质价值   |
| 表达流畅度 | `fluency`      | 15%  | 语言通顺、结构清晰   |
| 用户满意度 | `satisfaction` | 30%  | 真实用户看到会满意吗 |

每维度满分 10 分

### 聚合公式

```
单次 weighted_score = relevance × 0.20 + quality × 0.35 + fluency × 0.15 + satisfaction × 0.30
题目 mean_score     = mean(5 次 weighted_score)
通过线              = mean_score ≥ 8.0
```

辅助指标：`std_dev`（波动度）、`min_score`（最差表现）

### Judge

- API: SiliconFlow
- Model: Qwen/Qwen3.5-122B-A10B
- enable_thinking: 关闭

## 文件结构

```
remote/evals/<run_id>/
├── manifest.json              # run 元信息
├── generation_summary.json    # 生成统计
├── samples/
│   └── NNNN_completed_zh_chat.json   # 每题 5 次生成原文（340 个）
├── scores/
│   └── NNNN_score.json               # 每题 5 次评分结果（340 个）
└── scores_map.json            # ★ 聚合映射（本次产出）
```

当前 run_id: `2026-03-25_231448_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip`

## scores_map.json 格式

```jsonc
{
  "run_id": "...",
  "total": 340,
  "pass_threshold": 8.0,
  "passed": 212, // 通过数
  "failed": 128, // 未通过数
  "global_mean": 8.05, // 全局均分
  "category_summary": {
    "career": { "count": 68, "mean": 8.41, "passed": 49 },
    // ...其他类别
  },
  "items": [
    // 按 mean_score 降序排列
    {
      "sample_index": 310,
      "rendering_name": "用数学归纳法证明 1+2+...+n = n(n+1)/2",
      "category": "mathematics",
      "attempt_scores": [10.0, 10.0, 10.0, 10.0, 10.0],
      "mean_score": 10.0,
      "std_dev": 0.0,
      "min_score": 10.0,
      "max_score": 10.0,
      "dim_means": {
        "relevance": 10.0,
        "quality": 10.0,
        "fluency": 10.0,
        "satisfaction": 10.0,
      },
      "pass": true,
    },
    // ...339 more items
  ],
}
```

### 单条 item 字段说明

| 字段             | 类型     | 说明                              |
| ---------------- | -------- | --------------------------------- |
| `sample_index`   | int      | 题目在预置问题集中的序号（1-340） |
| `rendering_name` | string   | 前端展示用的短标题                |
| `category`       | string   | 所属类别                          |
| `attempt_scores` | float[5] | 5 次 attempt 的 weighted_score    |
| `mean_score`     | float    | 5 次均分                          |
| `std_dev`        | float    | 5 次标准差                        |
| `min_score`      | float    | 5 次中最低分                      |
| `max_score`      | float    | 5 次中最高分                      |
| `dim_means`      | object   | 4 维度各自的 5 次均分             |
| `pass`           | bool     | mean_score ≥ 8.0                  |

## 汇总结果

### 全局

- 总题数: 340
- 通过(≥8.0): **212** (62%)
- 未通过: **128** (38%)
- 全局均分: **8.05**

### 按类别

| 类别         | 数量 | 均分 | 通过 | 通过率 |
| ------------ | ---- | ---- | ---- | ------ |
| career       | 68   | 8.41 | 49   | 72%    |
| mathematics  | 32   | 8.37 | 25   | 78%    |
| family       | 48   | 8.25 | 34   | 71%    |
| encyclopedia | 31   | 8.22 | 21   | 68%    |
| creation     | 41   | 8.15 | 25   | 61%    |
| code         | 32   | 8.12 | 21   | 66%    |
| role_play    | 33   | 7.84 | 17   | 52%    |
| life         | 55   | 7.15 | 20   | 36%    |

### 分数分布

| 区间      | 数量 | 占比 |
| --------- | ---- | ---- |
| 9-10 优秀 | 101  | 30%  |
| 8-9 良好  | 111  | 33%  |
| 7-8 中等  | 64   | 19%  |
| <7 较弱   | 64   | 19%  |

### 关键发现

1. **mathematics 表现最稳定**：通过率 78%，且 top 3 全是满分题，模型在结构化推理上表现突出
2. **life 类拖后腿**：通过率仅 36%，均分 7.15，主要问题是生活建议类回答容易空泛或不接地气
3. **role_play 波动大**：通过率 52%，模型时好时坏，std_dev 普遍偏高
4. **底部题目**存在明显"翻车"：最低分 2.83，且多集中在需要具体事实（旅行规划、财务计算）的场景

## 聚合脚本

```bash
python3 tools/aggregate_eval_scores.py
```

- 默认读取最新 run 的 `scores/` 目录
- 可传入 run 目录路径作为参数: `python3 tools/aggregate_eval_scores.py <run_dir>`
- 输出: 终端汇总表 + `<run_dir>/scores_map.json`

## 下游消费方式

| 消费者       | 用途                                              |
| ------------ | ------------------------------------------------- |
| 前端展示筛选 | 取 `pass: true` 的 212 题作为"推荐问题"池         |
| prompt 迭代  | 关注 `pass: false` 的题目，优化 prompt 或替换弱题 |
| 模型对比     | 换模型重跑后，对比 `scores_map.json` 差异         |
| 波动分析     | 关注 `std_dev > 1.5` 的题目，这些题模型表现不稳定 |
