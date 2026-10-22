#!/usr/bin/env python3
"""唯讀統計 SF-16 T16 真實成長報告；不影響 Godot 規格與遊玩策略。

Usage: python tools/analyze_sf16_growth.py <reports/scifi-tests/<growth-run>>
       python tools/analyze_sf16_growth.py <growth-run> --require-pass
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import statistics
import sys

SEEDS = (17, 41, 73)
TARGET_MEDIAN = (3, 5)

REQUIRED_ASSERTIONS = {
    "growth.time_scale_one",
    "growth.standard_physics_tick",
    "growth.no_fixture_calls",
    "growth.win_within_five",
}



def read_json(path: Path) -> dict | None:
    if not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8-sig"))


def iter_jsonl(path: Path):
    if not path.is_file():
        return
    with path.open(encoding="utf-8") as handle:
        for index, line in enumerate(handle, start=1):
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                # An in-progress JSONL stream may contain a partial final line.
                if line.endswith("\n"):
                    raise ValueError(f"Corrupt completed JSONL line {path}:{index}")


def inspect_seed(folder: Path, seed: int) -> dict:
    base = folder / f"growth-seed-{seed}.json"
    invocation = read_json(folder / f"growth-seed-{seed}.invocation.json")
    report = read_json(base)
    live = read_json(folder / f"growth-seed-{seed}.json.live.json")
    hits = Counter()
    hits_by_source: Counter = Counter()
    repairs = 0
    boss_deaths = 0
    events = 0
    minimum_hp: float | None = None
    for item in iter_jsonl(folder / f"growth-seed-{seed}.json.events.jsonl"):
        event = item.get("event", {})
        if not isinstance(event, dict):
            continue
        events += 1
        if event.get("event") == "hit" and event.get("entity_id") == "player":
            hits["count"] += 1
            hits["raw_damage"] += float(event.get("amount", 0))
            hits["absorbed"] += float(event.get("absorbed", 0))
            hits_by_source[str(event.get("source_id", "unknown"))] += 1
        if event.get("event") == "skill" and event.get("key") == "repair":
            repairs += 1
        if event.get("event") == "death" and event.get("kind") == "boss":
            boss_deaths += 1
    runs = []
    for item in iter_jsonl(folder / f"growth-seed-{seed}.json.snapshots.jsonl"):
        snap = item.get("snapshot", {})
        if not isinstance(snap, dict):
            continue
        player = snap.get("player", {})
        if isinstance(player, dict) and isinstance(player.get("hp"), (int, float)):
            hp = float(player["hp"])
            minimum_hp = hp if minimum_hp is None else min(minimum_hp, hp)
        progress = snap.get("progress", {})
        if isinstance(progress, dict):
            observed = progress.get("runs", [])
            if isinstance(observed, list) and len(observed) >= len(runs):
                runs = observed
    first_win = next((i + 1 for i, run in enumerate(runs) if run.get("victory") is True), None)
    assertion_ids = {
        str(a.get("id")) for a in (report or {}).get("assertions", [])
        if isinstance(a, dict) and a.get("passed") is True
    }
    complete_evidence = (
        report is not None
        and report.get("scenario") == "growth"
        and report.get("status") == "logic_passed"
        and report.get("growth_exit_reason") == "first_win"
        and report.get("fixture_calls") == 0
        and report.get("failed") == 0
        and REQUIRED_ASSERTIONS.issubset(assertion_ids)
        and any(key.startswith("growth.natural_settlement_cause") for key in assertion_ids)
        and any(key.startswith("growth.settlement_saved") for key in assertion_ids)
        and boss_deaths >= 1
        and events > 0
        and (folder / f"growth-seed-{seed}.json.inputs.jsonl").is_file()
        and (folder / f"growth-seed-{seed}.json.inputs.jsonl").stat().st_size > 0
        and len(runs) >= 1
    )

    if report is not None:
        notes = report.get("notes", [])
        for note in notes if isinstance(notes, list) else []:
            if str(note).startswith("first_win_run="):
                stated = int(str(note).partition("=")[2])
                if first_win is not None and stated != first_win:
                    raise ValueError(f"Seed {seed}: notes contradict snapshot win history")
                first_win = stated or None
    return {
        "seed": seed,
        "invocation_present": invocation is not None,
        "completed_report": report is not None,
        "complete_evidence": complete_evidence,
        "report_failed_assertions": report.get("failed", None) if report else None,
        "source_hashes": invocation.get("source_hashes", {}) if invocation else {},
        "input_seed_matches": invocation is not None and invocation.get("seed") == seed,
        "game_runs": [
            {"win": bool(run.get("victory")), "seconds": run.get("time")}
            for run in runs
        ],
        "first_win_run": first_win,
        "live_game_time": live.get("time") if live else None,
        "live_hp": live.get("hp") if live else None,
        "minimum_observed_hp": minimum_hp,
        "player_hit_count": int(hits["count"]),
        "raw_contact_or_projectile_damage": float(hits["raw_damage"]),
        "shield_absorbed": float(hits["absorbed"]),
        "damage_sources": hits_by_source.most_common(8),
        "repair_activations": repairs,
        "boss_death_events": boss_deaths,
        "event_count": events,
    }


def analyze(folder: Path) -> dict:
    seeds = [inspect_seed(folder, seed) for seed in SEEDS]
    hashes = [json.dumps(row["source_hashes"], sort_keys=True) for row in seeds]
    wins = [row["first_win_run"] for row in seeds]
    # Never turn a partial diagnostic, or a run without complete reporting, into PASS.
    all_complete = all(row["complete_evidence"] for row in seeds)
    all_seeds_proven = all(row["input_seed_matches"] for row in seeds)
    same_sources = all_seeds_proven and len(set(hashes)) == 1 and bool(seeds[0]["source_hashes"])
    within_five = all(v is not None and 1 <= v <= 5 for v in wins)
    median = statistics.median(wins) if within_five else None
    passed = all_complete and all_seeds_proven and same_sources and within_five and TARGET_MEDIAN[0] <= median <= TARGET_MEDIAN[1]
    known_first_wins = [value for value in wins if value is not None]
    impossible_median = len([value for value in known_first_wins if value <= 2]) >= 2
    status = "PASS" if passed else "FAIL" if all(row["completed_report"] for row in seeds) or impossible_median else "INCOMPLETE"
    return {
        "report_dir": str(folder.resolve()),
        "status": status,
        "t16_compliant_full_matrix": passed,
        "all_reports_completed": all(row["completed_report"] for row in seeds),
        "all_required_evidence_verified": all_complete,
        "source_hashes_match": same_sources,
        "all_invocation_seeds_verified": all_seeds_proven,
        "first_win_median": median,
        "median_3_to_5_mathematically_impossible": impossible_median,
        "seeds": seeds,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report_dir", type=Path)
    parser.add_argument("--require-pass", action="store_true")
    args = parser.parse_args()
    if not args.report_dir.is_dir():
        parser.error("指定的成長報告資料夾不存在")
    result = analyze(args.report_dir)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return int(args.require_pass and not result["t16_compliant_full_matrix"])


if __name__ == "__main__":
    sys.exit(main())
