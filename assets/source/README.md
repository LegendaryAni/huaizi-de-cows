# 源圖說明

這裡放生成和再打包素材時使用的源圖，不是 Godot 執行時優先接入的素材。

遊戲開發優先使用 `assets/sprites/` 下的 PNG、`.spriteframes.tres` 和 manifest。

`cow_normal_8dir_256x192_redesign.png` 是普通奶牛 8 向圖集的校正源圖，`tools/build_directional_supplements.py` 會用它生成執行時的 `assets/sprites/cow_normal_8dir_256x192.png`。

`cow_tank_8dir_320x224_redesign.png` 是厚皮大奶牛 8 向圖集的校正源圖，由 `tools/build_directional_supplements.py` 基於普通奶牛校正源圖派生成更厚重的體型、輪廓和暗部，避免使用單張側檢視旋轉造成姿態、朝向和陰影異常。
