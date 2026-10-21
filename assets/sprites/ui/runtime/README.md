# 執行時 UI 資產目錄

這裡放 Godot 程式碼實際引用的 UI 資產。

當前目錄先保留為目標目錄；如果實現需要 HUD、升級卡、結算面板、暫停面板或提示橫幅，必須先從 `../reference_crops/` 生成適合執行尺寸的 PNG、`.9.png` 或 `.tres` 放到這裡，再由程式碼引用。

不要把 `../ui_assets_painted.png` 或 `../reference_crops/*_ref.png` 直接當作最終控制元件接入，除非 spec 或用戶明確把某個 crop 提升為執行時資產。
