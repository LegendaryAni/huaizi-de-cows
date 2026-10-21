# 遊戲資源使用說明

本文說明當前儲存庫有哪些遊戲資源、哪些可以直接作為 Godot 執行時資源、哪些只作為風格參考，以及新增或接入資源時要讀哪些文件。

## 執行時優先使用

- `assets/sprites/`：地圖、環境、花子、敵人、貓彈、奶滴、SpriteFrames 和視覺參考素材。
- `assets/audio/sfx/`：執行時音效文件。

## 圖片資源

圖片資源接入規則見 `assets/sprites/README.md`。

開發時重點區分：

- 地圖、花子、敵人、貓彈、奶滴：優先使用現有執行時素材和 `.spriteframes.tres`。
- `ui_assets_painted.png`：UI 和圖標風格參考，不直接切片當最終 UI；控制元件級參考 crop 和接入規則見 `assets/sprites/ui/README.md`。
- `assets/sprites/ui/reference_crops/`：從 UI 總參考圖拆出的控制元件級參考圖，用來鎖定視覺目標。
- `assets/sprites/ui/runtime/`：Godot 執行時程式碼應引用的 UI 資產目錄；缺少資產時先生成資產，再寫 UI。
- `combat_assets_painted.png`：戰鬥 VFX 風格參考；角色、敵人、貓彈按 8 向圖集使用，命中、爆炸、粒子等 VFX 需要定製生成。
- `assets/source/`：源圖和生成素材，不作為 Godot 執行時優先資源。

## 音訊資源

音訊使用說明見 `assets/audio/README.md`。音效文件在 `assets/audio/sfx/`；授權來源和文件映射見 `assets/audio/LICENSES.md`。

## 已確認資源覆蓋

當前資源已覆蓋正常可用版本需要的地圖、角色、敵人、貓彈、UI/VFX 風格參考和音效。日常開發不需要重新判斷資源夠不夠，重點是按說明正確接入和驗證。
