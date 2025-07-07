# RWKV App

[English](./README.md) | [中文](./README.zh.md)

This is a cross-platform mobile application for RWKV-LM, built with Flutter. It allows for on-device inference of the RWKV language model.

## Features

- **Cross-Platform:** Works on both Android and iOS.
- **On-Device Inference:** All computations are done locally on your device.
- **Modular Design:** Easily switch between different RWKV models (Chat, TTS, Visual Understanding, Othello, Sudoku).
- **Open Source:** The entire project is open source and available on GitHub.

## Architecture

- **Frontend (Flutter):** [rwkv_mobile_flutter](https://github.com/MollySophia/rwkv_mobile_flutter)
- **Backend (Dart FFI):** [rwkv_mobile_flutter](https://github.com/MollySophia/rwkv_mobile_flutter)
- **Models:** [mollysama/rwkv-mobile-models](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)

## Getting Started

## Development

### Prerequisites

- **Flutter:** Ensure you have Flutter installed and configured. See the [official documentation](https://flutter.dev/docs/get-started/install) for instructions.
- **Environment Setup:**
  - Obtain the `.env` file from the developers and place its contents in the `.env` directory.
  - Obtain the `assets/filter.txt` file from the developers and place it in the `assets/` directory.
  - Obtain the `assets/model` folder from the developers and place it in the `assets/` directory.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/MollySophia/rwkv_mobile_flutter.git
    cd rwkv_mobile_flutter
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

### Switching Environments

Use the following `fastlane` commands to switch between different app environments:

- **RWKV Chat:** `fastlane switch_env env:chat`
- **RWKV Talk (TTS):** `fastlane switch_env env:tts`
- **RWKV See (World):** `fastlane switch_env env:world`
- **RWKV Othello:** `fastlane switch_env env:othello`
- **RWKV Sudoku:** `fastlane switch_env env:sudoku`

### Running the App

- **VS Code / Cursor:** Launch the "Debug: Start Debugging" command (`workbench.action.debug.start`).
- **Command Line:**
  ```bash
  flutter run
  ```

## Chat Page Logic

### Key Files

- **UI:** `lib/page/chat.dart`
- **Message UI:** `lib/widgets/chat/message.dart`
- **State Management:** `lib/state/chat.dart`
- **Data Model:** `lib/model/message.dart`
- **Backend Communication:** `RWKV`

### Business Logic

- The chat interface uses a `ListView.separated` with `reverse = true` to display messages.
- The data source for the message list is `late final messages = qs<List<Message>>([]);`.
- The `P.chat.send` method handles sending messages. It first sends the user's message and updates the state, then sends a bot message and updates the state. Finally, it sends the message to the backend and periodically receives newly generated strings.
- When a new string is received from the backend, the bot's message state is updated, triggering a UI refresh.

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project is licensed under the [LICENSE](LICENSE) file.
