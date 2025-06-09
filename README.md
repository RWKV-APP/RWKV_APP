# RWKV Demo

## 技术架构

- 前端 (flutter): [本项目](https://github.com/MollySophia/rwkv_mobile_flutter)
- 后端 (dart ffi): [rwkv_mobile_flutter](https://github.com/MollySophia/rwkv_mobile_flutter)
- 权重: [mollysama/rwkv-mobile-models](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)

## 准备工作

- 找开发人员索要 `.env` 文件, 将 zip 文件解压后的文件拷贝至目录 `.env`
- 找开发人员索要 `assets/filter.txt` 文件, 将 zip 文件解压后的文件拷贝至目录 `assets/filter.txt`
- 找开发人员索要 `assets/model` 文件夹, 将 zip 文件解压后的文件夹拷贝至目录 `assets/model`

### flutter env

```
flutter doctor
```

```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.32.2, on macOS 15.5 24F74 darwin-arm64, locale en-CN)
[✓] Android toolchain - develop for Android devices (Android SDK version 35.0.0)
[✓] Xcode - develop for iOS and macOS (Xcode 16.4)
[✓] Chrome - develop for the web
[✓] Android Studio (version 2024.3)
[✓] VS Code (version 1.100.2)
```

## 开发

### 设置环境

- 使用 `fastlane switch_env env:chat` 切换至 chat app (RWKV Chat)
- 使用 `fastlane switch_env env:tts` 切换至 tts app (RWKV Talk)
- 使用 `fastlane switch_env env:world` 切换至 world app (RWKV See)
- 使用 `fastlane switch_env env:othello` 切换至 world app (RWKV Othello)
- 使用 `fastlane switch_env env:sudoku` 切换至 world app (RWKV Sudoku)

### 运行

- 在 vscode / cursor 中运行 "Debug: Start Debugging" (`workbench.action.debug.start`)

## 聊天页面逻辑

### 主要涉及的代码

- 页面 UI: `lib/page/chat.dart`
- 消息 UI: `lib/widgets/chat/message.dart`
- 状态: `lib/state/chat.dart`
- 模型: `lib/model/message.dart`
- 后端: RWKV

### 业务逻辑

- 使用 ListView.separated 来渲染消息列表, `ListView.reverse = true`
- 使用 `late final messages = qs<List<Message>>([]);` 作为数据源
- 使用 `P.chat.send` 方法发送消息, 主要逻辑为先发送用户消息, 同步至状态, 再发送 bot message, 同步至状态. 而后, 向 Backend 发送消息, 最后, 周期性地从 backend 接收新生成的字符串.
- 从 backend 接收到新生成的字符串后, 更新 bot message 的状态, 触发 UI 更新
