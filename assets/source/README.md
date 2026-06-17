# 源图说明

这里放生成和再打包素材时使用的源图，不是 Godot 运行时优先接入的素材。

游戏开发优先使用 `assets/sprites/` 下的 PNG、`.spriteframes.tres` 和 manifest。

`cow_normal_8dir_256x192_redesign.png` 是普通奶牛 8 向图集的校正源图，`tools/build_directional_supplements.py` 会用它生成运行时的 `assets/sprites/cow_normal_8dir_256x192.png`。

`cow_tank_8dir_320x224_redesign.png` 是厚皮大奶牛 8 向图集的校正源图，由 `tools/build_directional_supplements.py` 基于普通奶牛校正源图派生成更厚重的体型、轮廓和暗部，避免使用单张侧视图旋转造成姿态、朝向和阴影异常。
