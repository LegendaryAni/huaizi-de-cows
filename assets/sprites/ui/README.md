# UI 資源拆分說明

> v0.2使用科幻畫素主題：`reference_crops/scifi/` 為處理後參考，`runtime/scifi/` 為正式資產，生成原圖保留 `assets/source/scifi/`。舊手繪crop不再是新版材質目標；三張並排大卡、字區與正式資產等原則保留。HUD/卡片/按鈕以生成panel裁切與ninepatch整理，不以預設單色控制元件代替。

以下主要記錄 v0.1 歷史 UI 素材；現行《傳奇倖存者》v0.2 優先參考 `runtime/scifi/` 與 `reference_crops/scifi/`，不要以早期卡片材質取代現行科幻版 UI。

本文說明 `ui_assets_painted.png` 被拆成哪些控制元件級參考圖，以及後續執行時 UI 資產應該怎樣生成和接入。

## 目錄職責

- `reference_crops/`：從 `../ui_assets_painted.png` 直接裁出的控制元件級參考圖。它們用於鎖定視覺目標、裁切範圍和區域性細節，不直接等同於最終執行時控制元件。
- `runtime/`：Godot 實現應該引用的執行時 UI 資產目錄。這裡放按實際尺寸、透明邊距、九宮格拉伸區和文字安全區整理後的 PNG、`.9.png` 或 `.tres`。
- `ui_asset_manifest.json`：每個參考 crop 的來源 bbox、用途、建議執行時檔名和 Godot 接入方式。

程式碼裡不要引用 `.import` 檔案；`.import` 是 Godot 自動生成的匯入後設資料。執行時程式碼應引用 `res://assets/sprites/ui/runtime/...`，或引用由這些 PNG 建出的 `.tres`。

## 使用原則

1. 需要做 HUD、升級彈窗、結算、暫停、提示橫幅或圖示時，先查 `ui_asset_manifest.json`。
2. 如果 `runtime/` 下缺少對應資產，先基於 `reference_crops/` 生成或整理執行時資產，再寫 UI 實現。
3. 不允許用純 `draw_rect`、`draw_line`、`draw_circle`、預設 `Button`、預設 `Panel` 或單色 `StyleBoxFlat` 來模擬升級卡、HUD 主框、結算面板這類核心 UI 外觀。
4. 程式碼繪製可以用於文字、數值、填充條、輕量 hover 光效、短暫點選反饋和佈局輔助，但核心邊框、底紋、徽章、做舊材質和裝飾性邊角必須來自執行時 UI 資產。
5. 不能直接把 `ui_assets_painted.png` 當作執行時 atlas 整張載入後隨意裁用。需要先拆出 crop，明確用途，再生成適合實際尺寸的執行時資產。
6. 每次實現或重做核心 UI，都要保留參考 crop、執行截圖 crop 和並排對照圖，證明邊框材質、比例、視覺重心和文字安全區沒有偏離。

## 升級三選一卡片

升級彈窗使用三張並排豎向大卡片。卡片執行時建議顯示尺寸為 `320x540`，可在不破壞比例的前提下小幅調整，但不能改成長條按鈕、普通選單列表或預設系統面板。

| 控制元件 | 參考 crop | 建議執行時資產 | 用法 |
| --- | --- | --- | --- |
| 普通升級卡 | `reference_crops/upgrade_card_normal_ref.png` | `runtime/upgrade_card_normal.9.png` | 普通可選卡片背板 |
| 高亮升級卡 | `reference_crops/upgrade_card_gold_ref.png` | `runtime/upgrade_card_gold.9.png` | hover、推薦態或當前聚焦卡片 |
| 攻擊強調升級卡 | `reference_crops/upgrade_card_red_ref.png` | `runtime/upgrade_card_red.9.png` | 攻擊類升級或危險強調態，可選 |
| U01 圖示 | `reference_crops/upgrade_icon_cat_swarm_ref.png` | `runtime/upgrade_icon_cat_swarm.png` | 貓貓連發 |
| U02 圖示 | `reference_crops/upgrade_icon_damage_ref.png` | `runtime/upgrade_icon_damage.png` | 貓爪變鋒利 |
| U04 圖示 | `reference_crops/upgrade_icon_player_speed_ref.png` | `runtime/upgrade_icon_player_speed.png` | 跑快一點 |

建議文字安全區按 `320x540` 卡片尺寸記錄：

| 區域 | 建議範圍 |
| --- | --- |
| 標題 | `x=36..284, y=42..96` |
| 主圖示 / 主內容區 | `x=44..276, y=112..310` |
| 說明區 | `x=36..284, y=340..456` |
| 底部徽章 | 中心約 `x=160, y=492`，半徑約 `34` |
| 九宮格邊距 | `left=42, top=42, right=42, bottom=78` |

## HUD、面板和圖示

| 控制元件 | 參考 crop | 建議執行時資產 | 用法 |
| --- | --- | --- | --- |
| 花子頭像框 | `reference_crops/hud_avatar_huazi_ref.png` | `runtime/hud_avatar_frame.png` | HUD 左上頭像 |
| 血條/經驗條框 | `reference_crops/hud_health_bar_ref.png` | `runtime/hud_bar_frame.9.png` | HUD 條形背板，填充層另做 |
| 暖色結算面板 | `reference_crops/panel_result_warm_ref.png` | `runtime/panel_result_warm.9.png` | 勝利/結算背板 |
| 暗色結算面板 | `reference_crops/panel_result_dark_ref.png` | `runtime/panel_result_dark.9.png` | 失敗/暫停背板 |
| 頂部提示橫幅 | `reference_crops/notice_panel_wide_ref.png` | `runtime/notice_panel_wide.9.png` | 波次、新貓提示 |
| 三種貓武器槽圖示 | `reference_crops/weapon_icon_*_ref.png` | `runtime/weapon_icon_*.png` | HUD 已解鎖貓圖示 |

## 生成和驗收要求

執行時 UI 資產生成後，至少補齊下面幾類證據：

- `ui_reference_crop_*.png`：使用到的參考 crop。
- `ui_runtime_asset_*.png`：生成後的執行時資產。
- `ui_runtime_screenshot_*.png`：真實執行截圖 crop。
- `ui_compare_*.png`：參考 crop 與執行截圖並排對照。
- 簡短說明：哪些地方繼承了參考圖，哪些地方因為文字、尺寸或可互動狀態做了調整。

如果核心 UI 仍主要由程式碼畫矩形和圓形組成，即使佈局接近，也不能視為符合素材接入要求。
