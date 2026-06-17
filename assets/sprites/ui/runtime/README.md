# 运行时 UI 资产目录

这里放 Godot 代码实际引用的 UI 资产。

当前目录先保留为目标目录；如果实现需要 HUD、升级卡、结算面板、暂停面板或提示横幅，必须先从 `../reference_crops/` 生成适合运行尺寸的 PNG、`.9.png` 或 `.tres` 放到这里，再由代码引用。

不要把 `../ui_assets_painted.png` 或 `../reference_crops/*_ref.png` 直接当作最终控件接入，除非 spec 或用户明确把某个 crop 提升为运行时资产。
