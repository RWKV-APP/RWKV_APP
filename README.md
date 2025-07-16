# RWKV App ✨

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![English](https://img.shields.io/badge/README-English-blue.svg)](./README.md)
[![Chinese](https://img.shields.io/badge/README-中文-blue.svg)](./README.zh.md)

**Explore and experience running Large Language Models offline on your edge devices with the RWKV App.**

RWKV App is an experimental application that brings Large Language Models (LLMs) directly to your Android/iOS devices. You can experiment with different models, engage in chats, generate speech, perform visual understanding, and more! All computations are performed locally, and no internet connection is required after loading the model.

**Overview**

The RWKV App supports multi-turn conversations, text-to-speech, visual understanding, and various other tasks.

![RWKV App Screenshot](.github/images/readme/gallery.png)

## ✨ Core Features

- **📱 Run Locally, Fully Offline:** Experience the magic of generative AI without an internet connection. All processing is done directly on your device.
- **🤖 Switch Models Freely:** Easily download and switch between different models from Hugging Face to compare their performance.
- **💬 AI Chat:** Engage in fluent multi-turn conversations.
- **🔊 Text-to-Speech (TTS):** Convert text into natural-sounding speech.
- **🖼️ Visual Understanding:** Explore image-based AI use cases.
- **🌓 Dark Mode:** Supports comfortable use in various lighting conditions.

## 🧭 Download and Experience

### Downloads

<table>
<thead>
<tr>
<th style="text-align: center;"></th>
<th style="text-align: center;">RWKV Chat</th>
<th style="text-align: center;">RWKV See</th>
<th style="text-align: center;">RWKV Talk</th>
<th style="text-align: center;">RWKV Sudoku</th>
<th style="text-align: center;">RWKV Othello</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: center;">Android APK Download Link</td>
<td style="text-align: center;"><a href="https://huggingface.co/datasets/rwkv-app/RWKV-Chat/tree/main">huggingface</a> / <a href="https://www.pgyer.com/rwkvchat">pgyer</a></td>
<td style="text-align: center;"><a href="https://huggingface.co/datasets/rwkv-app/RWKV-See/tree/main">huggingface</a> / <a href="https://www.pgyer.com/rwkv-see">pgyer</a></td>
<td style="text-align: center;"><a href="https://huggingface.co/datasets/rwkv-app/RWKV-Talk/tree/main">huggingface</a> / <a href="https://www.pgyer.com/rwkv-see">pgyer</a></td>
<td style="text-align: center;"><a href="https://huggingface.co/datasets/rwkv-app/RWKV-Sudoku/tree/main">huggingface</a> / <a href="https://www.pgyer.com/rwkv-sudoku">pgyer</a></td>
<td style="text-align: center;"><a href="https://huggingface.co/datasets/rwkv-app/RWKV-Othello/tree/main">huggingface</a> / <a href="https://www.pgyer.com/rwkv-othello">pgyer</a></td>
</tr>
<tr>
<td style="text-align: center;">iOS</td>
<td style="text-align: center;"><a href="https://testflight.apple.com/join/DaMqCNKh">testflight</a></td>
<td style="text-align: center;"><a href="https://testflight.apple.com/join/vAjawMJc">testflight</a></td>
<td style="text-align: center;"><a href="https://testflight.apple.com/join/mfsdWS4b">testflight</a></td>
<td style="text-align: center;">-</td>
<td style="text-align: center;"><a href="https://testflight.apple.com/join/f5SVf76c">testflight</a></td>
</tr>
<tr>
<td style="text-align: center;" rowspan="2">Windows</td>
<td style="text-align: center;" colspan="5" rowspan="2"><a href="https://qm.qq.com/q/y0gOHcguty">QQ Group</a> / <a href="https://discord.gg/8NvyXcAP5W">Discord</a></td>
</tr>
<tr></tr>
<tr>
<td style="text-align: center;" rowspan="2">macOS</td>
<td style="text-align: center;" colspan="5" rowspan="2"><a href="https://qm.qq.com/q/y0gOHcguty">QQ Group</a> / <a href="https://discord.gg/8NvyXcAP5W">Discord</a></td>
</tr>
<tr></tr>
</tbody>
</table>

> [!NOTE]
> In the future, we will integrate all separate features into the RWKV Chat app to provide a unified experience.

### Usage

When you first open the app, a model selection panel will appear. Please choose the model weights you want to use based on your needs.

> [!WARNING]
> Devices older than the iPhone 14 may not be able to smoothly run models with 1.5B / 2.9B parameters.

## 💻 Development

1. **Clone the repository:**

```bash
git clone https://github.com/MollySophia/rwkv_mobile_flutter.git
# Make sure the rwkv_mobile_flutter and RWKV_APP are in the same directory
git clone https://github.com/RWKV-APP/RWKV_APP.git
cd RWKV_APP
```

2. **Install dependencies:**

```bash
flutter pub get
```

3. **Run the application:**

```bash
flutter run
```

## 🛠️ Technical Highlights

- **Flutter:** An open-source framework for building cross-platform user interfaces, supporting Android, iOS, Windows, and macOS.
- **Dart FFI (Foreign Function Interface):** Used for efficient communication between Dart and the C++ inference engine.
- **C++ Inference Engine:** The core on-device inference engine, built with C++, supporting multiple model formats and hardware acceleration (CPU/GPU/NPU).
- **Hugging Face:** An open-source community providing models, datasets, and tools; used here as the source for model weights.

## 🗺️ Roadmap

- [ ] UI Refactoring
- [ ] Integrate all features into the RWKV Chat app
- [ ] Support more model weights
- [ ] Support more hardware
- [ ] Support more operating systems
- [ ] Support more devices (e.g., watches, VR glasses)

## 🤝 Feedback and Contribution

This is an **experimental early-stage version**, and your feedback is crucial to us!

- 🐞 **Found a bug or issue?** [Report it here!](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=bug&template=bug_report.md&title=%5BBUG%5D)
- 💡 **Have a suggestion?** [Suggest a feature!](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5BFEATURE%5D)

## 📄 License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

## 🔗 Related Links

- [**Flutter Wrapper**](https://github.com/MollySophia/rwkv_mobile_flutter)
- [**C++ Inference Engine**](https://github.com/MollySophia/rwkv-mobile)
- [**Available Models**](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)
- [**Want to Train Your Own Model?**](https://github.com/RWKV-Vibe/RWKV-LM-V7)
- [**What is RWKV?**](https://rwkv.cn/)
