# Local Eval Notes

## 背景

本仓库近期把本地长跑 eval 的 runner 升级成了新的 prebuilt prompt 采集框架

新框架的目标是：

- 使用本机 `localhost:8080`
- 直接读取简体中文 prebuilt prompt 资产
- 顺序批量生成 RWKV 的原始回答
- 每个 prompt 连续生成多次
- 保留每一次 response
- 支持中断后续跑
- 把评分、加权和最终排序延后到单独阶段

## 当前 runner 的定位

当前主脚本：

`tools/run_local_chat_eval.py`

它现在只负责 generation，不再负责评分汇总

同时它会在 run 启动时记录设备信息，并把这些字段写入 manifest、generation summary 和 sample：

- `eval_device_label`
- `eval_device_cpu`
- `eval_device_gpu`
- `eval_device_memory_gb`
- `eval_device_vram_gb`

输入源固定为：

`docs/requirements/prompt/prebuilt-prompt-zh-hans.json`

这个文件是当前 RWKV Chat 的简体中文预置问题资产

## 当前 run 产物结构

每次 run 会生成独立目录：

```text
remote/evals/<run_id>/
  manifest.json
  generation_summary.json
  samples/
```

其中：

- `manifest.json` 负责 run 级状态和总计数
- `generation_summary.json` 负责机器可读的采集统计
- `samples/*.json` 负责逐题记录回答结果

## sample 文件语义

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
- `completed`: 所有 attempt 都成功
- `partial`: 一部分成功，一部分失败
- `error`: 所有 attempt 都失败

每个 sample 文件的核心字段现在是：

- `rendering_name`
- `prompt`
- `source_category`
- `source_category_display_name`
- `repeat_count_target`
- `repeat_count_done`
- `attempts`

不再保留旧的 `display`

## 当前框架和旧框架的区别

旧框架的特点：

- 吃旧的 `chat_suggestions_zh.json`
- 有 `score_status`
- attempt 内会写 `score` 和 `score_note`
- 生成和评分的边界不够清晰

新框架的特点：

- 吃 `prebuilt-prompt-zh-hans.json`
- 只做 generation
- attempt 内只保留原始回答和错误信息
- `manifest.json` 不再记录评分进度
- 评分阶段后续再单独接入

## 当前推荐的评测流程

建议拆成三步：

1. generation
   - 让 RWKV 跑完整批题目
   - 保留全部原始 response
2. scoring
   - 后续单独读取 completed sample
   - 用 GPT 做多维度评分
3. ranking
   - 后续再按平均分、波动、维度权重做汇总和榜单

这样做的原因是：

- 长跑更稳
- 中断恢复更清楚
- 评分标准修改时不需要重跑 RWKV

## 给后续实现的提醒

- 不要在 active run 期间把评分字段重新塞回 `manifest.json`
- 如果后面接 scorer，建议新建独立 summary 文件
- 历史 handoff 目录中的旧样本和旧文档保留即可，不要当成新 schema 的准则

## 下一步建议

如果后续继续推进：

1. 先用新的 runner 跑完整个 prebuilt prompt 集
2. 再单独做多维度评分脚本
3. 再做最终排序和 UI 选题逻辑
