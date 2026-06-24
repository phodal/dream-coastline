#!/usr/bin/env python3
"""Build a human QA checklist for the full Nova playable route."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STORY_DIR = ROOT / "data" / "story_scenes"
DEFAULT_OUTPUT = ROOT / "docs" / "nova-full-route-manual-qa.md"
DEFAULT_PROGRESS = ROOT / "docs" / "nova-full-route-manual-progress.json"

GLOBAL_ACCEPTANCE_ITEMS = [
    (
        "title_entry",
        "Start from the title splash and enter Nova with Enter/Space.",
    ),
    (
        "first_dialogic_return",
        "First Dialogic payload advances and returns to the Nova action menu.",
    ),
    (
        "full_route_no_deadlock",
        "Complete all {scene_count} scenes in order without input deadlock.",
    ),
    (
        "save_continue",
        "Save/continue works after at least one mid-route save.",
    ),
    (
        "pause_return_title",
        "Pause/resume and return-to-title work during exploration.",
    ),
    (
        "nova_entrypoint_only",
        "No legacy `res://src/main.tscn` / DreamField/OpenRPG entry is used for this route.",
    ),
    (
        "record_issues",
        "Record any visual, audio, or input issue against the scene and command step below.",
    ),
]

SCENE_ACCEPTANCE_ITEMS = [
    (
        "starts_expected_location",
        "Scene starts from the expected location after previous scene completion.",
    ),
    (
        "dialogic_advances",
        "Dialogic text can be advanced with Enter/Space or click when dialogue is active.",
    ),
    (
        "action_menu_returns",
        "Action menu focus returns after each dialogue/action payload.",
    ),
    (
        "pause_save_return_safe",
        "Pause, resume, save, and return-to-title do not corrupt the current scene.",
    ),
    (
        "ending_flag_reached",
        "Ending flag `{ending_flag}` is reached before moving to the next scene.",
    ),
]


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def load_progress(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    progress = load_json(path)
    if not isinstance(progress, dict):
        raise ValueError(f"{path.relative_to(ROOT)} must contain a JSON object")
    return progress


def scene_paths() -> list[Path]:
    return sorted(STORY_DIR.glob("*.json"))


def command_expectation(command: str) -> str:
    parts = command.split(maxsplit=1)
    if len(parts) != 2:
        return "screen responds without input deadlock"
    verb, target = parts
    if verb == "go":
        return f"location changes to `{target}` and action menu regains focus"
    if verb == "inspect":
        return f"`{target}` dialogue/action resolves and any flags are reflected in status"
    if verb == "choose":
        return f"choice `{target}` resolves and returns to exploration"
    if verb == "cast":
        return f"glyph `{target}` resolves with readable feedback"
    if verb == "build":
        return f"build `{target}` resolves with readable feedback"
    if verb == "engage":
        return f"encounter `{target}` starts and resolves through the authored branch"
    if verb == "combine":
        return f"combo `{target}` resolves with readable feedback"
    if verb in {"write", "attack", "guard"}:
        return f"combat action `{command}` advances without losing input focus"
    return "screen responds without input deadlock"


def render_command_rows(commands: list[str], route_start_index: int) -> str:
    rows = [
        "| Step | Route-full evidence key | Command | Expected live-window observation |",
        "| ---: | --- | --- | --- |",
    ]
    for index, command in enumerate(commands, 1):
        route_index = route_start_index + index
        rows.append(
            f"| {index} | `route-full #{route_index:03d}` | `{command}` | {command_expectation(command)} |"
        )
    return "\n".join(rows)


def render_flags(flags: list[str]) -> str:
    if not flags:
        return "- none"
    return "\n".join(f"- `{flag}`" for flag in flags)


def is_checked(progress_map: Any, key: str) -> bool:
    return isinstance(progress_map, dict) and bool(progress_map.get(key))


def render_checkbox(label: str, checked: bool) -> str:
    marker = "x" if checked else " "
    return f"- [{marker}] {label}"


def render_progress_notes(progress: dict[str, Any]) -> str:
    notes = progress.get("progress_notes", [])
    if not isinstance(notes, list) or not notes:
        return ""
    rows = ["Manual QA progress:", ""]
    rows.extend(f"- {str(note)}" for note in notes)
    rows.append("")
    rows.append("")
    return "\n".join(rows)


def render_global_acceptance(progress: dict[str, Any], scene_count: int) -> str:
    progress_map = progress.get("global_acceptance", {})
    rows = ["Global acceptance:", ""]
    for key, label in GLOBAL_ACCEPTANCE_ITEMS:
        rows.append(render_checkbox(label.format(scene_count=scene_count), is_checked(progress_map, key)))
    return "\n".join(rows)


def render_scene_acceptance(progress: dict[str, Any], scene_id: str, ending_flag: str) -> str:
    scene_progress = progress.get("scene_acceptance", {})
    progress_map = scene_progress.get(scene_id, {}) if isinstance(scene_progress, dict) else {}
    rows = ["Scene acceptance:", ""]
    for key, label in SCENE_ACCEPTANCE_ITEMS:
        rows.append(
            render_checkbox(
                label.format(ending_flag=ending_flag),
                is_checked(progress_map, key),
            )
        )
    return "\n".join(rows)


def validate_progress(progress: dict[str, Any], scene_ids: list[str]) -> list[str]:
    failures: list[str] = []
    known_global_keys = {key for key, _label in GLOBAL_ACCEPTANCE_ITEMS}
    known_scene_keys = {key for key, _label in SCENE_ACCEPTANCE_ITEMS}

    notes = progress.get("progress_notes", [])
    if "progress_notes" in progress and not isinstance(notes, list):
        failures.append("progress_notes must be a list")
    elif any(not isinstance(note, str) for note in notes):
        failures.append("progress_notes entries must be strings")

    global_acceptance = progress.get("global_acceptance", {})
    if "global_acceptance" in progress and not isinstance(global_acceptance, dict):
        failures.append("global_acceptance must be an object")
        global_acceptance = {}
    for key, value in global_acceptance.items():
        if key not in known_global_keys:
            failures.append(f"global_acceptance has unknown key: {key}")
        elif not isinstance(value, bool):
            failures.append(f"global_acceptance.{key} must be true or false")

    scene_acceptance = progress.get("scene_acceptance", {})
    if "scene_acceptance" in progress and not isinstance(scene_acceptance, dict):
        failures.append("scene_acceptance must be an object")
        scene_acceptance = {}
    known_scene_ids = set(scene_ids)
    for scene_id, scene_progress in scene_acceptance.items():
        if scene_id not in known_scene_ids:
            failures.append(f"scene_acceptance has unknown scene: {scene_id}")
            continue
        if not isinstance(scene_progress, dict):
            failures.append(f"scene_acceptance.{scene_id} must be an object")
            continue
        for key, value in scene_progress.items():
            if key not in known_scene_keys:
                failures.append(f"scene_acceptance.{scene_id} has unknown key: {key}")
            elif not isinstance(value, bool):
                failures.append(f"scene_acceptance.{scene_id}.{key} must be true or false")

    if global_acceptance.get("full_route_no_deadlock") is True:
        incomplete = []
        for scene_id in scene_ids:
            scene_progress = scene_acceptance.get(scene_id, {})
            if not isinstance(scene_progress, dict) or not all(scene_progress.get(key) is True for key in known_scene_keys):
                incomplete.append(scene_id)
        if incomplete:
            failures.append(
                "global_acceptance.full_route_no_deadlock requires all scene acceptance checks; "
                + "missing complete scenes: "
                + ", ".join(incomplete)
            )

    return failures


def build_markdown(progress: dict[str, Any] | None = None) -> str:
    progress = progress or {}
    scene_sections: list[str] = []
    total_commands = 0
    for path in scene_paths():
        scene = load_json(path)
        scene_id = str(scene.get("id", path.stem))
        title = str(scene.get("title", scene_id))
        start = str(scene.get("start", ""))
        ending_flag = str(scene.get("ending_flag", ""))
        required_flags = [str(flag) for flag in scene.get("required_flags", [])]
        commands = [str(command) for command in scene.get("walkthrough", [])]
        route_start_index = total_commands
        total_commands += len(commands)
        scene_sections.append(
            f"""## {scene_id} - {title}

- Start location: `{start}`
- Ending flag: `{ending_flag}`
- Walkthrough commands: {len(commands)}

Required flags:

{render_flags(required_flags)}

Live-window route:

{render_command_rows(commands, route_start_index)}

{render_scene_acceptance(progress, scene_id, ending_flag)}
"""
        )

    sections_markdown = "\n".join(scene_sections)
    progress_notes = render_progress_notes(progress)
    return f"""# Nova Full-Route Manual QA

This checklist is generated from `data/story_scenes/*.json` by
`tools/build_nova_manual_route_checklist.py`. Manual progress is sourced from
`docs/nova-full-route-manual-progress.json`. It is a live-window QA aid for
issue #6, not a replacement for headless smoke tests.

Current entrypoint: `res://src/nova/main.tscn`

{progress_notes}Recommended setup:

To update checked manual progress, edit
`docs/nova-full-route-manual-progress.json`, then regenerate this checklist.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Automated row-level visual evidence:

```sh
python3 tools/run_automated_tests.py --only route-full-screenshots --visual-style classic_dark
```

This produces `artifacts/scene-screenshots/route-full-latest/index.html` and a
manifest with one screenshot per walkthrough command. Use it to review row
evidence. The route table below includes a stable `route-full #NNN` key that
matches the manifest `command_index`, but only tick the manual checkboxes after
live-window observation.

{render_global_acceptance(progress, len(scene_sections))}

Route summary:

- Scenes: {len(scene_sections)}
- Walkthrough commands: {total_commands}

{sections_markdown}
"""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--progress", type=Path, default=DEFAULT_PROGRESS)
    parser.add_argument("--check", action="store_true", help="Fail if the output file is not up to date.")
    args = parser.parse_args()

    output = args.output.expanduser()
    if not output.is_absolute():
        output = ROOT / output
    progress = args.progress.expanduser()
    if not progress.is_absolute():
        progress = ROOT / progress
    progress_data = load_progress(progress)
    progress_failures = validate_progress(progress_data, [path.stem for path in scene_paths()])
    if progress_failures:
        for failure in progress_failures:
            print(f"nova-manual-route-checklist: {failure}", file=sys.stderr)
        return 1
    markdown = build_markdown(progress_data).rstrip() + "\n"
    if args.check:
        if not output.exists():
            print(f"nova-manual-route-checklist: missing {output.relative_to(ROOT)}")
            return 1
        current = output.read_text(encoding="utf-8")
        if current != markdown:
            print(f"nova-manual-route-checklist: stale {output.relative_to(ROOT)}")
            return 1
        print(f"nova-manual-route-checklist: OK {output.relative_to(ROOT)}")
        return 0

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(markdown, encoding="utf-8")
    print(f"nova-manual-route-checklist: wrote {output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
