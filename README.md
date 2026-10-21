# 傳奇倖存者 | Legendary Survivor

**Godot 俯視角生存動作遊戲／科幻機甲專案**

《傳奇倖存者》正在開發為 2D 科幻機甲生存動作遊戲：玩家操作「壁壘 1103」，使用自動武器、主動技能與改裝成長系統，在工業廢墟中迎戰敵軍與首領。

> **重要版本說明：** 這裡是 GitHub 預設 `main` 分支，**程式碼仍是早期 v0.1「花子／貓牛」玩法原型**，保留供歷史追溯。**最新版機甲遊戲的 Godot 原始碼、完整規格與開發文件在 [`feature/cinematic-menu-v3` 開發分支](https://github.com/LegendaryAni/legendary-survivor/tree/feature/cinematic-menu-v3)**。請不要將 `main` 的舊玩法誤認為目前的科幻機甲版本。

## 現行科幻機甲版（v0.2）

開發分支包含重裝機甲、六種武器、四種主動技能、敵人 AI、物理碰撞、首領戰、升級及永久成長、存檔與主選單動畫。部分平衡及獨立視覺驗收仍待完成。

- [最新版程式碼與 README](https://github.com/LegendaryAni/legendary-survivor/tree/feature/cinematic-menu-v3)
- [v0.2 科幻玩法規格](https://github.com/LegendaryAni/legendary-survivor/blob/feature/cinematic-menu-v3/spec/20261017_LegendarySurvivor_Scifi_v0.2.md)
- [開發文件總索引](https://github.com/LegendaryAni/legendary-survivor/blob/feature/cinematic-menu-v3/docs/index.md)
- [AI Agent 開發規則](https://github.com/LegendaryAni/legendary-survivor/blob/feature/cinematic-menu-v3/AGENTS.md)

## 啟動最新版本

安裝 **Godot 4.7.2**，取得開發分支後開啟 `project.godot`，執行 `scenes/Main.tscn`。

```bash
git clone --branch feature/cinematic-menu-v3 https://github.com/LegendaryAni/legendary-survivor.git
cd legendary-survivor
godot --path .
```

直接 Clone 預設的 `main` 分支只會取得早期 v0.1 原型。

## `main` 歷史原型

本分支保留以花子、三種貓類攻擊與奶牛敵人為基礎的一局制生存遊戲。其遊戲機制、素材與歷史驗收紀錄仍可從 [文件索引](docs/index.md) 查閱，但**不是現行 v0.2 的實作與玩法事實源**。

## 技術與來源

- **現行版本開發與整合：** LegendaryAni
- **遊戲引擎：** Godot 4.7.2／GDScript
- **開發流程：** Git／GitHub／AI Agent 協助實作及驗證
- **原始專案來源：** [mewamew/huaizi-de-cows](https://github.com/mewamew/huaizi-de-cows)

專案改名不會變更既有作者、素材授權與 Git 歷史的權利歸屬。
