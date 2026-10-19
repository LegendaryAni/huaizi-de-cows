# 《傳奇倖存者》v3 主要待辦項實作與驗證紀錄（2026-10-19）

## 目標與狀態

目前有效 GOAL：`wc_goal__aIMv8m5-4xhQhDj`，因獨立視覺／程式審查及美術正式接納未完成，仍為 Active。主場景舊版保持預設，這批全部先寫入**隔離可玩的 Windows v3 Preview**。

**完整美術來源的事實**：機甲是以 `tools/build_1103_mech_layers.py` 以多邊形與材質程式重新繪製為 1200×1400 的**原創 2D 繪製資產**。不是原本 96px PNG 拉伸的結果；也不是寫實 3D 模型、製作好的 Blender 骨架或外部高精度角色概念原畫。它比先前畫素放大圖清晰且能做分層關節動畫，但**美術表現仍和使用者的電影式高解析參考圖有差距**，不可宣稱相同品質。

## 已完成的具體實作

| 工作 | 實際檔案／行為 |
|---|---|
| 高解析原創機甲分層圖 | `assets/sprites/ui/runtime/scifi/v3_mech_layers/{backpack,legs,torso,left_arm,right_arm,head,weapon,effects}.png`：各 1200×1400 透明高解析層，具表面磨損紋理 |
| 可編輯美術原始生成程式 | `tools/build_1103_mech_layers.py` + `v3_mech_layers/rig.json` 包含各層 pivot；舊 96px 圖不覆蓋 |
| 角色分層待機動畫 | `scripts/scifi/MechIdleController.gd`：頭部、左右手臂、胸甲、武器、發光層真實獨立旋轉／位移；可停止、恢復；不動碰撞或 HP |
| 機庫動態 | 新 `v3_crane.png` 可獨立沿天車軌道動作與停頓；環境光 `AnimationPlayer`、粉塵 `GPUParticles2D`、少量視差仍存在 |
| 選單 UI | 新 v3 場景右側機甲，七個原功能可按、真實本機存檔統計、兩個分離的底部資訊模組、焦點與過場 |
| 「減少動態效果」 | `scripts/SfxBus.gd` 存入 `user://scifi_preferences_v1.cfg` 的 `display.reduce_motion`；`ScifiUI.gd` 設定頁可切換並回傳；機甲關節、粉塵、吊架、燈光迴圈與視差停用 |
| 提示音效 | 新版 v3 選單確認仍呼叫原 `SfxBus.play_event("ui_select")`，沿用原有音量設定 |
| FPS 度量 | GPU `menu-v3-perf` 真實逐影格量測 339 個樣本，計算平均 FPS、p95 影格 ms；不是估計值 |
| 儲存既有行為 | `ScifiUI.gd` 視需要切入 v3，正式預設場景不覆蓋；儲存、戰鬥數值及 GitHub 不動 |

## 最新可追溯測試結果

- v3 GPU 實機功能：`reports/scifi-tests/20261019-164511-menu-v3-4828336d/`，1600×900 PASS。
- 分層動畫、減少動態功能及恢復：`reports/scifi-tests/20261019-164521-menu-v3-motion-c5dd5a57/`，1920×1080 PASS。
- GPU 影格量測：`reports/scifi-tests/20261019-164530-menu-v3-perf-cdaf9b08/`，平均 **74.97 FPS**、p95 **13.444ms**、339 樣本；RTX 4060 Ti / 1920×1080，僅代表該機該次測試。
- 完整邏輯回歸：`reports/scifi-tests/20261019-164540-all-63cf5378/`，PASS。
- 固定種子重播：`reports/scifi-tests/20261019-163908-replay-9ffb51af/`，PASS。
- 原有舊選單的隔離相容性：前一輪 `reports/scifi-tests/20261019-161258-menu-preview-9ace130e/` PASS；本輪 source 仍不改預設載入條件。
- Windows v3 完成版：`.codex/builds/LegendarySurvivor_CinematicMenu_v3_preview_complete.exe` 與同名 `.pck`，已匯出。
- 匯出執行檔第一次 `menu-v3-motion`：**FAILED 6**，在關節動態截圖後畫面提前進入過場，後續控制項無法找到；原始報告 `.codex/builds/v3-complete-export-motion.json` 保留。
- 同一個 EXE 第二次重新驗證 `menu-v3-motion`：`.codex/builds/v3-export-motion-second.json`，failed=0。
- 匯出 EXE 第三次獨立七選單驗證 `menu-v3`：`.codex/builds/v3-export-full-third.json`，failed=0。第一次失敗不能僅因兩次重測透過而抹除。

## 明確仍開放的驗收及風險

1. **獨立 visual-reviewer／reviewer**：Chadex Runner 當下不支援 `coding_agent_runs`，不能提供 SF-17 要求的兩輪隔離審查，因此不能說整個遊戲驗收完成；這是正式替換主選單前的阻礙。
2. **參考圖品質差距**：雖已是分層高解析原創 2D art，有真實關節，但尚未達到參考圖的電影式高精度機甲插畫／立體模型品質。請勿將 2D 向量機甲偽稱為高保真 3D。
3. **正式 SF-13 畫素風規則**：專案目前標準仍要求統一畫素風與 Nearest，新 v3 屬候選風格；在更新此標準與視覺獨立驗收前不取代正式版。
4. **SF-16 平衡與過往 100 場 Computer Use 人工測試**：本輪未執行，不能拿 GPU 專項測試與 headless 回歸折抵。
5. **幀率外推限制**：75FPS 僅是該臺 Windows 1920×1080 實測，不代表長時間高壓戰鬥或其他硬體。
6. **第一次匯出互動失敗尚無單一確定根因**：兩次重新測試均未重現，仍需獨立審查及持續性測試，不聲稱已確認是外部輸入。

## 安全狀態

- 本輪新還原點：`.codex/restorepoints/20261019-cinematic-mech-rig-motion-complete/`。
- 保留玩家存檔、原始專案場景及先前 v3 Preview、不部署、不推送、不重設 Git。
- 獨立 Windows 預覽名稱包含 `CinematicMenu_v3_preview`，啟動後可直接看到新主畫面；普通 Godot 專案仍沿用原本的場景。
