# 《傳奇倖存者》玩家／敵人實體接觸傷害修復

日期：2026-10-22。工作起點：`b349a6c9b06c52f75ad8d971cc4fc3456a6e9594`，Godot 4.7.2。

## 根因與實機重現

`ScifiActor.gd` 的玩家與敵人均繼承 `CharacterBody2D`，使用 `move_and_slide()` 並保留 `safe_margin = 0.04`。原先 `ScifiMain.gd::_update_enemies` 只在「玩家和敵人中心距離不大於兩個碰撞圓半徑之和」時觸發接觸傷害；物理引擎先分開兩個碰撞體，使接觸後的中心距離可能仍稍大於半徑總和，進而**漏算應有的接觸傷害**。

實際紅燈測試條件：`collisions` 隔離環境，玩家位於 `(2048,1152)`、HP 120、無護盾且非無敵；血量極高的 `crawler` 從 `(2180,1152)` 追擊，速度 180、碰撞傷害 10，玩家不移動。約 110 個真實物理更新後：
- 玩家座標 `(2046.5968,1152)`；敵人 `(2098.6157,1152)`。
- 中心距離 `52.0189`，兩者半徑總和 `30+22=52`；僅差 **0.0189**。
- 原版 `collision.enemy_physics_contact_damages_player` **FAIL**：HP 120，敵人已由物理碰撞擋住，卻未扣血。
- 測試保留於本機 `reports/scifi-tests/20261022-164320-collisions-41efd1b6`。

## 最小修正

在 `ScifiMain.gd` 引入 `_enemy_touches_player(e)`：保留原幾何相交判定，並額外檢查敵人與玩家的 `get_slide_collision_count()` 和 `get_collider()`，確保 Godot 實際回報雙方發生碰撞時觸發既有的 `damage_player`。不修改傷害數值、無敵時間、移速、AI 指令或成長策略，既有 `damage_player` 的無敵與護盾保護仍生效。

修正後相同測試：玩家 HP 120→90，23 項碰撞檢查全部通過（含障礙物阻擋移動、衝刺不穿牆、敵彈不穿牆）。`smoke`、`replay`、`all` 三份 `logic_matrix_passed=true`。

| 測試 | 修正前 | 修正後 |
| --- | --- | --- |
| `collision.enemy_physics_contact_damages_player` | FAIL；HP 120 | PASS；HP 90 |
| `collisions` 完整場景 | 1 項失敗 | 23/23 PASS |
| `smoke` | 不適用於此錯誤的單獨驗證 | PASS |
| `replay` | 不適用於此錯誤的單獨驗證 | PASS |
| `all` | 不適用於此錯誤的單獨驗證 | PASS |

## 驗收界線

這是**物理接觸傷害 bug 修復**，不是 SF-16 難度已校準的證明。SF-16 必須另用固定的種子 `17、41、73`、T16 不變策略、真實時鐘與隔離新存檔，記錄每場自然結算及首次通關場次，確認中位數 3～5；SF-17 也仍需獨立審查。不可以已通過的普通回歸替代這兩項正式驗收。

本次不更動 `main` 或已存在的個人遊戲存檔。測試檔案和隔離成長證據不直接加入 GitHub。
