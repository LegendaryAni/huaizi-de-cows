# AGENTS.md

## 目標

用Godot 4.x + GDScript 開發2D 小遊戲《花子的奶牛關》。

## 倉庫結構

- `spec/`：當前版本目標、產品範圍和交付規格。
- `assets/`：遊戲資源檔案。說明見`assets/README.md`
- `docs/`: 記錄和專案有關的檔案。如果有新增的檔案，必須更新 `docs/index.md`
- `docs/experience-library/`：開發經驗，已解決問題、復發規則和開發經驗。
- `scenes/`：Godot 場景檔案。
- `scripts/`：GDScript 遊戲邏輯、除錯入口和測試指令碼。

## 實現約束

- 不替換 Godot 作為遊戲主體。
- 外部指令碼只用於資源處理、檢查和輔助驗證，不承載核心遊戲邏輯
- 實現視覺可讀性時，優先使用正式美術、動畫、粒子、短暫反饋和執行時 UI 資產；不要用常駐幾何圈、矩形框、文字標籤或輔助線替代美術表達。
- 如果為了測試需要顯示碰撞、攻擊範圍、啟用範圍、敵人型別、地圖邊界、刷怪區、座標或物件池資訊，必須做成預設關閉的除錯輔助層，並透過顯式除錯引數或驗證入口開啟。
- 正常執行、正式視覺驗收截圖和交付說明預設不顯示除錯輔助層；帶除錯輔助層的截圖必須在檔名或報告裡明確標註。

## 子 Agent 協作

- 子 Agent 使用規則見 `docs/subagent-guide.md`；寫程式碼的 AI 和挑毛病的 AI 分離規則見 `docs/builder-reviewer-separation.md`。
- 本專案預設使用 `.codex/agents/` 下的固定角色：
  - `builder`：根據主 Agent 指定範圍寫遊戲實現，可改程式碼、場景和必要資源，不改驗收標準，不做複核。
  - `test-author`：根據驗收標準寫或維護測試，不寫實現程式碼。
  - `acceptance-checker`：只核對每條驗收標準是否都有真實測試覆蓋，不寫程式碼、不寫測試。
  - `visual-reviewer`：對照畫面基準和真實執行截圖做只讀視覺驗收，不寫程式碼、不修 UI。
  - `reviewer`：開發完成後只讀複核，先核對驗收標準，再看程式碼質量。
- 同一輪任務裡，寫實現的 Agent 不能擔任 `visual-reviewer` 或 `reviewer`；寫實現的 Agent 也不能為了讓測試透過而降低驗收標準或測試要求。
- 涉及 HUD、升級彈窗、結算面板、VFX、場景觀感或畫面基準的任務，測試透過後必須先交給 `visual-reviewer` 只讀複核；視覺複核透過後再交給 `reviewer` 做綜合複核。
- 派發子 Agent 前，主 Agent 必須給出 spec、驗收標準、測試入口、允許讀寫範圍和返回要求。
- 最終結論由主 Agent 負責，但不能只照搬子 Agent 的結論；必須統一複核改動並執行必要驗證。

## 必須嚴格遵守的開發流程

- step 1: 主 Agent 先讀取 `docs/development/acceptance-standard.md`，並把它作為本專案當前驗收標準；驗收標準是外部合格線，AI 不得自行新增、改寫或降低。如果發現標準缺失、衝突或有待定項，必須先停下來請使用者確認。
- step 2: 由 `test-author` 根據 `docs/development/acceptance-standard.md` 設計詳細測試用例，同樣輸出到 `docs/` 目錄。
- step 3: 由 `acceptance-checker` 核對每條驗收標準是否都有真實測試覆蓋；如果沒有覆蓋完整，回到 step 2。
- step 4: 設計和開發測試所必須依賴的工具，建立充足的觀測手段，包括但不限於日誌、測試介面、截圖、幀序列或可復現執行步驟。
- step 5: 根據 spec 開發遊戲實現；可由 `builder` 承擔實現任務。實現 Agent 不修改驗收標準和測試口徑，除非使用者明確要求。
- step 6: 執行測試和檢查。如果測試不透過，彙報失敗，把失敗經驗更新到 `docs/experience-library/`，修復後重新回到 step 6。
- step 7: 如果改動涉及 HUD、升級彈窗、結算面板、VFX、場景觀感或畫面基準，測試透過後必須交給獨立 `visual-reviewer` 只讀複核；`visual-reviewer` 與寫實現的 Agent 不是同一個上下文。
- step 8: 如果 `visual-reviewer` 不透過，彙報失敗並修復，必要時更新 `docs/experience-library/`，然後重新回到 step 6。
- step 9: 測試透過且必要的視覺複核透過後，必須交給獨立 `reviewer` 複核；`reviewer` 與寫實現的 Agent 不是同一個上下文，並且預設只讀。
- step 10: 如果 `reviewer` 不透過，彙報失敗並修復，必要時更新 `docs/experience-library/`，然後重新回到 step 6。
- step 11: 只有測試透過、必要的 `visual-reviewer` 透過、`reviewer` 透過、主 Agent 複核透過，才視為開發完成。
