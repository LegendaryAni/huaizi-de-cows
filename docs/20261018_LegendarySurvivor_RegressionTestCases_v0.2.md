# 《傳奇倖存者》科幻 v0.2 回歸測試補充

日期：2026-10-18。補充 `20261017_LegendarySurvivor_ScifiTestCases_v0.2.md` 的 T06／T13／T15／T16，不取代、增加或降低 `docs/development/acceptance-standard.md` 的外部合格線。遊戲規格、固定策略、種子、門檻及所有遊戲數值保持原口徑。

## R06 榴彈六方向外圍真命中（SF-06、SF-14）

入口：`tools/run_scifi_tests.ps1 -Scenario evolutions -Headless -GodotPath <console.exe>`。

- 明確標為測試夾具，普通／進化各跑一次。玩家 (2048,1152)，主彈瞄準中心 (2280,1152)，中心目標先加入；再在中心半徑 240px 的六個等角方向各放一個 100000HP、靜止、無接觸傷害目標。所有目標密度相同時仍按原插入順序瞄準中心。
- 武器5級、blast=0，觀察0.95正常秒，保留原正式自動發射／飛行／碰撞／傷害。不能直接呼叫 explode 或 force_damage。
- 斷言僅一個主爆炸且中心受傷；普通榴彈外圍六敵 HP 完全不變，沒有 hit。
- 進化榴彈六敵各有一次真 hit，HP 差等於 `42*1.35^4*1.4*0.35`，容差0.01；六個 source_id 各自不同，且均不是主爆炸彈體。六個外圈目標都在140px主爆炸半徑外。
- 機械通過仍需獨立 visual-reviewer 對照實際進化特效；夾具不算自然成長。

## R13 HUD 與保存成功訊息（SF-13）

入口：`-Scenario visual-capture`，需要 GPU。runner 預設 `--resolution 1920x1080`，保留設計視口1920×1080，報告 invocation 同時記錄輸出解析度。

- 首領實際顯示時，對照真實 UI Control 的 global rect，Boss 面板不得與左上HUD面板相交，並保存 `fixture-boss` 圖供獨立視覺複核。
- 原有保存失敗→重試→成功流程中，斷言 pending 清空且 notice.visible=false、notice.text 為空，保存 `defeat-saved`。
- 這兩條補測不替代完整T13。未補齊的兩卡與其他技能畫面等項目仍需依原測試文件揭露。

## R15／R16 正常成長證據（SF-15、SF-16、SF-17）

正式入口：`-Scenario growth`，三seed 17／41／73；禁止覆用隔離目錄，runner不覆蓋既有結果。最終必須以整個三seed矩陣判定中位數；單seed或外部停止的短探測不能宣稱成長通過。

- `*.invocation.json`：Godot路徑／SHA256、完整引數、UTC開始時刻、seed、隔離save路徑與初始空目錄、source/config/policy/script SHA256、GPU/headless及輸出解析度。
- `*.snapshots.jsonl`：每1真實秒及每次開局、選牌前後、結果、購買完成、結束時，將正式snapshot完整落盤。包含玩家HP/位置、時間／階段、各武器等級／進化／傷害／CD、全部mods、技能CD／持續、敵與彈位置、Boss、pool/counts、XP、收益、永久層數、save status／pending／result／loaded resources。events另存串流，快照保留最後serial作關聯，不在記憶體囤積整個成長採樣。
- `*.events.jsonl`：每個process frame唯讀增量讀取正式events，依serial只寫新增尾段，不複製整個10000條緩衝；逐筆驗證serial連續，任何缺口直接失敗。每筆附run/run_id/wall_ms。包含所有原生attack/hit/death/skill/card/purchase/settlement/save等事件。
- `*.inputs.jsonl`：每次0.1秒移動決策與停止、E/Space的down/up、選牌完整可見候選／固定排序／選中與接受結果、購買前後錢包／層數／價格／指標、購買停止理由、收益／結算、時鐘稽核、存檔副本hash、自然圖與退出原因全部落盤。
- 成長技能經由正式InputEventKey與Viewport input走產品輸入handler，不能直接call use_skill；同一決策仍先repair再dash，沒有新增等待或改門檻。每場run_id非空且跨場唯一；其他武器升級／進化依原T16以key再id消歧。`smoke` 先以相同helper確認 E／Space實際讓對應CD啟動。
- 事件／快照／操作串流至少每1秒flush並檢查寫入錯誤，檔案不可開啟或serial不連續即失敗。強制終止仍只保留最後已flush資料，不偽造完整結論。
- `*-saves/<phase>/`：初始、每場前、結果、每次成功購買、每場後及最終複製隔離主檔／backup／pending／舊成績（若存在），逐一比對來源與副本SHA256。結果、每次成功購買與最終階段要求主檔存在且可讀JSON，逐欄讀回credits/upgrades/settled_ids與快照一致。不存在的檔案也記錄exists=false。
- 每秒稽核time_scale=1、physics tick=60、模擬時間前進不得超過實際wall時間（最多0.15秒採樣容差）；記錄UTC、wall、battle和nonbattle秒數，另逐frame累積upgrade UI毫秒並單列交易迴圈耗時。fixture事件／helper呼叫、關閉刷怪、非契約最大HP、保存故障注入、運行中source/config漂移均不得通過。正常技能與受擊無敵仍按原產品生效。
- 自然結果需要實際Boss death（勝利）或HP<=0（失敗），禁止finish_run、強勝、注資；正常交易仍只用 purchase_upgrade，選牌只用畫面可見候選的 choose_card。
- GPU `*-natural-frames/frame-NNNNNN.png`：自然出擊整備、battle、upgrade、真正skill事件、evolution選中、Boss生成、result及meta時觸發擷取，連續短窗3真實秒／目標5fps；每幀操作串流記載實際wall timestamp／game time／state／標籤及fixture=false。不同時間窗不可冒充一段不間斷錄影；以相鄰wall時刻確認連續片段。瞬間畫面另有各觸發標籤，完整長局照原策略運作。
- headless仍可跑邏輯但沒有GPU圖，必須標明無法替代T13/T15正式畫面。自然流程沒有出現的技能、進化、首領或勝敗類別仍是缺證，不能用fixture補成自然證據。

## 驗證與停止條件

先parse→smoke（包含正式技能Input）→evolutions；覆蓋經 acceptance-checker 檢查後，主Agent才啟動長growth。三seed最多五場、首次通關中位數3–5的合格線完全不變；不挑最好結果，不重跑單seed替換壞結果，不調策略或遊戲數值。

本文件只定義補測與觀測，不宣稱尚未執行的長growth、自然GPU圖、獨立視覺／綜合複核已通過。操作是讀取內部位置的全資訊自動策略，不能推論真人難度或樂趣。


## R03 同幀移動反轉與正式 Space 衝刺（SF-03、SF-08、T16）

2026-10-18 本次正常成長基準因方向不符合固定策略而作廢：seed73原本選NW但舊facing為SE、seed17選S但舊facing為E，Space沿上一physics的facing衝刺。基準保留，不強制結算，不將其算作合法三seed矩陣。

入口：`-Scenario movement`。先以正式Input移動0.06秒建立舊朝向，再在同一決策依序set_movement新方向、送正式Space down/up，兩者中間禁止等待physics frame。案例限定SE→NW、E→S。

- 斷言舊facing確實已建立、新Input仍是本次方向。
- 斷言本次dash_direction與新Input方向一致。
- 經0.24正常秒後，以真實玩家位置差斷言沿新方向至少完成240px衝刺，垂直偏差≤0.01px。普通移動多走的距離不算錯向。
- 所有案例都在中心、靜止空場執行，沒有直接改facing或dash_direction、沒有直接呼叫use_skill。
- 本回歸只處理非零Input。零Input下沿既有facing的正常產品行為保持原契約；T16「沒有合法方向則停止」和衝刺的交互由獨立checker對原規格判斷，本次不自行新增限制或改策略。
- 自然進化圖目前依每場的evolution分類去重，因此同一場後續其他武器的進化未各自保證擷取；依主Agent本次範圍不擴充media，後續視覺複核需明列此限制。
