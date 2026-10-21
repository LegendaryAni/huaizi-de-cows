# 《傳奇倖存者》主選單去模板化修訂 v2

日期：2026-10-19。延續 GOAL `wc_goal_MXBwdHzPm7MiFYqS`。本輪僅修改 Godot 主選單美術與介面佈局，保留原始七個主功能及 `ScifiUI` callback，不修改戰鬥、存檔與遊戲視口。

## 觀察到的既有問題

原先七個同尺寸長卡、每張固定英文副標、右上虛擬指揮官面板與下方「本機更新／PROJECT STATUS」並排，使畫面近似 AI 產出的泛用科幻儀錶板；量化資訊缺乏必要性。機甲 96×96 `1103/portrait.png` 被貼進 JPEG 背景放大，容易出現 JPEG 色塊、角色離地、角色狀態卡壓住機庫。

## 修改後的版面（1920×1080）

- 左上：傳奇倖存者標題，中文短副標「前線終端／工業廢墟行動」，沒有假遊戲品牌或假故事標語。
- 左欄：單一強調的「出擊整備」大操作；其下四項作戰支援排成緊湊按鈕；底下兩項系統功能使用次級橫排。按鈕數仍為七，`scifi_action` 仍沿用舊測試識別。
- 右上：精簡本機存檔實際紀錄數、信用點，移除假帳號資訊、重複的設定按鈕。讀取 `progress.credits` 及 `scores.size()`。
- 中央：在真正的維修艙背景前，以原生 Nearest 呈現 `1103` 畫素機甲，分離於 JPEG 場景素材；場景有維修升降臺、裝置、門軌、正確的地面透視及剋制的區域性光照，不採用密集偽 HUD 網格。
- 右側：單行「壁壘／1103 重裝型」機體識別，不再有擋住機甲的獨立狀態卡。
- 底部：單一連續任務資訊帶，只顯示「工業廢墟、擊敗徵收者、選武器與兩技能」等正式機制，不再假裝是線上新聞系統。
- 色彩：鋼灰、舊黃銅、低飽和工業綠；文字層級只用確定的對比，Hover 以小幅位移處理，淡入不依賴大量滑入卡。
- 操作語意：保留七項 `open_loadout`、`open_meta`、`open_scores`、`open_settings`、`tutorial`、`open_credits`、`quit` 及可選 `retry_save`；符合既有 mouse、focus、tests metadata。

## 檔案與回退

- 本輪修改前備份：`.codex/restorepoints/20261019-menu-authored-ui-v2/`（包含先前 dirty worktree Git 狀態）。
- 新視覺：`assets/sprites/ui/runtime/scifi/menu_backdrop_v2.jpg`、`menu_mech_1103.png`、`menu_mech_shadow.png`。
- 獨立版面指令碼：`scripts/scifi/ScifiMainMenuV2.gd`，由 `scenes/ui/ScifiMainMenu.tscn` 指向；舊 `ScifiMainMenu.gd` 與 `menu_backdrop.jpg` 保留供比較／回退。
- 依舊由 `ScifiUI.gd` 傳入真實進度、歷次成績和處理導航，未更改任何存檔格式。
- 原本 96×96 畫素機甲只做整數倍率無損放大與獨立顯示，仍不是高解析原創立繪；若要達成概念圖的機甲插畫品質，必須另行繪製符合世界觀的高解析資產。
- 本輪不重新宣稱 SF-16 遊戲平衡或 SF-17 獨立驗收已透過。

## 驗證

以 `tools/run_scifi_tests.ps1 -Scenario menu-preview` 在 GPU 預設／1920×1080 視口點選主功能並擷取真實畫面；必要時跑 `-Scenario all` 邏輯回歸與 Windows 匯出執行檔 Smoke。禁止只憑本檔案或設計稿宣稱透過。
