# RWKV App ✨

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![English](https://img.shields.io/badge/README-English-blue.svg)](./README.md)
[![Simplified Chinese](https://img.shields.io/badge/README-简体中文-blue.svg)](./README.zh-hans.md)
[![Traditional Chinese](https://img.shields.io/badge/README-繁體中文-blue.svg)](./README.zh-hant.md)
[![Japanese](https://img.shields.io/badge/README-日本語-blue.svg)](./README.ja.md)
[![Korean](https://img.shields.io/badge/README-한국어-blue.svg)](./README.ko.md)
[![Russian](https://img.shields.io/badge/README-Русский-blue.svg)](./README.ru.md)

**RWKV App を使って、エッジデバイス上で大規模言語モデル（LLM）をオフラインで探索・体験しましょう。**
**プライバシー重視で、日常のデバイス向けに完全オンデバイスで動く LLM 体験。**

RWKV App は、Android/iOS デバイスに大規模言語モデル（LLM）を直接導入する実験的なアプリケーションです。さまざまなモデルを試したり、チャットを楽しんだり、音声を生成したり、視覚理解を行ったりすることができます！すべての計算はローカルで行われ、モデルのロード後はインターネット接続は必要ありません。

**概要**

RWKV App は、マルチターン会話、テキスト読み上げ（TTS）、視覚理解、その他さまざまなタスクをサポートしています。

![RWKV App Screenshot](.github/images/readme/gallery.png)

## ✨ 主な機能

- **📱 ローカルで実行、完全オフライン:** インターネット接続なしで生成 AI の魔法を体験できます。すべての処理はデバイス上で直接行われます。
- **🤖 モデルを自由に切り替え:** Hugging Face からさまざまなモデルを簡単にダウンロードして切り替え、パフォーマンスを比較できます。
- **💬 AI チャット:** 流暢なマルチターン会話を楽しめます。
- **🔊 テキスト読み上げ (TTS):** テキストを自然な音声に変換します。
- **🖼️ 視覚理解:** 画像ベースの AI ユースケースを探索できます。
- **🌓 ダークモード:** さまざまな照明条件下でも快適に使用できるようサポートします。

## 🧭 ダウンロードと体験

### ダウンロード

**公式ダウンロードページ：[https://rwkv.halowang.cloud/](https://rwkv.halowang.cloud/)**

<table>
<thead>
<tr>
<th style="text-align: center;"></th>
<th style="text-align: center;">RWKV Chat (with See and Talk)</th>
<th style="text-align: center;">RWKV Sudoku</th>
<th style="text-align: center;">RWKV Othello</th>
<th style="text-align: center;">RWKV Music (別リポジトリ)</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: center;">Android APK ダウンロードリンク</td>
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
> 将来的には、すべての機能を RWKV Chat アプリに統合し、統一された体験を提供する予定です。

### 使い方

アプリを初めて開くと、モデル選択パネルが表示されます。ニーズに合わせて使用したいモデルの重みを選択してください。

> [!WARNING]
> iPhone 14 より古いデバイスでは、1.5B / 2.9B パラメータのモデルをスムーズに実行できない場合があります。

## 💻 開発

**[Flutter](https://flutter.dev/)開発環境がセットアップされていることを確認してください。**

1. **リポジトリをクローン:**

```bash
# 必ず 'dev' ブランチに切り替えてください
git clone -b dev https://github.com/MollySophia/rwkv_mobile_flutter.git
# rwkv_mobile_flutter と RWKV_APP が同じディレクトリにあることを確認してください
git clone -b dev https://github.com/RWKV-APP/RWKV_APP.git
cd RWKV_APP
```

2. **必要な設定ファイルを作成:**

```bash
touch assets/filter.txt;touch .env;
```

3. **依存関係をインストール:**

```bash
flutter pub get
```

4. **（任意）`tools` ディレクトリの依存関係をインストール:**

*この手順を実行すると、VS Code や Cursor でアプリを実行した際に「プロジェクトにエラーが存在します」という警告を避けられます。*

```bash
cd tools; flutter pub get; cd ..;
```

5. **アプリケーションを実行:**

```bash
flutter run
```

## 🛠️ 技術的ハイライト

- **Flutter:** Android、iOS、Windows、macOS をサポートする、クロスプラットフォームのユーザーインターフェースを構築するためのオープンソースフレームワーク。
- **Dart FFI (Foreign Function Interface):** Dart と C++ 推論エンジン間の効率的な通信に使用されます。
- **C++ 推論エンジン:** デバイス上の推論エンジンのコアで、C++ で構築されており、複数のモデル形式とハードウェアアクセラレーション（CPU/GPU/NPU）をサポートしています。
- **Hugging Face:** モデル、データセット、ツールを提供するオープンソースコミュニティ。ここではモデルの重みのソースとして使用されています。

## 🗺️ ロードマップ

- [x] すべての機能を RWKV Chat アプリに統合する
- [ ] より多くのモデルの重みをサポートする
- [ ] より多くのハードウェアをサポートする
- [ ] より多くのオペレーティングシステムをサポートする
- [ ] より多くのデバイス（時計、VR グラスなど）をサポートする

## 🤝 フィードバックと貢献

これは **実験的な初期段階のバージョン** であり、あなたのフィードバックは私たちにとって非常に重要です！

- 🐞 **バグや問題を見つけましたか？** [ここで報告してください！](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=bug&template=bug_report.md&title=%5BBUG%5D)
- 💡 **提案がありますか？** [機能を提案してください！](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5BFEATURE%5D)

## 📄 ライセンス

このプロジェクトは Apache License 2.0 の下でライセンスされています。詳細については [LICENSE](LICENSE) ファイルを参照してください。

## 🔗 関連リンク

- [**Flutter Wrapper**](https://github.com/MollySophia/rwkv_mobile_flutter)
- [**C++ 推論エンジン**](https://github.com/MollySophia/rwkv-mobile)
- [**利用可能なモデル**](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)
- [**独自のモデルをトレーニングしたいですか？**](https://github.com/RWKV-Vibe/RWKV-LM-V7)
- [**RWKV とは？**](https://rwkv.cn/)
