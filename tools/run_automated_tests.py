#!/usr/bin/env python3
"""Run Dream Coastline automated test tiers."""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GODOT = Path(os.environ.get("GODOT_PATH", "/Applications/Godot.app/Contents/MacOS/Godot"))
RELEASE_EXPORT_LOG_DIR = ROOT / "artifacts" / "release-export-logs"
ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-9;]*m")
ALLOWED_RELEASE_EXPORT_GODOT_PATHS = {
    "res://.godot/global_script_class_cache.cfg",
    "res://.godot/uid_cache.bin",
}
ALLOWED_RELEASE_EXPORT_GODOT_PREFIXES = (
    "res://.godot/imported/",
    "res://.godot/exported/",
)
FORBIDDEN_RELEASE_EXPORT_PREFIXES = (
    "res://.zig-cache/",
    "res://.claude/",
    "res://.cursor/",
    "res://.idea/",
    "res://.tmp/",
    "res://.venv/",
    "res://artifacts/",
    "res://builds/",
    "res://docs/",
    "res://five/",
    "res://node_modules/",
    "res://target/",
    "res://tools/",
    "res://addons/dialogic/Editor/",
    "res://addons/yarn_spinner/editor/",
    "res://addons/yarn_spinner/templates/",
)
FORBIDDEN_RELEASE_EXPORT_FILES = {
    "res://.DS_Store",
    "res://.env",
    "res://deepseek.local.cfg",
}
FORBIDDEN_RELEASE_EXPORT_SUFFIXES = (".log",)

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

    def run_godot(
        self,
        step: Step,
        flag: str | None = None,
        *,
        headless: bool = True,
        quit_after: int = 100,
        expected_output: str | None = None,
    ) -> int:
        command = [str(self.godot), "--path", str(ROOT)]
        if headless:
            command.append("--headless")
        if flag is None:
            command.append("--quit")
        else:
            command.extend(["--quit-after", str(quit_after), "--", flag])
        print(f"\n==> {step.id}: {step.description}")
        print(format_command(command))
        if self.args.dry_run:
            return 0
        project_file = ROOT / "project.godot"
        project_before = project_file.read_bytes() if project_file.exists() else None
        try:
            result = subprocess.run(
                command,
                cwd=ROOT,
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
            )
        except FileNotFoundError as error:
            print(f"missing executable: {error.filename}", file=sys.stderr)
            return 127
        finally:
            restore_project_file(project_file, project_before)
        if result.stdout:
            print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
        if "SCRIPT ERROR:" in result.stdout or "Failed to load script" in result.stdout:
            return 1
        if expected_output is not None and expected_output not in result.stdout:
            print(f"{step.id}: missing expected output: {expected_output}", file=sys.stderr)
            return 1
        return result.returncode

    def run_godot_editor_import(self, step: Step) -> int:
        command = [str(self.godot), "--editor", "--headless", "--path", str(ROOT), "--quit"]
        if self.args.dry_run:
            return self.run_command(step, command)

        project_file = ROOT / "project.godot"
        project_before = project_file.read_bytes() if project_file.exists() else None
        import_files_before = source_import_files()
        print(f"\n==> {step.id}: {step.description}")
        print(format_command(command))
        try:
            result = subprocess.run(
                command,
                cwd=ROOT,
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
            )
        except FileNotFoundError as error:
            print(f"missing executable: {error.filename}", file=sys.stderr)
            return 127
        finally:
            restore_project_file(project_file, project_before)
            for path in source_import_files() - import_files_before:
                try:
                    path.unlink()
                except FileNotFoundError:
                    pass
        if result.stdout:
            print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
        if "SCRIPT ERROR:" in result.stdout or "Failed to load script" in result.stdout:
            return 1
        return result.returncode


def format_command(command: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in command)


def source_import_files() -> set[Path]:
    return {
        path
        for path in ROOT.rglob("*.import")
        if ".git" not in path.parts and ".godot" not in path.parts and path.is_file()
    }


def restore_project_file(project_file: Path, project_before: bytes | None) -> None:
    if project_before is not None and project_file.exists() and project_file.read_bytes() != project_before:
        project_file.write_bytes(project_before)


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


def story_action_display_names(runner: Runner, step: Step) -> int:
    print(f"\n==> {step.id}: {step.description}")
    sections = ("items", "choices", "build_actions", "encounters", "combos")
    internal_id_pattern = re.compile(r"^[a-z0-9_-]+$")
    if runner.args.dry_run:
        print("validate player-facing labels in data/story_scenes/*.json")
        return 0
    failures: list[str] = []
    checked = 0
    for path in sorted((ROOT / "data" / "story_scenes").glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        locations = data.get("locations", {})
        for location_id, location in locations.items():
            if not isinstance(location, dict):
                continue
            for section in sections:
                records = location.get(section, {})
                if not isinstance(records, dict):
                    continue
                for action_id, record in records.items():
                    if not isinstance(record, dict):
                        failures.append(f"{path.name}:{location_id}.{section}.{action_id}: record is not a dictionary")
                        continue
                    checked += 1
                    label = str(record.get("name", "")).strip()
                    if not label:
                        failures.append(f"{path.name}:{location_id}.{section}.{action_id}: missing name")
                    elif internal_id_pattern.fullmatch(label):
                        failures.append(f"{path.name}:{location_id}.{section}.{action_id}: internal-looking name '{label}'")
            glyph_actions = location.get("glyph_actions", {})
            if isinstance(glyph_actions, dict):
                for action_id, record in glyph_actions.items():
                    if not isinstance(record, dict):
                        failures.append(f"{path.name}:{location_id}.glyph_actions.{action_id}: record is not a dictionary")
                        continue
                    label = str(record.get("name", "")).strip()
                    if label:
                        checked += 1
                        if internal_id_pattern.fullmatch(label):
                            failures.append(
                                f"{path.name}:{location_id}.glyph_actions.{action_id}: internal-looking name '{label}'"
                            )
            exits = location.get("exits", {})
            if isinstance(exits, dict):
                for exit_id, label_raw in exits.items():
                    checked += 1
                    label = str(label_raw).strip()
                    if not label:
                        failures.append(f"{path.name}:{location_id}.exits.{exit_id}: missing label")
                    elif internal_id_pattern.fullmatch(label):
                        failures.append(f"{path.name}:{location_id}.exits.{exit_id}: internal-looking label '{label}'")
            combat = location.get("combat", {})
            if isinstance(combat, dict) and combat:
                for field in ("hidden_name", "revealed_name"):
                    checked += 1
                    label = str(combat.get(field, "")).strip()
                    if not label:
                        failures.append(f"{path.name}:{location_id}.combat.{field}: missing label")
                    elif internal_id_pattern.fullmatch(label):
                        failures.append(f"{path.name}:{location_id}.combat.{field}: internal-looking label '{label}'")
                spells = combat.get("spells", {})
                if isinstance(spells, dict):
                    for spell_id, spell in spells.items():
                        if not isinstance(spell, dict):
                            failures.append(f"{path.name}:{location_id}.combat.spells.{spell_id}: record is not a dictionary")
                            continue
                        label = str(spell.get("name", "")).strip()
                        if label:
                            checked += 1
                            if internal_id_pattern.fullmatch(label):
                                failures.append(
                                    f"{path.name}:{location_id}.combat.spells.{spell_id}: internal-looking name '{label}'"
                                )
    if failures:
        for failure in failures:
            print(f"story-action-display-names: {failure}", file=sys.stderr)
        return 1
    print(f"story-action-display-names status=PASS records={checked}")
    return 0


def nova_manual_route_checklist(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/build_nova_manual_route_checklist.py", "--check")


def equipment_catalog(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/validate_equipment_catalog.py")


def supply_catalog(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/validate_supply_catalog.py")


def character_visual_models(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/validate_character_visual_models.py")


def character_voice_profiles(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/validate_character_voice_profiles.py")


def action_voice_lines(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/validate_action_voice_manifest.py")


def audio_listening_checklist(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/build_audio_listening_checklist.py", "--check")


def minimax_action_voice_dry_run(runner: Runner, step: Step) -> int:
    code = runner.run_command(step, ["node", "--check", "tools/minimax_audio_generate.mjs"])
    if code != 0:
        return code
    return runner.run_command(
        step,
        [
            "node",
            "tools/minimax_audio_generate.mjs",
            "--type",
            "action-voice",
            "--scene-id",
            "00-prologue-lights-out",
            "--cue-id",
            "AVL-00-001",
            "--dry-run",
        ],
    )


def character_development_profiles(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/validate_character_development_profiles.py")


def story_review_panels(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/validate_story_review_panels.py")


def playable_backdrops(runner: Runner, step: Step) -> int:
    print(f"\n==> {step.id}: {step.description}")
    if runner.args.dry_run:
        print("validate data/visual_scenes illustrated_backdrop paths")
        return 0
    failures: list[str] = []
    checked = 0
    for path in sorted((ROOT / "data" / "visual_scenes").glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        for location_id, visual in data.get("locations", {}).items():
            if not isinstance(visual, dict):
                continue
            backdrop = str(visual.get("illustrated_backdrop", "")).strip()
            if not backdrop:
                failures.append(f"{path.name}:{location_id}: missing illustrated_backdrop")
                continue
            checked += 1
            if "/story_review/" in backdrop:
                failures.append(f"{path.name}:{location_id}: uses story_review backdrop {backdrop}")
            if backdrop.startswith("res://"):
                backdrop_path = ROOT / backdrop.removeprefix("res://")
                if not backdrop_path.exists():
                    failures.append(f"{path.name}:{location_id}: missing backdrop file {backdrop}")
    if failures:
        for failure in failures:
            print(f"playable-backdrops: {failure}", file=sys.stderr)
        return 1
    print(f"playable-backdrops status=PASS locations={checked}")
    return 0


def playable_backdrop_imagen_manifest(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/build_playable_backdrop_imagen_manifest.py", "--check")


def dialogic_timelines(runner: Runner, step: Step) -> int:
    return runner.run_python(step, "tools/validate_dialogic_timelines.py")


def story_movie_smoke(runner: Runner, step: Step) -> int:
    code = runner.run_python(step, "tools/build_story_movie.py", "--check-deps")
    if code != 0:
        return code
    return runner.run_python(
        step,
        "tools/build_story_movie.py",
        "--scene",
        "00-prologue-lights-out",
        "--output",
        "artifacts/story-movie/00-prologue-lights-out-movie-smoke.mp4",
        "--size",
        "640x360",
        "--fps",
        "6",
        "--min-seconds",
        "0.4",
        "--max-seconds",
        "0.8",
        "--title-seconds",
        "0.6",
        "--no-sfx",
        "--no-voices",
    )


def audio_mix_audit(runner: Runner, step: Step) -> int:
    return runner.run_python(
        step,
        "tools/audit_audio_mix.py",
        "--json-output",
        "artifacts/audio-mix-audit/latest.json",
    )


def legacy_review_entrypoint_isolation(runner: Runner, step: Step) -> int:
    command = [
        sys.executable,
        "tools/record_story_review.py",
        "--scene",
        "00-prologue-lights-out",
        "--output",
        "artifacts/story-review/legacy-isolation-smoke",
    ]
    print(f"\n==> {step.id}: {step.description}")
    print(format_command(command))
    if runner.args.dry_run:
        return 0
    result = subprocess.run(
        command,
        cwd=ROOT,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if result.stdout:
        print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
    if result.returncode != 2:
        print(f"legacy-entrypoint-isolation: expected exit 2, got {result.returncode}", file=sys.stderr)
        return 1
    if "legacy-entrypoint-disabled" not in result.stdout or "res://src/nova/main.tscn" not in result.stdout:
        print("legacy-entrypoint-isolation: missing current-entrypoint guidance", file=sys.stderr)
        return 1
    return 0


def cargo_build(runner: Runner, step: Step) -> int:
    return runner.run_command(step, ["cargo", "build"])


def cargo_release_builds(runner: Runner, step: Step) -> int:
    return runner.run_command(step, ["tools/build_release_libraries.sh"])


def desktop_release_exports(runner: Runner, step: Step) -> int:
    outputs = [
        ROOT / "builds" / "macos" / "Dream Coastline.zip",
        ROOT / "builds" / "windows" / "Dream Coastline.exe",
        ROOT / "builds" / "windows" / "Dream Coastline.pck",
        ROOT / "builds" / "linux" / "dream-coastline.x86_64",
        ROOT / "builds" / "linux" / "dream-coastline.pck",
    ]
    if not runner.args.dry_run:
        for path in outputs:
            try:
                path.unlink()
            except FileNotFoundError:
                pass

    exports = [
        ("macOS", ROOT / "builds" / "macos" / "Dream Coastline.zip"),
        ("Windows Desktop", ROOT / "builds" / "windows" / "Dream Coastline.exe"),
        ("Linux/X11", ROOT / "builds" / "linux" / "dream-coastline.x86_64"),
    ]
    for _preset, output_path in exports:
        output_path.parent.mkdir(parents=True, exist_ok=True)

    if not runner.args.dry_run:
        RELEASE_EXPORT_LOG_DIR.mkdir(parents=True, exist_ok=True)
        for log_path in RELEASE_EXPORT_LOG_DIR.glob("*.log"):
            log_path.unlink()

    for preset, output_path in exports:
        code = run_godot_release_export(runner, step, preset, output_path)
        if code != 0:
            return code
    if runner.args.dry_run:
        return 0
    return validate_desktop_release_outputs()


def run_godot_release_export(runner: Runner, step: Step, preset: str, output_path: Path) -> int:
    command = [
        str(runner.godot),
        "--path",
        str(ROOT),
        "--headless",
        "--export-release",
        preset,
        str(output_path),
    ]
    log_path = RELEASE_EXPORT_LOG_DIR / f"{release_export_slug(preset)}.log"
    print(f"\n==> {step.id}: {preset} release export")
    print(format_command(command))
    if runner.args.dry_run:
        return 0
    project_file = ROOT / "project.godot"
    project_before = project_file.read_bytes() if project_file.exists() else None
    try:
        result = subprocess.run(
            command,
            cwd=ROOT,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
    except FileNotFoundError as error:
        print(f"missing executable: {error.filename}", file=sys.stderr)
        return 127
    finally:
        restore_project_file(project_file, project_before)

    log_path.write_text(result.stdout, encoding="utf-8")
    line_count = len(result.stdout.splitlines())
    print(f"release export log: {log_path.relative_to(ROOT)} lines={line_count}")

    if "SCRIPT ERROR:" in result.stdout or "Failed to load script" in result.stdout:
        print(f"{step.id}: Godot script/load error during {preset} export; see {log_path.relative_to(ROOT)}", file=sys.stderr)
        print_recent_output(result.stdout)
        return 1
    if result.returncode != 0:
        print(f"{step.id}: {preset} export exited {result.returncode}; see {log_path.relative_to(ROOT)}", file=sys.stderr)
        print_recent_output(result.stdout)
        return result.returncode

    forbidden = forbidden_release_export_lines(result.stdout)
    if forbidden:
        for line in forbidden[:20]:
            print(f"{step.id}: forbidden packaged resource in {preset}: {line}", file=sys.stderr)
        if len(forbidden) > 20:
            print(f"{step.id}: ... {len(forbidden) - 20} more forbidden packaged resources", file=sys.stderr)
        print(f"{step.id}: full export log: {log_path.relative_to(ROOT)}", file=sys.stderr)
        return 1
    return 0


def release_export_slug(preset: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", preset.lower()).strip("-")
    return slug or "export"


def forbidden_release_export_lines(output: str) -> list[str]:
    forbidden: list[str] = []
    for line in output.splitlines():
        marker = "Storing File: "
        if marker not in line:
            continue
        stored_path = strip_ansi(line.split(marker, 1)[1]).strip()
        if (
            stored_path.startswith("res://.godot/")
            and stored_path not in ALLOWED_RELEASE_EXPORT_GODOT_PATHS
            and not any(stored_path.startswith(prefix) for prefix in ALLOWED_RELEASE_EXPORT_GODOT_PREFIXES)
        ):
            forbidden.append(stored_path)
        elif stored_path in FORBIDDEN_RELEASE_EXPORT_FILES:
            forbidden.append(stored_path)
        elif any(stored_path.startswith(prefix) for prefix in FORBIDDEN_RELEASE_EXPORT_PREFIXES):
            forbidden.append(stored_path)
        elif any(stored_path.endswith(suffix) for suffix in FORBIDDEN_RELEASE_EXPORT_SUFFIXES):
            forbidden.append(stored_path)
    return forbidden


def strip_ansi(text: str) -> str:
    return ANSI_ESCAPE_RE.sub("", text)


def print_recent_output(output: str, line_count: int = 30) -> None:
    lines = output.splitlines()
    if not lines:
        return
    print("recent output:", file=sys.stderr)
    for line in lines[-line_count:]:
        print(line, file=sys.stderr)


def validate_desktop_release_outputs() -> int:
    expected_files = {
        "macOS zip": (ROOT / "builds" / "macos" / "Dream Coastline.zip", 50 * 1024 * 1024),
        "Windows executable": (ROOT / "builds" / "windows" / "Dream Coastline.exe", 20 * 1024 * 1024),
        "Windows pack": (ROOT / "builds" / "windows" / "Dream Coastline.pck", 50 * 1024 * 1024),
        "Linux executable": (ROOT / "builds" / "linux" / "dream-coastline.x86_64", 20 * 1024 * 1024),
        "Linux pack": (ROOT / "builds" / "linux" / "dream-coastline.pck", 50 * 1024 * 1024),
    }
    failures: list[str] = []
    for label, (path, min_size) in expected_files.items():
        if not path.exists():
            failures.append(f"{label} missing at {path.relative_to(ROOT)}")
            continue
        size = path.stat().st_size
        if size < min_size:
            failures.append(f"{label} too small: {path.relative_to(ROOT)} size={size}")

    mac_zip = ROOT / "builds" / "macos" / "Dream Coastline.zip"
    if mac_zip.exists():
        try:
            with zipfile.ZipFile(mac_zip) as archive:
                names = set(archive.namelist())
        except zipfile.BadZipFile:
            failures.append("macOS zip is not a valid zip archive")
        else:
            required_entries = {
                "Dream Coastline.app/Contents/MacOS/Dream Coastline",
                "Dream Coastline.app/Contents/Resources/Dream Coastline.pck",
                "Dream Coastline.app/Contents/Info.plist",
            }
            for entry in sorted(required_entries - names):
                failures.append(f"macOS zip missing {entry}")

    linux_binary = ROOT / "builds" / "linux" / "dream-coastline.x86_64"
    if linux_binary.exists() and not linux_binary.stat().st_mode & 0o111:
        failures.append("Linux executable is not marked executable")

    if failures:
        for failure in failures:
            print(f"desktop-release-exports: {failure}", file=sys.stderr)
        return 1
    print("desktop-release-exports status=PASS artifacts=5")
    return 0


def godot_load(runner: Runner, step: Step) -> int:
    return runner.run_godot(step, None)


def godot_import_cache(runner: Runner, step: Step) -> int:
    return runner.run_godot_editor_import(step)


def godot_smoke(flag: str, *, quit_after: int = 100, expected_output: str | None = None) -> StepAction:
    def action(runner: Runner, step: Step) -> int:
        return runner.run_godot(step, flag, quit_after=quit_after, expected_output=expected_output)

    return action


def render_frame(runner: Runner, step: Step) -> int:
    return runner.run_godot(
        step,
        "--capture-nova-screenshot",
        headless=False,
        quit_after=120,
        expected_output="nova-screenshot status=PASS",
    )


def dialogic_runtime_smoke(runner: Runner, step: Step) -> int:
    return runner.run_godot(
        step,
        "--smoke-dialogic-runtime",
        headless=False,
        quit_after=10000,
        expected_output="dialogic-runtime-smoke status=PASS",
    )


def keyboard_dialogic_smoke(runner: Runner, step: Step) -> int:
    return runner.run_godot(
        step,
        "--smoke-nova-keyboard-dialogic",
        headless=False,
        quit_after=10000,
        expected_output="nova-keyboard-dialogic-smoke status=PASS",
    )


def scene_screenshots(
    runner: Runner,
    step: Step,
    output: Path,
    scope: str,
    *,
    quit_after: int | None = None,
) -> int:
    command = [
        sys.executable,
        "tools/capture_scene_screenshots.py",
        "--godot",
        str(runner.godot),
        "--output",
        str(output),
        "--scope",
        scope,
        "--visual-style",
        runner.args.visual_style,
    ]
    if quit_after is not None:
        command.extend(["--quit-after", str(quit_after)])
    if runner.args.scene != "all":
        command.extend(["--scene", runner.args.scene])
    code = runner.run_command(step, command)
    if code != 0 or runner.args.dry_run:
        return code
    validate_command = [
        sys.executable,
        "tools/validate_scene_screenshot_manifest.py",
        "--manifest",
        str(output / "manifest.json"),
        "--scope",
        scope,
        "--visual-style",
        runner.args.visual_style,
    ]
    validate_command.append("--require-illustrated-backdrop")
    return runner.run_command(step, validate_command)


def screenshot_starts(runner: Runner, step: Step) -> int:
    return scene_screenshots(runner, step, ROOT / "artifacts" / "scene-screenshots" / "latest", runner.args.visual_scope)


def route_screenshots(runner: Runner, step: Step) -> int:
    return scene_screenshots(runner, step, ROOT / "artifacts" / "scene-screenshots" / "route-latest", "route")


def route_full_screenshots(runner: Runner, step: Step) -> int:
    return scene_screenshots(
        runner,
        step,
        ROOT / "artifacts" / "scene-screenshots" / "route-full-latest",
        "route-full",
        quit_after=900,
    )


STEPS: list[Step] = [
    Step("json-data", "quick", "parse data JSON files", validate_json_data),
    Step("python-tools", "quick", "compile top-level Python tools", py_compile_tools),
    Step("ascii-scenes", "quick", "verify ASCII walkthrough, duration, and UI gates", ascii_scene_walkthroughs),
    Step("story-continuity", "quick", "validate cross-scene continuity contracts", story_continuity),
    Step("story-action-display-names", "quick", "validate player-facing story action labels", story_action_display_names),
    Step("nova-manual-route-checklist", "quick", "validate generated Nova full-route manual QA checklist", nova_manual_route_checklist),
    Step("equipment-catalog", "quick", "validate equipment carrier catalog", equipment_catalog),
    Step("supply-catalog", "quick", "validate supply and consumable carrier catalog", supply_catalog),
    Step("character-voice-profiles", "quick", "validate character voice and dialogue contracts", character_voice_profiles),
    Step("action-voice-lines", "quick", "validate per-action voice-line coverage", action_voice_lines),
    Step("audio-listening-checklist", "quick", "validate generated audio listening QA checklist", audio_listening_checklist),
    Step("minimax-action-voice-dry-run", "quick", "validate MiniMax action voice job building", minimax_action_voice_dry_run),
    Step(
        "character-development-profiles",
        "quick",
        "validate character personality and development contracts",
        character_development_profiles,
    ),
    Step("character-visual-models", "quick", "validate main character visual model contracts", character_visual_models),
    Step("story-review-panels", "quick", "validate story review panel coverage and character refs", story_review_panels),
    Step("playable-backdrops", "quick", "validate playable-location backdrop coverage", playable_backdrops),
    Step(
        "playable-backdrop-imagen-manifest",
        "quick",
        "validate Imagen final-art prompt coverage for playable backdrops",
        playable_backdrop_imagen_manifest,
    ),
    Step("dialogic-timelines", "quick", "validate Dialogic timeline coverage and drift", dialogic_timelines),
    Step("story-movie-smoke", "quick", "validate reproducible story movie generation dependencies and output", story_movie_smoke),
    Step(
        "legacy-entrypoint-isolation",
        "quick",
        "ensure legacy story-review recorder is explicit opt-in",
        legacy_review_entrypoint_isolation,
    ),
    Step("godot-import-cache", "quick", "prime Godot script class and asset import cache", godot_import_cache),
    Step("godot-load", "quick", "load the Godot project headlessly", godot_load),
    Step(
        "smoke-nova-runtime",
        "quick",
        "validate Nova exploration and VN cutscene runtime",
        godot_smoke("--smoke-nova-runtime", expected_output="nova-runtime-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-progression",
        "quick",
        "validate Nova first-scene canonical progression",
        godot_smoke("--smoke-nova-progression", expected_output="nova-progression-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-choices",
        "quick",
        "validate Nova location choices and route flags",
        godot_smoke("--smoke-nova-choices", expected_output="nova-choice-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-all-scenes",
        "quick",
        "validate Nova narrative actions across all scenes",
        godot_smoke("--smoke-nova-all-scenes", expected_output="nova-all-scenes-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-manual-route",
        "quick",
        "validate Nova canonical walkthrough commands in order",
        godot_smoke("--smoke-nova-manual-route", expected_output="nova-manual-route-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-ui-manual-route",
        "quick",
        "validate Nova walkthrough commands through visible action-menu choices",
        godot_smoke("--smoke-nova-ui-manual-route", expected_output="nova-ui-manual-route-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-mouse-route",
        "quick",
        "validate Nova walkthrough commands through action-menu button click semantics",
        godot_smoke("--smoke-nova-mouse-route", expected_output="nova-mouse-route-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-keyboard-route",
        "quick",
        "validate Nova walkthrough commands through keyboard menu navigation",
        godot_smoke("--smoke-nova-keyboard-route", expected_output="nova-keyboard-route-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-gamepad-route",
        "quick",
        "validate Nova walkthrough commands through gamepad menu navigation",
        godot_smoke("--smoke-nova-gamepad-route", expected_output="nova-gamepad-route-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-save-continue",
        "quick",
        "validate Nova-native save and continue restoration",
        godot_smoke("--smoke-nova-save-continue", expected_output="nova-save-continue-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-pause-flow",
        "quick",
        "validate Nova pause, save, resume, and return-to-title flow",
        godot_smoke("--smoke-nova-pause-flow", expected_output="nova-pause-flow-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-gamepad-pause-flow",
        "quick",
        "validate Nova pause, save, resume, and return-to-title flow through gamepad input",
        godot_smoke("--smoke-nova-gamepad-pause-flow", expected_output="nova-gamepad-pause-flow-smoke status=PASS"),
    ),
    Step(
        "smoke-nova-assets",
        "quick",
        "validate Nova splash, character, and audio assets",
        godot_smoke("--smoke-nova-assets", expected_output="nova-assets-smoke status=PASS"),
    ),
    Step(
        "smoke-story-audio-targets",
        "quick",
        "validate generated story audio targets",
        godot_smoke("--smoke-story-audio-targets", expected_output="story-audio-targets-smoke status=PASS"),
    ),
    Step(
        "smoke-dialogic-bridge",
        "quick",
        "validate Dialogic addon install and timeline bridge",
        godot_smoke("--smoke-dialogic-bridge", expected_output="dialogic-bridge-smoke status=PASS"),
    ),
    Step("smoke-dialogic-runtime", "visual", "validate visible Dialogic playback and flag writeback", dialogic_runtime_smoke),
    Step(
        "smoke-nova-keyboard-dialogic",
        "visual",
        "validate keyboard action-menu input through visible Dialogic playback",
        keyboard_dialogic_smoke,
    ),
    Step("capture-nova-screenshot", "visual", "capture a visible Nova runtime frame", render_frame),
    Step("screenshots", "visual", "capture screenshot review contact sheet", screenshot_starts),
    Step("route-screenshots", "visual", "capture walkthrough route checkpoint review sheet", route_screenshots),
    Step("route-full-screenshots", "visual", "capture screenshot evidence for every walkthrough command", route_full_screenshots),
    Step(
        "smoke-export-config",
        "release",
        "validate desktop export presets and release branding",
        godot_smoke("--smoke-export-config", expected_output="export-config-smoke status=PASS"),
    ),
    Step("cargo-release-libraries", "release", "build desktop release libraries for export presets", cargo_release_builds),
    Step(
        "smoke-release-libraries",
        "release",
        "validate release libraries required by export presets",
        godot_smoke("--smoke-release-libraries", expected_output="release-libraries-smoke status=PASS"),
    ),
    Step("audio-mix-audit", "release", "audit generated audio files for release mix hygiene", audio_mix_audit),
    Step("desktop-release-exports", "release", "export and validate desktop release artifacts", desktop_release_exports),
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
    parser.add_argument("--visual-scope", choices=["starts", "locations", "route", "route-full"], default="starts")
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
