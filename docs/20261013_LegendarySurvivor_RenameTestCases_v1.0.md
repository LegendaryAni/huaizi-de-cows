# 傳奇倖存者改名專項測試用例 v1.0

## 檔案職責

本文把本輪改名需求轉成可執行、可觀測、可復核的測試用例。本文只定義測試與證據要求，不修改產品實作、場景、spec、驗收標準或既有歷史證據檔案。

## 依據

- 當前驗收標準：`docs/development/acceptance-standard.md`
- v0.1 交付範圍：`spec/v0.1-傳奇倖存者-歷史原型.md`
- UI 視覺事實源：`spec/視覺規格.md`
- 玩法事實源：`spec/遊戲機制.md`
- 既有選單與成績測試入口：`docs/v0.1-menu-score-bgm-test-cases.md`
- 本輪 authoritative naming spec：使用者明確指定遊戲顯示名稱為繁體中文《傳奇倖存者》

## 本輪需求編號

| 編號 | 需求 | 對映現有 AC |
| --- | --- | --- |
| R-LSR-01 | `project.godot` 的 Godot 顯示名稱改為繁體中文 `傳奇倖存者`。 | AC-RUN-02、AC-UI-05 |
| R-LSR-02 | 主選單實際標題顯示 `傳奇倖存者`，文字可見、無裁切遮擋。 | AC-RUN-02、AC-UI-04、AC-UI-05、AC-OBS-04 |
| R-LSR-03 | 既有 `user://` 成績儲存位置不因改名漂移，改名前後讀寫同一份本地成績資料。 | AC-RUN-02、AC-RUN-06 |
| R-LSR-04 | 全域 godot-gai 案例名稱與目前對外檔案一致，原專案路徑、角色花子、貓牛玩法與既有歷史證據位置不被改名波及。 | AC-RUN-02、AC-RUN-06、AC-UI-05 |

## 測試入口規劃

本輪優先沿用既有入口，不為低影響改名新增大量自動測試。若現有入口缺欄位，實作方只需補足報告欄位或讀回步驟。

| 入口 | 用途 | 必需證據 |
| --- | --- | --- |
| 靜態名稱檢查 | 讀取 `project.godot` 與本輪允許更新的對外檔案，確認顯示名稱與全域案例名稱。 | 靜態檢查輸出、相關檔案路徑與讀回值 |
| `--debug-mode=menu_probe` 或外部唯讀 SceneTree observer | 啟動到主選單，儲存真實主選單截圖並讀回標題 Label 文字與版面狀態。 | `validation_report.menu_probe` 或 observer 讀回輸出、`capture_dir/menu_start_normal.png` |
| `--debug-mode=scores_probe` | 在原 `user://` root 以唯一隔離檔名執行 before 寫入、after 讀回與重啟讀回，比對 Godot 使用者資料根目錄與持久化結果。 | `validation_report.scores_probe.persistence_path`、隔離檔名、`user_data_root_before`、`user_data_root_after`、重啟讀回證據 |
| 全域 source reference 檢查 | 讀回 godot-gai 案例索引或對外檔案中的案例名稱、原專案路徑與玩法摘要。 | source reference 檢查輸出、案例名稱、原專案路徑、玩法關鍵詞讀回 |

通用 Godot 執行範例：

```bash
godot --path . -- --debug-mode=menu_probe --validation-report=<report.json> --capture-dir=<capture_dir> --run-seconds=3
```

成績持久化比對可沿用既有成績探針：

```bash
godot --headless --path . -- --debug-mode=scores_probe --validation-report=<report.json> --run-seconds=3
```

## LSR-TC-01 靜態顯示名稱與全域案例名稱

目的：確認 Godot 工程顯示名稱與全域案例名稱都改成《傳奇倖存者》，並確認本輪若同步更新 README、AGENTS、spec、驗收或既有測試檔案中的完整遊戲名稱，只限名稱替換，不改玩法、驗收條文、測試步驟、檔名、連結或歷史證據位置。

覆蓋需求：R-LSR-01、R-LSR-04

覆蓋 AC：AC-RUN-02、AC-RUN-06、AC-UI-05

操作步驟：

1. 讀取 `project.godot`。
2. 讀取本輪實作實際更新的全域 godot-gai 案例索引或 source reference。
3. 檢查本輪變更清單，確認 README、AGENTS、spec、驗收與既有測試檔案若有變更，只是完整遊戲名稱替換；既有歷史證據檔、檔名與連結未被搬移或批次改名。
4. 對 source reference 讀回案例名稱、原專案路徑與玩法摘要。

自動斷言：

- `project.godot` 的 `config/name` 或等價 Godot 顯示名稱精確等於 `傳奇倖存者`。
- source reference 中的當前案例顯示名稱精確等於 `傳奇倖存者`。
- source reference 仍保留原專案路徑或來源識別，不把 repo 路徑、來源專案名稱改成新遊戲名。
- source reference 的玩法摘要仍包含「花子」、「貓」、「牛」或等價既有玩法關鍵詞，不得改成不同角色、不同敵人或不同玩法。
- 對照改名前 snapshot，本輪允許 README、AGENTS、spec、驗收與既有測試檔案中的完整遊戲名稱替換為 `傳奇倖存者`；除完整遊戲名稱外，玩法、驗收條文、測試步驟、檔名、連結與歷史證據位置需與 snapshot 一致。
- 靜態檢查或 Godot 專案載入日誌沒有解析錯誤。

判定方式：

- 任一名稱讀回值不是精確 `傳奇倖存者`，不透過。
- 任一非名稱內容或來源欄位被改成與既有 spec 衝突，不透過。

## LSR-TC-02 主選單真實標題截圖與 UI 可讀性

目的：確認玩家實際看到的主選單標題是《傳奇倖存者》，且標題符合中文 UI、無裁切、無遮擋、無驗收說明文字。

覆蓋需求：R-LSR-02

覆蓋 AC：AC-RUN-02、AC-UI-04、AC-UI-05、AC-OBS-04

前置條件：

- 優先沿用 `--debug-mode=menu_probe`；若不修改核心程式即可用外部唯讀 SceneTree observer 讀回真正主選單 Label，也可採用 observer。
- `menu_probe` 或 observer 需讀回主選單標題 Label 文字、標題 Control 的可見矩形、截圖路徑和錯誤摘要。

操作步驟：

1. 使用 `menu_probe` 或外部唯讀 SceneTree observer 以真實可截圖方式啟動主場景。
2. 儲存 `capture_dir/menu_start_normal.png`。
3. 讀取 `validation_report.menu_probe.start.title_text` 或 observer 讀回的等價主選單 Label 文字、`title_visible_rect`、`title_clipped`、`title_overlapped`、`unexpected_completion_texts`。
4. 讀取 Godot 載入與執行日誌。

自動斷言：

- `validation_report.menu_probe.start.title_text == "傳奇倖存者"`，或 observer 讀回的真正主選單標題 Label 文字精確等於 `傳奇倖存者`。
- `title_clipped == false`。
- `title_overlapped == false`。
- `unexpected_completion_texts` 為空；畫面不出現「已完成需求」或給驗收者看的說明文字。
- 主選單仍可看到既有入口，至少包含「開始遊戲」或既有等價開始入口，不因改名破壞選單流程。
- 日誌沒有指令碼解析錯誤、資源載入錯誤或執行時致命錯誤。

視覺復核：

- `menu_start_normal.png` 中標題 `傳奇倖存者` 清楚可見，未被按鈕、背景、面板或特效遮住。
- 標題使用繁體中文，不得顯示簡體「傳奇倖存者」、英文暫名或舊名。
- 正常截圖不得顯示除錯輔助層。

判定方式：

- 文字讀回與真實 PNG 截圖都必須存在；可由 `menu_probe` 報告或外部唯讀 observer 提供文字讀回。只有 headless 文字讀回、沒有真實主選單截圖時，R-LSR-02 不算透過。

## LSR-TC-03 `user://` 成績儲存位置不漂移

目的：確認改名不會讓本地持久化資料因 Godot `user://` 根目錄變更而漂移；在原 `user://` root 使用唯一隔離檔名寫入的測試成績，改名後仍能讀回並重啟後保留，不碰玩家正式成績檔。

覆蓋需求：R-LSR-03

覆蓋 AC：AC-RUN-02、AC-RUN-06

前置條件：

- 沿用 `--debug-mode=scores_probe`。
- 沿用既有 `scores_probe` write/read phases，在原 `user://` root 使用唯一隔離檔名，例如 `rename_probe_scores_<run_id>.json`。
- 報告需包含 `user_data_root_before`、`user_data_root_after`、`isolated_scores_filename`、`persistence_path_before`、`persistence_path_after`、`written_scores_before`、`loaded_scores_after_rename`、`restart_evidence`。

操作步驟：

1. 在改名前或改名前 snapshot 對應階段，透過 `scores_probe` write phase 於原 `user://` root 的唯一隔離檔名寫入一組可控成績，例如 `[1200, 900, 300]`，記錄 `user_data_root_before` 與 `persistence_path_before`。
2. 套用改名後，透過 `scores_probe` read phase 讀取同一個隔離檔名。
3. 記錄 `user_data_root_after` 與 `persistence_path_after`。
4. 讀回改名前寫入的成績，記錄 `loaded_scores_after_rename`。
5. 重新啟動 Godot 一次，再讀回同一份成績並記錄 `restart_evidence`。

自動斷言：

- `isolated_scores_filename` 非空，且不是玩家正式成績檔名。
- `user_data_root_after == user_data_root_before`，或有明確相容遷移證據證明改名前資料已原地保留並由新版本讀回；本輪預期是不漂移，優先要求兩者相同。
- `persistence_path_after == persistence_path_before`，或同樣提供明確相容讀回證據。
- `loaded_scores_after_rename` 至少包含改名前寫入的可控成績。
- `restart_evidence` 證明改名後至少經過一次獨立重啟仍可讀回。
- `uses_account_or_backend == false`；改名不得引入帳號、後端、線上排行榜或網路同步。
- 日誌沒有指令碼解析錯誤、資源載入錯誤或執行時致命錯誤。

判定方式：

- 缺少隔離檔名 before 寫入、after 讀回或重啟讀回任一證據時，本用例列為未驗證，不得宣稱 R-LSR-03 透過。
- 如果改名造成 `user://` 實際目錄改變且沒有相容讀回，測試不透過。

## LSR-TC-04 玩法、路徑與歷史證據保護

目的：確認改名隻影響顯示名稱與當前對外完整遊戲名稱；README、AGENTS、spec、驗收與既有測試檔案若同步替換完整遊戲名稱，除名稱外內容需與原始 snapshot 一致，不改角色花子、貓牛玩法、原專案路徑、存檔資料口徑與既有歷史證據位置。

覆蓋需求：R-LSR-04

覆蓋 AC：AC-RUN-02、AC-RUN-06、AC-UI-05

操作步驟：

1. 檢查本輪 diff 或變更清單。
2. 讀回 README、AGENTS、`spec/v0.1-傳奇倖存者-歷史原型.md`、`spec/視覺規格.md`、`spec/遊戲機制.md`、驗收與既有測試檔案的狀態，確認本輪只替換完整遊戲名稱，未修改玩法事實源、驗收條文或測試步驟。
3. 讀回全域 source reference，確認原專案路徑仍指向目前 repo 或既有來源，而不是新建錯誤路徑。
4. 使用 `menu_probe` 或最小 Godot 載入檢查確認主場景能啟動到選單。

自動斷言：

- 本輪 diff 不包含玩法邏輯、場景節點、角色、敵人、波次、升級、成績資料格式或玩家正式存檔檔名的改動，除非主 Agent 另列為實作必要且有測試覆蓋。
- README、AGENTS、spec、驗收與既有測試檔案若有修改，除完整遊戲名稱替換外，其餘內容需與原始 snapshot 一致。
- spec 事實源仍以花子、貓、牛、固定戶外大地圖、一局制倖存者玩法為核心，不因顯示名稱改成不同遊戲。
- source reference 的 `project_path` 或等價欄位仍指向既有 `huaizi-de-cows` repo 路徑；不得新建或改指向無關專案。
- 既有 historical evidence 的檔名與路徑不因改名批次重新命名。
- Godot 啟動到主選單時沒有解析、載入或致命錯誤。

判定方式：

- 任何超出完整遊戲名稱替換範圍的玩法、驗收條文、測試步驟、資料格式或歷史證據搬移，若沒有主 Agent 明確列入可寫範圍與對應測試，本用例不透過。

## 覆蓋匯總

| 需求 | 測試 |
| --- | --- |
| R-LSR-01 `project.godot` 顯示名稱 | LSR-TC-01 |
| R-LSR-02 主選單標題可見且無裁切遮擋 | LSR-TC-02 |
| R-LSR-03 `user://` 成績儲存位置不漂移 | LSR-TC-03 |
| R-LSR-04 全域案例名稱、原路徑與玩法保護 | LSR-TC-01、LSR-TC-04 |

## 覆蓋限制與待補測試

- 本檔案只覆蓋本輪改名需求與其對映到的 AC-RUN-02、AC-RUN-06、AC-UI-04、AC-UI-05、AC-OBS-04；不替代 v0.1 全量驗收測試。
- R-LSR-03 必須有原 `user://` root 中唯一隔離檔名的 before 寫入、after 讀回與重啟讀回證據；不存在玩家正式 scores file 不阻塞本用例，但不能用「目前能寫入」代替「不因改名漂移」。
- 全域 godot-gai source reference 的實際檔案或工具入口由主 Agent 在實作驗證時指定；未讀回前，R-LSR-04 不能宣稱透過。
- 若主選單標題報告欄位尚未存在，可用外部唯讀 SceneTree observer 讀回真正主選單 Label 並搭配 PNG 證據；不需要新增大量自動測試或改動核心玩法。
