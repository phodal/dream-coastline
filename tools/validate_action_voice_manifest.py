#!/usr/bin/env python3
"""Validate per-action voice-line manifests against playable story records."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STORY_DIR = ROOT / "data" / "story_scenes"
MANIFEST_DIR = ROOT / "data" / "action_voice_lines"
VOICE_PROFILES = ROOT / "data" / "character_voice_profiles.json"

LINE_ID_RE = re.compile(r"^AVL-\d{2}-\d{3}$")
VALID_ACTION_TYPES = {
    "inspect",
    "choice",
    "glyph",
    "build",
    "encounter",
    "combo",
    "combat_identify",
    "combat_spell",
    "combat_resolve",
}
VALID_STATUSES = {"planned", "generated", "skipped"}
ACTION_COLLECTIONS = [
    ("inspect", "items"),
    ("choice", "choices"),
    ("glyph", "glyph_actions"),
    ("build", "build_actions"),
    ("encounter", "encounters"),
    ("combo", "combos"),
]


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def repo_path(path_text: str) -> Path:
    return ROOT / path_text.split("#", 1)[0]


def is_non_empty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def require_string(data: dict[str, Any], field: str, label: str, failures: list[str]) -> None:
    if not is_non_empty_string(data.get(field)):
        failures.append(f"{label}.{field} must be a non-empty string")


def require_list(value: Any, label: str, failures: list[str]) -> None:
    if not isinstance(value, list):
        failures.append(f"{label} must be a list")


def require_source_paths(value: Any, label: str, failures: list[str]) -> None:
    if not isinstance(value, list) or not value:
        failures.append(f"{label} must be a non-empty list")
        return
    for index, item in enumerate(value):
        if not is_non_empty_string(item):
            failures.append(f"{label}[{index}] must be a non-empty string")
        elif not repo_path(item).exists():
            failures.append(f"{label}[{index}] references missing source: {item}")


def expected_actions(scene: dict[str, Any]) -> set[tuple[str, str, str]]:
    expected: set[tuple[str, str, str]] = set()
    for location_id, location in scene.get("locations", {}).items():
        if not isinstance(location, dict):
            continue
        for action_type, collection_name in ACTION_COLLECTIONS:
            collection = location.get(collection_name, {})
            if isinstance(collection, dict):
                for record_id in collection:
                    expected.add((str(location_id), action_type, str(record_id)))
        combat = location.get("combat", {})
        if isinstance(combat, dict) and combat:
            expected.add((str(location_id), "combat_identify", "identify"))
            expected.add((str(location_id), "combat_resolve", "resolve"))
            spells = combat.get("spells", {})
            if isinstance(spells, dict):
                for spell_id in spells:
                    expected.add((str(location_id), "combat_spell", str(spell_id)))
    return expected


def validate_line(
    line: Any,
    index: int,
    scene_id: str,
    character_ids: set[str],
    seen_line_ids: set[str],
    label: str,
    failures: list[str],
) -> None:
    line_label = f"{label}.playback_queue[{index}]"
    if not isinstance(line, dict):
        failures.append(f"{line_label} must be an object")
        return
    for field in ["line_id", "speaker_id", "speaker_name", "text", "delivery", "status", "target_path"]:
        require_string(line, field, line_label, failures)

    line_id = str(line.get("line_id", ""))
    if is_non_empty_string(line_id):
        if not LINE_ID_RE.match(line_id):
            failures.append(f"{line_label}.line_id has invalid format: {line_id}")
        if line_id in seen_line_ids:
            failures.append(f"{line_label}.line_id duplicates {line_id}")
        seen_line_ids.add(line_id)

    speaker_id = str(line.get("speaker_id", ""))
    if speaker_id != "narrator":
        if speaker_id not in character_ids:
            failures.append(f"{line_label}.speaker_id is not in character_voice_profiles.json: {speaker_id}")
        expected_ref = f"data/character_voice_profiles.json#characters.{speaker_id}"
        if line.get("voice_profile_ref") != expected_ref:
            failures.append(f"{line_label}.voice_profile_ref must be {expected_ref}")

    if line.get("status") not in VALID_STATUSES:
        failures.append(f"{line_label}.status must be one of {sorted(VALID_STATUSES)}")
    target_path = str(line.get("target_path", ""))
    expected_prefix = f"assets/audio/generated/action_voices/{scene_id}/"
    if is_non_empty_string(target_path):
        if not target_path.startswith(expected_prefix):
            failures.append(f"{line_label}.target_path must start with {expected_prefix}")
        if not target_path.endswith(".mp3"):
            failures.append(f"{line_label}.target_path must end with .mp3")
        if line.get("status") == "generated" and not (ROOT / target_path).exists():
            failures.append(f"{line_label}.target_path is missing for generated line: {target_path}")


def validate_manifest(path: Path, character_ids: set[str]) -> list[str]:
    failures: list[str] = []
    manifest = load_json(path)
    if not isinstance(manifest, dict):
        return [f"{path} must contain a JSON object"]
    scene_id = str(manifest.get("scene_id", ""))
    story_path = STORY_DIR / f"{scene_id}.json"
    if manifest.get("schema_version") != 1:
        failures.append("schema_version must be 1")
    if not story_path.exists():
        failures.append(f"missing story scene for {scene_id}")
        return failures
    if manifest.get("source") != f"data/story_scenes/{scene_id}.json":
        failures.append(f"source must be data/story_scenes/{scene_id}.json")
    require_source_paths(manifest.get("generated_from"), "generated_from", failures)

    scene = load_json(story_path)
    expected = expected_actions(scene)
    seen: set[tuple[str, str, str]] = set()
    seen_action_ids: set[str] = set()
    seen_line_ids: set[str] = set()
    actions = manifest.get("actions")
    if not isinstance(actions, list):
        failures.append("actions must be a list")
        return failures
    for index, action in enumerate(actions):
        label = f"actions[{index}]"
        if not isinstance(action, dict):
            failures.append(f"{label} must be an object")
            continue
        for field in ["action_id", "scene_id", "location_id", "action_type", "record_id", "display_name"]:
            require_string(action, field, label, failures)
        action_id = str(action.get("action_id", ""))
        if action_id in seen_action_ids:
            failures.append(f"{label}.action_id duplicates {action_id}")
        seen_action_ids.add(action_id)
        if action.get("scene_id") != scene_id:
            failures.append(f"{label}.scene_id must be {scene_id}")
        action_type = str(action.get("action_type", ""))
        if action_type not in VALID_ACTION_TYPES:
            failures.append(f"{label}.action_type must be one of {sorted(VALID_ACTION_TYPES)}")
        key = (str(action.get("location_id", "")), action_type, str(action.get("record_id", "")))
        seen.add(key)
        require_list(action.get("requires"), f"{label}.requires", failures)
        require_list(action.get("sets_flags"), f"{label}.sets_flags", failures)
        require_source_paths(action.get("source_evidence"), f"{label}.source_evidence", failures)
        queue = action.get("playback_queue")
        if not isinstance(queue, list) or not queue:
            failures.append(f"{label}.playback_queue must be a non-empty list")
            continue
        for line_index, line in enumerate(queue):
            validate_line(line, line_index, scene_id, character_ids, seen_line_ids, label, failures)

    for missing in sorted(expected - seen):
        failures.append("missing action voice coverage: %s/%s/%s" % missing)
    for stale in sorted(seen - expected):
        failures.append("stale action voice coverage: %s/%s/%s" % stale)
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    args = parser.parse_args()

    profiles = load_json(VOICE_PROFILES)
    character_ids = set(profiles.get("characters", {}).keys())
    paths = args.paths or sorted(MANIFEST_DIR.glob("*.json"))
    failures: list[str] = []
    for path in paths:
        manifest_path = path if path.is_absolute() else ROOT / path
        for failure in validate_manifest(manifest_path, character_ids):
            failures.append(f"{manifest_path.relative_to(ROOT)}: {failure}")
    if failures:
        for failure in failures:
            print(f"action-voice-lines: {failure}")
        return 1
    print(f"action-voice-lines: OK {len(paths)} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
