# 《傳奇倖存者》資產完整性及驗收／經驗庫同步（2026-10-21）

## 範圍

本次針對 GitHub `feature/cinematic-menu-v3` 的**可取得資源**及**文件事實源**補齊缺漏，不變更角色傷害、掉落、AI、關卡流程、難度、存檔格式或正式 `main`。

## 資產補齊範圍

- `assets/audio/scifi/`：31 個 WAV 事件音效、一個 Ogg 迴圈 BGM，以及對應 `manifest.json`，共 32 個音訊檔。逐檔依 manifest 中原始 SHA-256 比對；既有 `assets/audio/LICENSES.md` 的原創合成及歷史 Kenney 來源說明保持不變。
- `assets/sprites/legendaryani/`：早期原型使用的角色、敵人、投射物八方向 PNG／`SpriteFrames`、戶外地圖、環境材質與偏移資料；保留來源說明，不用來替換現行 v0.2 科幻美術。
- `assets/sprites/ui/runtime/legendaryani/`：歷史版實際 `GameUI.gd` 使用的九宮格面板、血量／經驗條、卡片、徽章、圖示與按鈕資產。
- `assets/sprites/vfx/runtime/legendaryani/`：歷史版的命中、爆炸、拾取、死亡 VFX 資產。
- `assets/source/legendaryani_huazi_pilot.png` 及 `tools/build_legendaryani_art.py`：產生該主題時的來源圖和可檢查生成程式（需要 NumPy、Pillow；不是遊戲啟動依賴）。
- **不納入** `*.import`、`.godot/`、`reports/`、`.codex/builds/`、`.codex/restorepoints/` 或 `user://` 玩家資料。保留既有 GitHub 授權與原始來源敘述。

## 防回歸檢查

`tools/verify_runtime_assets.py` 檢查 32 個音訊 SHA-256、Git 追蹤狀態、純文字資源中的靜態 `res://assets/` 路徑、歷史角色／UI／VFX 素材與生成來源；只讀，不修改存檔與資產。執行指令：

```powershell
python tools/verify_runtime_assets.py
```

仍須由 Godot 4.7.2 在**乾淨 Clone** 重建匯入，執行編輯器載入、`smoke`、`replay` 和 `all`；腳本通過本身不代表真人玩法或美術驗收完成。

## 驗收與 Knowledge 合併方式

- `docs/development/acceptance-standard.md`：保留 GitHub 原有完整 v0.1 驗收章節，在其前方新增本機**原文**確認的現行 v0.2 `SF-01～SF-17`。不以本次處理降低 SF-16、SF-17 合格線。
- `docs/experience-library/lessons.md`：保留原有範本，在空白 `Records` 區新增本機 3 筆歷史問題與各自驗證記載；不把設計檢查誤稱為完成真人驗證。
- `docs/experience-library/active-rules.md`：保留原說明，以本機 2 條持續生效規則取代「暫無」。
- 原本本機工作區與其還原點不被覆蓋。本次資產與文件採獨立工作樹執行，經靜態檢查及 Godot 載入／Smoke／Replay 測試確認後推送，並重新從 GitHub Clone 執行全套測試。

## 未結案的品質界線

完成乾淨 Clone 和迴歸，**仍不等於** SF-16 固定種子三輪成長平衡通過、SF-17 獨立視覺與程式碼審查、100 場人工完整遊玩、電影式主選單正式美術採納或上架發布。這些須沿用現行驗收流程另行記錄。


## GitHub 全新 Clone 實際驗證結果

- GitHub 開發分支資產補齊版本：`9ae17be03fd4fc3a85a8fc2ff680a183f3726ce4`。從 GitHub 以 `--single-branch --branch feature/cinematic-menu-v3 --depth 1` 完整 Clone；原始新工作樹在 Godot 首次匯入前無未提交內容，不依賴原本未追蹤檔案。
- 在**乾淨 Clone** 執行 `python tools/verify_runtime_assets.py`：PASS；32 個 WAV/Ogg 音訊 manifest SHA-256 一致、132 個可判定靜態引用存在、51 個主題素材均由 Git 提供。
- Godot 4.7.2 `--headless --editor --quit`：退出碼 0；首次匯入完成，沒有 parse error 或遺失必要資源造成的致命載入錯誤。
- 於乾淨 Clone 使用 `tools/run_scifi_tests.ps1 -Scenario ... -Headless`（seed 17）：

| Scenario | GitHub 乾淨 Clone 結果 | 測試報告（未提交） |
| --- | --- | --- |
| `smoke` | `logic_matrix_passed=true` | `reports/scifi-tests/20261021-225023-smoke-300c70b2/matrix.json` |
| `replay` | `logic_matrix_passed=true` | `reports/scifi-tests/20261021-225029-replay-0cf98125/matrix.json` |
| `all` | `logic_matrix_passed=true` | `reports/scifi-tests/20261021-225040-all-eff85835/matrix.json` |

- **驗收邊界：** 三份報告均是 `acceptance_status=partially_verified`；`full_growth_matrix=false`。不得由 `all` 的邏輯通過推論 SF-16、SF-17、真人 100 場或正式美術品質已驗收完成。
- `.godot/`、Godot 自動匯入快取、測試快照與報告均維持在本機隔離位置，不納入 GitHub。
