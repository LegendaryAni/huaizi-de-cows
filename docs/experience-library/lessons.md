# Lessons

完整經驗記錄放在這裡。每條經驗必須來自真實遇到並處理過的問題。

## Template

```md
### YYYY-MM-DD | 簡短標題

- 場景：
- 現象：
- 影響：
- 原因：
- 修復：
- 驗證：
- 下次規則：
- 關聯檔案 / 提交：
```

## Records

### 2026-10-18 | 同次轉向與技能 Input 必須驗實際方向，不只 CD

- 場景：T16 固定成長策略先更新八向 Input，緊接著按 Space，產品 physics 尚未更新 facing。
- 現象：獨立 reviewer 從 `20261018-growth-baseline-gpu` seed73 wall28979的 NW 輸入觀察到 SE 衝刺；seed17 wall148478的 S 輸入仍往 E。只驗 CD 啟動的 smoke 全過仍漏此錯。
- 影響：矩陣操作不符合既定策略，全部三種子需作無效基準保留，不能選用其中成功結果。
- 原因：use_skill 將上一 physics tick 的 facing 鎖定為 dash_direction，而未讀當下 Input。
- 處置：停止三個指定驗收程序、保留全部串流及 invalidation.json；不人工結算。先補同次反向與斜向 Input 的紅燈回歸，再修正式衝刺取向。
- 修復：正式 use_skill 在非零 Input 時使用當下歸一化向量，零 Input 保留原 facing；skill 事件加方向與位置，未變更數值。
- 驗證：`20261018-dash-input-regression-red-final` movement21斷言/4失敗；修後 `20261018-dash-input-movement-green` 21/0失敗、smoke43/0失敗，獨立 checker 核對覆蓋通過。新三種子矩陣 `20261018-growth-dash-fixed-gpu` 另行驗證，不引用作廢基準。
- 下次規則：Input→技能的同幀順序需同時驗 CD、方向及真實位移；前一 tick 的朝向不能代替目前控制輸入。
- 關聯檔案：scripts/scifi/ScifiMain.gd、scripts/scifi/tests/ScifiTests.gd。

### 2026-10-18 | 自動 UI 通過仍可能保留過期故障訊息與 HUD 交疊

- 場景：v0.2 正式主場景 GPU `visual-capture`，隔離測試存檔。
- 現象：`reports/scifi-tests/20261018-baseline-gpu/` 125斷言全過，但獨立視覺檢查在 defeat-saved、fixture-victory、meta-purchased 圖看見「已保存」與舊失敗通知同時存在；Boss框與左HUD邊緣交疊。
- 原因：保存成功只重建結果面板，未清除九秒通知；Boss框 x570..1350 與左HUD x28..618 存在空間交集。
- 修復：保存成功的結果畫面清除過期通知，空通知不顯示；Boss框縮至 x650..1270，子元件同步縮寬。
- 驗證：ScifiUI.gd 解析通過；`reports/scifi-tests/20261018-ui-fixed-gpu/` 129斷言/0失敗。獨立 visual-reviewer 實看修後四張圖，確認通知消失、HUD留白，76張PNG標頭皆1920×1080；只對本次局部UI修正判通過，整體視覺仍有缺證。
- 下次規則：故障恢復同時驗證成功狀態與舊通知消失；HUD版位需以實際矩形與正式畫面雙重確認。
- 關聯檔案：scripts/scifi/ScifiUI.gd、scripts/scifi/tests/ScifiTests.gd。

### 2026-10-17 | 改造前先補足測試設計的可觀測契約

- 場景：科幻v0.2，實作前的獨立覆蓋檢查。
- 現象：第一輪測試設計漏明確敵彈/邊界觀測、武器中間等級、癱瘓砲座停止攻擊與同幀勝負預期。
- 影響：即使測試存在，也可能漏掉普通砲座只停移動仍射擊，或用實作順序自行決定勝負。
- 原因：以功能名稱代替完整狀態/行為斷言，觀測欄位未對齊固定自動策略。
- 修復：先補spec死亡優先與持續/命中數值；test-author補全1–5級真命中/CD、砲座前後對照與snapshot欄位。
- 驗證：獨立coverage_check二次只讀檢查SF-01..17設計通過；這不代表任何實際遊戲測試通過。
- 下次規則：實作前逐項核對策略依賴的唯讀狀態；控制效果同時驗移動與攻擊，分級效果覆蓋中間層。
- 關聯文件：docs/20261017_LegendarySurvivor_ScifiTestCases_v0.2.md、spec/20261017_LegendarySurvivor_Scifi_v0.2.md。

### 2026-10-22 | CharacterBody2D 物理接觸不可只靠圓心距離判斷傷害

- 場景：v0.2 SF-16 難度診斷，玩家與敵人皆採 `CharacterBody2D`、`move_and_slide()`、`safe_margin=0.04`；接觸傷害原先只以兩碰撞半徑之和判定。
- 現象：敵人追近後被玩家實體擋住，中心距離 52.0189，半徑總和 52.0，玩家 HP 120 不變；`collision.enemy_physics_contact_damages_player` 紅燈。
- 影響：真實接觸可能漏算傷害，SF-16 玩家生存難度與歷史 HP 證據受到扭曲；僅調高敵人速度無法直接解決此判定問題。
- 原因：物理分離安全邊距使剛好碰撞的兩個 `CharacterBody2D` 不必滿足 `distance <= radius_sum`。
- 修復：在 `ScifiMain.gd` 增加 `_enemy_touches_player()`，保留幾何重疊判定並納入敵人／玩家 `get_slide_collision_count()` 真正回報的對方碰撞，再交由既有 `damage_player()` 處理無敵及護盾。
- 驗證：修前 `20261022-164320-collisions-41efd1b6` 新增斷言失敗且 HP120；修後 `20261022-164424-collisions-ff7d5f60` 23/23 成功、HP90，`smoke`／`replay`／`all` 均 `logic_matrix_passed=true`。這僅是接觸修復驗證，SF-16 三種子首次勝利中位數尚未判通過。
- 下次規則：任何 `CharacterBody2D` 的接觸效果都需檢查引擎碰撞接觸，不能只靠圓心距離重疊；加入「物理碰到但未重疊」的紅綠燈回歸。
- 關聯檔案 / 提交：`scripts/scifi/ScifiMain.gd`、`scripts/scifi/tests/ScifiTests.gd`、`docs/20261022_LegendarySurvivor_ContactCollisionFix.md`、`d949e1360d5161e9a780268fd65e3309c4e4f34c`。
