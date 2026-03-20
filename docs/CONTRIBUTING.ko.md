# 기여 가이드: Theme 빠른 시작

[![English](https://img.shields.io/badge/CONTRIBUTING-English-blue.svg)](../CONTRIBUTING.md)
[![Simplified Chinese](https://img.shields.io/badge/CONTRIBUTING-简体中文-blue.svg)](./CONTRIBUTING.zh-hans.md)
[![Traditional Chinese](https://img.shields.io/badge/CONTRIBUTING-繁體中文-blue.svg)](./CONTRIBUTING.zh-hant.md)
[![Japanese](https://img.shields.io/badge/CONTRIBUTING-日本語-blue.svg)](./CONTRIBUTING.ja.md)
[![Russian](https://img.shields.io/badge/CONTRIBUTING-Русский-blue.svg)](./CONTRIBUTING.ru.md)

이 문서는 앱 색상 테마를 변경하는 PR을 올리려는 외부 기여자를 위한 빠른 시작 가이드입니다.

## 1. `lib/model/app_theme.dart`에 테마 추가

1. 기존 테마(보통 `.dim` 또는 `.lightsOut`)를 복사하고, 예: `.myTheme` 로 이름을 바꿉니다.
2. 필수 색상 필드(`primary`, `themePrimary`, `qb*`, `g*`, 입력/메시지 색상 등)를 모두 채웁니다.
3. `isLight` 를 올바르게 설정합니다(라이트 테마 `true`, 다크 테마 `false`).
4. `displayName` 에 새 분기를 추가합니다.
5. 저장 호환성을 위해 `fromString`, `toString` 도 함께 업데이트합니다.

## 2. `lib/widgets/theme_selector.dart`에서 새 테마 노출

1. `items` 목록에 새 `FormItem` 을 추가합니다.
2. `_onDimPressed` / `_onLightsOutPressed` 와 유사한 핸들러를 추가합니다.
   - `P.preference.preferredDarkCustomTheme.q` 업데이트
   - `halo_state.preferredDarkCustomTheme` 저장
3. 선택 상태 UI는 `preferredDarkCustomTheme == .yourTheme` 로 처리합니다.

참고: 현재 구조는 "라이트 테마 1개 + 다크 테마 여러 개"입니다. 라이트 테마를 추가하려면 `lib/store/app.dart` 동기화 로직도 함께 수정해야 합니다.

## 3. `Args.debuggingThemes` 의 역할

- 실행 인자: `--dart-define=debuggingThemes=true`
- 디버그 동작: 앱이 1초마다 `.light` 와 현재 다크 선호값(`preferredDarkCustomTheme`) 사이를 전환합니다.
- 목적: 같은 화면에서 명암 대비, 가독성, 테마 적용 누락을 빠르게 점검합니다.

## 4. `.vscode/launch.json`에서 데스크톱 + 모바일 UI 동시 실행

1. 플랫폼별 launch 설정(예: macOS / Android / iOS)을 준비합니다.
2. `compounds` 에서 해당 설정을 묶습니다(예: `all (Halo)`).
3. compound 설정을 실행하면 멀티 플랫폼 UI를 동시에 띄울 수 있습니다.

선택 사항: 관련 launch 설정에 `--dart-define=debuggingThemes=true` 를 추가하면 자동 라이트/다크 미리보기가 가능합니다.
