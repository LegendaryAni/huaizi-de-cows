# 《傳奇倖存者》v0.2：Canvas 與地圖碰撞修正紀錄（2026-10-19）

## 問題診斷

原版以 `Node2D.position` 直接移動主角及敵人，環境只是一張 `4096×2305` 的背景 `map.png`，所有箱子及機器都沒有碰撞物理區。主視口設定為 1920×1080，預設視窗 1280×720，二次縮小造成素材細節損失。

## 本輪變更

- 保留 Godot 4.7.2、正式地圖 4096×2305、設計視口 1920×1080、Camera2D.zoom = 1、固定傷害及存檔格式。
- `tools/build_scifi_world.py` 根據原 `tools/prepare_scifi_art.py` 的 Python `random.Random(20261017)` 及地板 RNG 消耗重建擺設座標；產生 `assets/sprites/scifi/map_obstacles.json`，50 個不含出生核心的可視物件足部碰撞盒。**不將整個圖片的大面積透明區當碰撞**。
- `scripts/scifi/ScifiWorldCollision.gd` 依此資料建 `StaticBody2D/CollisionShape2D`，另建地圖外緣的物理牆壁。正常畫面不顯示除錯碰撞輪廓。
- `ScifiActor.gd` 改為 `CharacterBody2D`，新增主角及敵人實際的圓形 `CollisionShape2D`；主角對敵人／地形，敵人對玩家／地形；**敵人彼此不互推**以避免 180 名敵人擠成無法行進的團塊。
- 玩家移動／衝刺改使用 `move_and_slide()`。敵人行走／首領衝鋒改物理移動，牆面前方有切向繞行。物件池回收時關閉敵人碰撞遮罩、重用時復原。
- 敵方子彈、玩家實體彈藥使用地形 raycast 遮蔽，不能直接穿過箱子；榴彈撞牆時在碰撞點爆炸。
- `map_detail.png` 在原地圖上加少量金屬細紋；地圖獨立採線性取樣、角色／UI 仍採畫素美術 Nearest。預設視窗調整為 1600×900，畫面以固定 16:9 比例縮放，避免 HUD 裁切。原 `map.png` 保留作為基準。
- Windows `export_presets.cfg` 明確打包碰撞 JSON，以防匯出版只有美術沒有碰撞。

## 測試與界線

專項 `-Scenario collisions` 覆蓋：50 個障礙物、玩家碰撞層與牆壁阻擋、普通移動不穿箱、衝刺不可穿箱、敵人受牆阻擋、射線擊中、敵方子彈被擋及玩家未受隔牆傷害；支援正常 GPU 實機截圖。

不更改 SF-03 的視口與鏡頭倍率、不修改既有 SF-01～SF-17 驗收門檻；原本 SF-16 三種子成長平衡仍未透過，不能宣稱 v0.2 全部驗收完成。
