# 《傳奇倖存者》SF-16／SF-17 待驗事項與實測診斷

日期：2026-10-21。**本文件記錄尚未通過的驗收與診斷，不是簽核報告。**

## SF-16：三種子第一次真實時鐘診斷

事實源：`spec/20261017_LegendarySurvivor_Scifi_v0.2.md`、`docs/20261017_LegendarySurvivor_ScifiTestCases_v0.2.md` 的 T16、`docs/development/acceptance-standard.md` 的 SF-16。

- 測試來源：GitHub 開發分支 `4c99f61f28fa96e6281c6b80a1e48483af56baeb`（測試執行時的提交，尚未加入後來的防呆 wrapper）。
- Godot 4.7.2 Console 真實 `growth` 場景；正常 `Engine.time_scale=1`、每秒 60 次物理更新；依核准 T16 策略從不同的隔離新存檔分別跑種子 `17、41、73`，沒有作弊道具、強制勝利或改變策略。
- 狀態由 `growth-seed-*.json.snapshots.jsonl` 的 `progress.runs` 和 `result` 紀錄比對，不是人工猜測。

| 種子 | 第 1 場結算 | 戰鬥時間 | 對應第一次通關 |
| --- | --- | ---: | --- |
| 17 | 勝利 | 614.55 秒 | 第 1 場 |
| 41 | 失敗 | 494.78 秒 | 此時尚未通關 |
| 73 | 勝利 | 665.47 秒 | 第 1 場 |

**結論：目前配置不可能達到 SF-16 的「首次通關場次中位數 3～5」。** 因為兩個種子首次通關已固定為 1，所以第三個種子即使後續通關，中位數仍會是 1。為避免不必要長時間算力消耗，已在種子 41 第 2 場進行中保留紀錄並提前停止。**本診斷不是完整 T16 三種子 × 最多五場矩陣，因此不得標記 SF-16 PASS。**

首次使用 `pwsh -File ... -Seeds 17,41,73` 的參數曾被 PowerShell 當作**單一種子 174173**；已將該錯誤批次標為 `INVALID_SEED_DO_NOT_COUNT`，從未計入上述結果。其後的診斷批次實際啟動三個獨立種子 17／41／73。

## 已補強的驗收流程

`tools/run_sf16_growth.ps1` 使用原生整數陣列 `[int[]]@(17,41,73)` 鎖定種子，再呼叫正式 `tools/run_scifi_tests.ps1`。`-VerifyOnly` 可在不啟動 Godot 的情況下檢查種子集合。

```powershell
pwsh -NoProfile -File tools/run_sf16_growth.ps1 -VerifyOnly
pwsh -NoProfile -File tools/run_sf16_growth.ps1 -Headless -GodotPath "<Godot 4.7.2 console.exe>"
```

以頭部/邏輯測試替代完整三種子正常時鐘矩陣、修改策略或調低驗收門檻，均不合格。下一輪應基於本輪 HP、首領戰與敵人威脅紀錄調整**集中 Config**，先執行受影響回歸，再以全新隔離存檔**重新跑完整三種子五場上限矩陣**，記錄每次失敗與成功配置版本。真人難度另需試玩驗證。

## SF-17：獨立審查仍未完成

`docs/20261019_LegendarySurvivor_CinematicMenuV3_CompletionLog.md` 明確記載當時 Runner 不支援 `coding_agent_runs`，尚未完成**獨立 visual-reviewer、獨立 reviewer**；v3 機甲品質仍未達原參考美術，先維持獨立預覽，不替換正式預設主選單。後續應取得與現行資產完全相符的 GPU 截圖、連續片段、操作回饋、程式與美術獨立複核。現有自動回歸及此文件不能取代獨立簽核。

## 正式發布門檻

GitHub 資產與 Knowledge 已補齊，乾淨 Clone 已驗證；但 SF-16 平衡與 SF-17 視覺／獨立審查尚未通過，**不得將本文件視為正式 Release 或上架許可**。`main`、玩家存檔、歷史原型與原本未提交的工作檔均保持不變。
