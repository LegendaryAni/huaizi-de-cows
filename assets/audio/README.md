# 音訊資源使用說明

本文說明音訊資源的目錄、用途和接入要求。授權來源和文件映射見 `assets/audio/LICENSES.md`。

## 目錄

- `assets/audio/sfx/`：執行時音效文件，使用 `.ogg`。
- `assets/audio/sfx/background_bgm_01.ogg`：執行時背景音樂，來自用戶提供的 MP4 音軌提取。
- `assets/audio/LICENSES.md`：音訊素材來源、授權和文件映射。

## 事件和文件

| 遊戲事件 | 音效文件 |
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

| 執行時文件 | 來源文件 | 處理方式 |
| --- | --- | --- |
| `sfx/background_bgm_01.ogg` | `/Users/wawa/Downloads/39995331_da2-1-16.mp4` | 提取音軌並轉碼為 Ogg Vorbis。 |

## 接入規則

- 音訊是正常可用版本的必交項，不是可選增強。
- 執行時加載 `.ogg` 文件；Godot 生成的 `.ogg.import` 如果是執行所需，應一起保留。
- 新增或複製音訊後，先執行 Godot editor headless 匯入，再檢查執行時加載數量和關鍵事件是否能觸發音效。
- 高頻發射、命中和拾取音效需要限頻或複用播放器，避免聲音堆疊失控。
- 新增音訊時必須同步更新 `assets/audio/LICENSES.md`，記錄授權來源和文件映射。
