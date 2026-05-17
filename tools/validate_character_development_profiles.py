#!/usr/bin/env python3
"""Validate character development profiles used by story, art, and dialogue work."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PROFILES = ROOT / "data" / "character_development_profiles.json"
VOICE_PROFILES = ROOT / "data" / "character_voice_profiles.json"
VISUAL_MODELS = ROOT / "data" / "character_visual_models.json"

REQUIRED_TOP_FIELDS = [
    "schema_version",
    "generated_from",
    "global_development_rules",
    "characters",
]
REQUIRED_CHARACTER_FIELDS = [
    "display_name",
    "production_role",
    "personality_core",
    "motivation",
    "fear_or_wound",
    "conflict_style",
    "growth_direction",
    "relationship_hooks",
    "dialogue_guardrails",
    "scene_usage",
    "source_evidence",
]


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def repo_path(path_text: str) -> Path:
    clean_path = path_text.split("#", 1)[0]
    if clean_path.startswith("res://"):
        clean_path = clean_path.removeprefix("res://")
    return ROOT / clean_path


def non_empty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def require_string(value: Any, label: str, failures: list[str]) -> None:
    if not non_empty_string(value):
        failures.append(f"{label} must be a non-empty string")


def require_string_list(value: Any, label: str, failures: list[str], *, min_count: int = 1) -> None:
    if not isinstance(value, list) or len(value) < min_count:
        failures.append(f"{label} must be a list with at least {min_count} item(s)")
        return
    for index, item in enumerate(value):
        if not non_empty_string(item):
            failures.append(f"{label}[{index}] must be a non-empty string")


def validate_source_paths(paths: Any, label: str, failures: list[str]) -> None:
    require_string_list(paths, label, failures)
    if not isinstance(paths, list):
        return
    for item in paths:
        if non_empty_string(item) and not repo_path(item).exists():
            failures.append(f"{label} references missing source: {item}")


def validate_relationship_hooks(value: Any, label: str, failures: list[str]) -> None:
    if not isinstance(value, dict) or not value:
        failures.append(f"{label} must be a non-empty object")
        return
    for hook_id, hook_text in value.items():
        if not non_empty_string(hook_id):
            failures.append(f"{label} contains an empty relationship key")
        require_string(hook_text, f"{label}.{hook_id}", failures)


def validate_character(character_id: str, data: Any, voice_ids: set[str], failures: list[str]) -> None:
    if not isinstance(data, dict):
        failures.append(f"characters.{character_id} must be an object")
        return
    if character_id not in voice_ids:
        failures.append(f"characters.{character_id} is missing from character_voice_profiles.json")

    for field in REQUIRED_CHARACTER_FIELDS:
        if field not in data:
            failures.append(f"characters.{character_id}.{field} is required")

    prefix = f"characters.{character_id}"
    for field in [
        "display_name",
        "production_role",
        "motivation",
        "fear_or_wound",
        "conflict_style",
        "growth_direction",
    ]:
        require_string(data.get(field), f"{prefix}.{field}", failures)
    require_string_list(data.get("personality_core"), f"{prefix}.personality_core", failures, min_count=3)
    require_string_list(data.get("dialogue_guardrails"), f"{prefix}.dialogue_guardrails", failures, min_count=3)
    require_string_list(data.get("scene_usage"), f"{prefix}.scene_usage", failures, min_count=3)
    validate_relationship_hooks(data.get("relationship_hooks"), f"{prefix}.relationship_hooks", failures)
    validate_source_paths(data.get("source_evidence"), f"{prefix}.source_evidence", failures)


def validate_profiles(path: Path) -> list[str]:
    failures: list[str] = []
    data = load_json(path)
    if not isinstance(data, dict):
        return [f"{path} must contain a JSON object"]

    for field in REQUIRED_TOP_FIELDS:
        if field not in data:
            failures.append(f"{field} is required")
    if data.get("schema_version") != 1:
        failures.append("schema_version must be 1")
    validate_source_paths(data.get("generated_from"), "generated_from", failures)

    global_rules = data.get("global_development_rules")
    if not isinstance(global_rules, dict):
        failures.append("global_development_rules must be an object")
    else:
        require_string(global_rules.get("purpose"), "global_development_rules.purpose", failures)
        require_string_list(global_rules.get("usage_order"), "global_development_rules.usage_order", failures, min_count=3)
        require_string_list(global_rules.get("forbidden"), "global_development_rules.forbidden", failures, min_count=3)

    characters = data.get("characters")
    if not isinstance(characters, dict) or not characters:
        failures.append("characters must be a non-empty object")
        return failures

    voice_data = load_json(VOICE_PROFILES)
    voice_ids = set(voice_data.get("characters", {}).keys()) if isinstance(voice_data, dict) else set()
    visual_data = load_json(VISUAL_MODELS)
    visual_ids = set(visual_data.get("characters", {}).keys()) if isinstance(visual_data, dict) else set()

    missing_development_ids = sorted(voice_ids - set(characters.keys()))
    for character_id in missing_development_ids:
        failures.append(f"character_voice_profiles.json has no development profile for {character_id}")

    for character_id, character_data in characters.items():
        if not non_empty_string(character_id):
            failures.append("character IDs must be non-empty strings")
            continue
        validate_character(str(character_id), character_data, voice_ids, failures)
        if character_id in visual_ids:
            visual_name = visual_data["characters"][character_id].get("display_name")
            dev_name = character_data.get("display_name") if isinstance(character_data, dict) else None
            if visual_name != dev_name:
                failures.append(
                    f"characters.{character_id}.display_name must match character_visual_models.json"
                )
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("profiles", nargs="?", type=Path, default=DEFAULT_PROFILES)
    args = parser.parse_args()

    failures = validate_profiles(args.profiles)
    if failures:
        for failure in failures:
            print(f"character-development-profiles: {failure}")
        return 1
    print(f"character-development-profiles: OK {args.profiles}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
