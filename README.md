## 2026-10-19 Main Menu Goal implementation

Goal ID: wc_goal_MXBwdHzPm7MiFYqS. The main menu was refactored into
scenes/ui/ScifiMainMenu.tscn and scripts/scifi/ScifiMainMenu.gd.
It presents seven clickable navigation actions, a full 1920x1080 industrial
hangar/mech backdrop, a local (offline) status module, mission briefing,
local project update notes and real save credits.
Art source: assets/sprites/ui/runtime/scifi/menu_backdrop.jpg,
menu_icon_*.png. The hangar is procedural imagery composed with existing
low-resolution unit 1103 portrait; it remains a replacement-ready placeholder,
NOT a final high-definition mech illustration. See
docs/20261019_LegendarySurvivor_MainMenu_UI_Goal_v1.md.
Original saves, combat logic and non-menu screens are unchanged.

# 傳奇倖存者

## 目前版本：v0.2 科幻改造（驗收中）

Godot 4.7.2／GDScript 桌面科幻像素倖存者。主場景 `scenes/Main.tscn` 已接新版，從主選單進「出擊整備」，選一把起始武器與兩個主動技能，再開始作戰。

- 主角：壁壘重裝機甲；四種一般敵人與徵收者首領。
- 六種自動武器，每局最多三把，各五級；搭配三級改裝後可選專屬進化。
- 主動技能：衝刺、電磁脈衝、護盾、維修，出擊前四選二。
- 第8分鐘迎戰首領，擊敗才通關；信用點可購買四項永久升級，敗局保留收益。
- 舊成績檔與原使用者資料目錄保留；新版成長另存 `scifi_progress.json`，不做中途續局。

操作：WASD／方向鍵移動、Space／E技能、Esc／P暫停、滑鼠選牌與配裝。首次執行有三步驟引導；音效與畫面選單可獨立調整新音樂、音效及震屏。科幻原創音訊來源見 assets/audio/scifi/manifest.json。本機 Windows 預覽位於 .codex/builds/LegendarySurvivor_v0.2_preview.exe（搭配同名 .pck）。目前仍未通過 SF-16/SF-17 最終驗收。

```powershell
godot --path .
```

本版的玩法、初值與授權範圍見 [科幻規格](spec/20261017_LegendarySurvivor_Scifi_v0.2.md)，[驗收標準](docs/development/acceptance-standard.md) 與 [測試案例](docs/20261017_LegendarySurvivor_ScifiTestCases_v0.2.md) 分開維護。尚未完成的正常成長／真人難度與最終複核依 `current_status.md` 標示，不能以本入口存在推定驗收通過。

驗證：`tools/run_scifi_tests.ps1 -Scenario all -GodotPath <Godot console exe> -Headless`；三種子正常時鐘成長使用 `-Scenario growth -ParallelGrowth -Headless`。所有測試由工具建立隔離存檔，禁止指向玩家正式資料。UI／動畫證據必須另以可渲染入口執行，headless不證明畫面合格。

美術由使用者指定的《殖星鐵衛》既有原創素材複製接入，科幻面板/裝備圖示由OpenAI image_gen補製；來源、處理與雜湊見 [素材入口](assets/sprites/scifi/README.md)。來源專案保持不變。

## 歷史版本：v0.1

《傳奇倖存者》是一款 2D 俯视角幸存者类小游戏。你控制花子在户外大地图里走位，花子会不断放出猫猫攻击从四面八方冲来的奶牛。你要一边躲开敌人，一边选择升级，让猫群越打越强，撑过最后一波就能获胜。

## 游戏内容

- 固定户外大地图，镜头跟随花子移动。
- 花子自动放猫攻击敌人，玩家不用手动瞄准。
- 橘猫、黑猫、奶牛猫三种猫有不同攻击方式。
- 普通奶牛、疯跑小牛、厚皮大奶牛、吐奶远程牛会按波次出现。
- 战斗中会出现三选一升级，可以强化伤害、发射频率、移动速度或攻击范围。
- 花子血量归零会失败，撑过最后一波会胜利。

## 操作方式

- 移动：WASD / 方向键
- 选择升级：鼠标点击
- 暂停：Esc / P

## 技术栈

本游戏使用 Godot 4.x 和 GDScript 开发，目标是做成一个轻量、完整、能直接游玩的一局制 2D 小游戏。

## 制作信息

- 本版本开发：LegendaryAni
- 原始项目：`mewamew/huaizi-de-cows`
- 原始仓库 Git 作者：HexBlank
