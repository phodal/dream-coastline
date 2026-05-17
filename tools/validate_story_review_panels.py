#!/usr/bin/env python3
"""Validate story review panel coverage and character references."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
ILLUSTRATIONS = ROOT / "data" / "chapter_illustrations.json"
STORY_DIR = ROOT / "data" / "story_scenes"
CHARACTER_MODELS = ROOT / "data" / "character_visual_models.json"

GENERATION_STATUSES = {"ready", "fallback", "pending"}
MIN_NON_TRANSITION_PANELS = {
    "00-prologue-lights-out": 0,
}


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def repo_path(path_text: str) -> Path:
    clean_path = path_text.split("#", 1)[0]
    if clean_path.startswith("res://"):
        clean_path = clean_path.removeprefix("res://")
    return ROOT / clean_path


def is_non_empty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def validate_character_refs(
    scene_id: str,
    panel_id: str,
    refs: Any,
    character_ids: set[str],
    failures: list[str],
) -> None:
    if refs is None:
        return
    if not isinstance(refs, list):
        failures.append(f"{scene_id}/{panel_id} characters must be a list")
        return
    for index, ref in enumerate(refs):
        if isinstance(ref, str):
            character_id = ref
        elif isinstance(ref, dict):
            character_id = ref.get("id")
        else:
            failures.append(f"{scene_id}/{panel_id} characters[{index}] must be a string or object")
            continue
        if not is_non_empty_string(character_id):
            failures.append(f"{scene_id}/{panel_id} characters[{index}] is missing id")
            continue
        if character_id not in character_ids:
            failures.append(f"{scene_id}/{panel_id} references unknown character: {character_id}")


def validate_panel(
    scene_id: str,
    panel: Any,
    index: int,
    character_ids: set[str],
    failures: list[str],
) -> dict[str, Any]:
    if not isinstance(panel, dict):
        failures.append(f"{scene_id} panel {index} must be an object")
        return {"transition": False, "characters": False}

    panel_id = str(panel.get("id", f"panel-{index}"))
    for field in ["id", "path", "title", "caption"]:
        if not is_non_empty_string(panel.get(field)):
            failures.append(f"{scene_id}/{panel_id} is missing {field}")

    path = str(panel.get("path", ""))
    if is_non_empty_string(path) and not repo_path(path).exists():
        failures.append(f"{scene_id}/{panel_id} path does not exist: {path}")

    transition = bool(panel.get("transition", False))
    if not transition and not panel.get("commands") and not panel.get("locations"):
        failures.append(f"{scene_id}/{panel_id} non-transition panel needs commands or locations")

    status = panel.get("generation_status")
    if status is not None and status not in GENERATION_STATUSES:
        failures.append(f"{scene_id}/{panel_id} has invalid generation_status: {status}")
    target_path = panel.get("target_path")
    if is_non_empty_string(target_path):
        expected_prefix = f"res://assets/illustrations/story_review/{scene_id}/"
        if not str(target_path).startswith(expected_prefix):
            failures.append(f"{scene_id}/{panel_id} target_path must start with {expected_prefix}")
    if status in {"fallback", "pending"}:
        if not is_non_empty_string(target_path):
            failures.append(f"{scene_id}/{panel_id} fallback/pending panel needs target_path")
        if not is_non_empty_string(panel.get("imagen_prompt")):
            failures.append(f"{scene_id}/{panel_id} fallback/pending panel needs imagen_prompt")

    validate_character_refs(scene_id, panel_id, panel.get("characters"), character_ids, failures)
    return {
        "transition": transition,
        "characters": bool(panel.get("characters")),
    }


def validate() -> list[str]:
    failures: list[str] = []
    illustration_data = load_json(ILLUSTRATIONS)
    records_by_scene = illustration_data.get("illustrations")
    if not isinstance(records_by_scene, dict):
        return ["chapter_illustrations.json illustrations must be an object"]

    character_data = load_json(CHARACTER_MODELS)
    characters = character_data.get("characters", {})
    character_ids = set(characters.keys()) if isinstance(characters, dict) else set()
    if not character_ids:
        failures.append("character_visual_models.json has no characters")

    story_scene_ids = sorted(path.stem for path in STORY_DIR.glob("*.json"))
    for scene_id in story_scene_ids:
        records = records_by_scene.get(scene_id)
        if not isinstance(records, list) or not records:
            failures.append(f"{scene_id} has no story review panels")
            continue

        transition_count = 0
        non_transition_count = 0
        character_panel_count = 0
        seen_ids: set[str] = set()
        for index, panel in enumerate(records):
            if isinstance(panel, dict):
                panel_id = str(panel.get("id", f"panel-{index}"))
                if panel_id in seen_ids:
                    failures.append(f"{scene_id} has duplicate panel id: {panel_id}")
                seen_ids.add(panel_id)
            summary = validate_panel(scene_id, panel, index, character_ids, failures)
            if summary["transition"]:
                transition_count += 1
            else:
                non_transition_count += 1
            if summary["characters"]:
                character_panel_count += 1

        if transition_count == 0:
            failures.append(f"{scene_id} needs at least one transition panel")
        min_panels = MIN_NON_TRANSITION_PANELS.get(scene_id, 3)
        if non_transition_count < min_panels:
            failures.append(f"{scene_id} needs at least {min_panels} non-transition review panels")
        if scene_id != "00-prologue-lights-out" and character_panel_count == 0:
            failures.append(f"{scene_id} needs at least one panel with character refs")

    return failures


def main() -> int:
    failures = validate()
    if failures:
        for failure in failures:
            print(f"story-review-panels: {failure}")
        return 1
    print("story-review-panels: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
