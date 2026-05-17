#!/usr/bin/env python3
"""Validate main character visual model contracts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MODELS = ROOT / "data" / "character_visual_models.json"
VOICE_PROFILES = ROOT / "data" / "character_voice_profiles.json"

REQUIRED_TOP_FIELDS = [
    "schema_version",
    "generated_from",
    "global_art_rules",
    "required_role_slots",
    "characters",
]
REQUIRED_CHARACTER_FIELDS = [
    "display_name",
    "role_slot",
    "stable_id",
    "narrative_function",
    "age_read",
    "body_language",
    "silhouette",
    "palette",
    "costume_states",
    "expression_set",
    "must_read_as",
    "must_not_read_as",
    "asset_targets",
    "imagen_prompt",
    "source_evidence",
]
REQUIRED_ASSET_TARGETS = ["model_sheet", "portrait", "story_review_cutout"]
REQUIRED_PALETTE_FIELDS = ["base", "accent"]


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


def validate_palette(data: Any, label: str, failures: list[str]) -> None:
    if not isinstance(data, dict):
        failures.append(f"{label} must be an object")
        return
    for field in REQUIRED_PALETTE_FIELDS:
        require_string_list(data.get(field), f"{label}.{field}", failures, min_count=2)


def validate_costume_states(states: Any, label: str, failures: list[str]) -> None:
    if not isinstance(states, list) or not states:
        failures.append(f"{label} must be a non-empty list")
        return
    for index, state in enumerate(states):
        state_label = f"{label}[{index}]"
        if not isinstance(state, dict):
            failures.append(f"{state_label} must be an object")
            continue
        require_string(state.get("id"), f"{state_label}.id", failures)
        require_string(state.get("description"), f"{state_label}.description", failures)


def validate_asset_targets(targets: Any, label: str, failures: list[str]) -> None:
    if not isinstance(targets, dict):
        failures.append(f"{label} must be an object")
        return
    for field in REQUIRED_ASSET_TARGETS:
        value = targets.get(field)
        require_string(value, f"{label}.{field}", failures)
        if non_empty_string(value) and not str(value).startswith("res://assets/characters/main/"):
            failures.append(f"{label}.{field} must live under res://assets/characters/main/")


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
    for field in ["display_name", "role_slot", "stable_id", "narrative_function", "age_read", "body_language", "imagen_prompt"]:
        require_string(data.get(field), f"{prefix}.{field}", failures)
    stable_id = str(data.get("stable_id", ""))
    if non_empty_string(stable_id) and not stable_id.startswith("CHAR-"):
        failures.append(f"{prefix}.stable_id must start with CHAR-")

    require_string_list(data.get("silhouette"), f"{prefix}.silhouette", failures, min_count=3)
    require_string_list(data.get("expression_set"), f"{prefix}.expression_set", failures, min_count=4)
    require_string_list(data.get("must_read_as"), f"{prefix}.must_read_as", failures, min_count=2)
    require_string_list(data.get("must_not_read_as"), f"{prefix}.must_not_read_as", failures, min_count=2)
    validate_palette(data.get("palette"), f"{prefix}.palette", failures)
    validate_costume_states(data.get("costume_states"), f"{prefix}.costume_states", failures)
    validate_asset_targets(data.get("asset_targets"), f"{prefix}.asset_targets", failures)
    validate_source_paths(data.get("source_evidence"), f"{prefix}.source_evidence", failures)


def validate_models(path: Path) -> list[str]:
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

    art_rules = data.get("global_art_rules")
    if not isinstance(art_rules, dict):
        failures.append("global_art_rules must be an object")
    else:
        require_string(art_rules.get("style"), "global_art_rules.style", failures)
        require_string(art_rules.get("camera"), "global_art_rules.camera", failures)
        require_string(art_rules.get("palette_rule"), "global_art_rules.palette_rule", failures)
        require_string_list(art_rules.get("forbidden"), "global_art_rules.forbidden", failures, min_count=3)

    required_slots = data.get("required_role_slots")
    require_string_list(required_slots, "required_role_slots", failures, min_count=4)

    characters = data.get("characters")
    if not isinstance(characters, dict) or not characters:
        failures.append("characters must be a non-empty object")
        return failures
    voice_data = load_json(VOICE_PROFILES)
    voice_ids = set(voice_data.get("characters", {}).keys()) if isinstance(voice_data, dict) else set()
    for character_id, character_data in characters.items():
        if not non_empty_string(character_id):
            failures.append("character IDs must be non-empty strings")
            continue
        validate_character(str(character_id), character_data, voice_ids, failures)

    if isinstance(required_slots, list):
        present_slots = {
            str(character.get("role_slot", ""))
            for character in characters.values()
            if isinstance(character, dict)
        }
        for slot in required_slots:
            if non_empty_string(slot) and slot not in present_slots:
                failures.append(f"required role slot is missing a character: {slot}")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("models", nargs="?", type=Path, default=DEFAULT_MODELS)
    args = parser.parse_args()

    failures = validate_models(args.models)
    if failures:
        for failure in failures:
            print(f"character-visual-models: {failure}")
        return 1
    print(f"character-visual-models: OK {args.models}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
