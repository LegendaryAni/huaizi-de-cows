from __future__ import annotations

from pathlib import Path
import shutil

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "sprites"
SOURCE = ROOT / "assets" / "source"
THEME = SPRITES / "legendaryani"
UI_SRC = SPRITES / "ui" / "runtime"
UI_DST = UI_SRC / "legendaryani"
VFX_SRC = SPRITES / "vfx" / "runtime"
VFX_DST = VFX_SRC / "legendaryani"


SPRITE_FILES = [
    "orange_cat_projectile_8dir_192x128.png",
    "black_cat_projectile_8dir_192x128.png",
    "cow_cat_spin_8dir_192x128.png",
    "cow_normal_8dir_256x192.png",
    "cow_calf_8dir_192x144.png",
    "cow_tank_8dir_320x224.png",
    "cow_ranged_8dir_288x192.png",
    "milk_drop_8dir_192x128.png",
]


def _rgba(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGBA"), dtype=np.float32)


def _save(arr: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA").save(path)


def _blend_by_luma(luma: np.ndarray, dark: tuple[int, int, int], light: tuple[int, int, int]) -> np.ndarray:
    t = np.clip((luma - 0.06) / 0.90, 0.0, 1.0) ** 0.82
    d = np.array(dark, dtype=np.float32)
    h = np.array(light, dtype=np.float32)
    return d + (h - d) * t[..., None]


def grade_storybook(src: Path, dst: Path, *, strength: float = 0.78) -> None:
    arr = _rgba(src)
    rgb = arr[..., :3] / 255.0
    alpha = arr[..., 3:4]
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
    spread = rgb.max(axis=2) - rgb.min(axis=2)

    neutral = spread < 0.10
    warm = (r > g * 1.04) & (r > b * 1.14) & ~neutral
    green = (g > r * 0.92) & (g > b * 1.08) & ~neutral
    cool = ~(neutral | warm | green)

    out = np.zeros_like(rgb) * 255.0
    neutral_color = _blend_by_luma(luma, (27, 54, 57), (248, 230, 190))
    warm_color = _blend_by_luma(luma, (88, 48, 44), (244, 173, 95))
    green_color = _blend_by_luma(luma, (35, 77, 72), (174, 205, 145))
    cool_color = _blend_by_luma(luma, (36, 71, 80), (129, 196, 187))
    out[neutral] = neutral_color[neutral]
    out[warm] = warm_color[warm]
    out[green] = green_color[green]
    out[cool] = cool_color[cool]

    original = arr[..., :3]
    out = out * strength + original * (1.0 - strength)
    dark_outline = luma < 0.16
    out[dark_outline] = out[dark_outline] * 0.74
    result = np.concatenate([out, alpha], axis=2)
    _save(result, dst)


def grade_map(src: Path, dst: Path) -> None:
    arr = _rgba(src)
    rgb = arr[..., :3] / 255.0
    alpha = arr[..., 3:4]
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
    chroma = rgb.max(axis=2) - rgb.min(axis=2)

    sage = _blend_by_luma(luma, (54, 85, 66), (191, 205, 143))
    earth = _blend_by_luma(luma, (83, 66, 49), (220, 176, 112))
    mix = np.clip((r - b + 0.12) * 1.6 + chroma * 0.35, 0.0, 1.0)[..., None]
    out = sage * (1.0 - mix) + earth * mix
    out = out * 0.82 + arr[..., :3] * 0.18
    result = np.concatenate([out, alpha], axis=2)
    image = Image.fromarray(np.clip(result, 0, 255).astype(np.uint8), "RGBA")
    image = ImageEnhance.Brightness(image).enhance(1.10)
    image = ImageEnhance.Color(image).enhance(0.94)
    image.save(dst)


def build_player() -> None:
    source_sheet = SPRITES / "huazi_8dir_192x192.png"
    pilot = SOURCE / "legendaryani_huazi_pilot.png"
    base = Image.open(pilot).convert("RGBA")
    if base.size != Image.open(source_sheet).size:
        raise RuntimeError(f"player pilot size mismatch: {base.size}")
    source_alpha = Image.open(source_sheet).convert("RGBA").getchannel("A")
    base.putalpha(source_alpha)
    base = ImageEnhance.Brightness(base).enhance(1.04)
    base = ImageEnhance.Color(base).enhance(1.08)
    base.save(THEME / "huazi_8dir_192x192.png")


def build_sprite_frames() -> None:
    names = ["huazi_8dir_192x192"] + [Path(name).stem for name in SPRITE_FILES]
    for name in names:
        src = SPRITES / f"{name}.spriteframes.tres"
        if not src.exists():
            continue
        text = src.read_text(encoding="utf-8")
        text = text.replace(
            f"res://assets/sprites/{name}.png",
            f"res://assets/sprites/legendaryani/{name}.png",
        )
        (THEME / f"{name}.spriteframes.tres").write_text(text, encoding="utf-8", newline="\n")


def build_ui() -> None:
    for src in UI_SRC.glob("*.png"):
        grade_storybook(src, UI_DST / src.name, strength=0.86)


def build_vfx() -> None:
    for src in VFX_SRC.glob("*.png"):
        grade_storybook(src, VFX_DST / src.name, strength=0.70)


def main() -> None:
    THEME.mkdir(parents=True, exist_ok=True)
    UI_DST.mkdir(parents=True, exist_ok=True)
    VFX_DST.mkdir(parents=True, exist_ok=True)

    build_player()
    for name in SPRITE_FILES:
        grade_storybook(SPRITES / name, THEME / name)
    grade_storybook(SPRITES / "environment_assets_painted.png", THEME / "environment_assets_painted.png", strength=0.76)
    grade_map(SPRITES / "full_outdoor_map_painted_4096x2305.png", THEME / "full_outdoor_map_painted_4096x2305.png")
    build_sprite_frames()
    build_ui()
    build_vfx()

    shutil.copy2(SPRITES / "cow_ranged_muzzle_offsets.json", THEME / "cow_ranged_muzzle_offsets.json")
    print(f"Built LegendaryAni art theme under {THEME}")
    print(f"Built themed UI under {UI_DST}")
    print(f"Built themed VFX under {VFX_DST}")


if __name__ == "__main__":
    main()
