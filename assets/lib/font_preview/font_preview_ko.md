# Markdown 구문 테스트 (H1)

이것은 **Markdown 파서** 와 **CSS 스타일** 을 테스트하기 위한 표준 테스트 파일입니다.

## 1. 텍스트 서식 (Typography)

여기는 일반 텍스트 단락입니다. 한영 혼합 표시 테스트: The quick brown fox jumps over the lazy dog. 빠른 갈색 여우가 게으른 개를 뛰어넘었다.

- **굵은 텍스트 (Bold)** 또는 **다른 굵은체**
- *기울임 텍스트 (Italic)* 또는 _다른 기울임체_
- ***굵은 기울임 텍스트 (Bold & Italic)***
- ~~취소선 (Strikethrough)~~
- `인라인 코드 (Inline Code)`
- [링크 텍스트 (Link)](https://www.google.com)

## 2. 제목 수준 (Headings)

# 제목 1 (H1, font size: {h1BaseSize} * {scale} = {h1Size})

## 제목 2 (H2, font size: {h2BaseSize} * {scale} = {h2Size})

### 제목 3 (H3, font size: {h3BaseSize} * {scale} = {h3Size})

#### 제목 4 (H4, font size: {h4BaseSize} * {scale} = {h4Size})

##### 제목 5 (H5, font size: {h5BaseSize} * {scale} = {h5Size})

###### 제목 6 (H6, font size: {h6BaseSize} * {scale} = {h6Size})

본문 (XX, font size: {bodyBaseSize} * {scale} = {bodySize})

## 3. 목록 (Lists)

### 순서 없는 목록

- 항목 1
- 항목 2
  - 하위 항목 A
  - 하위 항목 B
    - 이하 동일

### 순서 있는 목록

1. 단계 1
2. 단계 2
3. 단계 3
   1. 하위 단계 I
   2. 하위 단계 II

### 작업 목록 (Task List)

- [x] 완료된 작업
- [ ] 미완료 작업
- [ ] 진행 중인 작업

## 4. 인용문 (Blockquotes)

> 이것은 1단계 인용문입니다.
>
> > 이것은 중첩된 2단계 인용문입니다.
> > 2단계로 돌아가기.
> > 1단계 인용문으로 돌아가기.

## 5. 수평선 (Horizontal Rules)

---

## 6. 코드 블록 (Code Blocks)

### 기본 코드 블록 (Indented)

    // 이것은 들여쓰기된 코드 블록입니다
    console.log('Hello');

### 구문 강조 (Fenced with Syntax Highlighting)

**JavaScript:**

```javascript
function helloWorld() {
  const message = "Hello, Markdown!";
  console.log(message);
  return true;
}
```
