# UI 资源拆分说明

> v0.2使用科幻像素主題：`reference_crops/scifi/` 為處理後參考，`runtime/scifi/` 為正式資產，生成原圖保留 `assets/source/scifi/`。舊手繪crop不再是新版材質目標；三張並排大卡、字區與正式資產等原則保留。HUD/卡片/按鈕以生成panel裁切與ninepatch整理，不以預設單色控件代替。

本文说明 `ui_assets_painted.png` 被拆成哪些控件级参考图，以及后续运行时 UI 资产应该怎样生成和接入。

## 目录职责

- `reference_crops/`：从 `../ui_assets_painted.png` 直接裁出的控件级参考图。它们用于锁定视觉目标、裁切范围和局部细节，不直接等同于最终运行时控件。
- `runtime/`：Godot 实现应该引用的运行时 UI 资产目录。这里放按实际尺寸、透明边距、九宫格拉伸区和文字安全区整理后的 PNG、`.9.png` 或 `.tres`。
- `ui_asset_manifest.json`：每个参考 crop 的来源 bbox、用途、建议运行时文件名和 Godot 接入方式。

代码里不要引用 `.import` 文件；`.import` 是 Godot 自动生成的导入元数据。运行时代码应引用 `res://assets/sprites/ui/runtime/...`，或引用由这些 PNG 建出的 `.tres`。

## 使用原则

1. 需要做 HUD、升级弹窗、结算、暂停、提示横幅或图标时，先查 `ui_asset_manifest.json`。
2. 如果 `runtime/` 下缺少对应资产，先基于 `reference_crops/` 生成或整理运行时资产，再写 UI 实现。
3. 不允许用纯 `draw_rect`、`draw_line`、`draw_circle`、默认 `Button`、默认 `Panel` 或单色 `StyleBoxFlat` 来模拟升级卡、HUD 主框、结算面板这类核心 UI 外观。
4. 代码绘制可以用于文字、数值、填充条、轻量 hover 光效、短暂点击反馈和布局辅助，但核心边框、底纹、徽章、做旧材质和装饰性边角必须来自运行时 UI 资产。
5. 不能直接把 `ui_assets_painted.png` 当作运行时 atlas 整张加载后随意裁用。需要先拆出 crop，明确用途，再生成适合实际尺寸的运行时资产。
6. 每次实现或重做核心 UI，都要保留参考 crop、运行截图 crop 和并排对照图，证明边框材质、比例、视觉重心和文字安全区没有偏离。

## 升级三选一卡片

升级弹窗使用三张并排竖向大卡片。卡片运行时建议显示尺寸为 `320x540`，可在不破坏比例的前提下小幅调整，但不能改成长条按钮、普通菜单列表或默认系统面板。

| 控件 | 参考 crop | 建议运行时资产 | 用法 |
| --- | --- | --- | --- |
| 普通升级卡 | `reference_crops/upgrade_card_normal_ref.png` | `runtime/upgrade_card_normal.9.png` | 普通可选卡片背板 |
| 高亮升级卡 | `reference_crops/upgrade_card_gold_ref.png` | `runtime/upgrade_card_gold.9.png` | hover、推荐态或当前聚焦卡片 |
| 攻击强调升级卡 | `reference_crops/upgrade_card_red_ref.png` | `runtime/upgrade_card_red.9.png` | 攻击类升级或危险强调态，可选 |
| U01 图标 | `reference_crops/upgrade_icon_cat_swarm_ref.png` | `runtime/upgrade_icon_cat_swarm.png` | 猫猫连发 |
| U02 图标 | `reference_crops/upgrade_icon_damage_ref.png` | `runtime/upgrade_icon_damage.png` | 猫爪变锋利 |
| U04 图标 | `reference_crops/upgrade_icon_player_speed_ref.png` | `runtime/upgrade_icon_player_speed.png` | 跑快一点 |

建议文字安全区按 `320x540` 卡片尺寸记录：

| 区域 | 建议范围 |
| --- | --- |
| 标题 | `x=36..284, y=42..96` |
| 主图标 / 主内容区 | `x=44..276, y=112..310` |
| 说明区 | `x=36..284, y=340..456` |
| 底部徽章 | 中心约 `x=160, y=492`，半径约 `34` |
| 九宫格边距 | `left=42, top=42, right=42, bottom=78` |

## HUD、面板和图标

| 控件 | 参考 crop | 建议运行时资产 | 用法 |
| --- | --- | --- | --- |
| 花子头像框 | `reference_crops/hud_avatar_huazi_ref.png` | `runtime/hud_avatar_frame.png` | HUD 左上头像 |
| 血条/经验条框 | `reference_crops/hud_health_bar_ref.png` | `runtime/hud_bar_frame.9.png` | HUD 条形背板，填充层另做 |
| 暖色结算面板 | `reference_crops/panel_result_warm_ref.png` | `runtime/panel_result_warm.9.png` | 胜利/结算背板 |
| 暗色结算面板 | `reference_crops/panel_result_dark_ref.png` | `runtime/panel_result_dark.9.png` | 失败/暂停背板 |
| 顶部提示横幅 | `reference_crops/notice_panel_wide_ref.png` | `runtime/notice_panel_wide.9.png` | 波次、新猫提示 |
| 三种猫武器槽图标 | `reference_crops/weapon_icon_*_ref.png` | `runtime/weapon_icon_*.png` | HUD 已解锁猫图标 |

## 生成和验收要求

运行时 UI 资产生成后，至少补齐下面几类证据：

- `ui_reference_crop_*.png`：使用到的参考 crop。
- `ui_runtime_asset_*.png`：生成后的运行时资产。
- `ui_runtime_screenshot_*.png`：真实运行截图 crop。
- `ui_compare_*.png`：参考 crop 与运行截图并排对照。
- 简短说明：哪些地方继承了参考图，哪些地方因为文字、尺寸或可交互状态做了调整。

如果核心 UI 仍主要由代码画矩形和圆形组成，即使布局接近，也不能视为符合素材接入要求。
