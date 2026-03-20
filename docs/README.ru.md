# RWKV App ✨

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](../LICENSE)
[![English](https://img.shields.io/badge/README-English-blue.svg)](../README.md)
[![Simplified Chinese](https://img.shields.io/badge/README-简体中文-blue.svg)](./README.zh-hans.md)
[![Traditional Chinese](https://img.shields.io/badge/README-繁體中文-blue.svg)](./README.zh-hant.md)
[![Japanese](https://img.shields.io/badge/README-日本語-blue.svg)](./README.ja.md)
[![Korean](https://img.shields.io/badge/README-한국어-blue.svg)](./README.ko.md)

**Запускайте приватный on-device AI на смартфонах и десктопах.**
**Локальный AI playground для чата, речи, зрения и экспериментов с моделями.**

RWKV App — это privacy-first AI-приложение для Android, iOS, Windows, macOS и Linux. Оно позволяет скачивать, переключать и сравнивать локальные модели на реальном железе, а также быстро прототипировать AI-сценарии без зависимости от облака. После загрузки модели инференс остается на устройстве.

## Почему RWKV App

- **Для реальных edge-устройств:** Проверяйте локальные модели на смартфонах и десктопах, а не только в облачных демо.
- **Одно приложение, несколько AI-сценариев:** Чат, преобразование текста в речь и визуальное понимание собраны в одном месте.
- **Быстрое сравнение моделей:** Скачивайте модели с Hugging Face и переключайтесь между ними, чтобы сравнивать качество, скорость и совместимость с железом.
- **Приватность в приоритете:** После загрузки модели промпты, ответы и инференс остаются на устройстве.

![RWKV App Screenshot](../.github/images/readme/gallery.png)

## ✨ Основные функции

- **📱 Кроссплатформенность и local-first:** Запускайте on-device инференс на Android, iOS, Windows, macOS и Linux.
- **🤖 Гибкое переключение моделей:** Скачивайте и сравнивайте разные модели из Hugging Face.
- **💬 ИИ-чат:** Исследуйте плавные многоходовые диалоги на реальном железе.
- **🔊 Текст в речь (TTS):** Преобразование текста в естественно звучащую речь.
- **🖼️ Визуальное понимание:** Изучите варианты использования ИИ на основе изображений.
- **🔌 Необязательный локальный API-доступ:** На десктопе можно поднять OpenAI-совместимый локальный endpoint для интеграций и экспериментов.
- **🌓 Темный режим:** Комфортная работа даже при долгих сессиях.

## 🚀 Быстрый старт

1. Скачайте RWKV App с официальной страницы или по ссылкам для вашей платформы ниже.
2. Откройте приложение и загрузите чат-модель, подходящую вашему устройству.
3. Начните исследовать чат, речь или сценарии визуального понимания. На десктопе при необходимости можно также включить встроенный локальный API endpoint.

### Загрузки

**Официальная страница загрузки：[https://rwkv.halowang.cloud/](https://rwkv.halowang.cloud/)**

<table>
<thead>
<tr>
<th style="text-align: center;"></th>
<th style="text-align: center;">RWKV Chat (with See and Talk)</th>
<th style="text-align: center;">RWKV Sudoku</th>
<th style="text-align: center;">RWKV Othello</th>
<th style="text-align: center;">RWKV Music (Другой репозиторий)</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: center;">Ссылка для Android APK</td>
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
> В будущем мы интегрируем все отдельные функции в приложение RWKV Chat, чтобы обеспечить единый опыт.

### Первый запуск

При первом открытии приложения появится панель выбора модели. Пожалуйста, выберите веса модели, которые вы хотите использовать, в соответствии с вашими потребностями.

> [!WARNING]
> Устройства старше iPhone 14 могут не обеспечивать плавную работу моделей с 1.5B / 2.9B параметров.

## 💻 Сборка из исходников

**Убедитесь, что у вас настроена среда разработки [Flutter](https://flutter.dev/).**

> Для разработки требуется **Flutter 3.41.1+** (рекомендуется stable channel).

1. **Клонирование репозитория:**

```bash
# ОБЯЗАТЕЛЬНО переключитесь на ветку 'dev'
git clone -b dev https://github.com/MollySophia/rwkv_mobile_flutter.git
# Убедитесь, что rwkv_mobile_flutter и RWKV_APP находятся в одной директории
git clone -b dev https://github.com/RWKV-APP/RWKV_APP.git
cd RWKV_APP
```

Структура каталогов должна выглядеть так:

```text
parent/
├─ rwkv_mobile_flutter/
└─ RWKV_APP/
```

2. **Создайте необходимые файлы конфигурации:**

```bash
touch assets/filter.txt;touch .env;
```

3. **Установка зависимостей:**

```bash
flutter pub get
```

4. **（Необязательно）Установка зависимостей для каталога `tools`:**

_Это избавляет от предупреждения «В проекте есть ошибки» в VS Code и Cursor при запуске приложения._

```bash
cd tools; flutter pub get; cd ..;
```

5. **Запуск приложения:**

```bash
flutter run
```

#### Отладка Windows ARM64 (QNN)

Если вы отлаживаете на Windows ARM64, раскомментируйте следующий блок в `pubspec.yaml`:

```yaml
- path: assets/lib/qnn-windows/
  platforms: [windows]
```

Для отладки на Windows ARM64 используйте ветку Flutter `master`, а не `stable`.

## 🏗️ Стек

- **Flutter:** Фреймворк с открытым исходным кодом для создания кроссплатформенных пользовательских интерфейсов, поддерживающий Android, iOS, Windows и macOS.
- **Dart FFI (Foreign Function Interface):** Используется для эффективного взаимодействия между Dart и движком вывода на C++.
- **C++ Inference Engine:** Ядро движка вывода на устройстве, созданное на C++, поддерживающее несколько форматов моделей и аппаратное ускорение (CPU/GPU/NPU).
- **Hugging Face:** Сообщество с открытым исходным кодом, предоставляющее модели, наборы данных и инструменты; используется здесь в качестве источника весов моделей.

## 🤝 Обратная связь и вклад

Это **экспериментальная версия на ранней стадии**, и ваши отзывы очень важны для нас!

- 🐞 **Нашли ошибку или проблему?** [Сообщите об этом здесь!](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=bug&template=bug_report.md&title=%5BBUG%5D)
- 💡 **Есть предложение?** [Предложите функцию!](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5BFEATURE%5D)
- 🎨 **Хотите внести свой вариант темы?** [Быстрый старт по темам](./CONTRIBUTING.ru.md)

## 📄 Лицензия

Этот проект лицензирован в соответствии с Apache License 2.0. См. файл [LICENSE](../LICENSE) для получения подробной информации.

## 🔗 Полезные ссылки

- [**Обертка Flutter**](https://github.com/MollySophia/rwkv_mobile_flutter)
- [**Движок вывода C++**](https://github.com/MollySophia/rwkv-mobile)
- [**Доступные модели**](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)
- [**Хотите обучить свою собственную модель?**](https://github.com/RWKV-Vibe/RWKV-LM-V7)
- [**Что такое RWKV?**](https://rwkv.cn/)
