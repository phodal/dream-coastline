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


def expected_pairs(scope: str, scene_filter: str) -> set[tuple[str, str]]:
    pairs: set[tuple[str, str]] = set()
    scene_paths = sorted(STORY_DIR.glob("*.json"))
    if scene_filter != "all":
        scene_paths = [STORY_DIR / f"{scene_filter}.json"]
    for path in scene_paths:
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

    seen: set[tuple[str, str]] = set()
    for index, shot in enumerate(screenshots):
        label = f"screenshots[{index}]"
        if not isinstance(shot, dict):
            failures.append(f"{label} must be an object")
            continue
        scene_id = str(shot.get("scene_id", ""))
        location_id = str(shot.get("location_id", ""))
        seen.add((scene_id, location_id))
        if shot.get("ok") is not True:
            failures.append(f"{label}.ok must be true")
        if shot.get("asset_status") != "asset_backed":
            failures.append(f"{label}.asset_status must be asset_backed")
        if require_illustrated_backdrop and not str(shot.get("asset_runtime_path", "")).strip():
            failures.append(f"{label}.asset_runtime_path must point to an illustrated backdrop")
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

    scope = str(manifest.get("scope", expected_scope or ""))
    scene_filter = str(manifest.get("scene_filter", "all"))
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
    parser.add_argument("--scope", choices=["starts", "locations"])
    parser.add_argument("--visual-style", choices=["sunlit_mmo", "classic_dark"])
    parser.add_argument("--require-illustrated-backdrop", action="store_true")
    args = parser.parse_args()

    manifest_path = args.manifest.expanduser()
    if not manifest_path.is_absolute():
        manifest_path = ROOT / manifest_path
    if not manifest_path.exists():
        print(f"scene-screenshot-manifest: missing {manifest_path.relative_to(ROOT)}")
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
            manifest_path.relative_to(ROOT),
            manifest.get("screenshot_count", 0),
            manifest.get("scope", ""),
            manifest.get("visual_style", ""),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
