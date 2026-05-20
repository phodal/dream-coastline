#!/usr/bin/env python3
"""Validate Dialogic timeline coverage against story scene JSON."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STORY_DIR = ROOT / "data" / "story_scenes"
TIMELINE_DIR = ROOT / "dialogic" / "timelines"
PROJECT_FILE = ROOT / "project.godot"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def expected_timeline_paths() -> set[Path]:
    expected: set[Path] = set()
    for story_path in sorted(STORY_DIR.glob("*.json")):
        scene = load_json(story_path)
        scene_id = scene.get("id", story_path.stem)
        for location_id, location in scene.get("locations", {}).items():
            for item_id in location.get("items", {}):
                expected.add(TIMELINE_DIR / scene_id / f"{location_id}_{item_id}.dtl")
            for choice_id in location.get("choices", {}):
                expected.add(TIMELINE_DIR / scene_id / f"{location_id}_choice_{choice_id}.dtl")
            for action_type, collection_name in [
                ("glyph", "glyph_actions"),
                ("build", "build_actions"),
                ("encounter", "encounters"),
                ("combo", "combos"),
            ]:
                for action_id in location.get(collection_name, {}):
                    expected.add(TIMELINE_DIR / scene_id / f"{location_id}_{action_type}_{action_id}.dtl")
            combat = location.get("combat", {})
            if isinstance(combat, dict) and combat:
                expected.add(TIMELINE_DIR / scene_id / f"{location_id}_combat_identify.dtl")
                expected.add(TIMELINE_DIR / scene_id / f"{location_id}_combat_resolve.dtl")
                for spell_id in combat.get("spells", {}):
                    expected.add(TIMELINE_DIR / scene_id / f"{location_id}_combat_spell_{spell_id}.dtl")
    return expected


def project_registered_timeline_paths() -> set[Path]:
    content = PROJECT_FILE.read_text(encoding="utf-8")
    marker = "directories/dtl_directory={"
    start = content.find(marker)
    if start == -1:
        return set()
    end = content.find("\n}", start)
    if end == -1:
        return set()
    registered: set[Path] = set()
    for line in content[start:end].splitlines()[1:]:
        if '": "' not in line:
            continue
        raw_value = line.split('": "', 1)[1].rstrip(",").strip().strip('"')
        if raw_value.startswith("res://"):
            registered.add(ROOT / raw_value.removeprefix("res://"))
    return registered


def main() -> int:
    expected = expected_timeline_paths()
    actual = set(TIMELINE_DIR.glob("*/*.dtl"))
    registered = project_registered_timeline_paths()
    missing = sorted(expected - actual)
    stale = sorted(actual - expected)
    registry_missing = sorted(expected - registered)
    registry_stale = sorted(registered - expected)

    failures: list[str] = []
    failures.extend(f"missing timeline: {path.relative_to(ROOT)}" for path in missing)
    failures.extend(f"stale timeline: {path.relative_to(ROOT)}" for path in stale)
    failures.extend(f"missing project registry entry: {path.relative_to(ROOT)}" for path in registry_missing)
    failures.extend(f"stale project registry entry: {path.relative_to(ROOT)}" for path in registry_stale)

    if failures:
        for failure in failures:
            print(f"dialogic-timelines: {failure}")
        return 1

    print(
        "dialogic-timelines status=PASS expected=%d actual=%d registered=%d"
        % (len(expected), len(actual), len(registered))
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
