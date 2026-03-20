# RWKV App ✨

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](../LICENSE)
[![English](https://img.shields.io/badge/README-English-blue.svg)](../README.md)
[![Traditional Chinese](https://img.shields.io/badge/README-繁體中文-blue.svg)](./README.zh-hant.md)
[![Japanese](https://img.shields.io/badge/README-日本語-blue.svg)](./README.ja.md)
[![Korean](https://img.shields.io/badge/README-한국어-blue.svg)](./README.ko.md)
[![Russian](https://img.shields.io/badge/README-Русский-blue.svg)](./README.ru.md)

**在手机与桌面设备上运行私有、端侧 AI。**
**一个面向聊天、语音、视觉与模型实验的本地优先 AI Playground。**

RWKV App 是一款面向 Android、iOS、Windows、macOS 和 Linux 的隐私优先 AI 应用。您可以在真实硬件上下载、切换并比较本地模型，体验聊天、语音和视觉等能力，而无需依赖云端推理。模型加载完成后，推理会留在您的设备上。

## 为什么选择 RWKV App

- **面向真实边缘设备：** 在手机与桌面设备上验证本地模型，而不是只在云端 Demo 里体验。
- **一个 App，覆盖多种 AI 工作流：** 将聊天、文本转语音和视觉理解放在同一处。
- **更快地比较模型：** 从 Hugging Face 下载并切换不同模型，直观比较质量、速度与硬件适配。
- **隐私优先：** 模型加载完成后，提示词、输出和推理过程都留在本地。

![RWKV App 截图](../.github/images/readme/gallery.png)

## ✨ 核心功能

- **📱 跨平台，本地优先：** 在 Android、iOS、Windows、macOS 和 Linux 上运行端侧推理。
- **🤖 灵活切换模型：** 从 Hugging Face 下载并比较不同模型。
- **💬 AI 聊天：** 在真实硬件上体验流畅的多轮对话。
- **🔊 文本转语音 (TTS)：** 将文本转换成自然流畅的语音。
- **🖼️ 视觉理解：** 探索基于图像的 AI 应用场景。
- **🔌 可选的本地 API 接口：** 在桌面端，您可以暴露 OpenAI 兼容的本地接口，用于工具集成和实验。
- **🌓 深色模式：** 让长时间使用更加舒适。

## 🚀 快速开始

1. 从官方下载页面或下方的平台链接下载安装包。
2. 打开 App，加载适合您设备的聊天模型。
3. 开始体验聊天、语音或视觉工作流；如果您在桌面端有集成需求，也可以启用内置本地 API 接口。

### 下载

**官方下载页面：[https://rwkv.halowang.cloud/](https://rwkv.halowang.cloud/)**

<table>
<thead>
<tr>
<th style="text-align: center;"></th>
<th style="text-align: center;">RWKV Chat</th>
<th style="text-align: center;">RWKV Sudoku</th>
<th style="text-align: center;">RWKV Othello</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: center;">Android APK 下载链接</td>
<td style="text-align: center;"><a href="https://play.google.com/store/apps/details?id=com.rwkvzone.chat">Google Play</a> / <a href="https://github.com/RWKV-APP/RWKV_APP/releases">GitHub Release</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/android-arm64">huggingface</a> / <a href="https://www.pgyer.com/rwkvchat">蒲公英</a></td>
<td style="text-align: center;"><a href="https://huggingface.co/datasets/rwkv-app/RWKV-Sudoku/tree/main">huggingface</a> / <a href="https://www.pgyer.com/rwkv-sudoku">蒲公英</a></td>
<td style="text-align: center;"><a href="https://huggingface.co/datasets/rwkv-app/RWKV-Othello/tree/main">huggingface</a> / <a href="https://www.pgyer.com/rwkv-othello">蒲公英</a></td>
</tr>
<tr>
<td style="text-align: center;">iOS</td>
<td style="text-align: center;"><a href="https://apps.apple.com/us/app/rwkv-chat/id6740192639">App Store</a> / <a href="https://testflight.apple.com/join/DaMqCNKh">testflight</a></td>
<td style="text-align: center;">-</td>
<td style="text-align: center;"><a href="https://testflight.apple.com/join/f5SVf76c">testflight</a></td>
</tr>
<tr>
<td style="text-align: center;" rowspan="2">Windows</td>
<td style="text-align: center;" colspan="3" rowspan="2"><a href="https://github.com/RWKV-APP/RWKV_APP/releases">GitHub Release</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/windows-x64">huggingface (zip)</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/windows-x64-installer">huggingface (installer)</a> / <a href="https://qm.qq.com/q/y0gOHcguty">QQ 群</a> / <a href="https://discord.gg/8NvyXcAP5W">Discord</a></td>
</tr>
<tr></tr>
<tr>
<td style="text-align: center;" rowspan="2">macOS</td>
<td style="text-align: center;" colspan="3" rowspan="2"><a href="https://github.com/RWKV-APP/RWKV_APP/releases">GitHub Release</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/macos-universal">huggingface</a> / <a href="https://qm.qq.com/q/y0gOHcguty">QQ 群</a> / <a href="https://discord.gg/8NvyXcAP5W">Discord</a></td>
</tr>
<tr></tr>
<tr>
<td style="text-align: center;">Linux</td>
<td style="text-align: center;"><a href="https://github.com/RWKV-APP/RWKV_APP/releases">GitHub Release</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/linux-x64">huggingface</a></td>
<td style="text-align: center;">-</td>
<td style="text-align: center;">-</td>
</tr>
</tbody>
</table>

> [!NOTE]
> 未来，我们会将所有独立功能整合进 RWKV Chat 应用中，为您提供统一的体验。

### 首次使用

首次打开 App 时，会弹出模型选择面板。请根据您的需求选择要使用的模型权重。

> [!WARNING]
> iPhone 14 及更早的设备可能无法流畅运行 1.5B / 2.9B 参数规模的模型。

## 💻 从源码构建

**请确保您已搭建好 [Flutter](https://flutter.dev/) 开发环境。**

> 开发环境要求 **Flutter 3.41.1+**（推荐使用 stable channel）。

1. **克隆仓库：**

```bash
# 必须切换到 'dev' 分支
git clone -b dev https://github.com/MollySophia/rwkv_mobile_flutter.git
# 确保 rwkv_mobile_flutter 和 RWKV_APP 在同一目录下
git clone -b dev https://github.com/RWKV-APP/RWKV_APP.git
cd RWKV_APP
```

目录结构应如下所示：

```text
parent/
├─ rwkv_mobile_flutter/
└─ RWKV_APP/
```

2. **创建必要的配置文件：**

```bash
touch assets/filter.txt;touch .env;
```

3. **安装依赖：**

```bash
flutter pub get
```

4. **（可选）为 `tools` 目录安装依赖：**

_执行此步骤可避免在 VS Code 或 Cursor 中运行应用时出现「您的项目中存在错误」的提示。_

```bash
cd tools; flutter pub get; cd ..;
```

5. **运行应用：**

```bash
flutter run
```

#### Windows ARM64 调试（QNN）

如果您在 Windows ARM64 上调试，请在 `pubspec.yaml` 中取消以下配置的注释：

```yaml
- path: assets/lib/qnn-windows/
  platforms: [windows]
```

在 Windows ARM64 上调试时，请使用 Flutter 的 `master` 分支，而不是 `stable` 分支。

## 🏗️ 技术栈

- **Flutter：** 一款用于构建跨平台用户界面的开源框架，支持安卓、苹果、Windows 和 macOS。
- **Dart FFI (外部函数接口)：** 用于 Dart 语言与 C++ 推理引擎进行高效通信。
- **C++ 推理引擎：** 项目核心的设备端推理引擎，使用 C++ 构建，支持多种模型格式和硬件加速（CPU/GPU/NPU）。
- **Hugging Face：** 一个提供模型、数据集和工具的开源社区，本项目用其作为模型权重的来源。

## 🤝 反馈与贡献

这是一个**实验性的早期测试版本**，您的反馈对我们至关重要！

- 🐞 **发现错误或问题？** [在此报告！](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=bug&template=bug_report.md&title=%5BBUG%5D)
- 💡 **想提出建议？** [建议一项功能！](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5BFEATURE%5D)
- 🎨 **想贡献自定义主题？** [Theme 快速开始](./CONTRIBUTING.zh-hans.md)

## 📄 开源许可协议

本项目基于 Apache License 2.0 协议开源，详情请参阅 [LICENSE](../LICENSE) 文件。

## 🔗 相关链接

- [**Flutter 封装层**](https://github.com/MollySophia/rwkv_mobile_flutter)
- [**C++ 推理引擎**](https://github.com/MollySophia/rwkv-mobile)
- [**可用模型下载**](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)
- [**训练您自己的模型？**](https://github.com/RWKV-Vibe/RWKV-LM-V7)
- [**什么是 RWKV？**](https://rwkv.cn/)
