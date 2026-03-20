# RWKV App ✨

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](../LICENSE)
[![English](https://img.shields.io/badge/README-English-blue.svg)](../README.md)
[![Simplified Chinese](https://img.shields.io/badge/README-简体中文-blue.svg)](./README.zh-hans.md)
[![Japanese](https://img.shields.io/badge/README-日本語-blue.svg)](./README.ja.md)
[![Korean](https://img.shields.io/badge/README-한국어-blue.svg)](./README.ko.md)
[![Russian](https://img.shields.io/badge/README-Русский-blue.svg)](./README.ru.md)

**在手機與桌面設備上運行私有、端側 AI。**
**一個面向聊天、語音、視覺與模型實驗的本機優先 AI Playground。**

RWKV App 是一款面向 Android、iOS、Windows、macOS 和 Linux 的隱私優先 AI 應用。您可以在真實硬體上下載、切換並比較本機模型，體驗聊天、語音和視覺等能力，而無需依賴雲端推理。模型載入完成後，推理會留在您的設備上。

## 為什麼選擇 RWKV App

- **面向真實邊緣設備：** 在手機與桌面設備上驗證本機模型，而不是只在雲端 Demo 裡體驗。
- **一個 App，覆蓋多種 AI 工作流程：** 將聊天、文本轉語音和視覺理解放在同一處。
- **更快地比較模型：** 從 Hugging Face 下載並切換不同模型，直觀比較品質、速度與硬體適配。
- **隱私優先：** 模型載入完成後，提示詞、輸出和推理過程都留在本地。

![RWKV App Screenshot](../.github/images/readme/gallery.png)

## ✨ 核心功能

- **📱 跨平台，本機優先：** 在 Android、iOS、Windows、macOS 和 Linux 上運行端側推理。
- **🤖 靈活切換模型：** 從 Hugging Face 下載並比較不同模型。
- **💬 AI 聊天：** 在真實硬體上體驗流暢的多輪對話。
- **🔊 文本轉語音 (TTS)：** 將文本轉換成自然流暢的語音。
- **🖼️ 視覺理解：** 探索基於圖像的 AI 應用場景。
- **🔌 可選的本機 API 介面：** 在桌面端，您可以暴露 OpenAI 相容的本機介面，用於工具整合和實驗。
- **🌓 深色模式：** 讓長時間使用更舒適。

## 🚀 快速開始

1. 從官方下載頁面或下方的平台鏈接下載安裝包。
2. 打開 App，載入適合您設備的聊天模型。
3. 開始體驗聊天、語音或視覺工作流程；如果您在桌面端有整合需求，也可以啟用內建本機 API 介面。

### 下載

**官方下載頁面：[https://rwkv.halowang.cloud/](https://rwkv.halowang.cloud/)**

<table>
<thead>
<tr>
<th style="text-align: center;"></th>
<th style="text-align: center;">RWKV Chat (with See and Talk)</th>
<th style="text-align: center;">RWKV Sudoku</th>
<th style="text-align: center;">RWKV Othello</th>
<th style="text-align: center;">RWKV Music (另一個倉庫)</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: center;">Android APK 下載鏈接</td>
<td style="text-align: center;"><a href="https://play.google.com/store/apps/details?id=com.rwkvzone.chat">Google Play</a> / <a href="https://github.com/RWKV-APP/RWKV_APP/releases">GitHub Release</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/android-arm64">huggingface</a> / <a href="https://www.pgyer.com/rwkvchat">蒲公英</a></td>
<td style="text-align: center;"><a href="https://huggingface.co/datasets/rwkv-app/RWKV-Sudoku/tree/main">huggingface</a> / <a href="https://www.pgyer.com/rwkv-sudoku">蒲公英</a></td>
<td style="text-align: center;"><a href="https://huggingface.co/datasets/rwkv-app/RWKV-Othello/tree/main">huggingface</a> / <a href="https://www.pgyer.com/rwkv-othello">蒲公英</a></td>
<td style="text-align: center;"><a href="https://www.pgyer.com/rwkv-music">蒲公英</a></td>
</tr>
<tr>
<td style="text-align: center;">iOS</td>
<td style="text-align: center;"><a href="https://apps.apple.com/us/app/rwkv-chat/id6740192639">App Store</a> / <a href="https://testflight.apple.com/join/DaMqCNKh">testflight</a></td>
<td style="text-align: center;">-</td>
<td style="text-align: center;"><a href="https://testflight.apple.com/join/f5SVf76c">testflight</a></td>
<td style="text-align: center;">-</td>
</tr>
<tr>
<td style="text-align: center;" rowspan="2">Windows</td>
<td style="text-align: center;" colspan="3" rowspan="2"><a href="https://github.com/RWKV-APP/RWKV_APP/releases">GitHub Release</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/windows-x64">huggingface (zip)</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/windows-x64-installer">huggingface (installer)</a> / <a href="https://qm.qq.com/q/y0gOHcguty">QQ 群</a> / <a href="https://discord.gg/8NvyXcAP5W">Discord</a></td>
<td style="text-align: center;" colspan="1" ><a href="https://apps.microsoft.com/detail/xpdc65wjh8ws17?hl=en-US&gl=US">Microsoft Store</a></td>
</tr>
<tr></tr>
<tr>
<td style="text-align: center;" rowspan="2">macOS</td>
<td style="text-align: center;" colspan="3" rowspan="2"><a href="https://github.com/RWKV-APP/RWKV_APP/releases">GitHub Release</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/macos-universal">huggingface</a> / <a href="https://qm.qq.com/q/y0gOHcguty">QQ 群</a> / <a href="https://discord.gg/8NvyXcAP5W">Discord</a></td>
<td style="text-align: center;">-</td>
</tr>
<tr></tr>
<tr>
<td style="text-align: center;">Linux</td>
<td style="text-align: center;"><a href="https://github.com/RWKV-APP/RWKV_APP/releases">GitHub Release</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/linux-x64">huggingface</a></td>
<td style="text-align: center;">-</td>
<td style="text-align: center;">-</td>
<td style="text-align: center;">-</td>
</tr>
</tbody>
</table>

> [!NOTE]
> 未來，我們會將所有獨立功能整合進 RWKV Chat 應用中，為您提供統一的體驗。

### 首次使用

首次打開 App 時，會彈出模型選擇面板。請根據您的需求選擇要使用的模型權重。

> [!WARNING]
> iPhone 14 及更早的設備可能無法流暢運行 1.5B / 2.9B 參數規模的模型。

## 💻 從原始碼構建

**請確保您已搭建好 [Flutter](https://flutter.dev/) 開發環境。**

> 開發環境要求 **Flutter 3.41.1+**（建議使用 stable channel）。

1. **克隆倉庫：**

```bash
# 必須切換到 'dev' 分支
git clone -b dev https://github.com/MollySophia/rwkv_mobile_flutter.git
# 確保 rwkv_mobile_flutter 和 RWKV_APP 在同一目錄下
git clone -b dev https://github.com/RWKV-APP/RWKV_APP.git
cd RWKV_APP
```

目錄結構應如下所示：

```text
parent/
├─ rwkv_mobile_flutter/
└─ RWKV_APP/
```

2. **創建必要的配置文件：**

```bash
touch assets/filter.txt;touch .env;
```

3. **安裝依賴：**

```bash
flutter pub get
```

4. **（可選）為 `tools` 目錄安裝依賴：**

_執行此步驟可避免在 VS Code 或 Cursor 中運行應用時出現「您的專案中存在錯誤」的提示。_

```bash
cd tools; flutter pub get; cd ..;
```

5. **運行應用：**

```bash
flutter run
```

#### Windows ARM64 偵錯（QNN）

如果您在 Windows ARM64 上偵錯，請在 `pubspec.yaml` 中取消以下配置的註解：

```yaml
- path: assets/lib/qnn-windows/
  platforms: [windows]
```

在 Windows ARM64 上偵錯時，請使用 Flutter 的 `master` 分支，而不是 `stable` 分支。

## 🏗️ 技術棧

- **Flutter：** 一款用於構建跨平台用戶界面的開源框架，支持安卓、iOS、Windows 和 macOS。
- **Dart FFI (外部函數接口)：** 用於 Dart 語言與 C++ 推理引擎進行高效通信。
- **C++ 推理引擎：** 項目核心的設備端推理引擎，使用 C++ 構建，支持多種模型格式和硬件加速（CPU/GPU/NPU）。
- **Hugging Face：** 一個提供模型、數據集和工具的開源社區，本項目用其作為模型權重的來源。

## 🤝 反饋與貢獻

這是一個**實驗性的早期測試版本**，您的反饋對我們至關重要！

- 🐞 **發現錯誤或問題？** [在此報告！](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=bug&template=bug_report.md&title=%5BBUG%5D)
- 💡 **想提出建議？** [建議一項功能！](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5BFEATURE%5D)
- 🎨 **想貢獻自訂主題？** [Theme 快速開始](./CONTRIBUTING.zh-hant.md)

## 📄 開源許可協議

本項目基於 Apache License 2.0 協議開源，詳情請參閱 [LICENSE](../LICENSE) 文件。

## 🔗 相關鏈接

- [**Flutter 封裝層**](https://github.com/MollySophia/rwkv_mobile_flutter)
- [**C++ 推理引擎**](https://github.com/MollySophia/rwkv-mobile)
- [**可用模型下載**](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)
- [**訓練您自己的模型？**](https://github.com/RWKV-Vibe/RWKV-LM-V7)
- [**什麼是 RWKV？**](https://rwkv.cn/)
