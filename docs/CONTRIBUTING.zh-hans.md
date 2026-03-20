# 贡献指南：Theme 快速开始

[![English](https://img.shields.io/badge/CONTRIBUTING-English-blue.svg)](../CONTRIBUTING.md)
[![Traditional Chinese](https://img.shields.io/badge/CONTRIBUTING-繁體中文-blue.svg)](./CONTRIBUTING.zh-hant.md)
[![Japanese](https://img.shields.io/badge/CONTRIBUTING-日本語-blue.svg)](./CONTRIBUTING.ja.md)
[![Korean](https://img.shields.io/badge/CONTRIBUTING-한국어-blue.svg)](./CONTRIBUTING.ko.md)
[![Russian](https://img.shields.io/badge/CONTRIBUTING-Русский-blue.svg)](./CONTRIBUTING.ru.md)

本指南面向主要想通过 PR 自定义 App 配色的外部贡献者。

## 1. 在 `lib/model/app_theme.dart` 中添加主题

1. 复制现有主题（通常是 `.dim` 或 `.lightsOut`），重命名为例如 `.myTheme`。
2. 补全所有必填颜色字段（`primary`、`themePrimary`、`qb*`、`g*`、输入框/消息颜色等）。
3. 正确设置 `isLight`（亮色为 `true`，暗色为 `false`）。
4. 在 `displayName` 中加入新分支。
5. 同步更新 `fromString` 与 `toString`，保证偏好持久化兼容。

## 2. 在 `lib/widgets/theme_selector.dart` 中暴露新主题

1. 在 `items` 列表中新增一个 `FormItem`。
2. 参考 `_onDimPressed` / `_onLightsOutPressed` 添加处理函数：
   - 更新 `P.preference.preferredDarkCustomTheme.q`
   - 持久化 `halo_state.preferredDarkCustomTheme`
3. 复用选中态逻辑：`preferredDarkCustomTheme == .yourTheme`。

说明：当前结构是「一个亮色主题 + 多个暗色主题」。如果新增额外亮色主题，还需要调整 `lib/store/app.dart` 的同步逻辑。

## 3. `Args.debuggingThemes` 的作用

- 启动参数：`--dart-define=debuggingThemes=true`
- 调试行为：应用会每秒在 `.light` 与当前暗色偏好（`preferredDarkCustomTheme`）之间切换。
- 用途：快速检查同一页面在明暗主题下的对比度、可读性和覆盖情况。

## 4. 在 `.vscode/launch.json` 同时启动桌面和移动端 UI

1. 保持按平台拆分的 launch 配置（如 macOS、Android、iOS）。
2. 在 `compounds` 中组合这些配置（例如 `all (Halo)`）。
3. 运行 compound 配置，即可并行启动多端 UI 对照调色。

可选：在对应配置中加入 `--dart-define=debuggingThemes=true`，实现自动明暗切换预览。
