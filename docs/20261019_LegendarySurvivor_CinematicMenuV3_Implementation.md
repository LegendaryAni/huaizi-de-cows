# 《傳奇倖存者》電影式主選單 v3 隔離預覽實作紀錄

日期：2026-10-19。使用的有效 GOAL：`wc_goal__aIMv8m5-4xhQhDj`。原文件曾提及的 `wc_goal_MXBwdHzPm7MiFYqS` 不存在於現行 Chadex Goal 後端；不將它當成目前的有效 GOAL。

## 已實作

- `scenes/ui/ScifiMainMenuV3.tscn`、`scripts/scifi/ScifiMainMenuV3.gd`：獨立的新主選單，有七個真實 Button，保留所有 `scifi_action` 與遊戲原有選單流程。
- 資產 `assets/sprites/ui/runtime/scifi/v3_*`：原創分層工業機庫遠景／中景／前景、環境光束、粉塵粒子素材、主機甲像素佔位立繪、四種按鈕狀態及下方兩張資訊卡。沒有把文字或假按鈕畫死在背景。
- `AnimationPlayer` 的環境光循環、`GPUParticles2D` 粉塵、背景少量滑鼠視差、主選單進場淡入、Hover／Focus 美術狀態、進入次頁淡出。過場中鎖住重複點擊；動畫在節點銷毀時會取消。
- 右上成績與信用點從遊戲真實的 `scores` 和 `progress.credits` 取得，存檔錯誤顯示與 `retry_save` 仍在。
- `ScifiUI.gd` 採分流而不是替換正式主選單：本機 Godot 正式專案仍使用舊 `ScifiMainMenu.tscn`；傳入 `--menu-v3-preview`、`--scifi-test=menu-v3` 或執行檔名稱包含 `CinematicMenu_v3_preview` 時載入 v3。新版獨立 Windows 預覽可以**直接雙擊**執行並進入 v3。

## 專項驗證（真實 Godot）

| 情境 | 來源 | 結果 |
|---|---|---|
| v3 主選單 1600×900 GPU 點擊與分層／動畫 | `reports/scifi-tests/20261019-161103-menu-v3-d01ca321/` | PASS |
| v3 主選單 1920×1080 GPU 點擊與分層／動畫 | `reports/scifi-tests/20261019-161147-menu-v3-dd925bf8/` | PASS |
| 原 v2 主選單專項（確認隔離不破壞舊版） | `reports/scifi-tests/20261019-161258-menu-preview-9ace130e/` | PASS |
| 完整既有邏輯回歸 | `reports/scifi-tests/20261019-161157-all-b1719a76/` | PASS |
| 固定重播 | `reports/scifi-tests/20261019-161244-replay-23e364a2/` | PASS |
| 從 Windows 匯出 EXE 實際執行 v3 GPU／七項點擊 | `.codex/builds/v3-final-export-test.json` | failed=0 |
| Windows 真正無參數啟動新版預覽 | `.codex/builds/LegendarySurvivor_CinematicMenu_v3_preview.exe` 及同名 `.pck` | 已在本機啟動並取得桌面截圖 |

## 待完成，不得誤報

- 目前主機甲仍來自原始 96px 像素角色圖的整數倍率佔位，**不是**高解析重繪、胸甲／雙臂／頭部獨立分層骨架。此階段只有機庫／光束／粉塵／UI／轉場動效；真正的機甲關節待機動畫需要多層素材。
- 尚未取得獨立 `visual-reviewer` 及 `reviewer` 的 SF-17 審查意見；不可稱整個遊戲正式驗收完成。
- 60FPS 實測幀時間與降低動態設定的 UI 正式整合尚未完成。v3 目前可使用啟動參數 `--reduce-motion` 降低主要動態。
- SF-16 成長平衡及先前要求的 100 場手動 Computer Use 完整遊玩均不是這次 UI 驗收項目的通過結果。

## 還原與隔離

- 修改前還原點：`.codex/restorepoints/20261019-cinematic-menu-v3-isolated/`。
- 保留原本其他 dirty 工作檔、正式玩家存檔、舊預覽執行檔、Git HEAD。
- 沒有推送 GitHub 或部署。
