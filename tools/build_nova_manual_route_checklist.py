#!/usr/bin/env python3
"""Build a human QA checklist for the full Nova playable route."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STORY_DIR = ROOT / "data" / "story_scenes"
DEFAULT_OUTPUT = ROOT / "docs" / "nova-full-route-manual-qa.md"


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


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


def render_command_rows(commands: list[str]) -> str:
    rows = ["| Step | Command | Expected live-window observation |", "| ---: | --- | --- |"]
    for index, command in enumerate(commands, 1):
        rows.append(f"| {index} | `{command}` | {command_expectation(command)} |")
    return "\n".join(rows)


def render_flags(flags: list[str]) -> str:
    if not flags:
        return "- none"
    return "\n".join(f"- `{flag}`" for flag in flags)


def build_markdown() -> str:
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
        total_commands += len(commands)
        scene_sections.append(
            f"""## {scene_id} - {title}

- Start location: `{start}`
- Ending flag: `{ending_flag}`
- Walkthrough commands: {len(commands)}

Required flags:

{render_flags(required_flags)}

Live-window route:

{render_command_rows(commands)}

Scene acceptance:

- [ ] Scene starts from the expected location after previous scene completion.
- [ ] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [ ] Action menu focus returns after each dialogue/action payload.
- [ ] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [ ] Ending flag `{ending_flag}` is reached before moving to the next scene.
"""
        )

    sections_markdown = "\n".join(scene_sections)
    return f"""# Nova Full-Route Manual QA

This checklist is generated from `data/story_scenes/*.json` by
`tools/build_nova_manual_route_checklist.py`. It is a live-window QA aid for
issue #6, not a replacement for headless smoke tests.

Current entrypoint: `res://src/nova/main.tscn`

Recommended setup:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Automated row-level visual evidence:

```sh
python3 tools/run_automated_tests.py --only route-full-screenshots --visual-style classic_dark
```

This produces `artifacts/scene-screenshots/route-full-latest/index.html` and a
manifest with one screenshot per walkthrough command. Use it to review row
evidence, but only tick the manual checkboxes after live-window observation.

Global acceptance:

- [ ] Start from the title splash and enter Nova with Enter/Space.
- [ ] First Dialogic payload advances and returns to the Nova action menu.
- [ ] Complete all {len(scene_sections)} scenes in order without input deadlock.
- [ ] Save/continue works after at least one mid-route save.
- [ ] Pause/resume and return-to-title work during exploration.
- [ ] No legacy `res://src/main.tscn` / DreamField/OpenRPG entry is used for this route.
- [ ] Record any visual, audio, or input issue against the scene and command step below.

Route summary:

- Scenes: {len(scene_sections)}
- Walkthrough commands: {total_commands}

{sections_markdown}
"""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--check", action="store_true", help="Fail if the output file is not up to date.")
    args = parser.parse_args()

    output = args.output.expanduser()
    if not output.is_absolute():
        output = ROOT / output
    markdown = build_markdown()
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
