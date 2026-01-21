# Markdown Syntax Test (H1)

This is a standard test file for testing **Markdown parser** and **CSS styles**.

## 1. Text Formatting (Typography)

This is a normal text paragraph. Testing mixed language display: The quick brown fox jumps over the lazy dog.

- **Bold Text** or **Another Bold**
- *Italic Text* or _Another Italic_
- ***Bold & Italic***
- ~~Strikethrough~~
- `Inline Code`
- [Link Text](https://www.google.com)

## 2. Heading Levels

# H1 (font size: {h1BaseSize} * {scale} = {h1Size})

## H2 (font size: {h2BaseSize} * {scale} = {h2Size})

### H3 (font size: {h3BaseSize} * {scale} = {h3Size})

#### H4 (font size: {h4BaseSize} * {scale} = {h4Size})

##### H5 (font size: {h5BaseSize} * {scale} = {h5Size})

###### H6 (font size: {h6BaseSize} * {scale} = {h6Size})

Body text (font size: {bodyBaseSize} * {scale} = {bodySize})

## 3. Lists

### Unordered List

- Item One
- Item Two
  - Sub-item A
  - Sub-item B
    - And so on

### Ordered List

1. Step One
2. Step Two
3. Step Three
   1. Sub-step I
   2. Sub-step II

### Task List

- [x] Completed task
- [ ] Incomplete task
- [ ] In progress task

## 4. Blockquotes

> This is a first-level quote.
>
> > This is a nested second-level quote.
> > Back to second level.
> > Back to first-level quote.

## 5. Horizontal Rules (Thematic Breaks)

---

## 6. Code Blocks

### Basic Code Block (Indented)

    // This is an indented code block
    console.log('Hello');

### Syntax Highlighting (Fenced)

**JavaScript:**

```javascript
function helloWorld() {
  const message = "Hello, Markdown!";
  console.log(message);
  return true;
}
```
