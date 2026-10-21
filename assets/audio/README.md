# 音訊資源使用說明

## v0.2 科幻版正式音效（2026-10-19）

正式聲音路徑現在是 `assets/audio/scifi/`，包含 **31 個重新合成的科幻 WAV 事件音效** 與 **1 個約 24 秒的原創迴圈 Ogg 背景配樂**。沒有取樣、剪接或沿用舊貓牛版音檔。六種武器有獨立發射與命中聲、四技能與首領死亡也各有辨識度。SHA-256 與檔名見 `assets/audio/scifi/manifest.json`。

`scripts/GameConfig.gd` 對映所有實際素材；`scripts/scifi/ScifiConfig.gd` 對映遊戲事件；`scripts/SfxBus.gd` 控制播放與音量。音樂／音效／震屏可在「音效與畫面」選單調整，偏好儲存在獨立設定檔，不修改進度存檔。舊 `assets/audio/sfx/` 檔保留作歷史追溯，不再用於 v0.2 科幻執行。

**下方為 v0.1 歷史音訊對應，不是現行 v0.2 執行路徑。**


以下為《傳奇倖存者》v0.1 原型的舊音訊對應，**不是目前 v0.2 的音效設定**。本段只保留檔案來源及維護歷史。授權來源和檔案對映見 `assets/audio/LICENSES.md`。

## 目錄

- `assets/audio/sfx/`：執行時音效檔案，使用 `.ogg`。
- `assets/audio/sfx/background_bgm_01.ogg`：執行時背景音樂，來自使用者提供的 MP4 音軌提取。
- `assets/audio/LICENSES.md`：音訊素材來源、授權和檔案對映。

## 事件和檔案

| 遊戲事件 | 音效檔案 |
| --- | --- |
| 橘貓發射 | `sfx/cat_orange_launch_01.ogg` |
| 黑貓發射 | `sfx/cat_black_launch_01.ogg` |
| 奶牛貓迴旋發射 | `sfx/cat_cow_spin_01.ogg` |
| 遠端牛奶滴發射 | `sfx/milk_launch_01.ogg` |
| 普通命中 / 奶牛受擊 | `sfx/cow_hit_01.ogg` |
| 黑貓爆炸 | `sfx/cat_black_explode_01.ogg` |
| 玩家受擊 | `sfx/player_hurt_01.ogg` |
| 敵人死亡 | `sfx/enemy_die_01.ogg` |
| XP 拾取 | `sfx/xp_pickup_01.ogg` |
| 升級 | `sfx/level_up_01.ogg` |
| UI 選擇 / 升級選擇 | `sfx/ui_select_01.ogg` |
| 波次開始 | `sfx/wave_start_01.ogg` |
| 解鎖新貓 | `sfx/weapon_unlock_01.ogg` |
| 勝利 | `sfx/victory_01.ogg` |
| 失敗 | `sfx/defeat_01.ogg` |
| 背景音樂 | `sfx/background_bgm_01.ogg` |

## BGM 來源

| 執行時檔案 | 來原始檔 | 處理方式 |
| --- | --- | --- |
| `sfx/background_bgm_01.ogg` | `/Users/wawa/Downloads/39995331_da2-1-16.mp4` | 提取音軌並轉碼為 Ogg Vorbis。 |

## 接入規則

- 音訊是正常可用版本的必交項，不是可選增強。
- 執行時載入 `.ogg` 檔案；Godot 生成的 `.ogg.import` 如果是執行所需，應一起保留。
- 新增或複製音訊後，先執行 Godot editor headless 匯入，再檢查執行時載入數量和關鍵事件是否能觸發音效。
- 高頻發射、命中和拾取音效需要限頻或複用播放器，避免聲音堆疊失控。
- 新增音訊時必須同步更新 `assets/audio/LICENSES.md`，記錄授權來源和檔案對映。
