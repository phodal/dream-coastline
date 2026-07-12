#!/usr/bin/env python3
"""Validate Nova screenshot contact-sheet manifests for review readiness."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STORY_DIR = ROOT / "data" / "story_scenes"
DEFAULT_MANIFEST = ROOT / "artifacts" / "scene-screenshots" / "latest" / "manifest.json"


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def expected_scene_paths(scene_filter: str) -> list[Path]:
    scene_paths = sorted(STORY_DIR.glob("*.json"))
    if scene_filter != "all":
        scene_paths = [STORY_DIR / f"{scene_filter}.json"]
    return scene_paths


def expected_pairs(scope: str, scene_filter: str) -> set[tuple[str, str]]:
    pairs: set[tuple[str, str]] = set()
    for path in expected_scene_paths(scene_filter):
        scene = load_json(path)
        scene_id = str(scene.get("id", path.stem))
        locations = scene.get("locations", {})
        if not isinstance(locations, dict) or not locations:
            continue
        if scope == "starts":
            start_location = str(scene.get("start", next(iter(locations))))
            pairs.add((scene_id, start_location))
        else:
            for location_id in locations:
                pairs.add((scene_id, str(location_id)))
    return pairs


def expected_route_keys(scene_filter: str) -> set[tuple[str, str]]:
    keys: set[tuple[str, str]] = set()
    for path in expected_scene_paths(scene_filter):
        scene = load_json(path)
        scene_id = str(scene.get("id", path.stem))
        keys.add((scene_id, "start"))
        keys.add((scene_id, "mid"))
        keys.add((scene_id, "before_end"))
    keys.add(("route", "final"))
    return keys


def expected_route_full_keys(scene_filter: str) -> set[tuple[str, int, str]]:
    keys: set[tuple[str, int, str]] = set()
    for path in expected_scene_paths(scene_filter):
        scene = load_json(path)
        scene_id = str(scene.get("id", path.stem))
        commands = scene.get("walkthrough", [])
        if not isinstance(commands, list):
            continue
        for index, command in enumerate(commands, 1):
            keys.add((scene_id, index, str(command)))
    return keys


def validate_manifest(
    path: Path,
    expected_scope: str | None,
    expected_style: str | None,
    require_illustrated_backdrop: bool,
) -> list[str]:
    failures: list[str] = []
    manifest = load_json(path)
    if not isinstance(manifest, dict):
        return [f"{path} must contain a JSON object"]

    output_dir = path.parent
    index_path = output_dir / "index.html"
    if not index_path.exists():
        failures.append(f"missing contact sheet: {index_path.relative_to(ROOT)}")

    if manifest.get("generated_by") != "--capture-scene-screenshots":
        failures.append("generated_by must be --capture-scene-screenshots")
    if manifest.get("architecture") != "nova":
        failures.append("architecture must be nova")
    if expected_scope and manifest.get("scope") != expected_scope:
        failures.append(f"scope must be {expected_scope}")
    if expected_style and manifest.get("visual_style") != expected_style:
        failures.append(f"visual_style must be {expected_style}")
    if manifest.get("failures") not in ([], None):
        failures.append(f"manifest failures must be empty: {manifest.get('failures')}")

    screenshots = manifest.get("screenshots")
    if not isinstance(screenshots, list) or not screenshots:
        failures.append("screenshots must be a non-empty list")
        return failures
    if manifest.get("screenshot_count") != len(screenshots):
        failures.append("screenshot_count must match screenshots length")
    if manifest.get("asset_backed_count") != len(screenshots):
        failures.append("asset_backed_count must cover every screenshot")
    if manifest.get("framework_placeholder_count") != 0:
        failures.append("framework_placeholder_count must be 0")
    if manifest.get("procedural_fallback_count") != 0:
        failures.append("procedural_fallback_count must be 0")

    scope = str(manifest.get("scope", expected_scope or ""))
    route_seen: set[tuple[str, str]] = set()
    route_full_seen: set[tuple[str, int, str]] = set()
    seen: set[tuple[str, str]] = set()
    for index, shot in enumerate(screenshots):
        label = f"screenshots[{index}]"
        if not isinstance(shot, dict):
            failures.append(f"{label} must be an object")
            continue
        scene_id = str(shot.get("scene_id", ""))
        location_id = str(shot.get("location_id", ""))
        seen.add((scene_id, location_id))
        if scope in {"route", "route-full"}:
            route_source_scene_id = str(shot.get("route_source_scene_id", ""))
            checkpoint = str(shot.get("checkpoint", ""))
            if not route_source_scene_id:
                failures.append(f"{label}.route_source_scene_id must be non-empty for route scope")
            choice_labels = shot.get("choice_labels")
            if not isinstance(choice_labels, list) or not choice_labels:
                failures.append(f"{label}.choice_labels must be a non-empty list for route scope")
            elif any(not str(choice_label).strip() for choice_label in choice_labels):
                failures.append(f"{label}.choice_labels must not contain blank player-facing labels")
            if scope == "route":
                route_seen.add((route_source_scene_id, checkpoint))
                if checkpoint not in {"start", "mid", "before_end", "final"}:
                    failures.append(f"{label}.checkpoint is invalid for route scope")
            else:
                command = str(shot.get("command", ""))
                scene_command_index = shot.get("scene_command_index")
                scene_commands_total = shot.get("scene_commands_total")
                command_index = shot.get("command_index")
                commands_total = shot.get("commands_total")
                if checkpoint != "command":
                    failures.append(f"{label}.checkpoint must be command for route-full scope")
                if not command:
                    failures.append(f"{label}.command must be non-empty for route-full scope")
                if not isinstance(scene_command_index, int) or scene_command_index <= 0:
                    failures.append(f"{label}.scene_command_index must be a positive integer")
                    scene_command_index_value = -1
                else:
                    scene_command_index_value = scene_command_index
                if not isinstance(scene_commands_total, int) or scene_commands_total <= 0:
                    failures.append(f"{label}.scene_commands_total must be a positive integer")
                elif isinstance(scene_command_index, int) and scene_command_index > scene_commands_total:
                    failures.append(f"{label}.scene_command_index exceeds scene_commands_total")
                route_command_count = manifest.get("route_command_count")
                if not isinstance(command_index, int) or command_index <= 0:
                    failures.append(f"{label}.command_index must be a positive integer")
                if not isinstance(commands_total, int) or commands_total <= 0:
                    failures.append(f"{label}.commands_total must be a positive integer")
                elif isinstance(route_command_count, int) and commands_total != route_command_count:
                    failures.append(f"{label}.commands_total must equal route_command_count")
                if isinstance(command_index, int) and isinstance(commands_total, int) and command_index > commands_total:
                    failures.append(f"{label}.command_index exceeds commands_total")
                if scene_command_index_value > 0:
                    route_full_seen.add((route_source_scene_id, scene_command_index_value, command))
        if shot.get("ok") is not True:
            failures.append(f"{label}.ok must be true")
        if shot.get("asset_status") != "asset_backed":
            failures.append(f"{label}.asset_status must be asset_backed")
        if require_illustrated_backdrop and not str(shot.get("asset_runtime_path", "")).strip():
            failures.append(f"{label}.asset_runtime_path must point to an illustrated backdrop")
        if require_illustrated_backdrop and shot.get("asset_loaded") is not True:
            failures.append(f"{label}.asset_loaded must be true for the illustrated backdrop")
        if require_illustrated_backdrop and "/playable/" not in str(shot.get("asset_runtime_path", "")):
            failures.append(f"{label}.asset_runtime_path must point to playable location art")
        if shot.get("hotspot_markers_visible") is True:
            failures.append(f"{label}.hotspot_markers_visible must be false for review screenshots")
        if shot.get("debug_flags_visible") is True:
            failures.append(f"{label}.debug_flags_visible must be false for review screenshots")
        for field in ["scene_id", "scene_title", "location_id", "location_name", "terrain", "visual_family", "visual_style", "asset_scene"]:
            if not str(shot.get(field, "")).strip():
                failures.append(f"{label}.{field} must be non-empty")
        image_name = str(shot.get("file", ""))
        image_path = output_dir / image_name
        if not image_name.endswith(".png"):
            failures.append(f"{label}.file must be a PNG filename")
        elif not image_path.exists():
            failures.append(f"{label}.file is missing: {image_path.relative_to(ROOT)}")
        elif image_path.stat().st_size < 1024:
            failures.append(f"{label}.file is too small for review: {image_path.relative_to(ROOT)}")

    scene_filter = str(manifest.get("scene_filter", "all"))
    if scope == "route":
        expected_route = expected_route_keys(scene_filter)
        missing_route = expected_route - route_seen
        extra_route = route_seen - expected_route
        if missing_route:
            failures.append("missing route screenshot coverage: " + ", ".join(f"{scene}/{checkpoint}" for scene, checkpoint in sorted(missing_route)))
        if extra_route:
            failures.append("unexpected route screenshot coverage: " + ", ".join(f"{scene}/{checkpoint}" for scene, checkpoint in sorted(extra_route)))
    elif scope == "route-full":
        expected_route_full = expected_route_full_keys(scene_filter)
        missing_route_full = expected_route_full - route_full_seen
        extra_route_full = route_full_seen - expected_route_full
        if manifest.get("route_command_count") != len(expected_route_full):
            failures.append("route_command_count must match authored walkthrough command count")
        if manifest.get("screenshot_count") != len(expected_route_full):
            failures.append("screenshot_count must match authored walkthrough command count for route-full")
        if missing_route_full:
            failures.append(
                "missing route-full screenshot coverage: "
                + ", ".join(f"{scene}#{index}:{command}" for scene, index, command in sorted(missing_route_full))
            )
        if extra_route_full:
            failures.append(
                "unexpected route-full screenshot coverage: "
                + ", ".join(f"{scene}#{index}:{command}" for scene, index, command in sorted(extra_route_full))
            )
    else:
        expected = expected_pairs(scope, scene_filter)
        missing = expected - seen
        extra = seen - expected
        if missing:
            failures.append("missing screenshot coverage: " + ", ".join(f"{scene}/{location}" for scene, location in sorted(missing)))
        if extra:
            failures.append("unexpected screenshot coverage: " + ", ".join(f"{scene}/{location}" for scene, location in sorted(extra)))
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--scope", choices=["starts", "locations", "route", "route-full"])
    parser.add_argument("--visual-style", choices=["sunlit_mmo", "classic_dark"])
    parser.add_argument("--require-illustrated-backdrop", action="store_true")
    args = parser.parse_args()

    manifest_path = args.manifest.expanduser()
    if not manifest_path.is_absolute():
        manifest_path = ROOT / manifest_path
    if not manifest_path.exists():
        print(f"scene-screenshot-manifest: missing {_display_path(manifest_path)}")
        return 1

    failures = validate_manifest(manifest_path, args.scope, args.visual_style, args.require_illustrated_backdrop)
    if failures:
        for failure in failures:
            print(f"scene-screenshot-manifest: {failure}")
        return 1

    manifest = load_json(manifest_path)
    print(
        "scene-screenshot-manifest: OK path=%s screenshots=%s scope=%s style=%s"
        % (
            _display_path(manifest_path),
            manifest.get("screenshot_count", 0),
            manifest.get("scope", ""),
            manifest.get("visual_style", ""),
        )
    )
    return 0


def _display_path(path: Path) -> Path:
    try:
        return path.relative_to(ROOT)
    except ValueError:
        return path


if __name__ == "__main__":
    raise SystemExit(main())
