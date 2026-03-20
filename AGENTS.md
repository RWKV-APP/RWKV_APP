# AGENTS.override.md

本文件由当前仓的 `.cursor/rules/*.mdc` 抽取并整理，用于 Codex 的项目级行为约束（override）。

## 本地项目路径

- flutter 前端仓库：`./` (本项目)
- flutter_cpp 桥接层：`../rwkv_mobile_flutter`
- cpp 后端推理引擎：`../rwkv_mobile` (可能为空)
- app 下载页面与 http 服务器后端 ：`../app_website` (可能为空)

## 应用方式

- `全局规则`：默认始终生效。
- `按范围规则`：仅在编辑匹配范围文件时生效。
- 若规则冲突：优先遵守更具体、更接近当前任务文件范围的规则。

## 全局规则

### 项目概况

- 本项目是 Flutter / Dart 项目，目标平台为 iOS / Android / Windows / macOS / Linux。
- 这是一个在本地运行大语言模型的 App，使用 NPU / GPU / CPU 推理，权重加载到显存或统一内存。

### 架构与状态管理

- 全项目使用 Riverpod 管理状态，并封装了原子化快捷方法：

```dart
StateProvider<V> qs<V>(V v)
Provider<V> qp<V>(V Function(Ref<V> ref) createFn)
StateProviderFamily<V, K> qsf<K, V>(V v)
StateProviderFamily<V, K> qsff<K, V>(V Function(Ref<V> ref, K arg) createFn)

// ProviderListenable / StateProvider 均可通过 `.q` 快捷读写
```

- 在 `build` 方法中，需要 UI 随状态变化时必须使用 `ref.watch(provider)`。
- 在逻辑层、回调、一次性读取场景中使用 `.q`。
- 严禁在 `build` 中用 `.q` 构建依赖状态的 UI（会导致 UI 不刷新）。

### 文件组织与导入

- 全局状态主要位于 `lib/store`。
- 仅在 `lib/store/p.dart` 中集中 `import`，其他 `lib/store` 文件通过 `part of 'p.dart';` 共享引用。
- 严禁相对路径导入，必须使用 `import 'package:.../...';`。
- 严禁使用 `show` 形式的导入或导出；统一使用普通 `import` / `export`。

### 路由与 UI

- 路由统一在 `lib/router`，使用 `go_router`。
- UI 大量使用 `ConsumerWidget`。

### 推理引擎

- `rwkv_mobile_flutter` 是本项目 LLM inference 引擎。

### 双仓协作与需求解析（RWKV_APP + rwkv_mobile_flutter）

- 本项目默认由两个强关联仓库组成：
  - Frontend：当前工作仓（即 `rwkv_app`）
  - Adapter / FFI：`rwkv_mobile_flutter`（与 frontend 同级、共享同一父目录）
- 路径解析规则（默认）：
  - frontend 根目录 = 当前工作目录仓库根
  - adapter 根目录 = `../rwkv_mobile_flutter`

### 图标与包体积规则（Material Symbols）

- 若使用 `material_symbols_icons`，仅允许 `import 'package:material_symbols_icons/symbols.dart';`。
- 仅允许静态常量方式引用图标：`Icon(Symbols.xxx)`；禁止动态按名称取图标。
- 严禁引入 `package:material_symbols_icons/get.dart`。
- 严禁引入 `package:material_symbols_icons/symbols_map.dart`。
- 打包时禁止使用 `--no-tree-shake-icons`，保持默认 icon tree-shake 开启。
- 若已添加 `material_symbols_icons` 依赖，必须至少存在一个静态 `Symbols.xxx` 引用，避免字体资源未被裁剪而整包进入产物。

### i18n 规则

- 项目当前有 6 个 ARB 文件：
  - `intl_en.arb`
  - `intl_ja.arb`
  - `intl_ko.arb`
  - `intl_ru.arb`
  - `intl_zh_Hans.arb`
  - `intl_zh_Hant.arb`
- 修改任一 `.arb` 后，必须同步更新其他语言文件对应 key。
- 修改 `.arb` 后必须运行：`dart pub global run intl_utils:generate`。
- 严禁运行 `flutter gen-l10n`。
- 严禁编辑 `lib/gen/l10n.dart`。
- ARB 中默认不保留单 `@` 开头的 metadata key；新增或修改文案时，不要补写 `@foo` 对应的 `placeholders`、`type`、`description` 等 metadata 块。
- 若外部工具自动生成了单 `@` metadata，在确认不影响当前项目生成结果后，应直接删除并保持各语言 ARB 同步。

### 工程目录约束

- 工程辅助代码（Python / Dart / 工具脚本 / 检查工具 / dev 辅助实现）必须放在 `./tools`。
- 严禁编辑 `lib/gen/intl` 下任何文件（生成内容交由插件维护）。

### 版本与技术栈基线

- Flutter 3.41.3+（stable）。
- Dart 3.11.0+（大量使用 Dot Shorthand）。
- 状态管理：Riverpod（`qs` / `qp` / `qsf` / `qsff`）。
- 路由：`go_router`。
- 推理：RWKV（权重加载到显存/统一内存）。

### Source Control 规则

- 严禁自动 `commit`，必须由用户手动提交。
- 不要向用户提供任何 Git 建议，除非用户明确要求。

### 忽视项目中的 albatross 逻辑

仅保证编译通过即可

### 忽视项目中的 flutter_roleplay 逻辑

仅保证编译通过即可

## 按范围规则

### 范围：`**/*.dart`（Dart 编码风格）

- 所有方法必须使用 early return 风格。
- 禁止使用 `var`，使用显式类型 + `final`（需要重赋值时再用非 `final` 显式类型）。
- 对于局部变量，若右侧初始化表达式已能明确推导出类型，则不要显式写类型；例如写 `final item = suggestions[index];`，不要写 `final String item = suggestions[index];`。写 `final foo = ref.watch(P.app.foo)`，不要写 `final String foo = ref.watch(P.app.foo)`。
- `for` 循环中的迭代变量使用 `final`。
- 使用 `for` 循环，禁止使用 `forEach`。
- 不要使用 `then`，优先 `await`。
- 优先使用 Dot Shorthand（枚举、静态方法、构造器等）。
- 已知可用 Dot Shorthand 的 symbols：
  - `Alignment`
  - `BoxShape`
  - `CrossAxisAlignment`
  - `EdgeInsets`
  - `FontWeight`
  - `MainAxisAlignment`
  - `MainAxisSize`
  - `Radius`
  - `TextScaler`

### 范围：`lib/**/*.dart`（Flutter UI 约束）

- 禁止使用 `Divider`，必须用 `Container` 实现分隔线，并设置 `height: 0.5`，颜色优先来自 `final qb = ref.watch(P.app.qb);`。
- 禁止使用 `ListTile`，必须使用原始 `Column + Row` 组合实现列表条目。
- 禁止在 UI 层实现超过三行的逻辑代码（尤其是设置 state provider、加载权重等）。
- `page` / `widget` 目录仅负责 UI 构建与 provider 绑定，不应实现复杂 `onClick` 等逻辑，重逻辑应放到 `store`。
- 严禁实现带以下模式的回调参数：

```dart
void Function()? onSuccess,
void Function(Object)? onError,
```

- 成功/失败提示直接在实现中使用：`Alert.success` / `Alert.error` / `Alert.warning`。
- 在 `Widget build(BuildContext context, WidgetRef ref) {` 顶部必须声明：`final theme = Theme.of(context);`；后续严禁再直接调用 `Theme.of(context)`。
- 严禁在 `build` 中使用 `FutureBuilder`。
- 不要在 UI 层 class 中声明任何 `Widget _build...` helper 方法；应拆成独立子组件。
- 获取屏幕宽度必须用 `MediaQuery.sizeOf(context).width`，不要用 `MediaQuery.of(context).size.width`。
- 获取屏幕内边距必须用 `MediaQuery.paddingOf(context)`，不要用 `MediaQuery.of(context).padding`。
- 调整 `Color` 透明度使用 `.q(.x)`，不要用 `withOpacity`。

### 范围：`**/*.md`（README / CONTRIBUTING 多语言同步）

- 多语言 README：
  - `README.md`
  - `docs/README.zh-hans.md`
  - `docs/README.zh-hant.md`
  - `docs/README.ja.md`
  - `docs/README.ko.md`
  - `docs/README.ru.md`
- 多语言 CONTRIBUTING：
  - `CONTRIBUTING.md`
  - `docs/CONTRIBUTING.zh-hans.md`
  - `docs/CONTRIBUTING.zh-hant.md`
  - `docs/CONTRIBUTING.ja.md`
  - `docs/CONTRIBUTING.ko.md`
  - `docs/CONTRIBUTING.ru.md`
- 修改任一 README 或 CONTRIBUTING 后，必须检查并同步更新其他语言版本的对应内容（结构、章节、关键信息、链接、徽章等）。
