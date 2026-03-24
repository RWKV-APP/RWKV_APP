# Local Eval Notes

## 背景

本仓库近期为内置 OpenAI Compatible Server 做了一套本地长跑测评流程

目标是：

- 使用本机 `localhost:8080`
- 对 chat 提示词做批量评测
- 每个 prompt 连续生成 5 次
- 保留每一次 response
- 为每个样本写回评分结果
- 支持中断后续跑

## 当前正在运行的正式评测

当前正式评测 run 是：

`2026-03-24_121809_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip_chat_zh_n240_r5_mt8000`

对应目录：

`remote/evals/2026-03-24_121809_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip_chat_zh_n240_r5_mt8000`

当前配置：

- language: `zh`
- source file: `remote/chat_suggestions_zh.json`
- total samples: `240`
- repeat count: `5`
- max tokens: `8000`
- selection mode: `sequential`

这个 run 是顺序执行的，不是随机抽样

也就是说：

- `0001` 到 `0240` 对应源文件中的前 240 个题目
- 中途如果中断，只要看文件名和 sample index 就能知道已经跑到哪里

## 产物结构

每个样本一个文件，文件名格式：

```text
<sample_index>_<status>_zh_chat.json
```

例如：

- `0001_completed_zh_chat.json`
- `0051_running_zh_chat.json`
- `0102_pending_zh_chat.json`

语义如下：

- `pending`: 还没开始
- `running`: 当前正在跑
- `completed`: 5 次都跑完并成功
- `partial`: 一部分成功，一部分失败
- `error`: 5 次都失败

manifest 文件：

`remote/evals/<run_id>/manifest.json`

sample 文件：

`remote/evals/<run_id>/samples/*.json`

## 评分方式

当前评分是样本级快速人工评分

含义是：

- 一个 sample 有 5 次 attempt
- 目前前 50 个样本的 5 次 attempt 已经补了 `score` 和 `score_note`
- 这批分数是“按样本给分”，即同一样本下 5 次 attempt 当前使用同一档分数
- `average_score` 也已经写回 sample 文件

评分标准是 1 到 10：

- `8-10`: 对 2.9B 本地模型来说表现较好，正确性和可读性都不错
- `6-7`: 基本可用，但偏模板化、深度一般或细节不够稳
- `4-5`: 方向相关，但存在明显不稳或不够可信的问题
- `1-3`: 前提错误、事实不可信，或输出基本不可采信

## 当前评分进度

前 50 个 `completed` 样本已经写回评分

注意：

- sample 文件中的 `score_status`、`score`、`average_score` 是有效的
- 运行中的 `manifest.json` 目前会被 eval runner 持续重写
- 因此 `manifest.json` 里的 `score_status`、`scored_samples` 等字段在 active run 期间不可靠

结论：

- 前端如果要显示评分进度，当前不要只信 `manifest.json`
- 更稳的做法是遍历 sample 文件，按 `score_status == completed` 统计

## 前 50 个样本的粗结论

基于当前已经补分的前 50 个中文样本：

- 已评分样本数：`50`
- 平均分：`6.94`
- 中位数：`7`

高分样本的共性：

- 常识解释题
- 一般心理学解释题
- 中低难度科普题
- 不要求特别精确工程细节的解释型问题

低分样本的共性：

- 问题前提本身就有陷阱
- 对科学细节要求很高
- 容易一本正经地胡说

典型高分样本：

- `0002`: 为什么吃辣会痛，但很多人还是喜欢
- `0007`: 新手练打字应该先追求速度还是准确率
- `0012`: 为什么运动后心情常常会变好
- `0014`: 为什么很多人不擅长拒绝别人
- `0017`: 为什么朗读比默读更容易记住内容

这些样本当前平均分都是 `8`

典型低分样本：

- `0049`: 植物如何利用月夜中的微弱月光进行光合作用  
  当前平均分：`1`
  原因：问题建立在错误前提上，但模型没有识别出来，反而顺着错误前提继续展开

- `0024`: 如果将人完全浸没在恒温水体中，水温保持在什么范围以内，人才可以长期生存  
  当前平均分：`4`
  原因：属于高风险问题，回答不适合直接采信

- `0045`: 为什么镜子好像会左右颠倒，却不会上下颠倒  
  当前平均分：`5`
  原因：模型会回答，但空间翻转的解释稳定性一般

- `0050`: 深海中居住的生物如何适应极端的压力环境  
  当前平均分：`5`
  原因：有部分正确点，但生物细节不够稳

## 给 APP_website 的建议

如果要基于这批 evaluation 和 score 做一个新 feature，建议优先做“评测结果浏览器”，而不是一上来做复杂分析系统

推荐的最小 feature：

### 1. Run 列表页

展示：

- run id
- model name
- language
- total samples
- completed samples
- running samples
- pending samples
- done attempts / total attempts

### 2. Run 详情页

展示：

- manifest 基本信息
- sample 文件列表
- 当前 running 样本
- 每个 sample 的状态
- 每个 sample 的 average score

### 3. 单样本详情页

展示：

- display
- prompt
- 5 次 attempt 的 response
- 每次 attempt 的 score
- 每次 attempt 的 score note
- average score

### 4. 基本筛选

建议支持：

- 按状态筛选：`completed / running / pending / partial / error`
- 按分数筛选：例如 `>= 8`、`<= 5`
- 按 sample index 范围筛选
- 按关键词搜索 display

## 给 APP_website 的实现建议

当前数据格式下，前端读取时建议遵循下面规则：

### 优先信 sample 文件，不要过度依赖 manifest 的评分字段

原因：

- manifest 的运行状态字段是稳定的
- 但评分相关字段在 active run 期间会被当前 runner 覆盖

所以：

- 运行进度：优先从 manifest 读取
- 评分进度：优先从 sample 文件聚合

### 顺序评测的 UI 应该突出 sample index

因为这轮 run 是 `sequential`

所以：

- `0024` 比 `0178` 更重要，因为它代表更早的题目
- 出现中断时，用户最关心“已经连续完成到第几题”

因此前端可以直接展示：

- last completed sample index
- current running sample index
- next pending sample index

### 低分样本应该支持单独标记

推荐分层：

- `8-10`: good
- `6-7`: acceptable
- `4-5`: weak
- `1-3`: unreliable

这会比纯数字更方便前端展示

## 已知问题

1. 当前 runner 的评分阶段和生成阶段是分开的，但 manifest 对评分进度的记录不够稳定

2. 当前前 50 个样本采用的是样本级快速评分，不是严格的 attempt-level 精细评分

3. 如果后面要把这些结果长期用于对外展示，建议增加一个单独的 scorer 或 review pass，把评分统计和生成统计彻底拆开

## 下一步建议

如果后续要继续推进：

1. 先让当前 240 题中文 run 跑完
2. 再把全部 sample 做完整评分
3. 然后让 `APP_website` 做一个只读结果页
4. 结果页第一版只做浏览、筛选、排序，不急着做复杂图表

## 相关路径

- eval runner  
  `tools/run_local_chat_eval.py`

- eval docs  
  `remote/evals/docs.md`

- current run manifest  
  `remote/evals/2026-03-24_121809_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip_chat_zh_n240_r5_mt8000/manifest.json`

- current run samples  
  `remote/evals/2026-03-24_121809_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip_chat_zh_n240_r5_mt8000/samples/`
