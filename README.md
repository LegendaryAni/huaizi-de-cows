# 傳奇倖存者 | Legendary Survivor

**科幻機甲生存動作遊戲 / Sci-Fi Mecha Survival Action**

《傳奇倖存者》是以 Godot 4.7.2 和 GDScript 開發的俯視角生存動作遊戲。駕駛重裝機甲「壁壘 1103」，探索工業廢墟，搭配武器、主動技能與局內改裝，抵禦敵軍並迎戰首領。

Legendary Survivor is a top-down mecha survival action game made with Godot 4.7.2 and GDScript. Pilot Bulwark 1103 through industrial ruins, combine weapons and active abilities, and survive escalating enemy waves.

> **開發版本 / Development Build:** v0.2
> **開發分支 / Development Branch:** `feature/cinematic-menu-v3`
> **狀態 / Status:** 可遊玩，正式平衡與視覺驗收尚未全部完成。 / Playable; final balance and visual acceptance are pending.

## 遊戲特色 / Game Features

| 系統 / System | 繁體中文 | English |
| --- | --- | --- |
| 機甲作戰 / Mecha Combat | 操作「壁壘 1103」進行走位、閃避與技能戰鬥。 | Pilot Bulwark 1103 in a movement-driven combat system. |
| 自動武器 / Automatic Weapons | 六種武器，每局最多三把，具備強化與專屬進化。 | Six weapons; equip up to three per run, with upgrades and evolutions. |
| 主動技能 / Active Skills | 衝刺、電磁脈衝、護盾、維修；出擊前選擇兩項。 | Dash, EMP Pulse, Shield, and Repair; choose two before deployment. |
| 局內成長 / Run Progression | 擊破敵人、收集經驗、選擇改裝卡。 | Defeat enemies, collect XP, and select upgrade cards. |
| 永久改裝 / Permanent Upgrades | 利用信用點強化機體與戰鬥系統。 | Spend credits on persistent enhancements. |
| 首領戰 / Boss Battle | 第八分鐘迎戰「徵收者」。 | Face the Collector at eight minutes. |
| 動態機庫 / Animated Hangar | v3 獨立預覽包含分層機甲與機庫環境動畫。 | The isolated v3 preview includes an articulated mech and animated hangar. |

## 操作方式 / Controls

| 操作 / Action | 按鍵 / Input |
| --- | --- |
| 移動 / Move | WASD／方向鍵 / Arrow Keys |
| 主動技能 / Skills | Space、E |
| 暫停 / Pause | Esc、P |
| 配裝與選牌 / Loadout & Upgrades | 滑鼠 / Mouse |

## 啟動遊戲 / Getting Started

以 **Godot 4.7.2** 開啟 `project.godot`，執行 `scenes/Main.tscn`。
Open `project.godot` in **Godot 4.7.2** and run `scenes/Main.tscn`.

```bash
godot --path .
```

**v3 電影式主選單 / Cinematic Menu Preview**

v3 主選單保留為獨立預覽，不覆蓋一般遊戲入口。
The v3 menu is available as a separate preview without replacing the default menu.

```bash
godot --path . -- --menu-v3-preview
```

Windows 預覽執行檔是本機建置產物，不包含在 GitHub 原始碼提交中。
Windows preview executables are local build artifacts, not included in the source commit.

## 專案內容 / Project Overview

此版本包含機甲戰鬥、六種武器、四種技能、敵人行為、碰撞、關卡流程、改裝、永久成長、存檔、音效與主畫面動畫。

The current build includes mecha combat, six weapons, four skills, enemy AI, collisions, run progression, upgrades, saves, audio, and animated menu presentation.

- **引擎 / Engine:** Godot 4.7.2
- **語言 / Language:** GDScript
- **主場景 / Main Scene:** `scenes/Main.tscn`
- **v3 機甲動畫 / Mech Rig:** `scripts/scifi/MechIdleController.gd`
- **玩法規格 / Gameplay Specification:** [v0.2 科幻玩法](spec/20261017_LegendarySurvivor_Scifi_v0.2.md)
- **開發檔案 / Documentation:** [檔案索引 / Documentation Index](docs/index.md)

## 測試 / Testing

```powershell
./tools/run_scifi_tests.ps1 -Scenario all -Headless -GodotPath "<Godot Console Executable>"
```

測試涵蓋固定重播及功能回歸。Headless 測試不代表畫面驗收透過；SF-16／SF-17 仍有待驗專案。

Tests include deterministic replay and functional regression. Headless tests do not replace visual acceptance; SF-16 and SF-17 remain pending.

## 文件與版本 / Documentation & Version Scope

現行科幻玩法以 `spec/20261017_LegendarySurvivor_Scifi_v0.2.md` 為準；早期 v0.1 原型文件與素材只供歷史追溯，並非現行遊戲內容。詳見 [專案名稱與版本說明](docs/20261021_LegendarySurvivor_ProjectIdentity.md)。

The current sci-fi game follows the v0.2 specification. Earlier prototype documents and assets are preserved for traceability; they do not describe the active gameplay.

## 製作與授權 / Development & Credits

**本版開發與整合 / Development & Integration:** LegendaryAni

本儲存庫包含既有專案基礎與本版新增的科幻玩法、美術及動畫；相關來源及權利紀錄見 [素材說明 / Art Notes](assets/sprites/scifi/README.md) 與 [音訊授權 / Audio Licenses](assets/audio/LICENSES.md)。基礎專案：[mewamew/huaizi-de-cows](https://github.com/mewamew/huaizi-de-cows)（原始 Git 作者記載為 HexBlank）。

This version builds upon an existing project foundation while adding sci-fi gameplay, art, and animation. Original project attribution and third-party licensing remain documented in the linked records.
