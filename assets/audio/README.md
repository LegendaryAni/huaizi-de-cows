# 音频资源使用说明

## v0.2 科幻版正式音效（2026-10-19）

正式聲音路徑現在是 `assets/audio/scifi/`，包含 **31 個重新合成的科幻 WAV 事件音效** 與 **1 個約 24 秒的原創循環 Ogg 背景配樂**。沒有取樣、剪接或沿用舊貓牛版音檔。六種武器有獨立發射與命中聲、四技能與首領死亡也各有辨識度。SHA-256 與檔名見 `assets/audio/scifi/manifest.json`。

`scripts/GameConfig.gd` 映射所有實際素材；`scripts/scifi/ScifiConfig.gd` 映射遊戲事件；`scripts/SfxBus.gd` 控制播放與音量。音樂／音效／震屏可在「音效與畫面」選單調整，偏好儲存在獨立設定檔，不修改進度存檔。舊 `assets/audio/sfx/` 檔保留作歷史追溯，不再用於 v0.2 科幻執行。

**下方為 v0.1 歷史音訊對應，不是現行 v0.2 執行路徑。**


本文说明音频资源的目录、用途和接入要求。授权来源和文件映射见 `assets/audio/LICENSES.md`。

## 目录

- `assets/audio/sfx/`：运行时音效文件，使用 `.ogg`。
- `assets/audio/sfx/background_bgm_01.ogg`：运行时背景音乐，来自用户提供的 MP4 音轨提取。
- `assets/audio/LICENSES.md`：音频素材来源、授权和文件映射。

## 事件和文件

| 游戏事件 | 音效文件 |
| --- | --- |
| 橘猫发射 | `sfx/cat_orange_launch_01.ogg` |
| 黑猫发射 | `sfx/cat_black_launch_01.ogg` |
| 奶牛猫回旋发射 | `sfx/cat_cow_spin_01.ogg` |
| 远程牛奶滴发射 | `sfx/milk_launch_01.ogg` |
| 普通命中 / 奶牛受击 | `sfx/cow_hit_01.ogg` |
| 黑猫爆炸 | `sfx/cat_black_explode_01.ogg` |
| 玩家受击 | `sfx/player_hurt_01.ogg` |
| 敌人死亡 | `sfx/enemy_die_01.ogg` |
| XP 拾取 | `sfx/xp_pickup_01.ogg` |
| 升级 | `sfx/level_up_01.ogg` |
| UI 选择 / 升级选择 | `sfx/ui_select_01.ogg` |
| 波次开始 | `sfx/wave_start_01.ogg` |
| 解锁新猫 | `sfx/weapon_unlock_01.ogg` |
| 胜利 | `sfx/victory_01.ogg` |
| 失败 | `sfx/defeat_01.ogg` |
| 背景音乐 | `sfx/background_bgm_01.ogg` |

## BGM 来源

| 运行时文件 | 来源文件 | 处理方式 |
| --- | --- | --- |
| `sfx/background_bgm_01.ogg` | `/Users/wawa/Downloads/39995331_da2-1-16.mp4` | 提取音轨并转码为 Ogg Vorbis。 |

## 接入规则

- 音频是正常可用版本的必交项，不是可选增强。
- 运行时加载 `.ogg` 文件；Godot 生成的 `.ogg.import` 如果是运行所需，应一起保留。
- 新增或复制音频后，先运行 Godot editor headless 导入，再检查运行时加载数量和关键事件是否能触发音效。
- 高频发射、命中和拾取音效需要限频或复用播放器，避免声音堆叠失控。
- 新增音频时必须同步更新 `assets/audio/LICENSES.md`，记录授权来源和文件映射。
