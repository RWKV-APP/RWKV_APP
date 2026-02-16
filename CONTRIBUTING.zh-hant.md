# 貢獻指南：Theme 快速開始

本指南面向主要想透過 PR 自訂 App 配色的外部貢獻者。

## 1. 在 `lib/model/app_theme.dart` 中新增主題

1. 複製現有主題（通常是 `.dim` 或 `.lightsOut`），重新命名為例如 `.myTheme`。
2. 補齊所有必填顏色欄位（`primary`、`themePrimary`、`qb*`、`g*`、輸入框/訊息顏色等）。
3. 正確設定 `isLight`（淺色為 `true`，深色為 `false`）。
4. 在 `displayName` 中加入新分支。
5. 同步更新 `fromString` 與 `toString`，確保偏好持久化相容。

## 2. 在 `lib/widgets/theme_selector.dart` 中顯示新主題

1. 在 `items` 清單中新增一個 `FormItem`。
2. 參考 `_onDimPressed` / `_onLightsOutPressed` 新增處理函式：
   - 更新 `P.preference.preferredDarkCustomTheme.q`
   - 持久化 `halo_state.preferredDarkCustomTheme`
3. 重用選中態邏輯：`preferredDarkCustomTheme == .yourTheme`。

說明：目前結構是「一個淺色主題 + 多個深色主題」。若要新增額外淺色主題，還需要調整 `lib/store/app.dart` 的同步邏輯。

## 3. `Args.debuggingThemes` 的作用

- 啟動參數：`--dart-define=debuggingThemes=true`
- 除錯行為：App 會每秒在 `.light` 與目前深色偏好（`preferredDarkCustomTheme`）之間切換。
- 用途：快速檢查同一頁面在明暗主題下的對比度、可讀性與覆蓋情況。

## 4. 在 `.vscode/launch.json` 同時啟動桌面與行動端 UI

1. 保留按平台拆分的 launch 設定（如 macOS、Android、iOS）。
2. 在 `compounds` 中組合這些設定（例如 `all (Halo)`）。
3. 執行 compound 設定，即可並行啟動多端 UI 進行對照調色。

可選：在對應設定中加入 `--dart-define=debuggingThemes=true`，做自動明暗切換預覽。

