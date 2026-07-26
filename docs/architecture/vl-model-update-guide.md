<a id="SPEC-RWKV-VL-MODEL-UPDATE"></a>

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

## Agent 更新检查清单

以后新增、替换或重命名 VL 模型时，必须逐项完成以下检查

### 1. 检查远程配置

- 模型放在 `remote/latest.json` 的 `world.model_config`
- 确认 `url` 最后一段是实际文件名
- 确认 `platforms`、`backends`、`tags`、`socLimitations` 和 `fileSize` 正确
- NPU 核心权重使用 `core` 标签
- encoder 和 adapter 使用对应标签，并确认它们与核心权重属于同一个 `WorldType`

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
flutter test test/world_type_test.dart
dart analyze lib/model/world_type.dart lib/model/file_info.dart test/world_type_test.dart
dart run tools/bin/agent_check.dart --rules-only
```

如果新增了另一种 VL 架构或 `WorldType`，还需要增加对应的配置到展示映射集成测试

### 6. 真机确认

在目标设备上确认：

- `P.rwkvBackend.socName.q` 与 `socLimitations`、`socPairs` 使用相同字符串
- VL 模型出现在 See 页模型选择器中
- 下载分组同时包含核心权重、encoder 和 adapter
- 下载完成后能够加载模型并开始视觉对话

## Agent 注意事项

看到“VL 模型已在 `latest.json` 中，但 App 不显示”时，依次检查以下位置：

1. `remote/latest.json`
2. `lib/model/world_type.dart` 的 `socPairs`
3. `lib/model/file_info.dart` 的 `worldType`
4. `lib/widgets/model_selector.dart` 的 See 分支
5. `lib/widgets/world_group_item.dart` 的文件分组条件

不要只检查 JSON 是否存在，也不要假设远程配置可以独立引入新的 VL 文件名
