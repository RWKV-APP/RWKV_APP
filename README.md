# RWKV App ✨

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Simplified Chinese](https://img.shields.io/badge/README-简体中文-blue.svg)](./docs/README.zh-hans.md)
[![Traditional Chinese](https://img.shields.io/badge/README-繁體中文-blue.svg)](./docs/README.zh-hant.md)
[![Japanese](https://img.shields.io/badge/README-日本語-blue.svg)](./docs/README.ja.md)
[![Korean](https://img.shields.io/badge/README-한국어-blue.svg)](./docs/README.ko.md)
[![Russian](https://img.shields.io/badge/README-Русский-blue.svg)](./docs/README.ru.md)

**Run private, on-device AI on phones and desktops with RWKV App.**
**A local-first playground for chat, speech, vision, and model experimentation.**

RWKV App is a privacy-first AI app for Android, iOS, Windows, macOS, and Linux. It lets you download local models, compare them on real hardware, and prototype AI experiences without depending on the cloud. After a model is loaded, inference stays on your device.

## Why RWKV App

- **Built for real edge devices:** Evaluate local models on phones and desktops instead of relying on cloud-only demos.
- **One app, multiple workflows:** Chat, text-to-speech, and visual understanding live in one place.
- **Fast model iteration:** Download and switch models from Hugging Face to compare quality, speed, and hardware fit.
- **Privacy first:** Keep prompts, outputs, and inference on device after the model is loaded.

![RWKV App Screenshot](.github/images/readme/gallery.png)

## ✨ Core Features

- **📱 Cross-Platform, Local-First:** Run on Android, iOS, Windows, macOS, and Linux with on-device inference.
- **🤖 Flexible Model Switching:** Download and compare different models from Hugging Face.
- **💬 AI Chat:** Explore fluent multi-turn conversations on real hardware.
- **🔊 Text-to-Speech (TTS):** Convert text into natural-sounding speech.
- **🖼️ Visual Understanding:** Explore image-based AI use cases.
- **🔌 Optional Local API Access:** On desktop, you can expose an OpenAI-compatible local endpoint for tooling and experiments.
- **🌓 Dark Mode:** Stay comfortable during long sessions.

## 🚀 Get Started

1. Download RWKV App from the official page or the platform links below.
2. Open the app and load a chat model that fits your device.
3. Start exploring chat, speech, or vision workflows. On desktop, you can also enable the built-in local API endpoint when you need it.

### Downloads

**Official Download Page: [https://rwkv.halowang.cloud/](https://rwkv.halowang.cloud/)**

<table>
<thead>
<tr>
<th style="text-align: center;"></th>
<th style="text-align: center;">RWKV Chat (with See and Talk)</th>
<th style="text-align: center;">RWKV Sudoku</th>
<th style="text-align: center;">RWKV Othello</th>
<th style="text-align: center;">RWKV Music (Another repo)</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: center;">Android APK Download Link</td>
<td style="text-align: center;"><a href="https://play.google.com/store/apps/details?id=com.rwkvzone.chat">Google Play</a> / <a href="https://github.com/RWKV-APP/RWKV_APP/releases">GitHub Release</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/android-arm64">huggingface</a> / <a href="https://www.pgyer.com/rwkvchat">pgyer</a></td>
<td style="text-align: center;"><a href="https://huggingface.co/datasets/rwkv-app/RWKV-Sudoku/tree/main">huggingface</a> / <a href="https://www.pgyer.com/rwkv-sudoku">pgyer</a></td>
<td style="text-align: center;"><a href="https://huggingface.co/datasets/rwkv-app/RWKV-Othello/tree/main">huggingface</a> / <a href="https://www.pgyer.com/rwkv-othello">pgyer</a></td>
<td style="text-align: center;"><a href="https://www.pgyer.com/rwkv-music">pgyer</a></td>
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
<td style="text-align: center;" colspan="3" rowspan="2"><a href="https://github.com/RWKV-APP/RWKV_APP/releases">GitHub Release</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/windows-x64">huggingface (zip)</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/windows-x64-installer">huggingface (installer)</a> / <a href="https://qm.qq.com/q/y0gOHcguty">QQ Group</a> / <a href="https://discord.gg/8NvyXcAP5W">Discord</a></td>
<td style="text-align: center;" colspan="1" ><a href="https://apps.microsoft.com/detail/xpdc65wjh8ws17?hl=en-US&gl=US">Microsoft Store</a></td>
</tr>
<tr></tr>
<tr>
<td style="text-align: center;" rowspan="2">macOS</td>
<td style="text-align: center;" colspan="3" rowspan="2"><a href="https://github.com/RWKV-APP/RWKV_APP/releases">GitHub Release</a> / <a href="https://huggingface.co/datasets/HaloWang/rwkv-chat/tree/main/macos-universal">huggingface</a> / <a href="https://qm.qq.com/q/y0gOHcguty">QQ Group</a> / <a href="https://discord.gg/8NvyXcAP5W">Discord</a></td>
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
> In the future, we will integrate all separate features into the RWKV Chat app to provide a unified experience.

### First Run

When you first open the app, a model selection panel will appear. Please choose the model weights you want to use based on your needs.

> [!WARNING]
> Devices older than the iPhone 14 may not be able to smoothly run models with 1.5B / 2.9B parameters.

## 💻 Build From Source

**Ensure you have the [Flutter](https://flutter.dev/) development environment set up.**

> Development requires **Flutter 3.41.1+** (stable channel recommended).

1. **Clone the repository:**

```bash
# MUST switch to the 'dev' branch
git clone -b dev https://github.com/MollySophia/rwkv_mobile_flutter.git
# Make sure the rwkv_mobile_flutter and RWKV_APP are in the same directory
git clone -b dev https://github.com/RWKV-APP/RWKV_APP.git
cd RWKV_APP
```

Project layout should look like this:

```text
parent/
├─ rwkv_mobile_flutter/
└─ RWKV_APP/
```

2. **Create necessary configuration files:**

```bash
touch assets/filter.txt;touch .env;
```

3. **Install dependencies:**

```bash
flutter pub get
```

4. **(Optional) Install dependencies for the `tools` directory:**

_Doing this avoids the “Errors exist in your project” warning in VS Code and Cursor when you run the app._

```bash
cd tools; flutter pub get; cd ..;
```

5. **Run the application:**

```bash
flutter run
```

#### Windows ARM64 Debug (QNN)

If you are debugging on Windows ARM64, uncomment the following section in `pubspec.yaml`:

```yaml
- path: assets/lib/qnn-windows/
  platforms: [windows]
```

For Windows ARM64 debugging, check out Flutter's `master` branch instead of the `stable` branch.

## 🏗️ Stack

- **Flutter:** An open-source framework for building cross-platform user interfaces, supporting Android, iOS, Windows, and macOS.
- **Dart FFI (Foreign Function Interface):** Used for efficient communication between Dart and the C++ inference engine.
- **C++ Inference Engine:** The core on-device inference engine, built with C++, supporting multiple model formats and hardware acceleration (CPU/GPU/NPU).
- **Hugging Face:** An open-source community providing models, datasets, and tools; used here as the source for model weights.

## 🤝 Feedback and Contribution

This is an **experimental early-stage version**, and your feedback is crucial to us!

- 🐞 **Found a bug or issue?** [Report it here!](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=bug&template=bug_report.md&title=%5BBUG%5D)
- 💡 **Have a suggestion?** [Suggest a feature!](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5BFEATURE%5D)
- 🎨 **Want to contribute a custom theme?** [Theme quick start](CONTRIBUTING.md)

## 📄 License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

## 🔗 Related Links

- [**Flutter Wrapper**](https://github.com/MollySophia/rwkv_mobile_flutter)
- [**C++ Inference Engine**](https://github.com/MollySophia/rwkv-mobile)
- [**Available Models**](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)
- [**Want to Train Your Own Model?**](https://github.com/RWKV-Vibe/RWKV-LM-V7)
- [**What is RWKV?**](https://rwkv.cn/)
