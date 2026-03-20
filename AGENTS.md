# AGENTS.md

> 目的：本文件是 coding agent 在本仓库中的强约束说明。除非用户明确要求例外处理，否则应直接按本文件执行，不应将其理解为普通建议。

## 1. 文件同步规则

- 修改 `AGENTS.md` 时，必须在同一次变更中同步修改 `CLAUDE.md`。
- `AGENTS.md` 与 `CLAUDE.md` 的规则内容必须保持一致，只有本节中的文件名允许不同。

## 2. 规则使用方式

### 2.1 适用顺序

按下面顺序理解并执行规则：

1. 先判断当前编辑的文件命中了哪些“按范围规则”。
2. 若命中多个范围，优先使用更具体、离当前文件路径更近的规则。
3. 再应用“全局规则”。
4. 若规则之间仍有冲突，以更具体的规则为准。

### 2.2 对 Coding Agent 的执行要求

- 开始编辑前，先根据目标文件路径判断适用规则。
- 除非任务明确要求，否则不要顺手重构无关代码。
- 只修改完成当前任务所必需的内容。
- 对生成文件、第三方代码、无关模块保持克制，避免无意义改动。
- 如果任务跨多个仓库，先判断改动应属于 frontend 还是 adapter，再开始编辑。

## 3. 本地仓库与路径

- Flutter 前端仓库：`./`（当前仓库）
- Flutter C++ 桥接层：`../rwkv_mobile_flutter`
- C++ 后端推理引擎：`../rwkv_mobile`（可能为空）
- App 下载页与 HTTP 服务端：`../app_website`（可能为空）

## 4. 全局规则

### 4.1 项目事实

- 本项目是 Flutter / Dart 项目。
- 目标平台：iOS / Android / Windows / macOS / Linux。
- 这是一个本地运行大语言模型的 App。
- 推理可使用 NPU / GPU / CPU。
- 权重加载到显存或统一内存。

### 4.2 架构与状态管理

- 全项目使用 Riverpod。
- 项目中存在以下快捷封装：

```dart
StateProvider<V> qs<V>(V v)
Provider<V> qp<V>(V Function(Ref<V> ref) createFn)
StateProviderFamily<V, K> qsf<K, V>(V v)
StateProviderFamily<V, K> qsff<K, V>(V Function(Ref<V> ref, K arg) createFn)

// ProviderListenable / StateProvider 均可通过 `.q` 快捷读写
```

- 在 `build` 方法中，凡是需要随着状态变化而自动刷新的 UI，必须使用 `ref.watch(provider)`。
- 在逻辑层、回调、一次性读取场景中，优先使用 `.q`。
- 严禁在 `build` 中使用 `.q` 来构建依赖状态的 UI；这样会导致 UI 不刷新。

### 4.3 文件组织与导入

- 全局状态主要位于 `lib/store`。
- `lib/store` 下只有 `lib/store/p.dart` 可以集中写 `import`。
- `lib/store` 下其他文件必须通过 `part of 'p.dart';` 共享引用。
- 严禁使用相对路径导入。
- 必须使用 `import 'package:.../...';`。
- 严禁在 `import` 或 `export` 中使用 `show`。
- 统一使用普通 `import` / `export`。

### 4.4 路由与 UI

- 路由统一放在 `lib/router`。
- 路由方案是 `go_router`。
- UI 中大量使用 `ConsumerWidget`，应优先保持现有模式一致。

### 4.5 推理引擎

- `rwkv_mobile_flutter` 是本项目使用的 LLM inference 引擎。

### 4.6 双仓协作规则

- 本项目通常与两个强关联仓库一起工作：
  - Frontend：当前仓库 `rwkv_app`
  - Adapter / FFI：`../rwkv_mobile_flutter`
- 默认路径解析方式：
  - frontend 根目录 = 当前工作目录仓库根目录
  - adapter 根目录 = `../rwkv_mobile_flutter`
- 如果一个问题看起来像 Flutter UI / 路由 / 页面状态问题，优先在 frontend 中定位。
- 如果一个问题看起来像 FFI / 推理接入 / 平台桥接问题，优先在 adapter 中定位。

### 4.7 图标与包体积规则

- 若使用 `material_symbols_icons`，只允许使用下面这个导入：

```dart
import 'package:material_symbols_icons/symbols.dart';
```

- 图标必须用静态常量方式引用，例如 `Icon(Symbols.xxx)`。
- 严禁按名称动态获取图标。
- 严禁导入 `package:material_symbols_icons/get.dart`。
- 严禁导入 `package:material_symbols_icons/symbols_map.dart`。
- 打包时严禁使用 `--no-tree-shake-icons`。
- 必须保持 icon tree-shake 开启。
- 如果项目已经引入 `material_symbols_icons` 依赖，代码中必须至少存在一个静态 `Symbols.xxx` 引用，避免字体资源整体进入产物。

### 4.8 i18n 规则

- 当前项目有 6 个 ARB 文件：
  - `intl_en.arb`
  - `intl_ja.arb`
  - `intl_ko.arb`
  - `intl_ru.arb`
  - `intl_zh_Hans.arb`
  - `intl_zh_Hant.arb`
- 修改任意一个 `.arb` 文件后，必须同步更新其他语言文件中的对应 key。
- 修改 `.arb` 后，必须运行：

```bash
dart pub global run intl_utils:generate
```

- 严禁运行 `flutter gen-l10n`。
- 严禁编辑 `lib/gen/l10n.dart`。
- ARB 默认不保留单个 `@` 开头的 metadata key。
- 新增或修改文案时，不要补写 `@foo` 形式的 metadata 块，例如 `placeholders`、`type`、`description`。
- 如果外部工具自动生成了单个 `@` metadata，在确认当前项目生成流程不受影响后，应删除这些 metadata，并保持所有 ARB 文件同步。

### 4.9 工程目录约束

- 工程辅助代码必须放在 `./tools`。
- 这包括 Python、Dart、工具脚本、检查工具、dev 辅助实现。
- 严禁编辑 `lib/gen/intl` 下的任何文件。
- 该目录属于生成内容，应交由插件维护。

### 4.10 版本与技术栈基线

- Flutter 3.41.3+（stable）
- Dart 3.11.0+（大量使用 Dot Shorthand）
- 状态管理：Riverpod（`qs` / `qp` / `qsf` / `qsff`）
- 路由：`go_router`
- 推理：RWKV

### 4.11 Source Control 规则

- 严禁自动 `commit`。
- 提交必须由用户手动完成。
- 除非用户明确要求，否则不要主动提供 Git 建议。

### 4.12 忽略范围

- 项目中的 `albatross` 逻辑可忽略，只需保证编译通过。
- 项目中的 `flutter_roleplay` 逻辑可忽略，只需保证编译通过。

## 5. 按范围规则

### 5.1 范围：`**/*.dart`

以下规则适用于所有 Dart 文件。

#### Dart 编码风格

- 所有方法必须使用 early return 风格。
- 禁止使用 `var`。
- 默认使用“显式类型 + `final`”；只有确实需要重赋值时才使用非 `final` 的显式类型。
- 对于局部变量，如果右侧初始化表达式已经足够明确，不要重复写类型。
- 示例：写 `final item = suggestions[index];`，不要写 `final String item = suggestions[index];`。
- 示例：写 `final foo = ref.watch(P.app.foo);`，不要写 `final String foo = ref.watch(P.app.foo);`。
- `for` 循环中的迭代变量使用 `final`。
- 使用 `for` 循环，不要使用 `forEach`。
- 不要使用 `then`，优先使用 `await`。
- 优先使用 Dot Shorthand，包括枚举、静态方法、构造器等场景。
- 已知支持 Dot Shorthand 的 symbols：
  - `Alignment`
  - `BoxShape`
  - `CrossAxisAlignment`
  - `EdgeInsets`
  - `FontWeight`
  - `MainAxisAlignment`
  - `MainAxisSize`
  - `Radius`
  - `TextScaler`

### 5.2 范围：`lib/**/*.dart`

以下规则适用于 `lib` 下的 Flutter UI 文件。

#### Flutter UI 约束

- 禁止使用 `Divider`。
- 分隔线必须使用 `Container` 实现，并设置 `height: 0.5`。
- 分隔线颜色优先来自：

```dart
final qb = ref.watch(P.app.qb);
```

- 禁止使用 `ListTile`。
- 列表条目必须使用原始 `Column + Row` 组合实现。
- UI 层不要写超过三行的逻辑代码。
- 这里的“逻辑代码”尤其包括：设置 state provider、加载权重、发起复杂流程、串联多个条件判断。
- `page` / `widget` 目录只负责 UI 构建和 provider 绑定。
- 复杂 `onClick`、业务判断、异步流程等重逻辑应放到 `store`。
- 严禁设计下面这种回调参数模式：

```dart
void Function()? onSuccess,
void Function(Object)? onError,
```

- 成功或失败提示应在实现内部直接使用：`Alert.success` / `Alert.error` / `Alert.warning`。
- 每个 `Widget build(BuildContext context, WidgetRef ref) {` 的顶部都必须先声明：

```dart
final theme = Theme.of(context);
```

- 在同一个 `build` 方法中，后续不要再次直接调用 `Theme.of(context)`。
- 严禁在 `build` 中使用 `FutureBuilder`。
- 不要在 UI 层 class 内声明任何 `Widget _build...` helper 方法。
- 应将其拆分为独立子组件。
- 获取屏幕宽度时，必须使用 `MediaQuery.sizeOf(context).width`。
- 不要使用 `MediaQuery.of(context).size.width`。
- 获取屏幕内边距时，必须使用 `MediaQuery.paddingOf(context)`。
- 不要使用 `MediaQuery.of(context).padding`。
- 调整 `Color` 透明度时，使用 `.q(.x)`。
- 不要使用 `withOpacity`。

### 5.3 范围：`**/*.md`

以下规则适用于多语言文档相关 Markdown 文件。

#### README / CONTRIBUTING 多语言同步

- 多语言 README 文件包括：
  - `README.md`
  - `docs/README.zh-hans.md`
  - `docs/README.zh-hant.md`
  - `docs/README.ja.md`
  - `docs/README.ko.md`
  - `docs/README.ru.md`
- 多语言 CONTRIBUTING 文件包括：
  - `CONTRIBUTING.md`
  - `docs/CONTRIBUTING.zh-hans.md`
  - `docs/CONTRIBUTING.zh-hant.md`
  - `docs/CONTRIBUTING.ja.md`
  - `docs/CONTRIBUTING.ko.md`
  - `docs/CONTRIBUTING.ru.md`
- 修改任意 README 或 CONTRIBUTING 后，必须同步检查并更新其他语言版本中的对应内容。
- 需要保持同步的内容包括：结构、章节、关键信息、链接、徽章。

## 6. Agent 执行检查清单

开始提交结果前，按下面清单自查：

- 如果修改了 `AGENTS.md`，是否同步修改了 `CLAUDE.md`。
- 如果修改了任意 `.arb`，是否同步更新了全部 6 个语言文件。
- 如果修改了任意 `.arb`，是否运行了 `dart pub global run intl_utils:generate`。
- 如果修改了 README 或 CONTRIBUTING，是否同步更新了所有语言版本。
- 如果修改了 `lib/store/*`，是否遵守了 `p.dart` 集中 `import` 与 `part of 'p.dart';` 规则。
- 如果修改了 `lib` 下 UI 文件，是否避开了 `Divider`、`ListTile`、`FutureBuilder`、重复 `Theme.of(context)`、旧式 `MediaQuery.of(context)`。
- 是否避免了无关改动。
- 是否没有自动 `commit`。
