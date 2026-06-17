# 游戏资源使用说明

本文说明当前仓库有哪些游戏资源、哪些可以直接作为 Godot 运行时资源、哪些只作为风格参考，以及新增或接入资源时要读哪些文件。

## 运行时优先使用

- `assets/sprites/`：地图、环境、花子、敌人、猫弹、奶滴、SpriteFrames 和视觉参考素材。
- `assets/audio/sfx/`：运行时音效文件。

## 图片资源

图片资源接入规则见 `assets/sprites/README.md`。

开发时重点区分：

- 地图、花子、敌人、猫弹、奶滴：优先使用现有运行时素材和 `.spriteframes.tres`。
- `ui_assets_painted.png`：UI 和图标风格参考，不直接切片当最终 UI；控件级参考 crop 和接入规则见 `assets/sprites/ui/README.md`。
- `assets/sprites/ui/reference_crops/`：从 UI 总参考图拆出的控件级参考图，用来锁定视觉目标。
- `assets/sprites/ui/runtime/`：Godot 运行时代码应引用的 UI 资产目录；缺少资产时先生成资产，再写 UI。
- `combat_assets_painted.png`：战斗 VFX 风格参考；角色、敌人、猫弹按 8 向图集使用，命中、爆炸、粒子等 VFX 需要定制生成。
- `assets/source/`：源图和生成素材，不作为 Godot 运行时优先资源。

## 音频资源

音频使用说明见 `assets/audio/README.md`。音效文件在 `assets/audio/sfx/`；授权来源和文件映射见 `assets/audio/LICENSES.md`。

## 已确认资源覆盖

当前资源已覆盖正常可用版本需要的地图、角色、敌人、猫弹、UI/VFX 风格参考和音效。日常开发不需要重新判断资源够不够，重点是按说明正确接入和验证。
