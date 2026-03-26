# Eval Workflow Handoff

## 背景

当前仓库已经完成了本地 generation runner 的升级，目标是对 RWKV Chat 的简体中文 prebuilt prompt 资产做长跑 eval，并把结果写入项目目录，供后续构建 scorer、ranking 和网站导入流程使用。

当前最重要的事情不是继续改 generation schema，而是基于现有 generation 产物设计下一阶段的 evaluation workflow。

## 当前 source of truth

- Prompt 资产：
  - `/Users/wangce/docs/repo/rwkv_app/docs/requirements/prompt/prebuilt-prompt-zh-hans.json`
- 当前 generation runner：
  - `/Users/wangce/docs/repo/rwkv_app/tools/run_local_chat_eval.py`
- runner 产物说明：
  - `/Users/wangce/docs/repo/rwkv_app/remote/evals/docs.md`
- 总体说明：
  - `/Users/wangce/docs/repo/rwkv_app/docs/EVAL_NOTES.zh-hans.md`

## 当前 runner 的行为

runner 现在只负责 generation，不负责评分。

它的主要特性：

- 直接读取 `prebuilt-prompt-zh-hans.json`
- 支持 `sequential` 和 `random`
- 每次 run 生成独立目录
- 每题一个 sample 文件
- 同时维护：
  - `manifest.json`
  - `generation_summary.json`
  - `samples/*.json`
- 设备信息已经写入：
  - `eval_device_label`
  - `eval_device_cpu`
  - `eval_device_gpu`
  - `eval_device_memory_gb`
  - `eval_device_vram_gb`

## 当前正式 run

当前主 run 是：

- run id:
  - `2026-03-25_231448_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip`
- 目录：
  - `/Users/wangce/docs/repo/rwkv_app/remote/evals/2026-03-25_231448_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip`

这轮 run 的配置：

- source file:
  - `/Users/wangce/docs/repo/rwkv_app/docs/requirements/prompt/prebuilt-prompt-zh-hans.json`
- selection mode:
  - `sequential`
- total samples:
  - `340`
- repeat count:
  - `5`
- total attempts:
  - `1700`
- model:
  - `rwkv7-2.9B-g1e-20260312-ctx8192-mlx-6bit.zip`

截至当前快照：

- completed samples:
  - `312`
- running samples:
  - `1`
- pending samples:
  - `27`
- partial samples:
  - `0`
- error samples:
  - `0`
- done attempts:
  - `1561 / 1700`
- latest completed sample index:
  - `312`

按分类看：

- `life`: 已完成
- `career`: 已完成
- `family`: 已完成
- `creation`: 已完成
- `role_play`: 已完成
- `encyclopedia`: 已完成
- `code`: 已完成
- `mathematics`: 未完成
  - 当前状态约为 `4 completed + 1 running + 27 pending`

## 当前设备信息

当前 run 自动检测到的设备信息是：

- `eval_device_label = MacBook Pro 16-inch`
- `eval_device_cpu = Apple M4 Pro`
- `eval_device_gpu = Apple M4 Pro`
- `eval_device_memory_gb = 48`
- `eval_device_vram_gb = null`

这里的 `vram` 当前为 `null`，因为 Apple Silicon 没有一个稳定、明确的独立显存值可直接自动检测；runner 按“不猜测”的原则处理。

## 你接手后更值得做的事情

建议下一阶段聚焦在 scorer 和 evaluation workflow，而不是继续改 generation。

推荐方向：

1. 读取当前 `completed` sample 作为 scorer 输入
2. 对每个 attempt 做多维度评分
3. 聚合成 prompt 级平均分、波动、稳定性指标
4. 生成新的 run 级 summary：
   - score summary
   - ranking summary
5. 再决定哪些 prompt 适合导入网站后台和 App 预置展示

## 已知事实

- 当前 generation 结果可以直接复用，不需要重跑前 312 题
- 当前旧的 `docs/eval_handoff_2026-03-24_151426` 是历史交接快照，不是新的 source of truth
- 当前 runner 已经去掉了旧 schema 中的评分字段
- 当前 scorer 还没有接入

## 建议先读的文件顺序

1. `/Users/wangce/docs/repo/rwkv_app/docs/requirements/prompt/README.md`
2. `/Users/wangce/docs/repo/rwkv_app/tools/run_local_chat_eval.py`
3. `/Users/wangce/docs/repo/rwkv_app/remote/evals/docs.md`
4. `/Users/wangce/docs/repo/rwkv_app/remote/evals/2026-03-25_231448_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip/manifest.json`
5. `/Users/wangce/docs/repo/rwkv_app/remote/evals/2026-03-25_231448_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip/generation_summary.json`

## 如果要继续这轮 run

可以直接 resume：

```bash
python3 tools/run_local_chat_eval.py \
  --resume-run-dir /Users/wangce/docs/repo/rwkv_app/remote/evals/2026-03-25_231448_rwkv7-2-9b-g1e-20260312-ctx8192-mlx-6bit-zip \
  --language zh
```
