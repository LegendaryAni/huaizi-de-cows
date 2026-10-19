# 科幻畫素 runtime 資產 v0.2

來源為使用者指定對話《規劃新手引導與通關驗收》的《殖星鐵衛》本機專案。只複製影象及動畫metadata，未改來源專案、未搬入網頁遊戲核心或存檔。

- `units/1103` 主角；`2101/2106/2103/2105` 四怪；`3101` 首領。PNG原樣複製、`frames.tres` 依來源方向/錨點/60Hz duration資料建立。
- `map.png` 是原始備份地圖；`map_detail.png` 是原生4096×2305加上細節的現行地圖（僅地圖採LINEAR平滑取樣）。`map_obstacles.json` 使用與原地圖相同的確定性擺設順序，為50個實體擺設底座產生碰撞形狀；產生器 `tools/build_scifi_world.py`。
- `../ui/runtime/scifi/` 面板與圖示由OpenAI image_gen補製；生成原圖留在 `assets/source/scifi/`，參考在 `../ui/reference_crops/scifi/`，無生成中文字。
- `../vfx/runtime/scifi/` 優先裁取來源projectile/impact表，迴旋刃、XP與煙塵等使用新生成裝備/FX表。
- 可重跑 `python tools/prepare_scifi_art.py` 作確定性處理。它不畫角色姿勢，不鏡射或虛構方向；角色來源原檔雜湊、生成來源與所有輸出雜湊見 `manifest.json`。
- 角色、裝備、地圖、VFX由Godot以Nearest呈現。UI文字由Godot系統中文字型繪製，不放進影象。

本機來源素材原先由OpenAI image_gen產生，紀錄見來源 `assets/animation-provenance.json`；它的歷史QC不是本專案的新版驗收，仍須本輪Godot執行與獨立視覺複核。既有HexBlank/mewamew來源與音訊說明保留。
