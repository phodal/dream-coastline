#!/usr/bin/env python3
"""Validate scene AI automation contracts before implementation."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_SHEET_SECTIONS = [
    "Source Scene Contract",
    "Visual Direction",
    "Must Read As",
    "Must Not Read As",
    "Implementation Tasks",
    "Acceptance",
    "Screenshot Review Gate",
    "Affected Files",
    "Non-Goals",
]

REQUIRED_BRIEF_SECTIONS = [
    "UI Objective",
    "Screen Region Contract",
    "Data Hook Matrix",
    "Scene Canvas Rendering Contract",
    "Prompt And Feedback Contract",
    "Interaction State Matrix",
    "Prop Risk To UI Task Map",
    "Component Tasks",
    "Screenshot Capture Plan",
    "Acceptance Commands",
    "Non-Goals",
]

VALID_STABLE_ID = re.compile(r"^(VIS|PROP|ANIM|HUD|SHOT|TASK)-[A-Z0-9]+-[0-9]{2}$")


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"Could not parse JSON {path}: {error}") from error
    if not isinstance(data, dict):
        raise SystemExit(f"Expected JSON object in {path}")
    return data


def repo_path(path_text: str) -> Path:
    path = Path(path_text)
    if path.is_absolute():
        return path
    return ROOT / path


def heading_exists(text: str, heading: str) -> bool:
    escaped = re.escape(heading)
    return re.search(rf"(?im)^#+\s+{escaped}\s*$", text) is not None


def non_empty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def non_empty_list(value: Any) -> bool:
    return isinstance(value, list) and len(value) > 0


def validate_source_paths(scene_map: dict[str, Any], failures: list[str]) -> None:
    sources = scene_map.get("sources")
    if not isinstance(sources, dict):
        failures.append("scene_sprint_map.sources must be an object")
        return
    for key in ["scene", "story_json", "visual_json"]:
        value = sources.get(key)
        if not non_empty_string(value):
            failures.append(f"sources.{key} must be a non-empty path")
            continue
        if not repo_path(value).exists():
            failures.append(f"sources.{key} path does not exist: {value}")


def validate_contract_rows(scene_map: dict[str, Any], failures: list[str]) -> None:
    rows = scene_map.get("source_scene_contract")
    if not non_empty_list(rows):
        failures.append("source_scene_contract must contain evidence rows")
        return
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            failures.append(f"source_scene_contract[{index}] must be an object")
            continue
        if not non_empty_string(row.get("evidence")):
            failures.append(f"source_scene_contract[{index}].evidence is missing")
        if not non_empty_string(row.get("screen_meaning")):
            failures.append(f"source_scene_contract[{index}].screen_meaning is missing")


def validate_location_map(
    scene_map: dict[str, Any],
    scene_id: str,
    failures: list[str],
) -> None:
    story_path = ROOT / "data" / "story_scenes" / f"{scene_id}.json"
    visual_path = ROOT / "data" / "visual_scenes" / f"{scene_id}.json"
    if not story_path.exists():
        failures.append(f"story JSON does not exist for scene: {scene_id}")
        return
    if not visual_path.exists():
        failures.append(f"visual JSON does not exist for scene: {scene_id}")
        return

    story = load_json(story_path)
    visual = load_json(visual_path)
    story_locations = story.get("locations", {})
    visual_locations = visual.get("locations", {})
    if not isinstance(story_locations, dict):
        failures.append(f"{story_path.relative_to(ROOT)} locations must be an object")
        return

    location_map = scene_map.get("location_map")
    if not non_empty_list(location_map):
        failures.append("location_map must cover every playable story location")
        return

    mapped_by_id: dict[str, dict[str, Any]] = {}
    for index, entry in enumerate(location_map):
        if not isinstance(entry, dict):
            failures.append(f"location_map[{index}] must be an object")
            continue
        location_id = entry.get("location_id")
        if not non_empty_string(location_id):
            failures.append(f"location_map[{index}].location_id is missing")
            continue
        mapped_by_id[str(location_id)] = entry
        if not non_empty_string(entry.get("story_name")):
            failures.append(f"location_map[{location_id}].story_name is missing")
        if not non_empty_string(entry.get("terrain")):
            failures.append(f"location_map[{location_id}].terrain is missing")
        spawn = entry.get("spawn")
        if not isinstance(spawn, dict) or "x" not in spawn or "y" not in spawn:
            failures.append(f"location_map[{location_id}].spawn must include x and y")
        if not non_empty_list(entry.get("key_props")) and visual_locations.get(location_id, {}).get("props"):
            failures.append(f"location_map[{location_id}].key_props is empty despite visual props")
        if not isinstance(entry.get("visual_risks", []), list):
            failures.append(f"location_map[{location_id}].visual_risks must be a list")

    expected_ids = set(story_locations.keys())
    found_ids = set(mapped_by_id.keys())
    for location_id in sorted(expected_ids - found_ids):
        failures.append(f"location_map missing story location: {location_id}")
    for location_id in sorted(found_ids - expected_ids):
        failures.append(f"location_map includes unknown story location: {location_id}")


def validate_tasks(scene_map: dict[str, Any], failures: list[str]) -> None:
    tasks = scene_map.get("implementation_tasks")
    if not non_empty_list(tasks):
        failures.append("implementation_tasks must not be empty")
        return
    for index, task in enumerate(tasks):
        if not isinstance(task, dict):
            failures.append(f"implementation_tasks[{index}] must be an object")
            continue
        for key in ["id", "goal"]:
            if not non_empty_string(task.get(key)):
                failures.append(f"implementation_tasks[{index}].{key} is missing")
        for key in ["inputs", "outputs", "acceptance"]:
            if not non_empty_list(task.get(key)):
                failures.append(f"implementation_tasks[{index}].{key} must not be empty")


def validate_screenshots(
    scene_map: dict[str, Any],
    failures: list[str],
    stable_ids: set[str] | None = None,
) -> None:
    states = scene_map.get("screenshot_states")
    if not non_empty_list(states):
        failures.append("screenshot_states must include reviewable states")
        return
    if len(states) < 2:
        failures.append("screenshot_states should include initial and progression states")
    for index, state in enumerate(states):
        if not isinstance(state, dict):
            failures.append(f"screenshot_states[{index}] must be an object")
            continue
        state_id = str(state.get("id", ""))
        if not non_empty_string(state_id):
            failures.append(f"screenshot_states[{index}].id is missing")
        elif stable_ids and state_id not in stable_ids:
            failures.append(f"screenshot_states[{state_id}].id is not listed in stable_ids")
        if not non_empty_string(state.get("location")):
            failures.append(f"screenshot_states[{index}].location is missing")
        if not non_empty_list(state.get("expect")):
            failures.append(f"screenshot_states[{index}].expect must not be empty")


def validate_stable_ids(scene_map: dict[str, Any], failures: list[str]) -> set[str]:
    rows = scene_map.get("stable_ids")
    if not non_empty_list(rows):
        failures.append("stable_ids must include traceable visual/prop/HUD/animation/screenshot IDs")
        return set()

    ids: set[str] = set()
    shot_ids = 0
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            failures.append(f"stable_ids[{index}] must be an object")
            continue
        stable_id = row.get("id")
        if not non_empty_string(stable_id):
            failures.append(f"stable_ids[{index}].id is missing")
            continue
        stable_id = str(stable_id)
        if not VALID_STABLE_ID.match(stable_id):
            failures.append(f"stable_ids[{index}].id has invalid format: {stable_id}")
        if stable_id in ids:
            failures.append(f"stable_ids duplicate id: {stable_id}")
        ids.add(stable_id)
        expected_type = stable_id.split("-", 1)[0]
        if str(row.get("type", "")) != expected_type:
            failures.append(f"stable_ids[{stable_id}].type must be {expected_type}")
        if expected_type == "SHOT":
            shot_ids += 1
        if not non_empty_string(row.get("label")):
            failures.append(f"stable_ids[{stable_id}].label is missing")
        if not non_empty_string(row.get("owner")):
            failures.append(f"stable_ids[{stable_id}].owner is missing")
    if shot_ids == 0:
        failures.append("stable_ids must include at least one SHOT-* screenshot state id")
    return ids


def validate_sprint_trace_map(
    scene_map: dict[str, Any],
    stable_ids: set[str],
    failures: list[str],
) -> None:
    rows = scene_map.get("sprint_trace_map")
    if not non_empty_list(rows):
        failures.append("sprint_trace_map must include evidence-to-runtime trace rows")
        return

    required = [
        "id",
        "scene_evidence",
        "runtime_function",
        "visual_object_or_animation_asset",
        "owner_file",
        "owner_function",
        "screenshot_state",
        "acceptance_gate",
    ]
    trace_ids: set[str] = set()
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            failures.append(f"sprint_trace_map[{index}] must be an object")
            continue
        row_id = str(row.get("id", ""))
        for key in required:
            if not non_empty_string(row.get(key)):
                failures.append(f"sprint_trace_map[{row_id or index}].{key} is missing")
        if row_id:
            trace_ids.add(row_id)
            if stable_ids and row_id not in stable_ids:
                failures.append(f"sprint_trace_map id is not listed in stable_ids: {row_id}")
        screenshot_state = str(row.get("screenshot_state", ""))
        if screenshot_state and stable_ids and screenshot_state not in stable_ids:
            failures.append(f"sprint_trace_map[{row_id}].screenshot_state is not listed in stable_ids: {screenshot_state}")
        owner_file = row.get("owner_file")
        if non_empty_string(owner_file):
            owner_path = repo_path(str(owner_file))
            if not owner_path.exists() and not owner_path.parent.exists():
                failures.append(f"sprint_trace_map[{row_id}].owner_file parent does not exist: {owner_file}")

    missing_trace_ids = {
        stable_id
        for stable_id in stable_ids
        if not stable_id.startswith("SHOT-") and stable_id not in trace_ids
    }
    for stable_id in sorted(missing_trace_ids):
        failures.append(f"stable_id missing sprint_trace_map row: {stable_id}")


def validate_map(map_path: Path, scene_id: str | None, failures: list[str]) -> str | None:
    data = load_json(map_path)
    scene_map = data.get("scene_sprint_map")
    if not isinstance(scene_map, dict):
        failures.append("map file must contain a scene_sprint_map object")
        return scene_id

    actual_scene_id = scene_map.get("scene_id")
    if not non_empty_string(actual_scene_id):
        failures.append("scene_sprint_map.scene_id is missing")
        return scene_id
    actual_scene_id = str(actual_scene_id)
    if scene_id is not None and actual_scene_id != scene_id:
        failures.append(f"scene_id mismatch: expected {scene_id}, got {actual_scene_id}")
    scene_id = scene_id or actual_scene_id

    if not non_empty_string(scene_map.get("title")):
        failures.append("scene_sprint_map.title is missing")
    validate_source_paths(scene_map, failures)
    validate_contract_rows(scene_map, failures)
    stable_ids = validate_stable_ids(scene_map, failures)
    validate_sprint_trace_map(scene_map, stable_ids, failures)
    for key in ["must_read_as", "must_not_read_as", "prop_risks", "acceptance_commands", "affected_files", "non_goals"]:
        if not non_empty_list(scene_map.get(key)):
            failures.append(f"{key} must not be empty")
    validate_location_map(scene_map, scene_id, failures)
    validate_screenshots(scene_map, failures, stable_ids)
    validate_tasks(scene_map, failures)
    for path_text in scene_map.get("affected_files", []):
        if not non_empty_string(path_text):
            failures.append("affected_files contains a non-string entry")
            continue
        path = repo_path(path_text)
        if not path.exists() and not path.parent.exists():
            failures.append(f"affected file parent does not exist: {path_text}")
    return scene_id


def validate_animation_screenshot_states(states: Any, failures: list[str]) -> None:
    if not non_empty_list(states):
        failures.append("animation_sprint_map.screenshot_states must not be empty")
        return
    for index, state in enumerate(states):
        if not isinstance(state, dict):
            failures.append(f"animation_sprint_map.screenshot_states[{index}] must be an object")
            continue
        if not non_empty_string(state.get("id")):
            failures.append(f"animation_sprint_map.screenshot_states[{index}].id is missing")
        if not non_empty_string(state.get("setup")):
            failures.append(f"animation_sprint_map.screenshot_states[{index}].setup is missing")
        if not non_empty_list(state.get("expect")):
            failures.append(f"animation_sprint_map.screenshot_states[{index}].expect must not be empty")


def validate_animation_map(
    animation_map_path: Path,
    scene_id: str | None,
    failures: list[str],
) -> str | None:
    data = load_json(animation_map_path)
    animation_map = data.get("animation_sprint_map")
    if not isinstance(animation_map, dict):
        failures.append("animation map file must contain an animation_sprint_map object")
        return scene_id

    map_id = str(animation_map.get("map_id", ""))
    if not non_empty_string(map_id):
        failures.append("animation_sprint_map.map_id is missing")
    elif not VALID_STABLE_ID.match(map_id) or not map_id.startswith("ANIM-"):
        failures.append(f"animation_sprint_map.map_id must be an ANIM-* stable id: {map_id}")

    actual_scene_id = animation_map.get("scene_id")
    if not non_empty_string(actual_scene_id):
        failures.append("animation_sprint_map.scene_id is missing")
    else:
        actual_scene_id = str(actual_scene_id)
        if scene_id is not None and actual_scene_id != scene_id:
            failures.append(f"scene_id mismatch: expected {scene_id}, got {actual_scene_id}")
        scene_id = scene_id or actual_scene_id

    for key in ["actor_id", "clip_id"]:
        if not non_empty_string(animation_map.get(key)):
            failures.append(f"animation_sprint_map.{key} is missing")
    for key in [
        "source_trace_ids",
        "scene_evidence",
        "must_read_as",
        "must_not_read_as",
        "required_animations",
        "asset_outputs",
        "owner_files",
        "acceptance_gates",
        "non_goals",
    ]:
        if not non_empty_list(animation_map.get(key)):
            failures.append(f"animation_sprint_map.{key} must not be empty")

    for trace_id in animation_map.get("source_trace_ids", []):
        if not non_empty_string(trace_id) or not VALID_STABLE_ID.match(str(trace_id)):
            failures.append(f"animation_sprint_map.source_trace_ids contains invalid id: {trace_id}")

    runtime_contract = animation_map.get("runtime_contract")
    if not isinstance(runtime_contract, dict):
        failures.append("animation_sprint_map.runtime_contract must be an object")
    else:
        for key in ["visual_asset_registry", "clip_file", "repository", "renderer"]:
            value = runtime_contract.get(key)
            if not non_empty_string(value):
                failures.append(f"animation_sprint_map.runtime_contract.{key} is missing")
                continue
            path = repo_path(str(value))
            if not path.exists() and not path.parent.exists():
                failures.append(f"animation_sprint_map.runtime_contract.{key} parent does not exist: {value}")
        if not non_empty_list(runtime_contract.get("state_inputs")):
            failures.append("animation_sprint_map.runtime_contract.state_inputs must not be empty")

    frame_contract = animation_map.get("frame_contract")
    if not isinstance(frame_contract, dict):
        failures.append("animation_sprint_map.frame_contract must be an object")
    else:
        for key in ["tile_size", "render_size", "anchor", "loop"]:
            if key not in frame_contract:
                failures.append(f"animation_sprint_map.frame_contract.{key} is missing")

    for path_text in animation_map.get("owner_files", []):
        if not non_empty_string(path_text):
            failures.append("animation_sprint_map.owner_files contains a non-string entry")
            continue
        path = repo_path(str(path_text))
        if not path.exists() and not path.parent.exists():
            failures.append(f"animation_sprint_map.owner_files parent does not exist: {path_text}")

    validate_animation_screenshot_states(animation_map.get("screenshot_states"), failures)

    gates = "\n".join(str(gate) for gate in animation_map.get("acceptance_gates", []))
    actor_id = str(animation_map.get("actor_id", ""))
    if actor_id == "jizixuan" and "--smoke-animation-clips" not in gates:
        failures.append("jizixuan animation maps must include --smoke-animation-clips acceptance")

    return scene_id


def validate_markdown(path: Path, required_sections: list[str], label: str, failures: list[str]) -> None:
    if not path.exists():
        failures.append(f"{label} does not exist: {path}")
        return
    text = path.read_text(encoding="utf-8")
    for section in required_sections:
        if not heading_exists(text, section):
            failures.append(f"{label} missing heading: {section}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene-id", help="Expected scene id, such as 01-illiterate")
    parser.add_argument("--map", dest="map_path", type=Path, help="scene_sprint_map JSON file")
    parser.add_argument("--animation-map", type=Path, help="animation_sprint_map JSON file")
    parser.add_argument("--sheet", type=Path, help="Sprint Sheet Markdown file")
    parser.add_argument("--brief", type=Path, help="UI Implementation Brief Markdown file")
    args = parser.parse_args()

    if args.map_path is None and args.animation_map is None and args.sheet is None and args.brief is None:
        raise SystemExit("Provide at least one of --map, --animation-map, --sheet, or --brief")

    failures: list[str] = []
    scene_id = args.scene_id
    if args.map_path is not None:
        scene_id = validate_map(args.map_path, scene_id, failures)
    if args.animation_map is not None:
        scene_id = validate_animation_map(args.animation_map, scene_id, failures)
    if args.sheet is not None:
        validate_markdown(args.sheet, REQUIRED_SHEET_SECTIONS, "Sprint Sheet", failures)
    if args.brief is not None:
        validate_markdown(args.brief, REQUIRED_BRIEF_SECTIONS, "UI Implementation Brief", failures)

    if failures:
        print(f"scene-ai-contract-validation status=FAIL failures={len(failures)}")
        for failure in failures:
            print(f"failure={failure}")
        sys.exit(1)

    checked = sum(value is not None for value in [args.map_path, args.animation_map, args.sheet, args.brief])
    suffix = f" scene_id={scene_id}" if scene_id else ""
    print(f"scene-ai-contract-validation status=PASS checked={checked}{suffix}")


if __name__ == "__main__":
    main()
