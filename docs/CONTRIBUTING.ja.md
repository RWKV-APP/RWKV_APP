# コントリビューションガイド: Theme クイックスタート

[![English](https://img.shields.io/badge/CONTRIBUTING-English-blue.svg)](../CONTRIBUTING.md)
[![Simplified Chinese](https://img.shields.io/badge/CONTRIBUTING-简体中文-blue.svg)](./CONTRIBUTING.zh-hans.md)
[![Traditional Chinese](https://img.shields.io/badge/CONTRIBUTING-繁體中文-blue.svg)](./CONTRIBUTING.zh-hant.md)
[![Korean](https://img.shields.io/badge/CONTRIBUTING-한국어-blue.svg)](./CONTRIBUTING.ko.md)
[![Russian](https://img.shields.io/badge/CONTRIBUTING-Русский-blue.svg)](./CONTRIBUTING.ru.md)

このガイドは、主にアプリの配色テーマを変更する PR を出したい外部コントリビューター向けです。

## 1. `lib/model/app_theme.dart` にテーマを追加

1. 既存テーマ（通常は `.dim` または `.lightsOut`）をコピーし、例えば `.myTheme` に名前を変更します。
2. 必須の色フィールド（`primary`、`themePrimary`、`qb*`、`g*`、入力欄/メッセージ色など）をすべて設定します。
3. `isLight` を正しく設定します（ライトテーマは `true`、ダークテーマは `false`）。
4. `displayName` に新しい分岐を追加します。
5. 永続化互換のため、`fromString` と `toString` も更新します。

## 2. `lib/widgets/theme_selector.dart` でテーマを選択可能にする

1. `items` リストに新しい `FormItem` を追加します。
2. `_onDimPressed` / `_onLightsOutPressed` と同様のハンドラーを追加します。
   - `P.preference.preferredDarkCustomTheme.q` を更新
   - `halo_state.preferredDarkCustomTheme` を保存
3. 選択状態の表示は `preferredDarkCustomTheme == .yourTheme` を再利用します。

注意: 現在の構成は「ライトテーマ 1 つ + ダークテーマ複数」です。ライトテーマを追加する場合は `lib/store/app.dart` の同期ロジックも調整してください。

## 3. `Args.debuggingThemes` の役割

- 起動引数: `--dart-define=debuggingThemes=true`
- デバッグ時の動作: アプリが 1 秒ごとに `.light` と現在のダーク設定（`preferredDarkCustomTheme`）を切り替えます。
- 用途: 同じ画面で明暗テーマのコントラスト、可読性、適用漏れを素早く確認できます。

## 4. `.vscode/launch.json` でデスクトップとモバイル UI を同時起動

1. プラットフォーム別の launch 設定（例: macOS / Android / iOS）を用意します。
2. `compounds` でそれらをまとめます（例: `all (Halo)`）。
3. compound 設定を実行し、複数プラットフォーム UI を並行起動します。

任意: 対象設定に `--dart-define=debuggingThemes=true` を追加すると、自動明暗切り替えで確認できます。
