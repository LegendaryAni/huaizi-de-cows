# 寫程式碼的 AI 與挑毛病的 AI 要分開

## 這份文件要解決什麼

在本專案上一輪開發裡，驗收標準、測試用例、檢查腳本和"判定通過"全都出自同一個 AI——也就是寫遊戲程式碼的那一個。結果是它給自己定了一條最容易過的線，驗收自然粗糙。

要根治這件事，只靠"換個更聰明的模型"或"讓它再認真一點"沒用。真正起作用的是兩件事配套：

1. **角色分開**：寫程式碼的 AI，不許同時給自己定標準、寫測試、審自己、判自己過。
2. **標準釘在外面**：合格線由人維護（見 [`docs/development/acceptance-standard.md`](./development/acceptance-standard.md)），寫程式碼的 AI 改不動，審查時也不能降低它。

本文件講第 1 件在 Codex 框架下具體怎麼落地，並說明它為什麼有效。

## 原理：為什麼"分一個 AI"還不夠

參考開源框架 [superpowers](https://github.com/obra/superpowers) 的做法，"寫程式碼的"和"挑毛病的"分開之所以有效，是三件事疊在一起，缺一不可：

1. **審查的那個是全新的**——不帶寫程式碼那個的記憶，所以沒有"這是我寫的、應該沒問題"的自我袒護，也不會被前面的實現思路帶著走。
2. **立場是對立的**——它的任務被定義成"挑錯、找沒做到的地方"，不是"確認沒問題"。
3. **標準是事先寫好、獨立的**——審查第一步就是"對照規範逐條核對"，規範是提前定好的，不是臨場編的。

第 3 件就是本專案那份驗收標準。換句話說：**角色分離要能生效，必須有一份獨立標準餵給審查的 AI。兩件事是配套的，單獨做任何一件都會落空。**

只開兩個 AI、卻讓挑毛病那個自己臨場決定什麼算合格，等於沒分。

## superpowers 是怎麼做的

superpowers 是一套跨平臺（Claude Code、Codex、Gemini 等都能用）的流程框架，本質是一堆 markdown 技能文件，強制 AI 走固定的工程流程。關於角色分離，它靠兩個技能：

- **subagent-driven-development**：計劃裡每個任務，派一個全新的 subagent 去做，原來那個 AI 退到協調者位置。
- **requesting-code-review**：任務做完後，由另一個全新的 AI 審查，分兩步——先查**是否符合規範**，再查**程式碼質量**；嚴重問題直接攔住，不許繼續。

配合它還強制 TDD（先寫測試、跑失敗、再最小實現）、用 git worktree 隔離、把計劃拆到 2～5 分鐘一個任務。

## Codex 框架下的三條落地路線

Codex 自帶兩個機制，不裝任何東西就能用。從省事到完整排列：

### 路線 A：直接用 `/review`（現在就能用）

Codex CLI 裡輸入 `/review`，它會**另起一個專門的審查 AI**，讀你選的改動，只報問題、**完全不碰工作樹**。選單四個選項：對比分支、審查未提交改動、審查某個提交、**自定義審查指令**。

對本專案最有用的是"自定義審查指令"，把它指向那份驗收標準：

```
對照 docs/development/acceptance-standard.md 逐條核對當前改動。
預設立場是“不通過”：每條標準必須有證據證明做到了，否則記為未通過。
按嚴重程度排序報告，嚴重問題必須攔住合入。
```

這一步就實現了"挑毛病的是另一個 AI，而且照著獨立標準挑"。還能在配置裡用 `review_model` 給審查換一個模型。

### 路線 B：固定一個 reviewer 角色（可複用、更穩定）

在專案裡建 `.codex/agents/reviewer.toml`，把審查 AI 的職責寫死，每次都一致：

```toml
# .codex/agents/reviewer.toml
name = "reviewer"
description = "對照驗收標準挑錯的獨立審查 agent"
model = "gpt-5.4"              # 可與寫程式碼那個用不同模型或檔位
model_reasoning_effort = "high"
sandbox_mode = "read-only"     # 只讀，碰不到程式碼
developer_instructions = """
你的職責是挑錯，不是誇。
對照 docs/development/acceptance-standard.md 逐條核對當前改動。
預設立場是“不通過”：每條標準必須有證據，否則記為未通過。
按嚴重程度排序輸出，嚴重問題必須攔住合入。不修改任何文件。
"""
```

（模型名按實際在用的填。）同樣的辦法，可以再建更多固定角色，把"寫實現"、"寫測試"、"核對覆蓋率"和"視覺校對"都拆開：

- `builder`：只按主 Agent 指定範圍寫實現，不改驗收標準，不做複核。
- `test-author`：照驗收標準生成測試用例，只寫測試。
- `acceptance-checker`：只核對"每條標準是否都有測試在管"，不寫程式碼也不寫測試。
- `visual-reviewer`：只讀對照畫面基準和真實執行截圖，不寫程式碼、不修 UI。

Codex 的 subagent 支持每個角色用不同模型、不同推理檔位、不同讀寫權限。自定義 agent 文件放在 `~/.codex/agents/`（全域）或 `.codex/agents/`（專案內），主要字段：

| 字段 | 作用 |
| --- | --- |
| `name` | 角色名 |
| `description` | 用途說明 |
| `developer_instructions` | 角色的核心職責指令 |
| `model` | 指定模型（可與主 AI 不同） |
| `model_reasoning_effort` | 推理檔位 `low/medium/high` |
| `sandbox_mode` | `read-only` 或 `workspace-write` |

併發和深度在主 `config.toml` 的 `[agents]` 段控制（`max_threads`、`max_depth`、`job_max_runtime_seconds`）。

另外 Codex 有 **auto-review**：AI 要做越界操作（改文件、跑命令）時，由一個獨立 reviewer 決定批不批，而不是每次都問人，可進一步降低盯著它的成本。

### 路線 C：直接上 superpowers（要整套流程時）

想要完整的 brainstorm → 計劃 → 每任務派新 AI 做 → 兩階段審查 → 收尾這一整套，在 Codex CLI 裡用 `/plugins` 裝 superpowers。注意：**它給的是通用工程流程，不含本遊戲的驗收標準**——標準那塊仍要用本專案那份文件餵給它的審查環節。

## 一個要說清楚的點

Codex 的"分離"分的是**記憶和立場**，底座可能還是同一個模型。這已經夠用——關鍵是全新的上下文、對立的立場、獨立的標準，不是非得換一家模型。要更徹底，就在 `reviewer.toml` 裡給審查角色配一個和寫程式碼那個不同的 model，或更高的推理檔位，獨立性更強。

## 在本專案的落地順序

1. 先用**路線 A** 跑一次：拿 [`docs/development/acceptance-standard.md`](./development/acceptance-standard.md) 當審查指令，對當前改動跑一遍 `/review`，看"獨立 AI 照標準挑錯"的實際效果。
2. 順手了，用**路線 B** 把 reviewer 固化成專案裡的角色，再視需要加 `builder`、`test-author`、`acceptance-checker`、`visual-reviewer`。
3. 在 `AGENTS.md` 的開發流程裡補一條：**測試通過之後，必須先過一遍獨立 reviewer；如果涉及畫面，還要先過 `visual-reviewer`。它們都不能和寫程式碼的是同一個 AI**。
4. 把這套和 [`docs/subagent-guide.md`](./subagent-guide.md) 對齊，避免兩份文件講法不一致。

## 來源

- [obra/superpowers（GitHub）](https://github.com/obra/superpowers)
- [Codex — Subagents 官方文件](https://developers.openai.com/codex/subagents)
- [Codex CLI — Features（含 /review）](https://developers.openai.com/codex/cli/features)
- [Codex — Auto-review](https://alignment.openai.com/auto-review/)
- [Superpowers: The Claude Code Skills Framework（Marc Nuri）](https://blog.marcnuri.com/superpowers-claude-code-skills-framework)
