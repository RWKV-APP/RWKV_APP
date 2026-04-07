# Coding Agent 适配优化 Proposal

> 记录针对 Coding Agent 协作体验的工程提案，当前仅归档，不代表开始实施

---

## 背景与目标

当前仓库已经具备较好的 Coding Agent 使用基础，但还没有达到“复杂任务也能稳定高质量协作”的状态

本 proposal 的目标不是立刻启动一次大重构，而是先把后续可能投入的优化方向整理清楚，便于团队后续评估排期、收益和实施边界

本 proposal 关注的是以下问题：

- 如何让 Coding Agent 更快理解项目结构
- 如何让 Coding Agent 更稳定定位改动位置
- 如何让 Coding Agent 更容易拿到可信反馈
- 如何减少 Coding Agent 因规则冲突、隐式经验、上下文过大而出现的误判

---

## 当前仓库现状

截至 2026-04-07，本仓库在 Coding Agent 适配方面已经具备以下优势：

- 已有单一规则源，`CLAUDE.md` 和 `GEMINI.md` 都转发到根目录 `AGENTS.md`
- 项目目录总体清晰，`lib/store`、`lib/router`、`lib/page`、`lib/widgets` 的职责边界基本可辨认
- `docs/requirements/` 已经作为需求与提案沉淀目录在使用
- 本地验证链路可运行，`flutter test` 当时为通过状态
- `flutter analyze` 当时仅发现 2 条问题，说明整体代码并未处于失控状态
- 项目与 `../rwkv_mobile_flutter` 的协作关系已经在规则中被明确记录

这些基础意味着，本项目并不需要从零开始适配 Coding Agent，更适合走“规则收敛 + 检查入口统一 + 高热点区域增量整理”的路线

---

## 当前主要瓶颈

### 1. 规则与现状之间存在信任差

当前 `AGENTS.md` 已经写得很细，但仓库中仍然存在与规则不一致的现状，例如：

- 规则禁止在 `lib/**/*.dart` 中使用 `Divider` 和 `ListTile`
- 规则要求每个 `build` 顶部声明 `final theme = Theme.of(context);`
- 仓库中仍然有页面使用 `Divider`、`ListTile`
- `build` 顶部统一声明 `theme` 的规则，在部分组件中又会直接触发未使用变量告警

这类不一致对人类开发者影响有限，但对 Coding Agent 影响很大，因为它会降低规则的可信度，增加“到底该遵守规则还是跟随现状”的判断成本

### 2. 缺少统一、标准、面向 Agent 的检查入口

当前仓库可以手动运行 `flutter analyze` 和 `flutter test`，但没有一个明确的、官方认可的、适合作为 Agent 默认入口的统一检查命令

这会带来几个问题：

- Agent 需要自己猜测应该先跑哪些命令
- 不同 Agent 容易采用不同检查顺序
- Flutter 命令存在启动锁，并行运行时会互相等待
- i18n、文档同步、规则扫描等仓库约束没有被统一串起来

### 3. `lib/store/p.dart` 的共享上下文过大

`lib/store` 当前采用 `part of 'p.dart';` 聚合方式，这对熟悉仓库的人是高效的，但对 Coding Agent 来说会显著抬高首次理解成本

主要问题包括：

- 单个入口文件聚合了大量 import、part 和全局状态入口
- Agent 很难只读局部文件就建立足够上下文
- 任何一个 store 任务都更容易演变为“需要先理解整组共享上下文”
- 初始化顺序、职责边界、跨模块依赖更多依赖隐式经验而不是显式说明

### 4. 高热点文件体量偏大

截至 2026-04-07 的观测结果，仓库中非生成 Dart 文件存在较多超大文件：

- 68 个文件达到或超过 300 行
- 43 个文件达到或超过 500 行
- 26 个文件达到或超过 800 行
- 16 个文件达到或超过 1000 行

热点主要集中在 `store`、`widgets`、`page`，这会直接增加 Coding Agent 在以下场景中的出错概率：

- 只改一个局部功能，却误碰其他逻辑
- 为了确认依赖关系，不得不读取过多上下文
- 难以判断哪些逻辑适合继续放在当前文件，哪些应该拆分

### 5. 多仓协作信息仍然偏“人类经验化”

虽然规则中已经提到 frontend 与 adapter 的双仓协作关系，但对 Coding Agent 来说，还缺少一份更偏“症状到入口”的工作地图，例如：

- 遇到 FFI 行为异常时，应先看哪个仓库、哪个目录、哪个入口
- 遇到模型加载问题时，应该先排查 frontend 状态还是 adapter 桥接
- 哪些改动只应在当前仓库处理，哪些需要同步到 `../rwkv_mobile_flutter`

---

## 推荐路线

本 proposal 推荐采用“平衡方案”作为主路线

### 主路线：平衡方案

目标是在 1 到 3 周的投入内，优先解决对 Coding Agent 影响最大的结构性问题，不追求一次性大规模改造

核心特点：

- 先修复高收益的规则与入口问题
- 先把知识显式化，而不是先做大重构
- 允许对高热点区域做增量整理
- 不要求本轮把所有历史问题一次清理完成

### 备选路线：轻量快修

若短期内只想快速提效，可以只做以下内容：

- 统一检查入口
- 收敛 `AGENTS.md` 中的硬规则与偏好规则
- 补充少量目录级说明文档

这条路线见效最快，但对复杂任务和跨模块改动的提升上限有限

### 备选路线：激进优化

若未来愿意投入更大工程成本，可以考虑更明显的结构调整，例如：

- 系统性拆分超大 store 文件
- 逐步弱化 `p.dart` 的超大共享上下文
- 为高频约束补充 custom lint 或自动扫描工具

这条路线理论上上限更高，但不适合作为当前阶段的第一步

---

## 优化建议分级

### Round 1 — 立即可做

1. **统一 Agent 检查入口**
   - 在 `tools` 中提供正式 CLI
   - 约定一个面向 Agent 的标准命令，例如 `agent-check`
   - 串行组织 `flutter analyze`、`flutter test`、规则扫描和同步检查

2. **收敛规则，明确硬规则与偏好规则**
   - 将 `AGENTS.md` 中真正必须遵守的规则标记为硬规则
   - 将偏工程风格、允许历史例外的内容标记为偏好规则
   - 优先消除已知的规则与现状冲突

3. **为高频目录补充 scoped `AGENTS.md`**
   - 首批建议覆盖 `lib/store`、`lib/widgets/chat`、`tools`
   - 每份只写最关键的职责边界、入口文件、常用验证命令、避免误碰区域

4. **补充 `store map` 和 `workspace map`**
   - 用文档明确 `P.*` 子域职责
   - 用文档明确 frontend 与 adapter 的切换信号
   - 让 Agent 遇到具体症状时能快速找到入口

5. **清理显眼且低风险的规则冲突**
   - 优先清理分析器已经发现的问题
   - 优先处理与 `AGENTS.md` 直接冲突、又容易统一的 UI 模式

### Round 2 — 中期增强

1. **对超大热点文件采用“触碰即拆”的增量策略**
   - 新逻辑不继续堆入超大文件
   - 每次业务改动顺手拆出边界清晰的小组件或子域
   - 首批关注 `remote.dart`、`rwkv.dart`、`chat.dart`、`ask_question_panel.dart`、`model_selector.dart`

2. **提供 changed-only 快速检查入口**
   - 针对当前改动文件做更快的检查
   - 降低 Agent 每次全量验证的成本
   - 让日常协作更适合频繁小步修改

3. **让关键约束尽量从“文档规则”升级为“工具规则”**
   - 可以自动检查的约束尽量不要只靠文字说明
   - 例如 ARB 同步、文档同步、禁用模式扫描、指定目录结构检查

4. **补充关键页面的 smoke tests**
   - 不追求全量 UI 自动化
   - 先覆盖聊天主流程、模型选择、核心设置页、Translator 基础状态

### Round 3 — 暂不建议现在做

1. **不建议当前就发起一次全仓大重构**
   - 收益和风险不成正比
   - 也会显著增加与现有分支工作的冲突概率

2. **不建议当前就彻底替换 `p.dart` 方案**
   - 这是高影响架构改动
   - 应当在规则、入口和文档先稳定后再评估

3. **不建议当前就为所有规则编写复杂 custom lint**
   - 成本较高
   - 更适合在第一轮收益兑现后再判断是否继续投入

---

## 建议优先级

建议按以下顺序评估后续排期：

1. **统一检查入口**
2. **规则收敛与规则冲突清理**
3. **scoped `AGENTS.md`**
4. **`store map` / `workspace map` 文档**
5. **高热点文件的增量拆分策略**

其中，前四项是本 proposal 认为的最高优先级，因为它们对 Coding Agent 的收益最直接，同时实施风险相对可控

---

## 不在本 proposal 中承诺的事项

本 proposal 当前不承诺以下事项：

- 不承诺本轮立即启动代码重构
- 不承诺马上进入排期
- 不承诺同步多语言文档
- 不承诺本轮就调整主发版流程
- 不承诺本轮就替换现有 `lib/store/p.dart` 组织方式
- 不承诺一次性消化所有历史风格问题

---

## 附录：2026-04-07 的客观观察记录

### 验证结果

- `flutter test`：通过
- `flutter analyze`：发现 2 条问题
  - `lib/widgets/chat/batch_message_content.dart` 中存在未使用的局部变量 `theme`
  - `lib/widgets/markdown_render.dart` 中存在 `depend_on_referenced_packages` 提示

### 代码体量分布

- `lib/widgets`：70 个文件，约 19878 行
- `lib/store`：30 个文件，约 17822 行
- `lib/page`：27 个文件，约 11088 行
- `lib/model`：38 个文件，约 2925 行

### 超大非生成文件示例

- `lib/store/remote.dart`：2142 行
- `lib/store/rwkv.dart`：1831 行
- `lib/store/chat.dart`：1741 行
- `lib/widgets/chat/ask_question_panel.dart`：1226 行
- `lib/store/api_server.dart`：1224 行
- `lib/store/ask_question.dart`：1089 行
- `lib/page/benchmark.dart`：1081 行

### 其他观察

- `lib/page` 与 `lib/widgets` 中的 Widget class 数量观测值为 326
- `lib/store` 中的 provider 声明观测值为 160
- `AGENTS.md` 已经覆盖大量项目约束，但仍存在规则与仓库现状不一致的例子
- `tools/README.md` 仍然接近样例模板，说明工具层入口还没有被正式产品化
- 当前 `.github/workflows/` 以构建与发布为主，缺少一个面向日常协作的通用检查 workflow

---

## 当前状态

当前状态：提案已归档，暂不执行，待后续排期再评估
