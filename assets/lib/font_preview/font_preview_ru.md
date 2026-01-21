# Тест синтаксиса Markdown (H1)

Это стандартный тестовый файл для проверки **парсера Markdown** и **CSS стилей**.

## 1. Форматирование текста (Typography)

Здесь обычный текстовый абзац. Тест отображения смешанного текста: The quick brown fox jumps over the lazy dog. Быстрая коричневая лиса перепрыгнула через ленивую собаку.

- **Жирный текст (Bold)** или **Другой жирный**
- *Курсивный текст (Italic)* или _Другой курсив_
- ***Жирный курсив (Bold & Italic)***
- ~~Зачеркнутый (Strikethrough)~~
- `Строчный код (Inline Code)`
- [Текст ссылки (Link)](https://www.google.com)

## 2. Уровни заголовков (Headings)

# Заголовок 1 (H1, font size: {h1BaseSize} * {scale} = {h1Size})

## Заголовок 2 (H2, font size: {h2BaseSize} * {scale} = {h2Size})

### Заголовок 3 (H3, font size: {h3BaseSize} * {scale} = {h3Size})

#### Заголовок 4 (H4, font size: {h4BaseSize} * {scale} = {h4Size})

##### Заголовок 5 (H5, font size: {h5BaseSize} * {scale} = {h5Size})

###### Заголовок 6 (H6, font size: {h6BaseSize} * {scale} = {h6Size})

Основной текст (XX, font size: {bodyBaseSize} * {scale} = {bodySize})

## 3. Списки (Lists)

### Маркированный список

- Пункт 1
- Пункт 2
  - Подпункт A
  - Подпункт B
    - И так далее

### Нумерованный список

1. Шаг 1
2. Шаг 2
3. Шаг 3
   1. Подшаг I
   2. Подшаг II

### Список задач (Task List)

- [x] Выполненная задача
- [ ] Невыполненная задача
- [ ] Задача в процессе

## 4. Цитаты (Blockquotes)

> Это цитата первого уровня.
>
> > Это вложенная цитата второго уровня.
> > Возврат ко второму уровню.
> > Возврат к цитате первого уровня.

## 5. Горизонтальные линии (Horizontal Rules)

---

## 6. Блоки кода (Code Blocks)

### Базовый блок кода (Indented)

    // Это блок кода с отступом
    console.log('Hello');

### Подсветка синтаксиса (Fenced with Syntax Highlighting)

**JavaScript:**

```javascript
function helloWorld() {
  const message = "Hello, Markdown!";
  console.log(message);
  return true;
}
```
