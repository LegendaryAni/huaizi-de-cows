# 素材需求检查清单

依据：`../../spec/游戏机制.md`

检查对象：`assets/sprites/`、`assets/audio/`

## 结论

当前新版手绘素材已经覆盖游戏机制文档里的美术素材需求：全图正常亮度的固定户外清晰底图、可叠加地图环境与边界、花子、三种猫弹、四种奶牛敌人，以及升级/UI/结算/提示、命中特效、经验反馈、死亡烟尘、碎屑和粒子的风格参考。UI 总参考图已经拆出控件级参考 crop，见 `ui/reference_crops/` 和 `ui/ui_asset_manifest.json`。

运行时使用规则需要区分：花子、奶牛、猫等角色/弹体素材优先直接使用 8 向图集；UI、图标、命中、爆炸、粒子等非角色视觉素材不得直接使用原素材文件作为最终游戏资产，必须按实际 HUD、弹窗、按钮、特效半径、动效帧数和透明边距重新生成合适尺寸和格式的定制资产。HUD、条形 UI、技能槽、升级卡片、按钮、暂停和结算等 UI 控件还必须逐项和参考 crop 对比，每一次对比都要记录，风格相似度与资产完成度都达到 0.90 以上，且真实截图和动态帧中不能有控件重叠、裁切或遮挡；任一控件不达标就必须重新生成或调整后再验收。

另外已补充 8 向 Godot 图集：花子、四种奶牛敌人、橘猫整猫扑击、黑猫整猫扑击、奶滴远程弹。它们用于解决俯视 45 度场景里多个方向显示的问题。

音频素材已补充到 `assets/audio/sfx/`，授权和文件映射见 `assets/audio/LICENSES.md`。敌人闪白、无敌闪烁、震屏、打击停顿适合在 Godot 里用代码或 shader 做，不需要单独图片素材。

## 新版主素材

| 文件 | 覆盖内容 |
| --- | --- |
| `full_outdoor_map_painted_4096x2305.png` | 固定户外清晰底图，全图正常亮度，不内置隔挡/环境装饰/暗角 |
| `environment_assets_painted.png` | 泥地、草地、深浅地块、草丛、石头、小土堆、落叶、围栏、树墙、石墙、水面边界 |
| `ui_assets_painted.png` | 血量条、升级三选一卡片、胜利/失败结算页、暂停界面、4 个升级图标、HUD 武器图标、波次提示、获得新猫提示的风格参考；控件级 crop 已拆到 `ui/reference_crops/`，运行时 UI 需要按 `ui/README.md` 定制生成 |
| `ui/ui_asset_manifest.json` | UI 控件参考 crop、建议运行时资产名、用途和 Godot 接入方式的映射 |
| `combat_assets_painted.png` | 花子、橘猫、黑猫、奶牛猫、普通奶牛、疯跑小牛、厚皮大奶牛、吐奶远程牛、奶滴弹、命中、爆炸、经验、吸附、死亡烟尘、碎屑、粒子的风格参考；角色/弹体用 8 向图集，VFX 需要定制生成 |
| `huazi_8dir_192x192.png` | 花子 8 向待机 / 行走 |
| `cow_normal_8dir_256x192.png` | 普通奶牛 8 向行走，已校正为普通荷斯坦奶牛形体 |
| `cow_calf_8dir_192x144.png` | 疯跑小牛 8 向奔跑 |
| `cow_tank_8dir_320x224.png` | 厚皮大奶牛 8 向行走，已校正为厚重 8 向姿态 |
| `cow_ranged_8dir_288x192.png` | 吐奶远程牛 8 向行走，不包含奶滴弹 |
| `orange_cat_projectile_8dir_192x128.png` | 橘猫整猫直线扑击 8 向飞行 |
| `black_cat_projectile_8dir_192x128.png` | 黑猫整猫范围扑击 8 向飞行 |
| `cow_cat_spin_8dir_192x128.png` | 奶牛猫回旋扫场弹 8 向 |
| `milk_drop_8dir_192x128.png` | 奶滴远程弹 8 向飞行 |
| `painted_regen_manifest.json` | 新版素材总清单 |
| `directional_asset_manifest.json` | 8 向补充素材清单 |
| `cow_ranged_muzzle_offsets.json` | 吐奶远程牛各方向奶滴生成偏移 |
| `full_outdoor_map_manifest.json` | 新版完整地图尺寸、出生点、刷怪区、视觉边界 |

## 音频素材

| 文件 | 覆盖内容 |
| --- | --- |
| `assets/audio/sfx/cat_orange_launch_01.ogg` | 橘猫发射 |
| `assets/audio/sfx/cat_black_launch_01.ogg` | 黑猫发射 |
| `assets/audio/sfx/cat_cow_spin_01.ogg` | 奶牛猫回旋发射 |
| `assets/audio/sfx/milk_launch_01.ogg` | 远程牛奶滴发射 |
| `assets/audio/sfx/hit_soft_01.ogg` | 普通命中 |
| `assets/audio/sfx/cat_black_explode_01.ogg` | 黑猫爆炸 |
| `assets/audio/sfx/player_hurt_01.ogg` | 玩家受击 |
| `assets/audio/sfx/enemy_die_01.ogg` | 敌人死亡 |
| `assets/audio/sfx/xp_pickup_01.ogg` | XP 拾取 |
| `assets/audio/sfx/level_up_01.ogg` | 升级 |
| `assets/audio/sfx/ui_select_01.ogg` | UI 选择 / 升级选择 |
| `assets/audio/sfx/wave_start_01.ogg` | 波次开始 |
| `assets/audio/sfx/weapon_unlock_01.ogg` | 解锁新猫 |
| `assets/audio/sfx/victory_01.ogg` | 胜利 |
| `assets/audio/sfx/defeat_01.ogg` | 失败 |

## 逐项检查

| 机制需求 | 状态 | 新版素材 |
| --- | --- | --- |
| 固定户外大地图 | 已覆盖，作为全图正常亮度的清晰底图 | `full_outdoor_map_painted_4096x2305.png` |
| 地图泥地 | 已覆盖 | `environment_assets_painted.png` |
| 地图草地 / 深浅地块 | 已覆盖 | `environment_assets_painted.png` |
| 草丛 | 已覆盖 | `environment_assets_painted.png` |
| 石头 | 已覆盖 | `environment_assets_painted.png` |
| 小土堆 | 已覆盖 | `environment_assets_painted.png` |
| 落叶 | 已覆盖 | `environment_assets_painted.png` |
| 围栏边界 | 已覆盖 | `environment_assets_painted.png` |
| 树墙边界 | 已覆盖 | `environment_assets_painted.png` |
| 石墙边界 | 已覆盖 | `environment_assets_painted.png` |
| 水面边界 | 已覆盖 | `environment_assets_painted.png` |
| 花子 | 已覆盖 | `combat_assets_painted.png` / `huazi_8dir_192x192.png` |
| 花子受击反馈 | 已覆盖风格参考，运行时可用 shader、`modulate` 或定制特效实现 | `combat_assets_painted.png` |
| 花子多方向显示 | 已覆盖 | `huazi_8dir_192x192.png` |
| 橘猫直线扑击 | 已覆盖 | `combat_assets_painted.png` / `orange_cat_projectile_8dir_192x128.png` |
| 橘猫整猫多方向扑击 | 已覆盖 | `orange_cat_projectile_8dir_192x128.png` |
| 黑猫范围攻击 | 已覆盖 | `combat_assets_painted.png` / `black_cat_projectile_8dir_192x128.png` |
| 黑猫整猫多方向扑击 | 已覆盖 | `black_cat_projectile_8dir_192x128.png` |
| 奶牛猫回旋扫场 | 已覆盖 | `combat_assets_painted.png` / `cow_cat_spin_8dir_192x128.png` |
| 奶牛猫回旋弹多方向显示 | 已覆盖 | `cow_cat_spin_8dir_192x128.png` |
| 普通奶牛 | 已覆盖，8 向图集已校正为普通荷斯坦奶牛形体 | `combat_assets_painted.png` / `cow_normal_8dir_256x192.png` |
| 疯跑小牛 | 已覆盖 | `combat_assets_painted.png` / `cow_calf_8dir_192x144.png` |
| 厚皮大奶牛 | 已覆盖，8 向图集已校正为厚重姿态，避免侧视旋转伪影 | `combat_assets_painted.png` / `cow_tank_8dir_320x224.png` |
| 吐奶远程牛 | 已覆盖 | `combat_assets_painted.png` / `cow_ranged_8dir_288x192.png` |
| 敌人多方向显示 | 已覆盖 | `cow_normal_8dir_256x192.png`、`cow_calf_8dir_192x144.png`、`cow_tank_8dir_320x224.png`、`cow_ranged_8dir_288x192.png` |
| 慢速奶滴弹 | 已覆盖 | `combat_assets_painted.png` / `milk_drop_8dir_192x128.png` |
| 慢速奶滴弹多方向飞行 | 已覆盖 | `milk_drop_8dir_192x128.png` |
| 吐奶远程牛发射点 | 已覆盖 | `cow_ranged_muzzle_offsets.json` |
| 猫攻击命中反馈 | 已覆盖风格参考，运行时需定制生成 | `combat_assets_painted.png` |
| 黑猫爆炸特效 | 已覆盖风格参考，运行时需定制生成 | `combat_assets_painted.png` |
| 经验球 / 经验吸附反馈 | 已覆盖风格参考，运行时需定制生成 | `combat_assets_painted.png` |
| 敌人死亡烟尘 / 碎屑 | 已覆盖风格参考，运行时需定制生成 | `combat_assets_painted.png` |
| 粒子小图集 | 已覆盖风格参考，运行时需定制生成 | `combat_assets_painted.png` |
| 血量条 | 已覆盖控件级参考 crop，运行时需定制生成 | `ui/reference_crops/hud_health_bar_ref.png` |
| 升级三选一卡片 | 已覆盖控件级参考 crop，运行时需定制生成 | `ui/reference_crops/upgrade_card_normal_ref.png`、`upgrade_card_gold_ref.png`、`upgrade_card_red_ref.png` |
| 胜利结算页 | 已覆盖控件级参考 crop，运行时需定制生成 | `ui/reference_crops/panel_result_warm_ref.png` |
| 失败结算页 | 已覆盖控件级参考 crop，运行时需定制生成 | `ui/reference_crops/panel_result_dark_ref.png` |
| 暂停界面 | 已覆盖控件级参考 crop，运行时需定制生成 | `ui/reference_crops/panel_result_dark_ref.png` |
| 4 个升级图标 | 已覆盖控件级参考 crop，运行时需定制生成 | `ui/reference_crops/upgrade_icon_*_ref.png` |
| HUD 武器图标 | 已覆盖控件级参考 crop，运行时需定制生成 | `ui/reference_crops/weapon_icon_*_ref.png` |
| 波次提示 | 已覆盖控件级参考 crop，运行时需定制生成 | `ui/reference_crops/notice_panel_wide_ref.png` |
| 获得新猫提示 | 已覆盖控件级参考 crop，运行时需定制生成 | `ui/reference_crops/weapon_banner_*_ref.png` |
| 发猫 / 命中 / 爆炸 / 受击 / 结算音效 | 已覆盖 | `assets/audio/sfx/*.ogg` |

## 不属于图片素材

| 需求 | 建议实现 |
| --- | --- |
| 敌人受击闪白或闪烁 | Godot shader、`modulate` 或 tween |
| 花子无敌时间闪烁 | Godot shader、`modulate` 或 tween |
| 轻微震屏 | `Camera2D` 抖动 |
| 打击停顿 | 短暂停帧或时间缩放 |
| 猫弹数量上限 | 游戏逻辑 |
| 更像真实猫叫 / 牛叫的拟声音效 | 当前音效可用于正常可用版本；如要更动物化，需要额外制作或寻找 CC0 音源，并更新 `assets/audio/LICENSES.md` |

旧版方块地图、旧非 8 向图集、旧 UI 单图和调试预览已从基准目录清理掉。当前主素材以上表为准。
