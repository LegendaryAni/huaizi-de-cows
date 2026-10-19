# 《傳奇倖存者》打擊感與 UI 可視邊界修正 v3

日期：2026-10-19。沿用 Godot 4.7.2／1920×1080 邏輯視口與 1600×900 預設視窗；本次不修改正式遊戲戰鬥數值或存檔格式。

## 修改前儲存

- 還原點：`.codex/restorepoints/20261019-hit-feel-ui-bounds-v3/`。
- 保留原有 dirty worktree；不執行 `git reset`、`git clean`、GitHub push 或正式發布。

## 打擊感增強（純視覺呈現）

- `ScifiActor.gd`：六武器不同受擊色調、短暫 2D 壓縮／後仰、輕重攻擊不同演出時間；受擊結束後復原原始 Sprite scale、modulate、position，不影響 CharacterBody2D 真正座標／碰撞／速度。
- `ScifiMain.gd`：榴彈及重型敵人中彈使用瞬間擴散衝擊圈，重型與首領被擊倒時有另一個短暫衝擊圈；命中／擊殺計算仍沿用原本程式。既有六武器衝擊 VFX、音效、重型鏡頭回饋保留。
- `assets/sprites/vfx/runtime/scifi/impact_ring.png`：新增單張原創短暫碎裂亮環（透明背景，不是遊戲中常駐幾何 debug 標記），經原有 80 容量的 VFX 池回收使用。
- **不調整** `ScifiConfig.gd` 傷害、武器 CD、掉落、敵人 HP、角色移動、勝敗門檻或音效檔路徑。

## UI 避免超出視窗

- `ScifiMainMenuAligned.gd`：全畫面錨點是尺寸唯一來源，取消 `_ready()` 硬性設定 size 的衝突；長本機紀錄文字會在現有儲存格中自動調整字級。
- `ScifiUI.gd`：單行 Label 依分配寬度自動調整字級；長文字只在單一元件內適度裁切。**未對整個 root／popup 啟用 clip_contents**，因為這樣會阻斷部分畫面回返後的滑鼠點選。以所有可見控制項的真實座標檢查防止越界，而非隱藏整頁超出的內容。
- `ScifiTests.gd`：新增 `ui-bounds` 情境，於真正的 GPU 視口逐頁巡檢主選單、配裝、永久改裝、歷次成績、來源、設定、三頁教學、暫停、三選一升級、勝敗結算、離開確認與戰鬥 HUD。每頁需含真實可見控制項，全部可見的 Button/Label/TextureRect/NinePatchRect/ColorRect 邊界皆須落在 `1920×1080` 視口範圍。測試依頁面實際元件數判定，不強加與產品無關的元件數量。
- 修正根節點裁切回歸後的 1600×900 與 1920×1080 Godot GPU 報告：
  - `reports/scifi-tests/20261019-152844-ui-bounds-89a1c7d1/`
  - `reports/scifi-tests/20261019-152849-ui-bounds-fa5fe314/`
- 選單操作回歸 `menu-preview` PASS：`reports/scifi-tests/20261019-152806-menu-preview-b4b125d6/`，涵蓋設定返回後再進入教學、成績、改裝、來源與配裝。
- 原本普通戰鬥 HUD 與選牌卡片實際畫面仍保留，需要持續人工確認可讀性及關鍵資訊不被臨時演出遮擋。

## 驗證與界線

- 2026-10-19 本輪 `replay` PASS：`reports/scifi-tests/20261019-152131-replay-131fbfcd/`。
- 全部邏輯 `all` PASS：`reports/scifi-tests/20261019-152120-all-457112ac/`。
- 實際音效及 VFX `feedback-audio` PASS：`reports/scifi-tests/20261019-152237-feedback-audio-97e2cdfe/`。
- Windows 最終修正版預覽 `.codex/builds/LegendarySurvivor_hitfeel_ui_v3_1_preview.exe` 與同名 `.pck`（保留有選單回返問題的 v3 供差異追溯）；以最終匯出 EXE 隔離 Smoke，`failed=0`。
- 物件池壓力測試 PASS：`reports/scifi-tests/20261019-152854-pool-stress-51ab2d3f/`。先前一次 175 秒測試逾時紀錄保留，不拿來充當透過報告。
- **尚未取得獨立 visual-reviewer 與 reviewer 簽核**：本次 Chadex Runner 不支援 Coding-Agent Runs。不能宣稱 SF-17 已正式驗收。
- **既有 SF-16 三種子成長平衡未達目標**，本次不調整。先前要求的 100 場真人手動測試也不是本次回歸的替代品，不能從自動程式測試推稱 100 場人工實測。

## 回退

保留修改前 `restorepoints/20261019-hit-feel-ui-bounds-v3/` 之所有已修改原始檔；另保留上一個 `.codex/builds/LegendarySurvivor_menu_v2_preview.exe` 預覽，以便逐項比對。
