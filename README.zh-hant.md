# RWKV App ✨

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![English](https://img.shields.io/badge/README-English-blue.svg)](./README.md)
[![Simplified Chinese](https://img.shields.io/badge/README-简体中文-blue.svg)](./README.zh-hans.md)
[![Traditional Chinese](https://img.shields.io/badge/README-繁體中文-blue.svg)](./README.zh-hant.md)
[![Japanese](https://img.shields.io/badge/README-日本語-blue.svg)](./README.ja.md)
[![Korean](https://img.shields.io/badge/README-한국어-blue.svg)](./README.ko.md)
[![Russian](https://img.shields.io/badge/README-Русский-blue.svg)](./README.ru.md)

**透過 RWKV App，探索、體驗在端側設備上離線運行大語言模型**
**面向日常設備的隱私優先、完全端側的 LLM 體驗。**

RWKV App 是一款實驗性的應用程式，它將大語言模型（LLM）直接帶到您的 Android / iOS 設備上。您可以盡情試驗不同的模型、進行聊天、生成語音、視覺理解等等！所有計算都在本地進行，加載模型後無需網絡連接。

**概述**

RWKV App 支持多輪對話、文本轉語音、視覺理解等多種任務。

![RWKV App Screenshot](.github/images/readme/gallery.png)

## ✨ 核心功能

- **📱 本地運行，完全離線：** 無需互聯網連接，即可體驗生成式 AI 的魅力。所有計算都直接在您的設備上完成。
- **🤖 隨心切換模型：** 從 Hugging Face 輕鬆下載並切換不同的模型，比較它們的性能。
- **💬 AI 聊天：** 進行流暢的多輪對話。
- **🔊 文本轉語音 (TTS)：** 將文本轉換成自然流暢的語音。
- **🖼️ 視覺理解：** 探索基於圖像的 AI 應用場景。
- **🌓 深色模式：** 支持在不同光線環境下舒適使用。

## 🧭 下載與體驗

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

### 使用

首次打開 App 時，會彈出模型選擇面板。請根據您的需求選擇要使用的模型權重。

> [!WARNING]
> iPhone 14 及更早的設備可能無法流暢運行 1.5B / 2.9B 參數規模的模型。

## 💻 開發

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

## 🛠️ 技術亮點

- **Flutter：** 一款用於構建跨平台用戶界面的開源框架，支持安卓、iOS、Windows 和 macOS。
- **Dart FFI (外部函數接口)：** 用於 Dart 語言與 C++ 推理引擎進行高效通信。
- **C++ 推理引擎：** 項目核心的設備端推理引擎，使用 C++ 構建，支持多種模型格式和硬件加速（CPU/GPU/NPU）。
- **Hugging Face：** 一個提供模型、數據集和工具的開源社區，本項目用其作為模型權重的來源。

## 🗺️ 路線圖 (Roadmap)

- [x] 將所有功能整合至 RWKV 聊天應用
- [ ] 支持更多模型權重
- [ ] 適配更多硬件
- [ ] 適配更多操作系統
- [ ] 支持手錶、VR 眼鏡等更多設備形態

## 🤝 反饋與貢獻

這是一個**實驗性的早期測試版本**，您的反饋對我們至關重要！

- 🐞 **發現錯誤或問題？** [在此報告！](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=bug&template=bug_report.md&title=%5BBUG%5D)
- 💡 **想提出建議？** [建議一項功能！](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5BFEATURE%5D)
- 🎨 **想貢獻自訂主題？** [Theme 快速開始](CONTRIBUTING.zh-hant.md)

## 📄 開源許可協議

本項目基於 Apache License 2.0 協議開源，詳情請參閱 [LICENSE](LICENSE) 文件。

## 🔗 相關鏈接

- [**Flutter 封裝層**](https://github.com/MollySophia/rwkv_mobile_flutter)
- [**C++ 推理引擎**](https://github.com/MollySophia/rwkv-mobile)
- [**可用模型下載**](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)
- [**訓練您自己的模型？**](https://github.com/RWKV-Vibe/RWKV-LM-V7)
- [**什麼是 RWKV？**](https://rwkv.cn/)
