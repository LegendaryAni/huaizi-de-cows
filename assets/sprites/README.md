# Godot 素材說明

> v0.2有效規格為 `spec/20261017_LegendarySurvivor_Scifi_v0.2.md`。目前科幻角色/地圖用 `scifi/`、UI/VFX用對應runtime/scifi目錄，畫素Nearest；舊手繪圖與Linear規則只適用v0.1。新UI參考在 `ui/reference_crops/scifi/`，保持HUD資訊、三卡結構與真實畫面證據要求。

倉庫保留原始的高對比暗色漫畫街機素材作為基線；當前執行時已切換到 `legendaryani/` 的明亮手繪貼紙 / 繪本風主題。新版仍維持原有圖集格數、地圖尺寸、環境 atlas 版位與 UI 結構，因此玩法、碰撞與方向動畫語義不變。固定戶外大地圖仍是全圖正常亮度的連續手繪底圖，不預烘焙暗角或角色中心光照；環境層由 Godot 疊加。

## 主檔案

| 檔案 | 用途 |
| --- | --- |
| `legendaryani/` | 當前執行時角色、貓、奶牛、奶滴、地圖與環境主題；來源與生成方式見 `legendaryani/README.md` |
| `ui/runtime/legendaryani/` | 當前執行時 HUD、按鈕、升級卡、圖示與結算面板主題 |
| `vfx/runtime/legendaryani/` | 當前執行時命中、爆炸、死亡煙塵與經驗視覺主題 |
| `full_outdoor_map_painted_4096x2305.png` | 固定戶外清晰底圖，直接作為背景使用，全圖正常亮度，不內建隔擋/環境裝飾/暗角 |
| `environment_assets_painted.png` | 地圖素材表：泥地、草地、深淺地塊、草叢、石頭、小土堆、落葉、圍欄、樹牆、石牆、水面邊界 |
| `ui_assets_painted.png` | UI 與圖示風格參考素材表：血量條、升級三選一卡片、勝利/失敗結算頁、暫停介面、4 個升級圖示、HUD 武器圖示、波次/新貓提示。控制元件級參考 crop 和執行時資產規則見 `ui/README.md` |
| `ui/` | UI 控制元件拆分目錄：`reference_crops/` 存放從總參考圖裁出的控制元件級視覺錨點，`runtime/` 存放 Godot 程式碼實際引用的執行時 UI 資產，`ui_asset_manifest.json` 記錄對映關係 |
| `combat_assets_painted.png` | 戰鬥風格參考素材表：花子、三種貓彈、四種奶牛敵人、命中/爆炸/經驗/死亡煙塵/碎屑/粒子。角色/貓/奶牛優先使用 8 向圖集；命中、爆炸、粒子等 VFX 需要按實際效果重新生成 |
| `huazi_8dir_192x192.png` | 花子 8 向待機 / 行走圖集 |
| `cow_normal_8dir_256x192.png` | 普通奶牛 8 向行走圖集，使用校正後的普通荷斯坦奶牛源圖 |
| `cow_calf_8dir_192x144.png` | 瘋跑小牛 8 向奔跑圖集 |
| `cow_tank_8dir_320x224.png` | 厚皮大奶牛 8 向行走圖集，使用校正後的厚重 8 向源圖 |
| `cow_ranged_8dir_288x192.png` | 吐奶遠端牛 8 向行走圖集，不包含奶滴彈 |
| `orange_cat_projectile_8dir_192x128.png` | 橘貓整貓直線撲擊 8 向飛行動畫 |
| `black_cat_projectile_8dir_192x128.png` | 黑貓整貓範圍撲擊 8 向飛行動畫 |
| `cow_cat_spin_8dir_192x128.png` | 奶牛貓迴旋掃場彈 8 向動畫 |
| `milk_drop_8dir_192x128.png` | 奶滴遠端彈 8 向飛行動畫 |
| `painted_regen_manifest.json` | 新版素材總清單 |
| `directional_asset_manifest.json` | 8 向補充素材清單 |
| `cow_ranged_muzzle_offsets.json` | 吐奶遠端牛各方向的建議奶滴生成偏移 |
| `full_outdoor_map_manifest.json` | 新版完整地圖尺寸、出生點、刷怪區和視覺邊界 |

## 音訊檔案

音訊素材放在 `assets/audio/sfx/`，授權和來源記錄見 `assets/audio/LICENSES.md`。音訊不是可選項；發貓、命中、黑貓爆炸、敵人死亡、玩家受擊、XP、升級、升級選擇、波次開始、武器解鎖、勝利和失敗都應接入對應 SFX。

## Godot 接入

1. 把 `assets/sprites/` 放到 Godot 專案內。
2. 完整地圖用 `full_outdoor_map_painted_4096x2305.png` 建立 `Sprite2D` 或背景層，環境裝飾和隔擋碰撞再由 Godot 疊加。
3. `environment_assets_painted.png` 可按需要切成 `AtlasTexture`、`NinePatchRect`、`TextureRect` 或匯入到 `SpriteFrames`。
4. `ui_assets_painted.png` 和 `combat_assets_painted.png` 中的 UI、命中、爆炸、粒子等非角色元素只做風格參考。UI 控制元件先使用 `ui/reference_crops/` 鎖定參考區域，再生成適合當前控制元件尺寸、縮放方式、透明邊距和動效節奏的執行時 PNG/WebP/Atlas/NinePatch/粒子貼圖，並記錄生成資產、參考來源和用途。
5. 不得直接把原 UI 素材或原爆炸/粒子素材檔案切片後當作最終 HUD、彈窗、按鈕、命中特效或爆炸特效；否則容易出現拉伸、裁切、漏邊、層級錯亂或語義錯誤。
6. 只記錄風格參考路徑不夠。生成 UI/VFX 前必須裁出或說明參考區域，拆解手繪描邊、做舊材質、木牌/皮革/金屬邊框、暖色高對比、貓頭像徽章、裝飾性邊角、戰鬥碎屑/煙塵節奏等特徵；生成後必須儲存參考 crop 與最終執行截圖的並排對照和差異說明。
7. HUD 外框、血量條、經驗條、技能槽、升級卡片、升級圖示、按鈕、提示、暫停介面和結算介面等執行時 UI 控制元件必須逐項驗收；每一次對比都要記錄參考 crop、執行截圖 crop、並排對照圖、相似度、完成度和差異說明。所有 UI 控制元件的風格相似度和資產完成度都要達到 0.90 以上，任何單項不達標或缺少記錄都必須退回重做。
8. 生成 UI 強烈建議優先使用影象生成、區域性重繪、NinePatch、AtlasTexture、TextureRect、指令碼化點陣圖生成或其他合適流程，再把生成結果調整為遊戲需要的尺寸、透明邊距、格式和匯入方式；不要只依賴 Godot 原生 Control、ColorRect、StyleBox、Label 或程式碼繪製來模擬參考圖效果，不能直接切 `ui_assets_painted.png` 原圖當最終控制元件。
9. Godot 程式碼不要引用 `.import` 檔案。核心 UI 應引用 `res://assets/sprites/ui/runtime/` 下的執行時資產，或引用由這些資產建出的 `.tres`。如果 `runtime/` 下沒有對應資產，先補資產，不允許退回純程式碼畫框。
10. UI 完成前必須儲存並親自檢視關鍵狀態截圖和執行中連續幀，檢查控制元件、文字、圖示、條形填充和點選區域沒有重疊、裁切、遮擋、跳位或被戰鬥特效壓住的問題；動態幀確認正常後才能標記完成。
11. UI 預設使用中文文案，升級、波次、結算和按鈕文字不要混入英文模板，除非任務明確要求。
12. 角色、敵人和方向敏感彈體優先使用 `*_8dir_*.spriteframes.tres`。
13. 8 向圖集行順序固定為 `e / se / s / sw / w / nw / n / ne`，每行 4 幀。
14. 動畫命名示例：花子 `walk_e`、`walk_se`、`idle_s`；牛 `walk_e` 或 `run_e`；彈體 `fly_e`。
15. 吐奶遠端牛隻用 `cow_ranged_8dir_288x192.png` 播牛本體；奶滴用 `milk_drop_8dir_192x128.png` 單獨生成，發射點偏移見 `cow_ranged_muzzle_offsets.json`。
16. 普通牛和厚皮牛使用單獨校正後的完整 8 向源圖，執行時圖集已穩定每幀 cell 錨點；小牛、吐奶遠端牛仍是側視源圖補足八向：左右用映象，斜向/上下用有限旋轉。
17. 這批圖是手繪描邊風，匯入過濾建議先用 `Linear`；如果專案整體做畫素縮放，再改為 `Nearest`。
18. 地圖碰撞邊界建議用程式碼/碰撞形狀沿畫面邊緣配置，不依賴環境裝飾圖本身。
19. 音訊新增或複製後，先執行 Godot editor headless 匯入，再檢查執行時載入數量和關鍵音效事件。

## 預覽

開啟 `preview.html` 可以看新版素材總覽。

舊版方塊地圖、舊非 8 向圖集、舊 UI 單圖和除錯預覽已從基準目錄清理掉。當前開發只按上面的主檔案接入。

生成源圖集中放在 `assets/source/`，不是 Godot 執行時優先接入目錄。
