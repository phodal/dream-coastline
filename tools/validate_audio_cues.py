#!/usr/bin/env python3
"""Validate Dream Coastline audio cue and voice sample contracts."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
AUDIO_CUE_DIR = ROOT / "data" / "audio_cues"
STORY_SCENE_DIR = ROOT / "data" / "story_scenes"
VOICE_PROFILES = ROOT / "data" / "character_voice_profiles.json"

CUE_ID_RE = re.compile(r"^(AMB|MUS|STG)-\d{2}-\d{3}$")
SFX_ID_RE = re.compile(r"^SFX-\d{2}-[A-Z0-9-]+$")
LINE_ID_RE = re.compile(r"^DLG-\d{2}-SAMPLE-[A-Z0-9]+$")
VALID_CUE_TYPES = {"ambience", "music", "stinger"}


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def repo_path(path_text: str) -> Path:
    return ROOT / path_text.split("#", 1)[0]


def is_non_empty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def require_string(data: dict[str, Any], field: str, label: str, failures: list[str]) -> None:
    if not is_non_empty_string(data.get(field)):
        failures.append(f"{label}.{field} must be a non-empty string")


def require_number(data: dict[str, Any], field: str, label: str, failures: list[str]) -> None:
    if not isinstance(data.get(field), (int, float)):
        failures.append(f"{label}.{field} must be a number")


def require_source_paths(value: Any, label: str, failures: list[str]) -> None:
    if not isinstance(value, list) or not value:
        failures.append(f"{label} must be a non-empty list")
        return
    for index, item in enumerate(value):
        if not is_non_empty_string(item):
            failures.append(f"{label}[{index}] must be a non-empty string")
            continue
        if not repo_path(item).exists():
            failures.append(f"{label}[{index}] references missing source: {item}")


def validate_target_path(value: Any, label: str, expected_prefix: str, failures: list[str]) -> None:
    if not is_non_empty_string(value):
        failures.append(f"{label} must be a non-empty string")
        return
    if not value.startswith(expected_prefix):
        failures.append(f"{label} must start with {expected_prefix}")
    if not value.endswith(".mp3"):
        failures.append(f"{label} must end with .mp3")


def validate_cue(
    cue: Any,
    index: int,
    scene_id: str,
    locations: set[str],
    seen_ids: set[str],
    failures: list[str],
) -> None:
    label = f"cues[{index}]"
    if not isinstance(cue, dict):
        failures.append(f"{label} must be an object")
        return

    for field in [
        "cue_id",
        "scene_id",
        "location_id",
        "type",
        "mood",
        "instrumentation_prompt",
        "looping_intent",
        "source_evidence",
        "target_path",
    ]:
        if field != "source_evidence":
            require_string(cue, field, label, failures)

    cue_id = cue.get("cue_id")
    if is_non_empty_string(cue_id):
        if not CUE_ID_RE.match(cue_id):
            failures.append(f"{label}.cue_id has invalid format: {cue_id}")
        if cue_id in seen_ids:
            failures.append(f"{label}.cue_id duplicates {cue_id}")
        seen_ids.add(cue_id)

    if cue.get("scene_id") != scene_id:
        failures.append(f"{label}.scene_id must be {scene_id}")
    if cue.get("location_id") not in locations:
        failures.append(f"{label}.location_id is not in story scene locations")
    cue_locations = cue.get("locations", [])
    if cue_locations:
        if not isinstance(cue_locations, list):
            failures.append(f"{label}.locations must be a list when present")
        else:
            for location_id in cue_locations:
                if not is_non_empty_string(location_id):
                    failures.append(f"{label}.locations must contain strings")
                elif location_id not in locations:
                    failures.append(f"{label}.locations contains unknown location: {location_id}")
    if cue.get("type") not in VALID_CUE_TYPES:
        failures.append(f"{label}.type must be one of {sorted(VALID_CUE_TYPES)}")
    require_source_paths(cue.get("source_evidence"), f"{label}.source_evidence", failures)
    validate_target_path(
        cue.get("target_path"),
        f"{label}.target_path",
        f"assets/audio/generated/music/{scene_id}/",
        failures,
    )


def validate_voice_sample(
    line: Any,
    index: int,
    scene_id: str,
    locations: set[str],
    character_ids: set[str],
    seen_ids: set[str],
    failures: list[str],
) -> None:
    label = f"voice_samples[{index}]"
    if not isinstance(line, dict):
        failures.append(f"{label} must be an object")
        return

    for field in [
        "line_id",
        "scene_id",
        "location_id",
        "character_id",
        "character_name",
        "text",
        "delivery",
        "voice_id",
        "source_evidence",
        "target_path",
    ]:
        if field != "source_evidence":
            require_string(line, field, label, failures)
    for field in ["speed", "vol", "pitch"]:
        require_number(line, field, label, failures)

    line_id = line.get("line_id")
    if is_non_empty_string(line_id):
        if not LINE_ID_RE.match(line_id):
            failures.append(f"{label}.line_id has invalid format: {line_id}")
        if line_id in seen_ids:
            failures.append(f"{label}.line_id duplicates {line_id}")
        seen_ids.add(line_id)

    if line.get("scene_id") != scene_id:
        failures.append(f"{label}.scene_id must be {scene_id}")
    if line.get("location_id") not in locations:
        failures.append(f"{label}.location_id is not in story scene locations")
    if line.get("character_id") not in character_ids:
        failures.append(f"{label}.character_id is not in character_voice_profiles.json")
    require_source_paths(line.get("source_evidence"), f"{label}.source_evidence", failures)
    validate_target_path(
        line.get("target_path"),
        f"{label}.target_path",
        f"assets/audio/generated/voices/{scene_id}/",
        failures,
    )


def validate_event_sound(
    sound: Any,
    index: int,
    scene_id: str,
    locations: set[str],
    seen_ids: set[str],
    failures: list[str],
) -> None:
    label = f"event_sounds[{index}]"
    if not isinstance(sound, dict):
        failures.append(f"{label} must be an object")
        return

    for field in [
        "sfx_id",
        "scene_id",
        "event_name",
        "mood",
        "instrumentation_prompt",
        "source_evidence",
        "target_path",
    ]:
        if field != "source_evidence":
            require_string(sound, field, label, failures)
    require_number(sound, "duration_ms", label, failures)

    sfx_id = sound.get("sfx_id")
    if is_non_empty_string(sfx_id):
        if not SFX_ID_RE.match(sfx_id):
            failures.append(f"{label}.sfx_id has invalid format: {sfx_id}")
        if sfx_id in seen_ids:
            failures.append(f"{label}.sfx_id duplicates {sfx_id}")
        seen_ids.add(sfx_id)

    if sound.get("scene_id") != scene_id:
        failures.append(f"{label}.scene_id must be {scene_id}")
    duration_ms = sound.get("duration_ms")
    if isinstance(duration_ms, (int, float)) and not 100 <= duration_ms <= 3000:
        failures.append(f"{label}.duration_ms must be between 100 and 3000")
    sound_locations = sound.get("locations", [])
    if not isinstance(sound_locations, list) or not sound_locations:
        failures.append(f"{label}.locations must be a non-empty list")
    else:
        for location_id in sound_locations:
            if not is_non_empty_string(location_id):
                failures.append(f"{label}.locations must contain strings")
            elif location_id not in locations:
                failures.append(f"{label}.locations contains unknown location: {location_id}")
    require_source_paths(sound.get("source_evidence"), f"{label}.source_evidence", failures)
    validate_target_path(
        sound.get("target_path"),
        f"{label}.target_path",
        f"assets/audio/generated/sfx/{scene_id}/",
        failures,
    )


def validate_audio_cue_file(path: Path, character_ids: set[str]) -> list[str]:
    failures: list[str] = []
    data = load_json(path)
    if not isinstance(data, dict):
        return [f"{path} must contain a JSON object"]

    scene_id = data.get("scene_id")
    if data.get("schema_version") != 1:
        failures.append("schema_version must be 1")
    if not is_non_empty_string(scene_id):
        failures.append("scene_id must be a non-empty string")
        return failures

    story_path = STORY_SCENE_DIR / f"{scene_id}.json"
    if not story_path.exists():
        failures.append(f"missing story scene: {story_path.relative_to(ROOT)}")
        return failures
    story = load_json(story_path)
    locations = set(story.get("locations", {}).keys())

    if data.get("source") != f"data/story_scenes/{scene_id}.json":
        failures.append(f"source must be data/story_scenes/{scene_id}.json")
    require_source_paths(data.get("generated_from"), "generated_from", failures)

    cues = data.get("cues")
    if not isinstance(cues, list) or not cues:
        failures.append("cues must be a non-empty list")
    else:
        seen_cue_ids: set[str] = set()
        for index, cue in enumerate(cues):
            validate_cue(cue, index, scene_id, locations, seen_cue_ids, failures)

    voice_samples = data.get("voice_samples", [])
    if not isinstance(voice_samples, list):
        failures.append("voice_samples must be a list")
    else:
        seen_line_ids: set[str] = set()
        for index, line in enumerate(voice_samples):
            validate_voice_sample(
                line,
                index,
                scene_id,
                locations,
                character_ids,
                seen_line_ids,
                failures,
            )

    event_sounds = data.get("event_sounds", [])
    if not isinstance(event_sounds, list):
        failures.append("event_sounds must be a list")
    else:
        seen_sfx_ids: set[str] = set()
        for index, sound in enumerate(event_sounds):
            validate_event_sound(sound, index, scene_id, locations, seen_sfx_ids, failures)
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    args = parser.parse_args()

    profiles = load_json(VOICE_PROFILES)
    character_ids = set(profiles.get("characters", {}).keys())
    paths = args.paths or sorted(AUDIO_CUE_DIR.glob("*.json"))
    failures: list[str] = []
    for path in paths:
        cue_path = path if path.is_absolute() else ROOT / path
        for failure in validate_audio_cue_file(cue_path, character_ids):
            failures.append(f"{cue_path.relative_to(ROOT)}: {failure}")

    if failures:
        for failure in failures:
            print(f"audio-cues: {failure}")
        return 1
    print(f"audio-cues: OK {len(paths)} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
