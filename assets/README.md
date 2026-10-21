# 遊戲資源使用說明

## 目前版本 v0.2

科幻改造的正式角色、地圖與物件在 `assets/sprites/scifi/`，UI在 `assets/sprites/ui/runtime/scifi/`，VFX在 `assets/sprites/vfx/runtime/scifi/`。入口與生成方法見 `assets/sprites/scifi/README.md`；來源圖僅供處理，不由遊戲載入。下列手繪主題敘述保留為v0.1歷史。

本文說明當前倉庫有哪些遊戲資源、哪些可以直接作為 Godot 執行時資源、哪些只作為風格參考，以及新增或接入資源時要讀哪些檔案。

## v0.1 歷史素材規則（非目前執行時）

以下條目保存早期原型的目錄與素材設計；現行《傳奇倖存者》v0.2 的機甲與科幻資產已列於本文件開頭。

## 執行時優先使用

- `assets/sprites/`：地圖、環境、花子、敵人、貓彈、奶滴、SpriteFrames 和視覺參考素材；當前執行時主題位於 `assets/sprites/legendaryani/`。
- `assets/audio/sfx/`：執行時音效檔案。

## 圖片資源

圖片資源接入規則見 `assets/sprites/README.md`。

開發時重點區分：

- 地圖、花子、敵人、貓彈、奶滴：優先使用現有執行時素材和 `.spriteframes.tres`。
- `ui_assets_painted.png`：UI 和圖示風格參考，不直接切片當最終 UI；控制元件級參考 crop 和接入規則見 `assets/sprites/ui/README.md`。
- `assets/sprites/ui/reference_crops/`：從 UI 總參考圖拆出的控制元件級參考圖，用來鎖定視覺目標。
- `assets/sprites/ui/runtime/`：Godot 執行時程式碼應引用的 UI 資產目錄；當前主題使用 `assets/sprites/ui/runtime/legendaryani/`。
- `combat_assets_painted.png`：戰鬥 VFX 風格參考；角色、敵人、貓彈按 8 向圖集使用，命中、爆炸、粒子等 VFX 需要定製生成。
- `assets/source/`：源圖和生成素材，不作為 Godot 執行時優先資源。

## 音訊資源

音訊使用說明見 `assets/audio/README.md`。音效檔案在 `assets/audio/sfx/`；授權來源和檔案對映見 `assets/audio/LICENSES.md`。

## 已確認資源覆蓋

歷史 v0.1 原型的資產曾覆蓋舊版地圖、角色、敵人與 UI/VFX；不可用此段推定現行 v0.2 科幻素材已完成正式驗收。日常開發不需要重新判斷資源夠不夠，重點是按說明正確接入和驗證。
