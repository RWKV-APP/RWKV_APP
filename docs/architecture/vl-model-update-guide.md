<a id="SPEC-RWKV-VL-MODEL-UPDATE"></a>
<a id="SPEC-RWKV-VL-THINKING-CAPABILITY"></a>

# VL 模型更新与展示映射检查

本文记录 VL 模型配置进入 App 展示列表的完整链路，以及新增、替换 VL 权重时必须同步检查的代码位置

适用范围包括 `remote/latest.json` 中 `world.model_config` 的模型、视觉编码器、视觉适配器、平台和 SoC 配置

## Bug 记录：8 Gen 5 VL 模型未显示

记录日期：2026-07-14

### 现象

`remote/latest.json` 已包含以下 8 Gen 5 VL 权重，但 App 的 VL 模型选择列表中没有对应项目

```text
rwkv-vl-0.4B-260625-a16w8-8gen5.rmpack
```

该配置的主要字段均有效：

- 位于 `world.model_config`
- `platforms` 包含 `android`
- `backends` 包含 `qnn`
- `tags` 包含 `npu` 和 `core`
- `socLimitations` 包含 `8 Gen 5`

### 原因

VL 模型选择列表没有直接遍历 `latest.json` 中所有可用的 `world` 模型

它还依赖两处代码注册：

1. [`lib/model/world_type.dart`](../../lib/model/world_type.dart) 中 `WorldType.modrwkvV3.socPairs` 必须包含 SoC 名称和核心权重文件名
2. [`lib/model/file_info.dart`](../../lib/model/file_info.dart) 中 `FileInfo.worldType` 必须把核心权重文件名识别为 `WorldType.modrwkvV3`

当时 8 Gen 5 的 VL 文件在 [`remote/latest.json`](../../remote/latest.json) 中存在，但上述两处均没有登记

结果如下：

- 模型选择器不会为 `8 Gen 5` 创建 VL 展示项
- 该文件的 `worldType` 为 `null`，即使创建展示项也会在分组筛选时被排除

因此，只更新 `remote/latest.json` 无法让新的 VL 文件或 SoC 组合自动出现在 App 中

### 修复

- 在 `WorldType.modrwkvV3.socPairs` 中加入 `8 Gen 5` 与对应文件名
- 在 `FileInfo.worldType` 中把对应文件名映射为 `WorldType.modrwkvV3`
- 在 [`test/world_type_test.dart`](../../test/world_type_test.dart) 中增加读取当前 `remote/latest.json` 的回归测试

## VL 模型展示链路

1. `remote/latest.json` 提供 `world.model_config`
2. `P.remote.syncAvailableModels()` 将配置解析为 `FileInfo`，并根据平台和 `socLimitations` 生成 `seeWeights`
3. 模型选择器在 See 页面通过 `WorldType.values` 和 `WorldType.socPairs` 创建 `WorldGroupItem`
4. `WorldGroupItem` 使用 `FileInfo.worldType` 和核心权重文件名筛选模型及其 encoder、adapter 依赖
5. 两处映射和远程配置同时匹配时，VL 模型才会显示

## 模型选择器统一排序

VL 模型选择器必须沿用 Chat 模型选择器的同一个核心权重 comparator，不能维护
另一套独立优先级。完成当前平台和 SoC 过滤后，每个 `WorldType + socPair`
展示项先通过核心权重文件名解析为 `FileInfo`，再按下列顺序排列：

1. Core ML
2. MLX
3. NPU
4. GPU
5. WebRWKV
6. 同类权重按 `modelSize` 从大到小

同一 comparator 也继续用于 Chat 和 TTS。以后调整加速后端或模型大小优先级时，
三个选择器必须同时生效，不能只修改其中一个分支。VL 的 SoC 过滤规则保持不变；
`remote/latest.json` 中 `world.model_config` 的书写顺序不构成展示排序规则。

## 可配置 Thinking 能力

`thinking` 是 VL 模型组支持用户切换思考模式的能力标签，不是所有 VL
模型的默认属性。只有已经确认同时支持下列两种前缀的 VL 模型组才能声明：

- Thinking 开启：`<think>`
- Thinking 关闭（界面命名沿用 Chat 的“快思考”）：`<think>\n</think>`

同一可配置模型组的核心权重、vision encoder 和 vision adapter 目录项都要
包含小写 `thinking` 标签。App 以当前加载的核心权重为运行时判断依据：See
页仅在该权重具有 `thinking` 标签时显示 Thinking 按钮；标签缺失时不显示，
不得根据模型名称、`reason` 标签或 `WorldType.isReasoning` 猜测能力。

在 See 页中，Suggested Prompts 与 Thinking 按钮属于同一组输入选项，必须
使用同一个横向滚动行、相同控件高度和相同输入栏边距。显示为 Fast 或 High
的 Thinking 按钮必须固定为整行最左项，Suggested Prompts 按既有顺序跟在其后；
不得让 Thinking 按钮单独占据第二行。Suggested Prompts 的空闲态背景、边框、
文字颜色和文字粗细必须复用 Fast 按钮的可用态视觉规则，不能在浅色模式下使用
额外的灰色填充或阴影。
模型选择列表还必须在核心权重的模型卡片上显示独立的 `Thinking` 能力标签。
该列表标签与 See 页按钮使用同一个核心权重 `thinking` 判断，不从 encoder、
adapter、模型名称或其他标签推导。

当前目录中只有 `RWKV-VL 1.5B Thinking Preview · 260815` 这一组的三个组成
条目具备该能力。此前的 `RWKV-VL-260625`、FineVisionMax 非 Thinking Preview
以及更早的 VL 条目都不具备可配置 Thinking 能力，必须保持无 `thinking`
标签。

VL Thinking 按钮复用 Chat 的 Thinking 模式状态和原生
`SetThinkingToken` 链路，但在 See 页只提供“快思考/高思考”两态切换。
当前 VL 模板把 `spaceAfterRoles` 设为 `false`，因此传给原生运行时的 token
必须分别精确为 `<think>\n</think>` 和 `<think>`，不能附加空格，也不能把
VL 选择写回 Chat 的首选 Thinking 模式。

旧版或不支持切换的 VL 模型继续不带 `thinking` 标签，即使它会自行输出
`<think>\n</think>`，也不能因此显示切换按钮。以后新增支持切换的 VL 权重
时，能力标签、前缀测试和 See 页可见性测试必须与目录项一起交付。

## Agent 更新检查清单

以后新增、替换或重命名 VL 模型时，必须逐项完成以下检查

### 1. 检查远程配置

- 模型放在 `remote/latest.json` 的 `world.model_config`
- 确认 `url` 最后一段是实际文件名
- 确认 `platforms`、`backends`、`tags`、`socLimitations` 和 `fileSize` 正确
- NPU 核心权重使用 `core` 标签
- encoder 和 adapter 使用对应标签，并确认它们与核心权重属于同一个 `WorldType`
- 支持用户切换 Thinking 的模型组在核心权重、encoder 和 adapter 上都使用 `thinking` 标签；不支持切换的模型组不得添加
- 核心权重带 `thinking` 时，模型选择列表显示独立的 `Thinking` 标签；核心权重不带时不显示

### 2. 同步文件类型映射

在 `lib/model/file_info.dart` 的 `FileInfo.worldType` 中登记所有新增或改名的文件：

- 核心权重
- vision encoder
- vision adapter

缺少映射时，该文件的 `worldType` 为 `null`，无法加入正确的 VL 下载和加载分组

### 3. 同步 SoC 展示映射

在 `lib/model/world_type.dart` 的目标 `WorldType.socPairs` 中登记每个计划展示的 SoC 与核心权重文件名

SoC 字符串需要与 `P.rwkvBackend.socName.q` 完全一致，例如 `8 Gen 5` 和 `8 Elite Gen5` 是两个不同值

### 4. 考虑旧版本 App

VL 文件名和 SoC 映射位于 App 代码中，远程更新 `latest.json` 不会给已经安装的旧版本补充这些映射

如果远程配置将旧文件直接替换为新文件，旧版本 App 可能无法显示新模型。发布配置前需要评估旧版本兼容性，并协调 App 版本和远程配置的发布时间

### 5. 更新并运行测试

至少运行：

```bash
jq empty remote/latest.json
flutter test test/model_weight_sort_test.dart test/world_type_test.dart test/vl_thinking_capability_test.dart
dart analyze lib/model/model_weight_sort.dart lib/model/world_type.dart lib/model/file_info.dart lib/func/thinking_prefix.dart lib/store/rwkv_params.dart lib/page/see.dart lib/widgets/model_selector.dart lib/widgets/input_interactions.dart lib/widgets/see/floating_suggestions.dart lib/widgets/suggestion_chips.dart lib/widgets/chat/thinking_mode_button.dart lib/widgets/world_group_item.dart lib/widgets/model_tag.dart test/model_weight_sort_test.dart test/world_type_test.dart test/vl_thinking_capability_test.dart
dart run tools/bin/agent_check.dart --rules-only
```

如果新增了另一种 VL 架构或 `WorldType`，还需要增加对应的配置到展示映射集成测试

### 6. 真机确认

在目标设备上确认：

- `P.rwkvBackend.socName.q` 与 `socLimitations`、`socPairs` 使用相同字符串
- VL 模型出现在 See 页模型选择器中
- VL 模型与 Chat 使用相同的加速后端和模型大小优先级；当前 SoC 的专用核心权重与通用核心权重都位于正确排序位置
- 支持切换的 VL 模型卡片显示独立 `Thinking` 标签，不支持切换的卡片不显示
- 下载分组同时包含核心权重、encoder 和 adapter
- 下载完成后能够加载模型并开始视觉对话
- Thinking 按钮位于 Suggested Prompts 左侧并在同一横向行内等高对齐；Suggested Prompts 的空闲态视觉与 Fast 按钮一致，且不支持切换的模型没有 Thinking 按钮

## Agent 注意事项

看到“VL 模型已在 `latest.json` 中，但 App 不显示”时，依次检查以下位置：

1. `remote/latest.json`
2. `lib/model/world_type.dart` 的 `socPairs`
3. `lib/model/file_info.dart` 的 `worldType`
4. `lib/widgets/model_selector.dart` 的 See 分支
5. `lib/widgets/world_group_item.dart` 的文件分组条件

不要只检查 JSON 是否存在，也不要假设远程配置可以独立引入新的 VL 文件名
