# Experience Library

Experience Library 用於沉澱本儲存庫開發時真實踩過、修過、驗證過的問題。它不是事後總結，也不是泛泛建議；只有遇到問題並解決之後，才寫入經驗庫。

## 文件

| 文件 | 用途 |
| --- | --- |
| `active-rules.md` | 每次開發前必須讀的短規則，只放高頻、關鍵、容易復犯的問題 |
| `lessons.md` | 完整經驗記錄，按條目記錄現象、原因、修復、驗證和下次檢查方式 |

## 使用規則

每次執行新方案前：

1. 先讀 `AGENTS.md`。
2. 再讀 `docs/experience-library/active-rules.md`。
3. 如果當前任務涉及已記錄問題，再讀 `docs/experience-library/lessons.md` 中相關條目。

遇到問題並解決後：

1. 必須在 `docs/experience-library/lessons.md` 新增經驗條目。
2. 如果這個問題會高概率復發，必須把短規則補充到 `docs/experience-library/active-rules.md`。

不要寫入：

- 沒有復現過的問題。
- 沒有解決的問題，除非明確標為“未解決”並寫清阻塞原因。
- 泛泛而談的建議，例如“注意測試”“程式碼要清晰”。
- 為了顯得完成而寫的空洞總結。

## 經驗條目格式

```md
### YYYY-MM-DD | 簡短標題

- 場景：
- 現象：
- 影響：
- 原因：
- 修復：
- 驗證：
- 下次規則：
- 關聯文件 / 提交：
```
