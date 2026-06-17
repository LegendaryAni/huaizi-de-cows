# Godot 素材说明

这版主素材已按参考图重做为高对比暗色漫画街机风。固定户外大地图是全图正常亮度的清晰连续手绘底图，不预烘焙暗角或角色中心光照，不再使用方块 tile 拼接；泥地、草地、深浅地块、草丛、石头、土堆、落叶、围栏、树墙、石墙、水面等环境层由 Godot 叠加。

## 主文件

| 文件 | 用途 |
| --- | --- |
| `full_outdoor_map_painted_4096x2305.png` | 固定户外清晰底图，直接作为背景使用，全图正常亮度，不内置隔挡/环境装饰/暗角 |
| `environment_assets_painted.png` | 地图素材表：泥地、草地、深浅地块、草丛、石头、小土堆、落叶、围栏、树墙、石墙、水面边界 |
| `ui_assets_painted.png` | UI 与图标风格参考素材表：血量条、升级三选一卡片、胜利/失败结算页、暂停界面、4 个升级图标、HUD 武器图标、波次/新猫提示。控件级参考 crop 和运行时资产规则见 `ui/README.md` |
| `ui/` | UI 控件拆分目录：`reference_crops/` 存放从总参考图裁出的控件级视觉锚点，`runtime/` 存放 Godot 代码实际引用的运行时 UI 资产，`ui_asset_manifest.json` 记录映射关系 |
| `combat_assets_painted.png` | 战斗风格参考素材表：花子、三种猫弹、四种奶牛敌人、命中/爆炸/经验/死亡烟尘/碎屑/粒子。角色/猫/奶牛优先使用 8 向图集；命中、爆炸、粒子等 VFX 需要按实际效果重新生成 |
| `huazi_8dir_192x192.png` | 花子 8 向待机 / 行走图集 |
| `cow_normal_8dir_256x192.png` | 普通奶牛 8 向行走图集，使用校正后的普通荷斯坦奶牛源图 |
| `cow_calf_8dir_192x144.png` | 疯跑小牛 8 向奔跑图集 |
| `cow_tank_8dir_320x224.png` | 厚皮大奶牛 8 向行走图集，使用校正后的厚重 8 向源图 |
| `cow_ranged_8dir_288x192.png` | 吐奶远程牛 8 向行走图集，不包含奶滴弹 |
| `orange_cat_projectile_8dir_192x128.png` | 橘猫整猫直线扑击 8 向飞行动画 |
| `black_cat_projectile_8dir_192x128.png` | 黑猫整猫范围扑击 8 向飞行动画 |
| `cow_cat_spin_8dir_192x128.png` | 奶牛猫回旋扫场弹 8 向动画 |
| `milk_drop_8dir_192x128.png` | 奶滴远程弹 8 向飞行动画 |
| `painted_regen_manifest.json` | 新版素材总清单 |
| `directional_asset_manifest.json` | 8 向补充素材清单 |
| `cow_ranged_muzzle_offsets.json` | 吐奶远程牛各方向的建议奶滴生成偏移 |
| `full_outdoor_map_manifest.json` | 新版完整地图尺寸、出生点、刷怪区和视觉边界 |

## 音频文件

音频素材放在 `assets/audio/sfx/`，授权和来源记录见 `assets/audio/LICENSES.md`。音频不是可选项；发猫、命中、黑猫爆炸、敌人死亡、玩家受击、XP、升级、升级选择、波次开始、武器解锁、胜利和失败都应接入对应 SFX。

## Godot 接入

1. 把 `assets/sprites/` 放到 Godot 项目内。
2. 完整地图用 `full_outdoor_map_painted_4096x2305.png` 创建 `Sprite2D` 或背景层，环境装饰和隔挡碰撞再由 Godot 叠加。
3. `environment_assets_painted.png` 可按需要切成 `AtlasTexture`、`NinePatchRect`、`TextureRect` 或导入到 `SpriteFrames`。
4. `ui_assets_painted.png` 和 `combat_assets_painted.png` 中的 UI、命中、爆炸、粒子等非角色元素只做风格参考。UI 控件先使用 `ui/reference_crops/` 锁定参考区域，再生成适合当前控件尺寸、缩放方式、透明边距和动效节奏的运行时 PNG/WebP/Atlas/NinePatch/粒子贴图，并记录生成资产、参考来源和用途。
5. 不得直接把原 UI 素材或原爆炸/粒子素材文件切片后当作最终 HUD、弹窗、按钮、命中特效或爆炸特效；否则容易出现拉伸、裁切、漏边、层级错乱或语义错误。
6. 只记录风格参考路径不够。生成 UI/VFX 前必须裁出或说明参考区域，拆解手绘描边、做旧材质、木牌/皮革/金属边框、暖色高对比、猫头像徽章、装饰性边角、战斗碎屑/烟尘节奏等特征；生成后必须保存参考 crop 与最终运行截图的并排对照和差异说明。
7. HUD 外框、血量条、经验条、技能槽、升级卡片、升级图标、按钮、提示、暂停界面和结算界面等运行时 UI 控件必须逐项验收；每一次对比都要记录参考 crop、运行截图 crop、并排对照图、相似度、完成度和差异说明。所有 UI 控件的风格相似度和资产完成度都要达到 0.90 以上，任何单项不达标或缺少记录都必须退回重做。
8. 生成 UI 强烈建议优先使用图像生成、局部重绘、NinePatch、AtlasTexture、TextureRect、脚本化位图生成或其他合适流程，再把生成结果调整为游戏需要的尺寸、透明边距、格式和导入方式；不要只依赖 Godot 原生 Control、ColorRect、StyleBox、Label 或代码绘制来模拟参考图效果，不能直接切 `ui_assets_painted.png` 原图当最终控件。
9. Godot 代码不要引用 `.import` 文件。核心 UI 应引用 `res://assets/sprites/ui/runtime/` 下的运行时资产，或引用由这些资产建出的 `.tres`。如果 `runtime/` 下没有对应资产，先补资产，不允许退回纯代码画框。
10. UI 完成前必须保存并亲自查看关键状态截图和运行中连续帧，检查控件、文字、图标、条形填充和点击区域没有重叠、裁切、遮挡、跳位或被战斗特效压住的问题；动态帧确认正常后才能标记完成。
11. UI 默认使用中文文案，升级、波次、结算和按钮文字不要混入英文模板，除非任务明确要求。
12. 角色、敌人和方向敏感弹体优先使用 `*_8dir_*.spriteframes.tres`。
13. 8 向图集行顺序固定为 `e / se / s / sw / w / nw / n / ne`，每行 4 帧。
14. 动画命名示例：花子 `walk_e`、`walk_se`、`idle_s`；牛 `walk_e` 或 `run_e`；弹体 `fly_e`。
15. 吐奶远程牛只用 `cow_ranged_8dir_288x192.png` 播牛本体；奶滴用 `milk_drop_8dir_192x128.png` 单独生成，发射点偏移见 `cow_ranged_muzzle_offsets.json`。
16. 普通牛和厚皮牛使用单独校正后的完整 8 向源图，运行时图集已稳定每帧 cell 锚点；小牛、吐奶远程牛仍是侧视源图补足八向：左右用镜像，斜向/上下用有限旋转。
17. 这批图是手绘描边风，导入过滤建议先用 `Linear`；如果项目整体做像素缩放，再改为 `Nearest`。
18. 地图碰撞边界建议用代码/碰撞形状沿画面边缘配置，不依赖环境装饰图本身。
19. 音频新增或复制后，先运行 Godot editor headless 导入，再检查运行时加载数量和关键音效事件。

## 预览

打开 `preview.html` 可以看新版素材总览。

旧版方块地图、旧非 8 向图集、旧 UI 单图和调试预览已从基准目录清理掉。当前开发只按上面的主文件接入。

生成源图集中放在 `assets/source/`，不是 Godot 运行时优先接入目录。
