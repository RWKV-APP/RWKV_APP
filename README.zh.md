# RWKV App

[English](./README.md) | [中文](./README.zh.md)

这是一个使用 Flutter 构建的、用于 RWKV-LM 的跨平台移动应用程序。它允许在设备上对 RWKV 语言模型进行推理。

## 功能

- **跨平台:** 可在 Android 和 iOS 上运行。
- **端侧推理:** 所有计算都在您的设备上本地完成。
- **模块化设计:** 可以轻松地在不同的 RWKV 模型（聊天、TTS、视觉理解、奥赛罗、数独）之间切换。
- **开源:** 整个项目是开源的，并在 GitHub 上提供。

## 技术架构

- **前端 (Flutter):** [rwkv_mobile_flutter](https://github.com/MollySophia/rwkv_mobile_flutter)
- **后端 (Dart FFI):** [rwkv_mobile_flutter](https://github.com/MollySophia/rwkv_mobile_flutter)
- **模型:** [mollysama/rwkv-mobile-models](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)

## 快速开始

## 开发

### 环境要求

- **Flutter:** 确保您已安装并配置了 Flutter。有关说明，请参阅[官方文档](https://flutter.dev/docs/get-started/install)。
- **环境设置:**
  - 从开发人员处获取 `.env` 文件，并将其内容放置在 `.env` 目录中。
  - 从开发人员处获取 `assets/filter.txt` 文件，并将其放置在 `assets/` 目录中。
  - 从开发人员处获取 `assets/model` 文件夹，并将其放置在 `assets/` 目录中。

### 安装

1.  **克隆仓库:**
    ```bash
    git clone https://github.com/MollySophia/rwkv_mobile_flutter.git
    cd rwkv_mobile_flutter
    ```
2.  **安装依赖:**
    ```bash
    flutter pub get
    ```

### 切换环境

使用以下 `fastlane` 命令在不同的应用程序环境之间切换：

- **RWKV Chat:** `fastlane switch_env env:chat`
- **RWKV Talk (TTS):** `fastlane switch_env env:tts`
- **RWKV See (World):** `fastlane switch_env env:world`
- **RWKV Othello:** `fastlane switch_env env:othello`
- **RWKV Sudoku:** `fastlane switch_env env:sudoku`

### 运行应用

- **VS Code / Cursor:** 启动 "Debug: Start Debugging" 命令 (`workbench.action.debug.start`)。
- **命令行:**
  ```bash
  flutter run
  ```

## 聊天页 �� 逻辑

### 主要涉及的代码

- **页面 UI:** `lib/page/chat.dart`
- **消息 UI:** `lib/widgets/chat/message.dart`
- **状态:** `lib/state/chat.dart`
- **模型:** `lib/model/message.dart`
- **后端:** `RWKV`

### 业务逻辑

- 使用 `ListView.separated` 来渲染消息列表, `ListView.reverse = true`
- 使用 `late final messages = qs<List<Message>>([]);` 作为数据源
- 使用 `P.chat.send` 方法发送消息, 主要逻辑为先发送用户消息, 同步至状态, 再发送 bot message, 同步至状态. 而后, 向 Backend 发送消息, 最后, 周期性地从 backend 接收新生成的字符串.
- 从 backend 接收到新生成的字符串后, 更新 bot message 的状态, 触发 UI 更新

## 贡献

欢迎贡献！请随时提交拉取请求。

## 许可证

该项目根据 [LICENSE](LICENSE) 文件进行许可。
