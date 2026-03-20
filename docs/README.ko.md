# RWKV App ✨

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](../LICENSE)
[![English](https://img.shields.io/badge/README-English-blue.svg)](../README.md)
[![Simplified Chinese](https://img.shields.io/badge/README-简体中文-blue.svg)](./README.zh-hans.md)
[![Traditional Chinese](https://img.shields.io/badge/README-繁體中文-blue.svg)](./README.zh-hant.md)
[![Japanese](https://img.shields.io/badge/README-日本語-blue.svg)](./README.ja.md)
[![Russian](https://img.shields.io/badge/README-Русский-blue.svg)](./README.ru.md)

**스마트폰과 데스크톱에서 프라이빗한 온디바이스 AI를 실행하세요.**
**채팅, 음성, 비전, 모델 실험을 위한 로컬 퍼스트 AI 플레이그라운드.**

RWKV App은 Android, iOS, Windows, macOS, Linux를 위한 프라이버시 우선 AI 앱입니다. 로컬 모델을 실제 하드웨어에서 다운로드하고, 전환하고, 비교하면서 클라우드에 의존하지 않고 AI 경험을 빠르게 실험할 수 있습니다. 모델을 로드한 뒤의 추론은 기기 안에 머무릅니다.

## 왜 RWKV App인가

- **실제 엣지 디바이스를 위한 설계:** 클라우드 중심 데모가 아니라 스마트폰과 데스크톱에서 로컬 모델을 직접 평가할 수 있습니다.
- **하나의 앱, 여러 AI 워크플로:** 채팅, 텍스트 음성 변환, 시각적 이해를 한곳에서 다룰 수 있습니다.
- **더 빠른 모델 비교:** Hugging Face에서 모델을 다운로드하고 전환하면서 품질, 속도, 하드웨어 적합성을 바로 비교할 수 있습니다.
- **프라이버시 우선:** 모델 로드 이후의 프롬프트, 출력, 추론은 모두 기기 안에 머무릅니다.

![RWKV App Screenshot](../.github/images/readme/gallery.png)

## ✨ 핵심 기능

- **📱 크로스 플랫폼, 로컬 퍼스트:** Android, iOS, Windows, macOS, Linux에서 온디바이스 추론을 실행할 수 있습니다.
- **🤖 유연한 모델 전환:** Hugging Face에서 다양한 모델을 다운로드하고 비교할 수 있습니다.
- **💬 AI 채팅:** 실제 하드웨어에서 자연스러운 멀티턴 대화를 경험할 수 있습니다.
- **🔊 텍스트 음성 변환 (TTS):** 텍스트를 자연스러운 음성으로 변환합니다.
- **🖼️ 시각적 이해:** 이미지 기반 AI 사용 사례를 탐색합니다.
- **🔌 선택형 로컬 API 접근:** 데스크톱에서는 도구 연동이나 실험을 위해 OpenAI 호환 로컬 엔드포인트를 노출할 수 있습니다.
- **🌓 다크 모드:** 장시간 사용에도 편안함을 유지할 수 있습니다.

## 🚀 빠른 시작

1. 공식 다운로드 페이지 또는 아래 플랫폼 링크에서 RWKV App을 내려받습니다.
2. 앱을 열고 기기에 맞는 채팅 모델을 로드합니다.
3. 채팅, 음성, 비전 워크플로를 바로 시작합니다. 데스크톱에서는 필요할 때 내장 로컬 API 엔드포인트도 활성화할 수 있습니다.

### 다운로드

**공식 다운로드 페이지：[https://rwkv.halowang.cloud/](https://rwkv.halowang.cloud/)**

<table>
<thead>
<tr>
<th style="text-align: center;"></th>
<th style="text-align: center;">RWKV Chat (with See and Talk)</th>
<th style="text-align: center;">RWKV Sudoku</th>
<th style="text-align: center;">RWKV Othello</th>
<th style="text-align: center;">RWKV Music (별도 리포지토리)</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: center;">Android APK 다운로드 링크</td>
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
> 향후 통합된 경험을 제공하기 위해 모든 개별 기능을 RWKV Chat 앱에 통합할 예정입니다.

### 첫 실행

앱을 처음 열면 모델 선택 패널이 나타납니다. 필요에 따라 사용하려는 모델 가중치를 선택하십시오.

> [!WARNING]
> iPhone 14 이전 기기는 1.5B / 2.9B 매개변수 모델을 원활하게 실행하지 못할 수 있습니다.

## 💻 소스에서 빌드

**[Flutter](https://flutter.dev/) 개발 환경이 설정되어 있는지 확인하십시오.**

> 개발 환경에서는 **Flutter 3.41.1+** 가 필요합니다(stable channel 권장).

1. **리포지토리 복제:**

```bash
# 반드시 'dev' 브랜치로 전환해야 합니다
git clone -b dev https://github.com/MollySophia/rwkv_mobile_flutter.git
# rwkv_mobile_flutter와 RWKV_APP가 같은 디렉토리에 있는지 확인하세요
git clone -b dev https://github.com/RWKV-APP/RWKV_APP.git
cd RWKV_APP
```

디렉터리 구조는 다음과 같아야 합니다.

```text
parent/
├─ rwkv_mobile_flutter/
└─ RWKV_APP/
```

2. **필요한 구성 파일 생성:**

```bash
touch assets/filter.txt;touch .env;
```

3. **종속성 설치:**

```bash
flutter pub get
```

4. **（선택 사항）`tools` 디렉토리 종속성 설치:**

_이 단계를 수행하면 VS Code 또는 Cursor에서 앱을 실행할 때 "프로젝트에 오류가 있습니다" 경고를 피할 수 있습니다._

```bash
cd tools; flutter pub get; cd ..;
```

5. **애플리케이션 실행:**

```bash
flutter run
```

#### Windows ARM64 디버그 (QNN)

Windows ARM64에서 디버그하려면 `pubspec.yaml`의 아래 설정 주석을 해제하세요.

```yaml
- path: assets/lib/qnn-windows/
  platforms: [windows]
```

Windows ARM64 디버그 시에는 Flutter `stable` 브랜치가 아니라 `master` 브랜치를 사용하세요.

## 🏗️ 스택

- **Flutter:** Android, iOS, Windows 및 macOS를 지원하는 크로스 플랫폼 사용자 인터페이스 구축을 위한 오픈 소스 프레임워크입니다.
- **Dart FFI (Foreign Function Interface):** Dart와 C++ 추론 엔진 간의 효율적인 통신에 사용됩니다.
- **C++ 추론 엔진:** C++로 구축된 온디바이스 추론 엔진의 핵심으로, 여러 모델 형식과 하드웨어 가속(CPU/GPU/NPU)을 지원합니다.
- **Hugging Face:** 모델, 데이터 세트 및 도구를 제공하는 오픈 소스 커뮤니티이며, 여기서는 모델 가중치의 소스로 사용됩니다.

## 🤝 피드백 및 기여

이것은 **실험적인 초기 단계 버전**이며, 여러분의 피드백은 우리에게 매우 중요합니다!

- 🐞 **버그나 문제를 발견하셨나요?** [여기에서 보고하세요!](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=bug&template=bug_report.md&title=%5BBUG%5D)
- 💡 **제안 사항이 있으신가요?** [기능을 제안하세요!](https://github.com/RWKV-APP/RWKV_APP/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5BFEATURE%5D)
- 🎨 **커스텀 테마를 기여하고 싶나요?** [Theme 빠른 시작](./CONTRIBUTING.ko.md)

## 📄 라이선스

이 프로젝트는 Apache License 2.0에 따라 라이선스가 부여됩니다. 자세한 내용은 [LICENSE](../LICENSE) 파일을 참조하세요.

## 🔗 관련 링크

- [**Flutter Wrapper**](https://github.com/MollySophia/rwkv_mobile_flutter)
- [**C++ 추론 엔진**](https://github.com/MollySophia/rwkv-mobile)
- [**사용 가능한 모델**](https://huggingface.co/mollysama/rwkv-mobile-models/tree/main)
- [**나만의 모델을 훈련하고 싶으신가요?**](https://github.com/RWKV-Vibe/RWKV-LM-V7)
- [**RWKV란 무엇인가요?**](https://rwkv.cn/)
