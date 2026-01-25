# Markdown 语法全集测试 (H1)

这是一个用于测试 **Markdown 解析器** 和 **CSS 样式** 的标准测试文件。

## 1. 文本格式 (Typography)

这里是普通文本段落。测试中英文混排的表现：The quick brown fox jumps over the lazy dog. 敏捷的棕色狐狸跳过了懒惰的狗。

- **加粗文本 (Bold)** 或 **另一种加粗**
- *斜体文本 (Italic)* 或 _另一种斜体_
- ***粗斜体文本 (Bold & Italic)***
- ~~删除线 (Strikethrough)~~
- `行内代码 (Inline Code)`
- [链接文本 (Link)](https://www.google.com)

## 2. 标题层级 (Headings)

# 一级标题 (H1, font size: {h1BaseSize} * {scale} = {h1Size})

## 二级标题 (H2, font size: {h2BaseSize} * {scale} = {h2Size})

### 三级标题 (H3, font size: {h3BaseSize} * {scale} = {h3Size})

#### 四级标题 (H4, font size: {h4BaseSize} * {scale} = {h4Size})

##### 五级标题 (H5, font size: {h5BaseSize} * {scale} = {h5Size})

###### 六级标题 (H6, font size: {h6BaseSize} * {scale} = {h6Size})

正文内容 (XX, font size: {bodyBaseSize} * {scale} = {bodySize})

## 3. 列表 (Lists)

### 无序列表

- 项目一
- 项目二
  - 子项目 A
  - 子项目 B \*以此类推

### 有序列表

1. 第一步
2. 第二步
3. 第三步
   1. 子步骤 I
   2. 子步骤 II

### 任务列表 (Task List)

- [x] 已完成的任务
- [ ] 未完成的任务
- [ ] 正在进行的任务

## 4. 引用 (Blockquotes)

> 这是一个一级引用。
>
> > 这是一个嵌套的二级引用。
> > 回到二级。
> > 回到一级引用。

## 5. 水平分隔线 (Horizontal Rules)

在水平分隔线之前的内容

---

在水平分隔线之后的内容

## 6. 代码块 (Code Blocks)

### 基础代码块 (Indented)

    // 这是一个缩进代码块
    console.log('Hello');

### 语法高亮 (Fenced with Syntax Highlighting)

**JavaScript:**

```javascript
function helloWorld() {
  const message = "Hello, Markdown!";
  console.log(message);
  return true;
}
```
