# Markdown 構文テスト (H1)

これは **Markdown パーサー** と **CSS スタイル** をテストするための標準テストファイルです。

## 1. テキスト書式 (Typography)

ここは通常のテキスト段落です。日英混在表示のテスト：The quick brown fox jumps over the lazy dog. 素早い茶色の狐が怠惰な犬を飛び越えた。

- **太字テキスト (Bold)** または **別の太字**
- *斜体テキスト (Italic)* または _別の斜体_
- ***太字斜体テキスト (Bold & Italic)***
- ~~取り消し線 (Strikethrough)~~
- `インラインコード (Inline Code)`
- [リンクテキスト (Link)](https://www.google.com)

## 2. 見出しレベル (Headings)

# 見出し 1 (H1, font size: {h1BaseSize} * {scale} = {h1Size})

## 見出し 2 (H2, font size: {h2BaseSize} * {scale} = {h2Size})

### 見出し 3 (H3, font size: {h3BaseSize} * {scale} = {h3Size})

#### 見出し 4 (H4, font size: {h4BaseSize} * {scale} = {h4Size})

##### 見出し 5 (H5, font size: {h5BaseSize} * {scale} = {h5Size})

###### 見出し 6 (H6, font size: {h6BaseSize} * {scale} = {h6Size})

本文 (XX, font size: {bodyBaseSize} * {scale} = {bodySize})

## 3. リスト (Lists)

### 番号なしリスト

- 項目 1
- 項目 2
  - サブ項目 A
  - サブ項目 B
    - 以下同様

### 番号付きリスト

1. ステップ 1
2. ステップ 2
3. ステップ 3
   1. サブステップ I
   2. サブステップ II

### タスクリスト (Task List)

- [x] 完了したタスク
- [ ] 未完了のタスク
- [ ] 進行中のタスク

## 4. 引用 (Blockquotes)

> これは第 1 レベルの引用です。
>
> > これはネストされた第 2 レベルの引用です。
> > 第 2 レベルに戻る。
> > 第 1 レベルの引用に戻る。

## 5. 水平罫線 (Horizontal Rules)

---

## 6. コードブロック (Code Blocks)

### 基本コードブロック (Indented)

    // これはインデントされたコードブロックです
    console.log('Hello');

### シンタックスハイライト (Fenced with Syntax Highlighting)

**JavaScript:**

```javascript
function helloWorld() {
  const message = "Hello, Markdown!";
  console.log(message);
  return true;
}
```
