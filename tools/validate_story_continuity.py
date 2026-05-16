#!/usr/bin/env python3
"""Validate cross-scene story continuity rules.

This catches narrative regressions that normal smoke tests can miss:

- a later "first encounter" enemy being defeated too early;
- scene slices missing the previous scene's ending fact;
- choice branches that only work for the canonical walkthrough route;
- authored requirements that reference flags no action can produce.
- story interactions that exist in JSON but cannot be reached from the RPG map.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = ROOT / "data" / "story_scenes"
VISUAL_DIR = ROOT / "data" / "visual_scenes"


def load_scene(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def scene_paths() -> list[Path]:
    return sorted(SCENE_DIR.glob("*.json"))


def load_ascii_runner():
    module_path = ROOT / "tools" / "ascii_five.py"
    spec = importlib.util.spec_from_file_location("ascii_five", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def collect_flags(scene: dict[str, Any]) -> tuple[set[str], set[str]]:
    produced: set[str] = set(scene.get("initial_flags", []))
    required: set[str] = set()

    def visit_action(action: Any) -> None:
        if not isinstance(action, dict):
            return
        produced.update(str(flag) for flag in action.get("flags", []))
        required.update(str(flag) for flag in action.get("requires", []))
        produced.update(str(flag) for flag in action.get("success_flags", []))
        produced.update(str(flag) for flag in action.get("reward_flags", []))
        if action.get("win_flag"):
            produced.add(str(action["win_flag"]))
        if action.get("lock_flag"):
            produced.add(str(action["lock_flag"]))
        required.update(str(flag) for flag in action.get("required_attack_flags", []))
        if action.get("learn_flag"):
            required.add(str(action["learn_flag"]))
        for nested_key in ["items", "glyph_actions", "build_actions", "choices", "encounters", "combos", "spells"]:
            nested = action.get(nested_key, {})
            if isinstance(nested, dict):
                for nested_action in nested.values():
                    visit_action(nested_action)
        combat = action.get("combat")
        if isinstance(combat, dict):
            visit_action(combat)

    for location in scene.get("locations", {}).values():
        visit_action(location)
    return produced, required


def validate_initial_flag_chain(scenes: list[dict[str, Any]], failures: list[str]) -> None:
    for previous, current in zip(scenes, scenes[1:]):
        previous_ending = previous.get("ending_flag")
        if previous_ending and previous_ending not in current.get("initial_flags", []):
            failures.append(
                f"{current['id']} initial_flags should include previous ending flag {previous_ending}"
            )


def validate_no_unproducible_requires(scenes: list[dict[str, Any]], failures: list[str]) -> None:
    for scene in scenes:
        produced, required = collect_flags(scene)
        missing = sorted(required - produced)
        if missing:
            failures.append(f"{scene['id']} has requirements with no producer or initial flag: {', '.join(missing)}")


def validate_enemy_first_contact(scenes_by_id: dict[str, dict[str, Any]], failures: list[str]) -> None:
    fifth = scenes_by_id.get("05-century-continuation", {})
    if "defeated_silent_probe" in set(fifth.get("required_flags", [])):
        failures.append("05-century-continuation must not defeat the silent probe before its first direct encounter")
    produced, _ = collect_flags(fifth)
    if "defeated_silent_probe" in produced:
        failures.append("05-century-continuation still produces defeated_silent_probe")
    sixth = scenes_by_id.get("06-return-star-plan", {})
    if "defeated_invasion_probe" not in set(sixth.get("required_flags", [])):
        failures.append("06-return-star-plan should own the first direct probe defeat")


def validate_branch_contract(scene: dict[str, Any], failures: list[str]) -> None:
    contract = scene.get("branch_consequences")
    if not isinstance(contract, dict):
        failures.append(f"{scene['id']} is missing branch_consequences")
        return
    resolved_flag = str(contract.get("resolved_flag", ""))
    routes = contract.get("routes", {})
    if not resolved_flag:
        failures.append(f"{scene['id']} branch_consequences.resolved_flag is missing")
    if not isinstance(routes, dict) or not routes:
        failures.append(f"{scene['id']} branch_consequences.routes is empty")
        return

    choice_routes: dict[str, dict[str, Any]] = {}
    for location in scene.get("locations", {}).values():
        choices = location.get("choices", {})
        if isinstance(choices, dict):
            choice_routes.update({str(key): value for key, value in choices.items() if isinstance(value, dict)})

    for route, choice in sorted(choice_routes.items()):
        flags = set(str(flag) for flag in choice.get("flags", []))
        if resolved_flag and resolved_flag not in flags:
            failures.append(f"{scene['id']} choice {route} does not set {resolved_flag}")
        route_contract = routes.get(route)
        if not isinstance(route_contract, dict):
            failures.append(f"{scene['id']} choice {route} has no branch consequence contract")
            continue
        route_flag = route_contract.get("flag")
        if route_flag not in flags:
            failures.append(f"{scene['id']} choice {route} contract flag does not match choice flags")
        if not route_contract.get("next_scene_metrics"):
            failures.append(f"{scene['id']} choice {route} lacks next_scene_metrics")
        if not route_contract.get("continuity_note"):
            failures.append(f"{scene['id']} choice {route} lacks continuity_note")


def collect_route_text_flags(scene: dict[str, Any]) -> set[str]:
    route_text_flags: set[str] = set()

    def visit_action(action: Any) -> None:
        if not isinstance(action, dict):
            return
        route_texts = action.get("route_texts", {})
        if isinstance(route_texts, dict):
            route_text_flags.update(str(flag) for flag in route_texts.keys())
        for nested_key in ["items", "glyph_actions", "build_actions", "choices", "encounters", "combos", "spells"]:
            nested = action.get(nested_key, {})
            if isinstance(nested, dict):
                for nested_action in nested.values():
                    visit_action(nested_action)
        combat = action.get("combat")
        if isinstance(combat, dict):
            visit_action(combat)

    for location in scene.get("locations", {}).values():
        visit_action(location)
    return route_text_flags


def validate_branch_visible_feedback(scenes_by_id: dict[str, dict[str, Any]], failures: list[str]) -> None:
    source = scenes_by_id.get("03-dead-kingdom", {})
    routes = source.get("branch_consequences", {}).get("routes", {})
    if not isinstance(routes, dict) or not routes:
        return
    route_flags = {
        str(route_contract.get("flag", ""))
        for route_contract in routes.values()
        if isinstance(route_contract, dict) and route_contract.get("flag")
    }
    for target_scene_id in ["04-continuation-institute", "06-return-star-plan"]:
        target = scenes_by_id.get(target_scene_id, {})
        feedback_flags = collect_route_text_flags(target)
        missing = sorted(route_flags - feedback_flags)
        if missing:
            failures.append(
                f"{target_scene_id} route_texts missing branch feedback for: {', '.join(missing)}"
            )


def validate_visual_interaction_contract(scenes: list[dict[str, Any]], failures: list[str]) -> None:
    for scene in scenes:
        visual_path = VISUAL_DIR / f"{scene['id']}.json"
        if not visual_path.exists():
            failures.append(f"{scene['id']} is missing visual scene file {visual_path.relative_to(ROOT)}")
            continue
        visual = load_scene(visual_path)
        visual_locations = visual.get("locations", {})
        if not isinstance(visual_locations, dict):
            failures.append(f"{scene['id']} visual scene has no locations dictionary")
            continue

        for location_id, location in scene.get("locations", {}).items():
            visual_location = visual_locations.get(location_id, {})
            if not isinstance(visual_location, dict):
                failures.append(f"{scene['id']} location {location_id} is missing from visual scene")
                continue

            props = visual_location.get("props", [])
            if not isinstance(props, list):
                failures.append(f"{scene['id']} location {location_id} visual props must be a list")
                continue

            item_props = {
                str(prop.get("item", ""))
                for prop in props
                if isinstance(prop, dict) and prop.get("item")
            }
            missing_items = sorted(set(location.get("items", {}).keys()) - item_props)
            if missing_items:
                failures.append(
                    f"{scene['id']} location {location_id} visual props missing story items: {', '.join(missing_items)}"
                )

            choice_actions = {
                str(prop.get("action", {}).get("arg", ""))
                for prop in props
                if isinstance(prop, dict)
                and isinstance(prop.get("action"), dict)
                and prop["action"].get("verb") == "choose"
            }
            missing_choices = sorted(set(location.get("choices", {}).keys()) - choice_actions)
            if missing_choices:
                failures.append(
                    f"{scene['id']} location {location_id} visual props missing choice actions: {', '.join(missing_choices)}"
                )


def validate_branch_walkthroughs(scene: dict[str, Any], failures: list[str]) -> None:
    runner = load_ascii_runner()
    walkthrough = scene.get("walkthrough", [])
    choose_commands = [command for command in walkthrough if str(command).startswith("choose ")]
    if not choose_commands:
        return
    canonical = choose_commands[0]
    canonical_route = canonical.split(" ", 1)[1]

    routes: list[str] = []
    for location in scene.get("locations", {}).values():
        choices = location.get("choices", {})
        if isinstance(choices, dict):
            routes.extend(str(route) for route in choices.keys())

    for route in sorted(set(routes)):
        if route == canonical_route:
            continue
        commands = [f"choose {route}" if command == canonical else command for command in walkthrough]
        state, _ = runner.run_walkthrough(scene, commands)
        missing = sorted(set(scene.get("required_flags", [])) - state.flags)
        if not state.ended or missing:
            failures.append(
                f"{scene['id']} non-canonical route {route} does not complete; missing={','.join(missing) or '-'}"
            )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    scenes = [load_scene(path) for path in scene_paths()]
    scenes_by_id = {scene["id"]: scene for scene in scenes}
    failures: list[str] = []

    validate_initial_flag_chain(scenes, failures)
    validate_no_unproducible_requires(scenes, failures)
    validate_enemy_first_contact(scenes_by_id, failures)
    dead_kingdom = scenes_by_id.get("03-dead-kingdom")
    if dead_kingdom:
        validate_branch_contract(dead_kingdom, failures)
        validate_branch_walkthroughs(dead_kingdom, failures)
    validate_branch_visible_feedback(scenes_by_id, failures)
    validate_visual_interaction_contract(scenes, failures)

    if failures:
        for failure in failures:
            print(f"FAIL {failure}")
        return 1
    if args.verbose:
        print(f"story-continuity status=PASS scenes={len(scenes)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
