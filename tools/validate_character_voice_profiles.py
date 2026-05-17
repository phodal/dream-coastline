#!/usr/bin/env python3
"""Validate character voice profiles used by AI dialogue and voice prompts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PROFILES = ROOT / "data" / "character_voice_profiles.json"
REQUIRED_CHARACTER_FIELDS = [
    "display_name",
    "role",
    "personality",
    "arc",
    "dialogue_rules",
    "voice_direction",
    "sample_lines",
    "source_evidence",
]
REQUIRED_DIALOGUE_RULE_FIELDS = ["sentence_shape", "lexicon", "avoid"]
REQUIRED_VOICE_FIELDS = [
    "age_read",
    "timbre",
    "pitch",
    "pace",
    "energy",
    "performance_notes",
    "tts_prompt",
]


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def repo_path(path_text: str) -> Path:
    clean_path = path_text.split("#", 1)[0]
    return ROOT / clean_path


def non_empty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def non_empty_list(value: Any) -> bool:
    return isinstance(value, list) and len(value) > 0


def require_string(value: Any, label: str, failures: list[str]) -> None:
    if not non_empty_string(value):
        failures.append(f"{label} must be a non-empty string")


def require_string_list(value: Any, label: str, failures: list[str]) -> None:
    if not non_empty_list(value):
        failures.append(f"{label} must be a non-empty list")
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


def validate_character(character_id: str, data: Any, failures: list[str]) -> None:
    if not isinstance(data, dict):
        failures.append(f"characters.{character_id} must be an object")
        return

    for field in REQUIRED_CHARACTER_FIELDS:
        if field not in data:
            failures.append(f"characters.{character_id}.{field} is required")

    require_string(data.get("display_name"), f"characters.{character_id}.display_name", failures)
    require_string(data.get("role"), f"characters.{character_id}.role", failures)
    require_string_list(data.get("personality"), f"characters.{character_id}.personality", failures)
    require_string_list(data.get("arc"), f"characters.{character_id}.arc", failures)
    require_string_list(data.get("sample_lines"), f"characters.{character_id}.sample_lines", failures)
    validate_source_paths(data.get("source_evidence"), f"characters.{character_id}.source_evidence", failures)

    dialogue_rules = data.get("dialogue_rules")
    if not isinstance(dialogue_rules, dict):
        failures.append(f"characters.{character_id}.dialogue_rules must be an object")
    else:
        for field in REQUIRED_DIALOGUE_RULE_FIELDS:
            if field not in dialogue_rules:
                failures.append(f"characters.{character_id}.dialogue_rules.{field} is required")
        require_string(
            dialogue_rules.get("sentence_shape"),
            f"characters.{character_id}.dialogue_rules.sentence_shape",
            failures,
        )
        require_string_list(
            dialogue_rules.get("lexicon"),
            f"characters.{character_id}.dialogue_rules.lexicon",
            failures,
        )
        require_string_list(
            dialogue_rules.get("avoid"),
            f"characters.{character_id}.dialogue_rules.avoid",
            failures,
        )

    voice_direction = data.get("voice_direction")
    if not isinstance(voice_direction, dict):
        failures.append(f"characters.{character_id}.voice_direction must be an object")
    else:
        for field in REQUIRED_VOICE_FIELDS:
            if field not in voice_direction:
                failures.append(f"characters.{character_id}.voice_direction.{field} is required")
        for field in ["age_read", "timbre", "pitch", "pace", "energy", "tts_prompt"]:
            require_string(
                voice_direction.get(field),
                f"characters.{character_id}.voice_direction.{field}",
                failures,
            )
        require_string_list(
            voice_direction.get("performance_notes"),
            f"characters.{character_id}.voice_direction.performance_notes",
            failures,
        )


def validate_profiles(path: Path) -> list[str]:
    failures: list[str] = []
    data = load_json(path)
    if not isinstance(data, dict):
        return [f"{path} must contain a JSON object"]

    if data.get("schema_version") != 1:
        failures.append("schema_version must be 1")
    validate_source_paths(data.get("generated_from"), "generated_from", failures)

    global_rules = data.get("global_voice_rules")
    if not isinstance(global_rules, dict):
        failures.append("global_voice_rules must be an object")
    else:
        require_string(global_rules.get("language"), "global_voice_rules.language", failures)
        require_string(global_rules.get("style"), "global_voice_rules.style", failures)
        require_string_list(global_rules.get("forbidden"), "global_voice_rules.forbidden", failures)

    characters = data.get("characters")
    if not isinstance(characters, dict) or not characters:
        failures.append("characters must be a non-empty object")
        return failures
    for character_id, character_data in characters.items():
        if not non_empty_string(character_id):
            failures.append("character IDs must be non-empty strings")
            continue
        validate_character(str(character_id), character_data, failures)
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("profiles", nargs="?", type=Path, default=DEFAULT_PROFILES)
    args = parser.parse_args()

    failures = validate_profiles(args.profiles)
    if failures:
        for failure in failures:
            print(f"character-voice-profiles: {failure}")
        return 1
    print(f"character-voice-profiles: OK {args.profiles}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
