#!/usr/bin/env python3
"""驗證《傳奇倖存者》GitHub 原始碼包含所有宣告的 runtime 資源。

不會載入、修改、刪除使用者存檔，亦不會建立或覆寫遊戲資產。
需要 Python 標準函式庫與 Git；Godot 載入和回歸測試須另外執行。
"""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets/audio/scifi/manifest.json"
SCANNED_SOURCE_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".json"}
RUNTIME_SUFFIXES = {".wav", ".ogg", ".png", ".jpg", ".jpeg", ".tres", ".json"}
RUNTIME_FOLDERS = (
    "assets/audio/scifi/",
    "assets/sprites/legendaryani/",
    "assets/sprites/ui/runtime/legendaryani/",
    "assets/sprites/vfx/runtime/legendaryani/",
)
SOURCE_ITEMS = (
    "assets/source/legendaryani_huazi_pilot.png",
    "tools/build_legendaryani_art.py",
)
errors: list[str] = []


def expected(path: str, tracked: set[str]) -> None:
    item = ROOT / path
    if not item.is_file():
        errors.append("找不到資產：" + path)
    elif path not in tracked:
        errors.append("檔案存在但未納入 Git：" + path)


def main() -> int:
    result = subprocess.run(
        ["git", "-C", str(ROOT), "ls-files", "-z"],
        capture_output=True,
        check=True,
    )
    tracked = set(filter(None, result.stdout.decode("utf-8").split("\x00")))
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    audio_files = data["files"]
    if len(audio_files) != 32:
        errors.append(f"音訊清單不是 32 個檔案：{len(audio_files)}")
    for filename, declared_hash in audio_files.items():
        path = "assets/audio/scifi/" + filename
        expected(path, tracked)
        target = ROOT / path
        if target.is_file():
            digest = hashlib.sha256(target.read_bytes()).hexdigest()
            if digest.lower() != declared_hash.lower():
                errors.append(f"音訊雜湊不符：{path}")
            if target.suffix.lower() == ".wav" and target.read_bytes()[:4] != b"RIFF":
                errors.append(f"無效 WAV 檔頭：{path}")
            if target.suffix.lower() == ".ogg" and target.read_bytes()[:4] != b"OggS":
                errors.append(f"無效 Ogg 檔頭：{path}")
    expected("assets/audio/scifi/manifest.json", tracked)
    for path in SOURCE_ITEMS:
        expected(path, tracked)
    # 遊戲所有純文字資源中的直接引用。避免把動態字串格式 %s 當成檔名。
    refs: set[str] = set()
    pattern = re.compile(r"res://assets/[A-Za-z0-9_./%-]+?\.(?:wav|ogg|png|jpg|jpeg|tres|json)\b")
    for path in tracked:
        item = ROOT / path
        if item.suffix.lower() not in SCANNED_SOURCE_SUFFIXES or not item.is_file():
            continue
        try:
            content = item.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for candidate in pattern.findall(content):
            if "%" not in candidate:
                refs.add(candidate.removeprefix("res://"))
    for path in sorted(refs):
        expected(path, tracked)
    # 包括未在固定字串中直寫、而是 runtime 動態使用的主題素材。
    theme_paths: set[str] = set()
    for folder in RUNTIME_FOLDERS[1:]:
        home = ROOT / folder
        if not home.is_dir():
            errors.append("缺少主題目錄：" + folder)
            continue
        for item in home.rglob("*"):
            if item.is_file() and item.suffix.lower() in RUNTIME_SUFFIXES:
                path = item.relative_to(ROOT).as_posix()
                theme_paths.add(path)
                expected(path, tracked)
        if not any(name.startswith(folder) and (name.endswith(".png") or name.endswith(".tres")) for name in tracked):
            errors.append("Git 未追蹤任何主題素材：" + folder)
    if errors:
        print(f"資源完整性失敗：{len(errors)} 個問題")
        for error in errors:
            print(" - " + error)
        return 1
    print(
        f"資源完整性通過：32 個音訊雜湊、{len(refs)} 條"
        f" 靜態素材引用、{len(theme_paths)} 個主題素材、原始生成來源與程式。"
    )
    print("此檢查不取代 Godot 載入、實際遊玩或獨立視覺審查。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
