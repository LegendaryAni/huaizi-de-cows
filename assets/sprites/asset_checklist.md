# 素材需求檢查清單

> 此為《傳奇倖存者》v0.1 **歷史原型素材紀錄**，不代表現行 v0.2 科幻機甲遊戲的執行時資產。現行素材請依 `assets/sprites/scifi/`、`assets/sprites/ui/runtime/scifi/`、`assets/sprites/vfx/runtime/scifi/` 與 `assets/audio/scifi/` 驗證。

依據：`../../spec/遊戲機制.md`

檢查物件：`assets/sprites/`、`assets/audio/`

## 結論

當前新版手繪素材已經覆蓋遊戲機制檔案裡的美術素材需求：全圖正常亮度的固定戶外清晰底圖、可疊加地圖環境與邊界、花子、三種貓彈、四種奶牛敵人，以及升級/UI/結算/提示、命中特效、經驗反饋、死亡煙塵、碎屑和粒子的風格參考。UI 總參考圖已經拆出控制元件級參考 crop，見 `ui/reference_crops/` 和 `ui/ui_asset_manifest.json`。

執行時使用規則需要區分：花子、奶牛、貓等角色/彈體素材優先直接使用 8 向圖集；UI、圖示、命中、爆炸、粒子等非角色視覺素材不得直接使用原素材檔案作為最終遊戲資產，必須按實際 HUD、彈窗、按鈕、特效半徑、動效幀數和透明邊距重新生成合適尺寸和格式的定製資產。HUD、條形 UI、技能槽、升級卡片、按鈕、暫停和結算等 UI 控制元件還必須逐項和參考 crop 對比，每一次對比都要記錄，風格相似度與資產完成度都達到 0.90 以上，且真實截圖和動態幀中不能有控制元件重疊、裁切或遮擋；任一控制元件不達標就必須重新生成或調整後再驗收。

另外已補充 8 向 Godot 圖集：花子、四種奶牛敵人、橘貓整貓撲擊、黑貓整貓撲擊、奶滴遠端彈。它們用於解決俯視 45 度場景裡多個方向顯示的問題。

音訊素材已補充到 `assets/audio/sfx/`，授權和檔案對映見 `assets/audio/LICENSES.md`。敵人閃白、無敵閃爍、震屏、打擊停頓適合在 Godot 裡用程式碼或 shader 做，不需要單獨圖片素材。

## 新版主素材

| 檔案 | 覆蓋內容 |
| --- | --- |
| `full_outdoor_map_painted_4096x2305.png` | 固定戶外清晰底圖，全圖正常亮度，不內建隔擋/環境裝飾/暗角 |
| `environment_assets_painted.png` | 泥地、草地、深淺地塊、草叢、石頭、小土堆、落葉、圍欄、樹牆、石牆、水面邊界 |
| `ui_assets_painted.png` | 血量條、升級三選一卡片、勝利/失敗結算頁、暫停介面、4 個升級圖示、HUD 武器圖示、波次提示、獲得新貓提示的風格參考；控制元件級 crop 已拆到 `ui/reference_crops/`，執行時 UI 需要按 `ui/README.md` 定製生成 |
| `ui/ui_asset_manifest.json` | UI 控制元件參考 crop、建議執行時資產名、用途和 Godot 接入方式的對映 |
| `combat_assets_painted.png` | 花子、橘貓、黑貓、奶牛貓、普通奶牛、瘋跑小牛、厚皮大奶牛、吐奶遠端牛、奶滴彈、命中、爆炸、經驗、吸附、死亡煙塵、碎屑、粒子的風格參考；角色/彈體用 8 向圖集，VFX 需要定製生成 |
| `huazi_8dir_192x192.png` | 花子 8 向待機 / 行走 |
| `cow_normal_8dir_256x192.png` | 普通奶牛 8 向行走，已校正為普通荷斯坦奶牛形體 |
| `cow_calf_8dir_192x144.png` | 瘋跑小牛 8 向奔跑 |
| `cow_tank_8dir_320x224.png` | 厚皮大奶牛 8 向行走，已校正為厚重 8 向姿態 |
| `cow_ranged_8dir_288x192.png` | 吐奶遠端牛 8 向行走，不包含奶滴彈 |
| `orange_cat_projectile_8dir_192x128.png` | 橘貓整貓直線撲擊 8 向飛行 |
| `black_cat_projectile_8dir_192x128.png` | 黑貓整貓範圍撲擊 8 向飛行 |
| `cow_cat_spin_8dir_192x128.png` | 奶牛貓迴旋掃場彈 8 向 |
| `milk_drop_8dir_192x128.png` | 奶滴遠端彈 8 向飛行 |
| `painted_regen_manifest.json` | 新版素材總清單 |
| `directional_asset_manifest.json` | 8 向補充素材清單 |
| `cow_ranged_muzzle_offsets.json` | 吐奶遠端牛各方向奶滴生成偏移 |
| `full_outdoor_map_manifest.json` | 新版完整地圖尺寸、出生點、刷怪區、視覺邊界 |

## 音訊素材

| 檔案 | 覆蓋內容 |
| --- | --- |
| `assets/audio/sfx/cat_orange_launch_01.ogg` | 橘貓發射 |
| `assets/audio/sfx/cat_black_launch_01.ogg` | 黑貓發射 |
| `assets/audio/sfx/cat_cow_spin_01.ogg` | 奶牛貓迴旋發射 |
| `assets/audio/sfx/milk_launch_01.ogg` | 遠端牛奶滴發射 |
| `assets/audio/sfx/hit_soft_01.ogg` | 普通命中 |
| `assets/audio/sfx/cat_black_explode_01.ogg` | 黑貓爆炸 |
| `assets/audio/sfx/player_hurt_01.ogg` | 玩家受擊 |
| `assets/audio/sfx/enemy_die_01.ogg` | 敵人死亡 |
| `assets/audio/sfx/xp_pickup_01.ogg` | XP 拾取 |
| `assets/audio/sfx/level_up_01.ogg` | 升級 |
| `assets/audio/sfx/ui_select_01.ogg` | UI 選擇 / 升級選擇 |
| `assets/audio/sfx/wave_start_01.ogg` | 波次開始 |
| `assets/audio/sfx/weapon_unlock_01.ogg` | 解鎖新貓 |
| `assets/audio/sfx/victory_01.ogg` | 勝利 |
| `assets/audio/sfx/defeat_01.ogg` | 失敗 |

## 逐項檢查

| 機制需求 | 狀態 | 新版素材 |
| --- | --- | --- |
| 固定戶外大地圖 | 已覆蓋，作為全圖正常亮度的清晰底圖 | `full_outdoor_map_painted_4096x2305.png` |
| 地圖泥地 | 已覆蓋 | `environment_assets_painted.png` |
| 地圖草地 / 深淺地塊 | 已覆蓋 | `environment_assets_painted.png` |
| 草叢 | 已覆蓋 | `environment_assets_painted.png` |
| 石頭 | 已覆蓋 | `environment_assets_painted.png` |
| 小土堆 | 已覆蓋 | `environment_assets_painted.png` |
| 落葉 | 已覆蓋 | `environment_assets_painted.png` |
| 圍欄邊界 | 已覆蓋 | `environment_assets_painted.png` |
| 樹牆邊界 | 已覆蓋 | `environment_assets_painted.png` |
| 石牆邊界 | 已覆蓋 | `environment_assets_painted.png` |
| 水面邊界 | 已覆蓋 | `environment_assets_painted.png` |
| 花子 | 已覆蓋 | `combat_assets_painted.png` / `huazi_8dir_192x192.png` |
| 花子受擊反饋 | 已覆蓋風格參考，執行時可用 shader、`modulate` 或定製特效實現 | `combat_assets_painted.png` |
| 花子多方向顯示 | 已覆蓋 | `huazi_8dir_192x192.png` |
| 橘貓直線撲擊 | 已覆蓋 | `combat_assets_painted.png` / `orange_cat_projectile_8dir_192x128.png` |
| 橘貓整貓多方向撲擊 | 已覆蓋 | `orange_cat_projectile_8dir_192x128.png` |
| 黑貓範圍攻擊 | 已覆蓋 | `combat_assets_painted.png` / `black_cat_projectile_8dir_192x128.png` |
| 黑貓整貓多方向撲擊 | 已覆蓋 | `black_cat_projectile_8dir_192x128.png` |
| 奶牛貓迴旋掃場 | 已覆蓋 | `combat_assets_painted.png` / `cow_cat_spin_8dir_192x128.png` |
| 奶牛貓迴旋彈多方向顯示 | 已覆蓋 | `cow_cat_spin_8dir_192x128.png` |
| 普通奶牛 | 已覆蓋，8 向圖集已校正為普通荷斯坦奶牛形體 | `combat_assets_painted.png` / `cow_normal_8dir_256x192.png` |
| 瘋跑小牛 | 已覆蓋 | `combat_assets_painted.png` / `cow_calf_8dir_192x144.png` |
| 厚皮大奶牛 | 已覆蓋，8 向圖集已校正為厚重姿態，避免側視旋轉偽影 | `combat_assets_painted.png` / `cow_tank_8dir_320x224.png` |
| 吐奶遠端牛 | 已覆蓋 | `combat_assets_painted.png` / `cow_ranged_8dir_288x192.png` |
| 敵人多方向顯示 | 已覆蓋 | `cow_normal_8dir_256x192.png`、`cow_calf_8dir_192x144.png`、`cow_tank_8dir_320x224.png`、`cow_ranged_8dir_288x192.png` |
| 慢速奶滴彈 | 已覆蓋 | `combat_assets_painted.png` / `milk_drop_8dir_192x128.png` |
| 慢速奶滴彈多方向飛行 | 已覆蓋 | `milk_drop_8dir_192x128.png` |
| 吐奶遠端牛發射點 | 已覆蓋 | `cow_ranged_muzzle_offsets.json` |
| 貓攻擊命中反饋 | 已覆蓋風格參考，執行時需定製生成 | `combat_assets_painted.png` |
| 黑貓爆炸特效 | 已覆蓋風格參考，執行時需定製生成 | `combat_assets_painted.png` |
| 經驗球 / 經驗吸附反饋 | 已覆蓋風格參考，執行時需定製生成 | `combat_assets_painted.png` |
| 敵人死亡煙塵 / 碎屑 | 已覆蓋風格參考，執行時需定製生成 | `combat_assets_painted.png` |
| 粒子小圖集 | 已覆蓋風格參考，執行時需定製生成 | `combat_assets_painted.png` |
| 血量條 | 已覆蓋控制元件級參考 crop，執行時需定製生成 | `ui/reference_crops/hud_health_bar_ref.png` |
| 升級三選一卡片 | 已覆蓋控制元件級參考 crop，執行時需定製生成 | `ui/reference_crops/upgrade_card_normal_ref.png`、`upgrade_card_gold_ref.png`、`upgrade_card_red_ref.png` |
| 勝利結算頁 | 已覆蓋控制元件級參考 crop，執行時需定製生成 | `ui/reference_crops/panel_result_warm_ref.png` |
| 失敗結算頁 | 已覆蓋控制元件級參考 crop，執行時需定製生成 | `ui/reference_crops/panel_result_dark_ref.png` |
| 暫停介面 | 已覆蓋控制元件級參考 crop，執行時需定製生成 | `ui/reference_crops/panel_result_dark_ref.png` |
| 4 個升級圖示 | 已覆蓋控制元件級參考 crop，執行時需定製生成 | `ui/reference_crops/upgrade_icon_*_ref.png` |
| HUD 武器圖示 | 已覆蓋控制元件級參考 crop，執行時需定製生成 | `ui/reference_crops/weapon_icon_*_ref.png` |
| 波次提示 | 已覆蓋控制元件級參考 crop，執行時需定製生成 | `ui/reference_crops/notice_panel_wide_ref.png` |
| 獲得新貓提示 | 已覆蓋控制元件級參考 crop，執行時需定製生成 | `ui/reference_crops/weapon_banner_*_ref.png` |
| 發貓 / 命中 / 爆炸 / 受擊 / 結算音效 | 已覆蓋 | `assets/audio/sfx/*.ogg` |

## 不屬於圖片素材

| 需求 | 建議實現 |
| --- | --- |
| 敵人受擊閃白或閃爍 | Godot shader、`modulate` 或 tween |
| 花子無敵時間閃爍 | Godot shader、`modulate` 或 tween |
| 輕微震屏 | `Camera2D` 抖動 |
| 打擊停頓 | 短暫停幀或時間縮放 |
| 貓彈數量上限 | 遊戲邏輯 |
| 更像真實貓叫 / 牛叫的擬聲音效 | 當前音效可用於正常可用版本；如要更動物化，需要額外製作或尋找 CC0 音源，並更新 `assets/audio/LICENSES.md` |

舊版方塊地圖、舊非 8 向圖集、舊 UI 單圖和除錯預覽已從基準目錄清理掉。當前主素材以上表為準。
