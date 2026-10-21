# LegendaryAni 視覺主題

當前運行時使用這一套替換美術，而不是直接覆蓋倉庫原始素材。

## 視覺方向

- 明亮、柔和的手繪貼紙 / 繪本風。
- 主色以暖奶油色、珊瑚橙、柔和青綠與鼠尾草綠為主。
- 保留原有 8 向動畫格數、方向、尺寸、碰撞語義與地圖尺寸，避免影響玩法。
- UI、VFX 與角色使用同一套色彩語言，原始暗色漫畫素材保留在原目錄，方便回退與比對。

## 生成與來源

- 玩家圖集以 `assets/source/legendaryani_huazi_pilot.png` 為圖像生成結果，再套回原 `huazi_8dir_192x192.png` 的透明度遮罩，確保 4×8 格線與透明邊界不變。
- 其餘角色、貓、奶滴、地圖、環境、UI 與 VFX 由 `tools/build_legendaryani_art.py` 從倉庫現有素材重建為本主題版本。
- 生成腳本不會覆蓋原圖；運行時通過 `scripts/` 中的資源路徑切換到本目錄和 `ui/runtime/legendaryani/`、`vfx/runtime/legendaryani/`。

## 原始項目來源

本主題是當前版本的修改內容。原始項目仍保留為 `mewamew/huaizi-de-cows`，原始 Git 作者為 HexBlank；遊戲內開發團隊頁與根目錄 `README.md` 同樣保留這項來源信息。
