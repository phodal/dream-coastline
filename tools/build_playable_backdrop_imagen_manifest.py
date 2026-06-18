#!/usr/bin/env python3
"""Build Imagen prompt manifest for final playable-location backdrops."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STORY_SCENE_DIR = ROOT / "data" / "story_scenes"
VISUAL_SCENE_DIR = ROOT / "data" / "visual_scenes"
CHAPTER_ILLUSTRATIONS = ROOT / "data" / "chapter_illustrations.json"
DEFAULT_OUTPUT = ROOT / "data" / "playable_backdrop_imagen_manifest.json"


STYLE_LINE = (
    "Restrained ink-and-paper narrative RPG location art, playable 16:9 backdrop, "
    "muted palette, clean silhouettes, soft vignette, clear foreground/midground/background depth, "
    "no readable text, no UI, no debug markers."
)

NEGATIVE_PROMPT = (
    "Do not add menus, buttons, subtitles, text labels, speech bubbles, watermarks, debug hotspots, "
    "grid overlays, generic fantasy castle scenery, photorealistic stock-image lighting, or unrelated characters."
)


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def res_to_path(value: str) -> Path:
    if value.startswith("res://"):
        return ROOT / value.removeprefix("res://")
    return ROOT / value


def rel_res_path(path: str) -> str:
    if path.startswith("res://"):
        return path
    return f"res://{path}"


def scene_index(scene_id: str) -> str:
    match = re.match(r"^(\d+)-", scene_id)
    return match.group(1) if match else scene_id[:2].upper()


def stable_location_id(scene_id: str, location_id: str) -> str:
    token = re.sub(r"[^A-Za-z0-9]+", "_", location_id).strip("_").upper()
    return f"PBG-{scene_index(scene_id)}-{token}"


def short_list(values: list[str], limit: int = 6) -> str:
    clean = [value for value in values if value]
    if len(clean) <= limit:
        return ", ".join(clean)
    return ", ".join(clean[:limit]) + ", ..."


def prop_label(prop: dict[str, Any]) -> str:
    kind = str(prop.get("kind", "prop"))
    for key in ["item", "exit", "choice", "combat", "id"]:
        if prop.get(key):
            return f"{kind}:{prop[key]}"
    return kind


def load_story_scenes() -> dict[str, dict[str, Any]]:
    scenes: dict[str, dict[str, Any]] = {}
    for path in sorted(STORY_SCENE_DIR.glob("*.json")):
        data = load_json(path)
        scenes[str(data.get("id", path.stem))] = data
    return scenes


def load_style_references() -> dict[tuple[str, str], list[str]]:
    references: dict[tuple[str, str], list[str]] = {}
    if not CHAPTER_ILLUSTRATIONS.exists():
        return references
    data = load_json(CHAPTER_ILLUSTRATIONS)
    for scene_id, panels in data.get("illustrations", {}).items():
        for panel in panels:
            if not isinstance(panel, dict):
                continue
            panel_path = str(panel.get("target_path") or panel.get("path") or "")
            if not panel_path:
                continue
            for location_id in panel.get("locations", []):
                key = (str(scene_id), str(location_id))
                references.setdefault(key, [])
                if panel_path not in references[key]:
                    references[key].append(panel_path)
    return references


def build_prompt(
    scene: dict[str, Any],
    location_id: str,
    story_location: dict[str, Any],
    visual_location: dict[str, Any],
    style_references: list[str],
) -> str:
    scene_title = str(scene.get("title", scene.get("id", "")))
    location_name = str(story_location.get("name", location_id))
    description = str(story_location.get("description", "")).strip()
    terrain = str(visual_location.get("terrain", ""))
    family = str(visual_location.get("visual_family", ""))
    mood = str(visual_location.get("visual_mood", ""))
    props = [prop_label(prop) for prop in visual_location.get("props", []) if isinstance(prop, dict)]
    items = [
        str(value.get("name", key))
        for key, value in story_location.get("items", {}).items()
        if isinstance(value, dict)
    ]
    exits = [str(label) for label in story_location.get("exits", {}).values()]
    reference_clause = ""
    if style_references:
        reference_clause = " Match the art direction of the provided reference panels for this scene."
    return (
        f"Final playable location backdrop for {scene_title}, location {location_name} ({location_id}). "
        f"Scene description: {description or 'Use the visual map and story props as the source of truth.'} "
        f"Terrain: {terrain}; visual family: {family}; mood: {mood}. "
        f"Visible semantic anchors: {short_list(items + props + exits, 10)}. "
        f"The image must work behind Nova's RPG action menu, so keep the main focal shapes readable in the center "
        f"and leave the lower UI area visually calm without becoming empty.{reference_clause} {STYLE_LINE}"
    )


def build_manifest() -> dict[str, Any]:
    story_scenes = load_story_scenes()
    style_references = load_style_references()
    backdrops: list[dict[str, Any]] = []
    missing_files: list[str] = []

    for path in sorted(VISUAL_SCENE_DIR.glob("*.json")):
        visual_scene = load_json(path)
        scene_id = str(visual_scene.get("id", path.stem))
        story_scene = story_scenes.get(scene_id, {})
        story_locations = story_scene.get("locations", {})
        for location_id, visual_location in sorted(visual_scene.get("locations", {}).items()):
            if not isinstance(visual_location, dict):
                continue
            story_location = story_locations.get(location_id, {})
            current_path = str(visual_location.get("illustrated_backdrop", ""))
            target_path = rel_res_path(f"assets/illustrations/playable/{scene_id}/{location_id}.png")
            if current_path and not res_to_path(current_path).exists():
                missing_files.append(current_path)
            refs = style_references.get((scene_id, str(location_id)), [])[:4]
            backdrops.append(
                {
                    "id": stable_location_id(scene_id, str(location_id)),
                    "scene_id": scene_id,
                    "scene_title": story_scene.get("title", scene_id),
                    "location_id": str(location_id),
                    "location_name": story_location.get("name", str(location_id)),
                    "generation_status": "needs_imagen_final_art",
                    "provider": "Imagen",
                    "aspect_ratio": "16:9",
                    "target_path": target_path,
                    "current_reference_path": current_path,
                    "style_reference_paths": refs,
                    "visual_family": visual_location.get("visual_family", ""),
                    "visual_mood": visual_location.get("visual_mood", ""),
                    "terrain": visual_location.get("terrain", ""),
                    "source_scene_contract": {
                        "description": story_location.get("description", ""),
                        "story_items": sorted(story_location.get("items", {}).keys()),
                        "exits": sorted(story_location.get("exits", {}).keys()),
                        "visual_props": [
                            prop_label(prop)
                            for prop in visual_location.get("props", [])
                            if isinstance(prop, dict)
                        ],
                    },
                    "prompt": build_prompt(story_scene, str(location_id), story_location, visual_location, refs),
                    "negative_prompt": NEGATIVE_PROMPT,
                    "acceptance": [
                        "Output replaces the target_path PNG and keeps the Godot import metadata refreshed.",
                        "Screenshot manifest still reports asset_loaded=true, procedural_fallback=false, hotspot_markers_visible=false, and debug_flags_visible=false.",
                        "The scene reads as the named story location before reading the action menu.",
                        "The image contains no readable text, UI chrome, watermark, or debug overlay.",
                    ],
                }
            )

    manifest = {
        "schema": "dream-coastline.playable_backdrop_imagen_manifest.v1",
        "purpose": "Final-quality Imagen replacement plan for Nova playable-location backdrops.",
        "notes": [
            "Runtime coverage is already provided by deterministic playable PNGs.",
            "Use this manifest for final art-direction replacement, one stable backdrop id at a time.",
            "After replacing any target_path, run Godot editor import before screenshot gates.",
        ],
        "backdrops": backdrops,
    }
    if missing_files:
        manifest["source_warnings"] = {"missing_current_reference_paths": sorted(missing_files)}
    return manifest


def write_manifest(path: Path, manifest: dict[str, Any]) -> None:
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--write", action="store_true", help="Write the manifest JSON.")
    parser.add_argument("--check", action="store_true", help="Fail if the existing manifest is missing or stale.")
    args = parser.parse_args()

    manifest = build_manifest()
    output = args.output if args.output.is_absolute() else ROOT / args.output

    if args.check:
        if not output.exists():
            print(f"playable-backdrop-imagen-manifest status=FAIL reason=missing path={output.relative_to(ROOT)}", file=sys.stderr)
            return 1
        current = load_json(output)
        if current != manifest:
            print(f"playable-backdrop-imagen-manifest status=FAIL reason=stale path={output.relative_to(ROOT)}", file=sys.stderr)
            return 1
        print(f"playable-backdrop-imagen-manifest status=PASS backdrops={len(manifest['backdrops'])}")
        return 0

    if args.write:
        write_manifest(output, manifest)
    print(
        "playable-backdrop-imagen-manifest status=PASS backdrops=%d wrote=%s output=%s"
        % (len(manifest["backdrops"]), str(args.write).lower(), output.relative_to(ROOT))
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
