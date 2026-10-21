# 《傳奇倖存者》專案名稱、版本與歷史資料說明

更新：2026-10-21。本文件統一產品名稱及 AI 的文件讀取順序，不更動實際玩法、存檔格式、權利歸屬或歷史驗收事實。

## 現行產品

- 正式中文名稱：**傳奇倖存者**；英文名稱：**Legendary Survivor**。
- 引擎：Godot 4.7.2；語言：GDScript；類型：2D 俯視角科幻機甲生存動作遊戲。
- 現行玩法與數值：`spec/20261017_LegendarySurvivor_Scifi_v0.2.md`。
- 遊戲入口：`scenes/Main.tscn`；v3 電影式主選單仍由 `--menu-v3-preview` 開啟獨立預覽。
- 玩家可見文字以繁體中文（臺灣用語）為主、英文輔助。程式識別字、API、JSON key、檔名及路徑按實際依賴保留。

## 歷史原型的界線

- `spec/v0.1-傳奇倖存者-歷史原型.md`、`spec/遊戲機制.md`、`spec/視覺規格.md` 與 v0.1 測試文件保存早期原型，不是科幻 v0.2 的正式玩法。
- 早期貓、奶牛及戶外地圖內容是可追溯的歷史機制，**不得**用於覆蓋現行機甲角色、武器、地圖和敵人規格。
- 相關歷史素材、圖檔、JSON manifest、資源 ID 和 Godot 場景仍按原有路徑保留，避免破壞程式引用；只有對外產品名稱統一。
- v0.2 美術、介面及音效以 `assets/sprites/scifi/`、`assets/sprites/ui/runtime/scifi/`、`assets/sprites/vfx/runtime/scifi/`、`assets/audio/scifi/` 為準。
- `docs/development/acceptance-standard.md` 同時含有舊版 AC 與科幻版 SF 條款，執行時務必判斷版本，切勿直接沿用舊版限制。

## 存檔相容性與授權

- `project.godot` 的 `custom_user_dir_name` 是原有玩家存檔資料夾路徑。更名產品顯示文字不代表已完成存檔遷移；沒有完整備份、讀回與回復方案前不得改此設定。
- `scripts/GameConfig.gd` 等舊版資源名稱、音效檔名與技術識別字保留歷史用途；未授權進行破壞性全面改名。
- 上游 Git 專案來源、作者記錄及第三方授權條件不因品牌統一而消失。詳見 `README.md` 及 `assets/audio/LICENSES.md`。
- GitHub 儲存庫名稱、branch/ref 及 URL 是技術定位符，本輪不重新命名以免破壞現存 Git 歷史與外部連結。

## AI 開發文件讀取順序

1. `AGENTS.md` — 工作指令、權限、資料保護。
2. `spec/20261017_LegendarySurvivor_Scifi_v0.2.md` — 科幻版現行規格。
3. `docs/development/acceptance-standard.md` — 現行版本適用 SF 條款。
4. `docs/20261019_LegendarySurvivor_CinematicMenuV3_CompletionLog.md` — 已完成及未完成的 v3 工作。
5. `docs/experience-library/` — 經驗及持續生效規則（目前待累積）。
6. 關聯程式、測試報告、Godot 實機證據及 Git Commit。

**注意：** 修改品牌名稱或繁體字形，不代表遊戲的 SF-16、SF-17、完整美術驗收或 100 場真人操作已完成。
