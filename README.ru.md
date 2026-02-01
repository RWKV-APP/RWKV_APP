# RWKV App ✨

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![English](https://img.shields.io/badge/README-English-blue.svg)](./README.md)
[![Simplified Chinese](https://img.shields.io/badge/README-简体中文-blue.svg)](./README.zh-hans.md)
[![Traditional Chinese](https://img.shields.io/badge/README-繁體中文-blue.svg)](./README.zh-hant.md)
[![Japanese](https://img.shields.io/badge/README-日本語-blue.svg)](./README.ja.md)
[![Korean](https://img.shields.io/badge/README-한국어-blue.svg)](./README.ko.md)
[![Russian](https://img.shields.io/badge/README-Русский-blue.svg)](./README.ru.md)

**Исследуйте и запускайте большие языковые модели (LLM) оффлайн на ваших пограничных устройствах с помощью RWKV App.**

RWKV App — это экспериментальное приложение, которое переносит большие языковые модели (LLM) непосредственно на ваши устройства Android/iOS. Вы можете экспериментировать с различными моделями, общаться в чате, генерировать речь, выполнять визуальное понимание и многое другое! Все вычисления выполняются локально, и после загрузки модели подключение к Интернету не требуется.

**Обзор**

RWKV App поддерживает многоходовые диалоги, преобразование текста в речь (TTS), визуальное понимание и различные другие задачи.

![RWKV App Screenshot](.github/images/readme/gallery.png)

## ✨ Основные функции

- **📱 Локальный запуск, полностью оффлайн:** Испытайте магию генеративного ИИ без подключения к Интернету. Вся обработка выполняется непосредственно на вашем устройстве.
- **🤖 Свободное переключение моделей:** Легко скачивайте и переключайтесь между различными моделями с Hugging Face, чтобы сравнить их производительность.
- **💬 ИИ-чат:** Участвуйте в плавных многоходовые диалогах.
- **🔊 Текст в речь (TTS):** Преобразование текста в естественно звучащую речь.
- **🖼️ Визуальное понимание:** Изучите варианты использования ИИ на основе изображений.
- **🌓 Темный режим:** Поддержка комфортного использования при различных условиях освещения.

## 🧭 Загрузка и использование

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

### Использование

При первом открытии приложения появится панель выбора модели. Пожалуйста, выберите веса модели, которые вы хотите использовать, в соответствии с вашими потребностями.

> [!WARNING]
> Устройства старше iPhone 14 могут не обеспечивать плавную работу моделей с 1.5B / 2.9B параметров.

## 💻 Разработка

**Убедитесь, что у вас настроена среда разработки [Flutter](https://flutter.dev/).**

1. **Клонирование репозитория:**

```bash
# ОБЯЗАТЕЛЬНО переключитесь на ветку 'dev'
git clone -b dev https://github.com/MollySophia/rwkv_mobile_flutter.git
# Убедитесь, что rwkv_mobile_flutter и RWKV_APP находятся в одной директории
git clone -b dev https://github.com/RWKV-APP/RWKV_APP.git
cd RWKV_APP
```

2. **Создайте необходимые файлы конфигурации:**

```bash
touch assets/filter.txt
touch .env
```

3. **Установка зависимостей:**

```bash
flutter pub get
```

4. **（Необязательно）Установка зависимостей для каталога `tools`:**

*Это избавляет от предупреждения «В проекте есть ошибки» в VS Code и Cursor при запуске приложения.*

```bash
cd tools
flutter pub get
cd ..
```

5. **Запуск приложения:**

```bash
flutter run
```

## 🛠️ Технические особенности

- **Flutter:** Фреймворк с открытым исходным кодом для создания кроссплатформенных пользовательских интерфейсов, поддерживающий Android, iOS, Windows и macOS.
- **Dart FFI (Foreign Function Interface):** Используется для эффективного взаимодействия между Dart и движком вывода на C++.
- **C++ Inference Engine:** Ядро движка вывода на устройстве, созданное на C++, поддерживающее несколько форматов моделей и аппаратное ускорение (CPU/GPU/NPU).
- **Hugging Face:** Сообщество с открытым исходным кодом, предоставляющее модели, наборы данных и инструменты; используется здесь в качестве источника весов моделей.

## 🗺️ Дорожная карта (Roadmap)

- [x] Интегрировать все функции в приложение RWKV Chat
- [ ] Поддержка большего количества весов моделей
- [ ] Поддержка большего количества оборудования
- [ ] Поддержка большего количества операционных систем
- [ ] Поддержка большего количества устройств (например, часов, VR-очков)

## 🤝 Обратная связь и вклад

Это **экспериментальная версия на ранней стадии**, и ваши отзывы очень важны для нас!

- 🐞 **Нашли ошибку или проблему?** [Сообщите об этом здесь!](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=bug&template=bug_report.md&title=%5BBUG%5D)
- 💡 **Есть предложение?** [Предложите функцию!](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5BFEATURE%5D)

## 📄 Лицензия

Этот проект лицензирован в соответствии с Apache License 2.0. См. файл [LICENSE](LICENSE) для получения подробной информации.

## 🔗 Полезные ссылки

- [**Обертка Flutter**](https://github.com/MollySophia/rwkv_mobile_flutter)
- [**Движок вывода C++**](https://github.com/MollySophia/rwkv-mobile)
- [**Доступные модели**](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)
- [**Хотите обучить свою собственную модель?**](https://github.com/RWKV-Vibe/RWKV-LM-V7)
- [**Что такое RWKV?**](https://rwkv.cn/)
