#!/usr/bin/env python3
"""Run Dream Coastline automated test tiers."""

from __future__ import annotations

import argparse
import json
import os
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GODOT = Path(os.environ.get("GODOT_PATH", "/Applications/Godot.app/Contents/MacOS/Godot"))

StepAction = Callable[["Runner", "Step"], int]


@dataclass(frozen=True)
class Step:
    id: str
    group: str
    description: str
    action: StepAction


class Runner:
    def __init__(self, args: argparse.Namespace) -> None:
        self.args = args
        self.failed: list[str] = []

    @property
    def godot(self) -> Path:
        raw = str(self.args.godot)
        path = Path(raw).expanduser()
        if not path.is_absolute() and (raw.startswith(".") or "/" in raw or (ROOT / path).exists()):
            return ROOT / path
        return path

    def run_command(self, step: Step, command: list[str]) -> int:
        print(f"\n==> {step.id}: {step.description}")
        print(format_command(command))
        if self.args.dry_run:
            return 0
        try:
            result = subprocess.run(command, cwd=ROOT, check=False)
        except FileNotFoundError as error:
            print(f"missing executable: {error.filename}", file=sys.stderr)
            return 127
        return result.returncode

    def run_python(self, step: Step, *args: str) -> int:
        return self.run_command(step, [sys.executable, *args])

    def run_godot(self, step: Step, flag: str | None = None, *, headless: bool = True, quit_after: int = 100) -> int:
        command = [str(self.godot), "--path", str(ROOT)]
        if headless:
            command.append("--headless")
        if flag is None:
            command.append("--quit")
        else:
            command.extend(["--quit-after", str(quit_after), "--", flag])
        return self.run_command(step, command)


def format_command(command: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in command)


def validate_json_data(runner: Runner, step: Step) -> int:
    print(f"\n==> {step.id}: {step.description}")
    if runner.args.dry_run:
        print("parse data/**/*.json")
        return 0
    failures: list[str] = []
    for path in sorted((ROOT / "data").rglob("*.json")):
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            failures.append(f"{path.relative_to(ROOT)}: {error}")
    if failures:
        for failure in failures:
            print(f"json-data: {failure}", file=sys.stderr)
        return 1
    print(f"json-data status=PASS files={len(list((ROOT / 'data').rglob('*.json')))}")
    return 0


def py_compile_tools(runner: Runner, step: Step) -> int:
    files = sorted(path for path in (ROOT / "tools").glob("*.py") if path.is_file())
    return runner.run_python(step, "-m", "py_compile", *(str(path.relative_to(ROOT)) for path in files))


def ascii_scene_walkthroughs(runner: Runner, step: Step) -> int:
    scene_ids = sorted(path.stem for path in (ROOT / "data" / "story_scenes").glob("*.json"))
    if not scene_ids:
        print("no story scenes found", file=sys.stderr)
        return 1
    for scene_id in scene_ids:
        code = runner.run_python(step, "tools/ascii_five.py", scene_id, "--verify")
        if code != 0:
            return code
    return 0


def story_continuity(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/validate_story_continuity.py", "--verbose")


def equipment_catalog(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/validate_equipment_catalog.py")


def supply_catalog(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/validate_supply_catalog.py")


def cargo_build(runner: Runner, step: Step) -> int:
    return runner.run_command(step, ["cargo", "build"])


def cargo_release_builds(runner: Runner, step: Step) -> int:
    return runner.run_command(step, ["tools/build_release_libraries.sh"])


def godot_load(runner: Runner, step: Step) -> int:
    return runner.run_godot(step, None)


def godot_smoke(flag: str) -> StepAction:
    def action(runner: Runner, step: Step) -> int:
        return runner.run_godot(step, flag)

    return action


def render_frame(runner: Runner, step: Step) -> int:
    return runner.run_godot(step, "--smoke-render-frame", headless=False, quit_after=120)


def screenshot_starts(runner: Runner, step: Step) -> int:
    command = [
        sys.executable,
        "tools/capture_scene_screenshots.py",
        "--godot",
        str(runner.godot),
        "--scope",
        runner.args.visual_scope,
        "--visual-style",
        runner.args.visual_style,
    ]
    if runner.args.scene != "all":
        command.extend(["--scene", runner.args.scene])
    return runner.run_command(step, command)


STEPS: list[Step] = [
    Step("json-data", "quick", "parse data JSON files", validate_json_data),
    Step("python-tools", "quick", "compile top-level Python tools", py_compile_tools),
    Step("ascii-scenes", "quick", "verify ASCII walkthrough, duration, and UI gates", ascii_scene_walkthroughs),
    Step("story-continuity", "quick", "validate cross-scene continuity contracts", story_continuity),
    Step("equipment-catalog", "quick", "validate equipment carrier catalog", equipment_catalog),
    Step("supply-catalog", "quick", "validate supply and consumable carrier catalog", supply_catalog),
    Step("cargo-build", "quick", "build Rust GDExtension for the current platform", cargo_build),
    Step("godot-load", "quick", "load the Godot project headlessly", godot_load),
    Step("smoke-open-rpg-story", "quick", "validate migrated story walkthroughs on the OpenRPG spine", godot_smoke("--smoke-open-rpg-story")),
    Step("smoke-open-rpg-runtime", "quick", "validate OpenRPG field runtime nodes and pathfinder", godot_smoke("--smoke-open-rpg-runtime")),
    Step("smoke-open-rpg-actions", "quick", "validate story action records are exposed as OpenRPG interactions", godot_smoke("--smoke-open-rpg-actions")),
    Step("smoke-rpg-progression", "quick", "validate RPG progression data slice", godot_smoke("--smoke-rpg-progression")),
    Step("smoke-input-map", "quick", "validate keyboard and gamepad input mapping", godot_smoke("--smoke-input-map")),
    Step("smoke-animation-clips", "quick", "validate animation clip contracts", godot_smoke("--smoke-animation-clips")),
    Step("smoke-visual-asset-scenes", "quick", "validate asset-backed visual location scenes", godot_smoke("--smoke-visual-asset-scenes")),
    Step("smoke-autoplay", "headless", "complete every implemented scene runner", godot_smoke("--smoke-autoplay")),
    Step("smoke-rpg-first-act", "headless", "complete first-act keyboard route", godot_smoke("--smoke-rpg-first-act")),
    Step("smoke-rpg-illiterate", "headless", "complete illiterate scene keyboard route", godot_smoke("--smoke-rpg-illiterate")),
    Step("smoke-rpg-moqi-academy", "headless", "complete Moqi Academy keyboard route", godot_smoke("--smoke-rpg-moqi-academy")),
    Step("smoke-rpg-dead-kingdom", "headless", "complete dead kingdom keyboard route", godot_smoke("--smoke-rpg-dead-kingdom")),
    Step(
        "smoke-rpg-continuation-institute",
        "headless",
        "complete continuation institute keyboard route",
        godot_smoke("--smoke-rpg-continuation-institute"),
    ),
    Step(
        "smoke-rpg-century-continuation",
        "headless",
        "complete century continuation keyboard route",
        godot_smoke("--smoke-rpg-century-continuation"),
    ),
    Step(
        "smoke-rpg-return-star-plan",
        "headless",
        "complete return star plan keyboard route",
        godot_smoke("--smoke-rpg-return-star-plan"),
    ),
    Step(
        "smoke-rpg-lights-on-again",
        "headless",
        "complete lights-on-again keyboard route",
        godot_smoke("--smoke-rpg-lights-on-again"),
    ),
    Step("smoke-save-load", "headless", "validate save/load round trip", godot_smoke("--smoke-save-load")),
    Step("smoke-menu-flow", "headless", "validate title, pause, and settings flow", godot_smoke("--smoke-menu-flow")),
    Step("smoke-audio-director", "headless", "validate generated fallback audio streams", godot_smoke("--smoke-audio-director")),
    Step("smoke-export-config", "headless", "validate export preset configuration", godot_smoke("--smoke-export-config")),
    Step("smoke-render-frame", "visual", "verify a visible rendered frame is non-empty", render_frame),
    Step("screenshots", "visual", "capture screenshot review contact sheet", screenshot_starts),
    Step("release-build-libraries", "release", "build desktop release GDExtension libraries", cargo_release_builds),
    Step("smoke-release-libraries", "release", "validate release GDExtension library paths", godot_smoke("--smoke-release-libraries")),
]

TIER_GROUPS = {
    "quick": {"quick"},
    "headless": {"quick", "headless"},
    "visual": {"quick", "headless", "visual"},
    "release": {"quick", "headless", "release"},
    "all": {"quick", "headless", "visual", "release"},
}


def parse_csv(values: list[str]) -> set[str]:
    result: set[str] = set()
    for value in values:
        result.update(item.strip() for item in value.split(",") if item.strip())
    return result


def select_steps(args: argparse.Namespace) -> list[Step]:
    steps_by_id = {step.id: step for step in STEPS}
    only = parse_csv(args.only)
    skip = parse_csv(args.skip)
    if only:
        unknown = sorted(only - set(steps_by_id))
        if unknown:
            raise SystemExit(f"unknown --only step(s): {', '.join(unknown)}")
        selected = [steps_by_id[step_id] for step_id in steps_by_id if step_id in only]
    else:
        groups = TIER_GROUPS[args.tier]
        selected = [step for step in STEPS if step.group in groups]

    unknown_skip = sorted(skip - set(steps_by_id))
    if unknown_skip:
        raise SystemExit(f"unknown --skip step(s): {', '.join(unknown_skip)}")
    return [step for step in selected if step.id not in skip]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tier", choices=sorted(TIER_GROUPS), default="quick")
    parser.add_argument("--godot", default=str(DEFAULT_GODOT))
    parser.add_argument("--only", action="append", default=[], help="Comma-separated step ids to run.")
    parser.add_argument("--skip", action="append", default=[], help="Comma-separated step ids to skip.")
    parser.add_argument("--list", action="store_true", help="List available steps and exit.")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without running them.")
    parser.add_argument("--scene", default="all", help="Scene id for the visual screenshot step.")
    parser.add_argument("--visual-scope", choices=["starts", "locations"], default="starts")
    parser.add_argument("--visual-style", choices=["sunlit_mmo", "classic_dark"], default="sunlit_mmo")
    return parser.parse_args()


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(line_buffering=True)
    args = parse_args()
    if args.list:
        for step in STEPS:
            print(f"{step.id}\t{step.group}\t{step.description}")
        return 0

    runner = Runner(args)
    selected = select_steps(args)
    print(f"automated-tests tier={args.tier} steps={len(selected)} godot={runner.godot}")
    for step in selected:
        code = step.action(runner, step)
        if code != 0:
            print(f"\nFAIL {step.id} exited with {code}", file=sys.stderr)
            return code

    print(f"\nautomated-tests status=PASS tier={args.tier} steps={len(selected)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
