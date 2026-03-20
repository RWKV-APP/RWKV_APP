# RWKV App ✨

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](../LICENSE)
[![English](https://img.shields.io/badge/README-English-blue.svg)](../README.md)
[![Simplified Chinese](https://img.shields.io/badge/README-简体中文-blue.svg)](./README.zh-hans.md)
[![Traditional Chinese](https://img.shields.io/badge/README-繁體中文-blue.svg)](./README.zh-hant.md)
[![Korean](https://img.shields.io/badge/README-한국어-blue.svg)](./README.ko.md)
[![Russian](https://img.shields.io/badge/README-Русский-blue.svg)](./README.ru.md)

**スマートフォンとデスクトップで、プライベートなオンデバイス AI を動かす。**
**チャット、音声、視覚、モデル検証のためのローカルファーストな AI プレイグラウンド。**

RWKV App は、Android、iOS、Windows、macOS、Linux 向けのプライバシー重視 AI アプリです。ローカルモデルを実機でダウンロード・切り替え・比較し、クラウドに依存せず AI 体験を試作できます。モデルを読み込んだ後の推論はデバイス上に留まります。

## なぜ RWKV App なのか

- **実機のエッジデバイス向け：** クラウド中心のデモではなく、スマートフォンやデスクトップ上でローカルモデルを評価できます。
- **1つのアプリで複数の AI ワークフロー：** チャット、テキスト読み上げ、視覚理解をまとめて扱えます。
- **モデル比較が速い：** Hugging Face からモデルをダウンロードして切り替え、品質・速度・ハードウェア適性を見比べられます。
- **プライバシー重視：** モデル読み込み後のプロンプト、出力、推論はデバイス内に留まります。

![RWKV App Screenshot](../.github/images/readme/gallery.png)

## ✨ 主な機能

- **📱 クロスプラットフォーム、ローカルファースト:** Android、iOS、Windows、macOS、Linux でオンデバイス推論を実行できます。
- **🤖 柔軟なモデル切り替え:** Hugging Face からさまざまなモデルをダウンロードして比較できます。
- **💬 AI チャット:** 実機上で自然なマルチターン会話を試せます。
- **🔊 テキスト読み上げ (TTS):** テキストを自然な音声に変換します。
- **🖼️ 視覚理解:** 画像ベースの AI ユースケースを探索できます。
- **🔌 任意のローカル API アクセス:** デスクトップでは、ツール連携や実験向けに OpenAI 互換のローカルエンドポイントを公開できます。
- **🌓 ダークモード:** 長時間の利用でも快適に使えます。

## 🚀 クイックスタート

1. 公式ダウンロードページ、または以下のプラットフォーム別リンクから RWKV App を入手します。
2. アプリを開き、デバイスに合ったチャットモデルを読み込みます。
3. チャット、音声、視覚のワークフローを試します。デスクトップでは、必要に応じて内蔵のローカル API エンドポイントも有効化できます。

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

### 初回起動

アプリを初めて開くと、モデル選択パネルが表示されます。ニーズに合わせて使用したいモデルの重みを選択してください。

> [!WARNING]
> iPhone 14 より古いデバイスでは、1.5B / 2.9B パラメータのモデルをスムーズに実行できない場合があります。

## 💻 ソースからビルド

**[Flutter](https://flutter.dev/)開発環境がセットアップされていることを確認してください。**

> 開発環境では **Flutter 3.41.1+** が必要です（stable channel 推奨）。

1. **リポジトリをクローン:**

```bash
# 必ず 'dev' ブランチに切り替えてください
git clone -b dev https://github.com/MollySophia/rwkv_mobile_flutter.git
# rwkv_mobile_flutter と RWKV_APP が同じディレクトリにあることを確認してください
git clone -b dev https://github.com/RWKV-APP/RWKV_APP.git
cd RWKV_APP
```

ディレクトリ構成は次のようになります。

```text
parent/
├─ rwkv_mobile_flutter/
└─ RWKV_APP/
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

_この手順を実行すると、VS Code や Cursor でアプリを実行した際に「プロジェクトにエラーが存在します」という警告を避けられます。_

```bash
cd tools; flutter pub get; cd ..;
```

5. **アプリケーションを実行:**

```bash
flutter run
```

#### Windows ARM64 デバッグ（QNN）

Windows ARM64 でデバッグする場合は、`pubspec.yaml` の次の設定をアンコメントしてください。

```yaml
- path: assets/lib/qnn-windows/
  platforms: [windows]
```

Windows ARM64 でデバッグする場合は、Flutter の `stable` ブランチではなく `master` ブランチを使用してください。

## 🏗️ スタック

- **Flutter:** Android、iOS、Windows、macOS をサポートする、クロスプラットフォームのユーザーインターフェースを構築するためのオープンソースフレームワーク。
- **Dart FFI (Foreign Function Interface):** Dart と C++ 推論エンジン間の効率的な通信に使用されます。
- **C++ 推論エンジン:** デバイス上の推論エンジンのコアで、C++ で構築されており、複数のモデル形式とハードウェアアクセラレーション（CPU/GPU/NPU）をサポートしています。
- **Hugging Face:** モデル、データセット、ツールを提供するオープンソースコミュニティ。ここではモデルの重みのソースとして使用されています。

## 🤝 フィードバックと貢献

これは **実験的な初期段階のバージョン** であり、あなたのフィードバックは私たちにとって非常に重要です！

- 🐞 **バグや問題を見つけましたか？** [ここで報告してください！](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=bug&template=bug_report.md&title=%5BBUG%5D)
- 💡 **提案がありますか？** [機能を提案してください！](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5BFEATURE%5D)
- 🎨 **カスタムテーマを貢献したいですか？** [Theme クイックスタート](./CONTRIBUTING.ja.md)

## 📄 ライセンス

このプロジェクトは Apache License 2.0 の下でライセンスされています。詳細については [LICENSE](../LICENSE) ファイルを参照してください。

## 🔗 関連リンク

- [**Flutter Wrapper**](https://github.com/MollySophia/rwkv_mobile_flutter)
- [**C++ 推論エンジン**](https://github.com/MollySophia/rwkv-mobile)
- [**利用可能なモデル**](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)
- [**独自のモデルをトレーニングしたいですか？**](https://github.com/RWKV-Vibe/RWKV-LM-V7)
- [**RWKV とは？**](https://rwkv.cn/)
