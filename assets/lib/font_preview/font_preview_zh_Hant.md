# Markdown 語法全集測試 (H1)

這是一個用於測試 **Markdown 解析器** 和 **CSS 樣式** 的標準測試檔案。

## 1. 文字格式 (Typography)

這裡是普通文字段落。測試中英文混排的表現：The quick brown fox jumps over the lazy dog. 敏捷的棕色狐狸跳過了懶惰的狗。

- **粗體文字 (Bold)** 或 **另一種粗體**
- *斜體文字 (Italic)* 或 _另一種斜體_
- ***粗斜體文字 (Bold & Italic)***
- ~~刪除線 (Strikethrough)~~
- `行內程式碼 (Inline Code)`
- [連結文字 (Link)](https://www.google.com)

## 2. 標題層級 (Headings)

# 一級標題 (H1, font size: {h1BaseSize} * {scale} = {h1Size})

## 二級標題 (H2, font size: {h2BaseSize} * {scale} = {h2Size})

### 三級標題 (H3, font size: {h3BaseSize} * {scale} = {h3Size})

#### 四級標題 (H4, font size: {h4BaseSize} * {scale} = {h4Size})

##### 五級標題 (H5, font size: {h5BaseSize} * {scale} = {h5Size})

###### 六級標題 (H6, font size: {h6BaseSize} * {scale} = {h6Size})

正文內容 (XX, font size: {bodyBaseSize} * {scale} = {bodySize})

## 3. 列表 (Lists)

### 無序列表

- 項目一
- 項目二
  - 子項目 A
  - 子項目 B
    - 以此類推

### 有序列表

1. 第一步
2. 第二步
3. 第三步
   1. 子步驟 I
   2. 子步驟 II

### 任務列表 (Task List)

- [x] 已完成的任務
- [ ] 未完成的任務
- [ ] 正在進行的任務

## 4. 引用 (Blockquotes)

> 這是一個一級引用。
>
> > 這是一個巢狀的二級引用。
> > 回到二級。
> > 回到一級引用。

## 5. 水平分隔線 (Horizontal Rules)

在水平分隔线之前的内容

---

在水平分隔线之后的内容

## 6. 程式碼區塊 (Code Blocks)

### 基礎程式碼區塊 (Indented)

    // 這是一個縮排程式碼區塊
    console.log('Hello');

### 語法高亮 (Fenced with Syntax Highlighting)

**JavaScript:**

```javascript
function helloWorld() {
  const message = "Hello, Markdown!";
  console.log(message);
  return true;
}
```
