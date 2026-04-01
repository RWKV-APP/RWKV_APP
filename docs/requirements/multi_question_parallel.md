# 高并发回答不同问题（Multi-Question Parallel Inference）

> 记录本功能所有迭代需求，按轮次归档。

---

## 背景

老板提出需求："高并发回答不同问题"。
利用已有的 batch inference 基础设施，让用户预填多个不同的问题，并行发送给模型，结果直接在 Chat 页以横向可滚动的卡片形式展示，每张卡片同时展示用户问题与模型回答。

---

## Round 1 — 核心基础设施

- 新增 `sendAll()` 方法，将多个不同问题组装为 `ChatBatchAsync(List<List<String>>)` 发出
- 约定批次消息格式：`resp0{batchMarker}resp1{batchMarker}…{batchMarker}-1`
  - `batchMarker` = `"V9m!T7#q2fH@x1Lz*8YwK0^g4"`
- 结果在 Chat 页以与现有 batch inference 一致的横向滚动卡片渲染
- 每张卡片同时展示用户问题与模型回答
- 批次结束后恢复普通消息渲染

---

## Round 2 — UI 细节与交互打磨（10 项）

1. **移除灯泡 AI 建议图标**，改为刷新图标（`Symbols.refresh`）
2. **自动填充问题**：打开面板时，从 `P.suggestion.highScoreTopSuggestions`（score ≥ 9.0）随机取建议填入各输入框，且各槽位不重复
3. **动态增减问题数**：AppBar 添加 `+` / `-` 按钮
   - 最小 2 个，最大为 `P.rwkv.supportedBatchSizes.q.max`
   - `+` 追加新槽位并自动填入不重复的高分建议
   - `-` 移除对应槽位，不低于最小值
4. **刷新单个槽位**：刷新图标按钮重新从高分建议中随机取一条（排除其他槽位当前内容）
5. **隐藏批次用户消息气泡**：Chat 页中 `isMine && batchData.isBatch` 时返回 `SizedBox.shrink()`；批次结束后恢复正常渲染
6. **重排槽位内容顺序**：decode params 徽章 → "User:" 标签 + 问题 → 分隔线 → "RWKV:" 标签 + 模型回答

---

## Round 3 — 细节修复（5 项）

1. **Token 限制 × 批次数**：对话 token 提醒阈值改为 `Config.newConversationTokenReminderThreshold × batchCount`（`chat.dart` 与 `bot_message_bottom.dart` 同步修改）
2. **批次结束后重新计算 token 数**：`_fullyReceived()` 完成后调用 `P.chat._refreshTokenCountsForMessage(...)` 重算
3. **decode params 仅显示在第一个槽位的 Bug**：`_resolveDecodeParamsSnapshotRaw()` 只返回 1 条参数时，改为将最后一条参数复用到所有槽位，而非越界取 null
4. **持久化 `batchVW`**：写入 / 读取 `SharedPreferences`，key 为 `"halo_state.batchVW"`
5. **Ask Question 面板新增"Send All as Batch"按钮**：
   - 位于已生成问题列表底部
   - 不支持 batch 或问题数 < 2 时禁用
   - 点击后关闭面板，调用 `P.multiQuestion.sendFromAskQuestion(questions)`
   - `sendFromAskQuestion()` 内部自动将问题数 clamp 到模型支持的最大 batch size

---

## Round 5 — "帮你问"面板使用 batch 加速

**需求**：只要当前加载的模型支持 batch（tag 包含 `"batch"`），Ask Question 面板在生成问题时就启用 batch 并行，不再依赖用户是否在聊天界面手动开启 batch 模式。

**修改**：`_resolveParallelCount()`（`ask_question.dart`）移除对 `P.chat.batchEnabled` 的检查，仅保留模型能力检查。

---

## Round 4 — Bug 修复：Ask Question 生成问题含 batch 分隔符

### 现象

Ask Question 面板在 batch 模式下生成的问题文本中混入了 `V9m!T7#q2fH@x1Lz*8YwK0^g4<think></think>` 等批次分隔符。

### 根因

`_buildHistoryMessagesForQuestionGeneration()`（`ask_question.dart`）构建历史上下文时，直接读取 `getContentForHistoryWithRef()` / `getHistoryContent()` 的原始内容。若聊天记录中已有批次消息，这些方法会返回含 `batchMarker` 的原始格式，导致分隔符泄漏进模型 prompt，模型在输出中复现这些特殊字符。

### 修复方案

在 `_buildHistoryMessagesForQuestionGeneration()` 的循环体中，获取 `userContent` / `botContent` 后立即做 batch 解析：

- **用户批次消息**：调用 `getBatchInfo()` 取 `batch.first`（第一个问题）作为代表
- **模型批次消息**：调用 `getBatchInfo()` 取用户已选中的槽位（`selectedBatch`），若无则取 `batch[0]`

这样传入 prompt 的历史内容始终是纯文本，不含任何批次分隔符。

---

## 关键技术细节

| 项目               | 值 / 位置                                                   |
| ------------------ | ----------------------------------------------------------- |
| batchMarker        | `"V9m!T7#q2fH@x1Lz*8YwK0^g4"` (`Config.batchMarker`)        |
| 批次消息格式       | `slot0{marker}slot1{marker}…{marker}{selectionIdx}`         |
| 高分建议来源       | `P.suggestion.highScoreTopSuggestions`（score ≥ 9.0）       |
| batch size 范围    | min=2，max=`P.rwkv.supportedBatchSizes.q.reduce(max)`       |
| batchVW 持久化 key | `"halo_state.batchVW"`                                      |
| token 阈值公式     | `Config.newConversationTokenReminderThreshold × batchCount` |

---

## 涉及的主要文件

| 文件                                          | 职责                                                               |
| --------------------------------------------- | ------------------------------------------------------------------ |
| `lib/store/multi_question.dart`               | 核心状态：sendAll、sendFromAskQuestion、增删刷新槽位、自动填充建议 |
| `lib/store/chat.dart`                         | token 阈值 × batchCount、token recount、batchVW 持久化             |
| `lib/store/ask_question.dart`                 | 历史构建时剥离 batch 分隔符                                        |
| `lib/widgets/chat/multi_question_input.dart`  | 单个问题输入槽位 UI，刷新 / 删除按钮                               |
| `lib/widgets/chat/multi_question_panel.dart`  | 面板整体 UI，增减按钮                                              |
| `lib/widgets/chat/batch_message_content.dart` | 批次结果卡片渲染，decode param badge，User/RWKV 标签               |
| `lib/widgets/chat/ask_question_panel.dart`    | "Send All as Batch" 按钮                                           |
| `lib/widgets/message.dart`                    | 隐藏批次用户消息气泡                                               |
| `lib/widgets/bot_message_bottom.dart`         | token 阈值提示 × batchCount                                        |
