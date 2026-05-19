#!/usr/bin/env python3
"""
tools/generate_dialogic_timelines.py

Generate Dialogic .dtl timeline files from data/story_scenes/*.json.

Output: dialogic/timelines/{scene_id}/{location_id}_{item_id}.dtl

Usage:
    python3 tools/generate_dialogic_timelines.py [--scene SCENE_ID] [--dry-run]

Each .dtl file corresponds to one interactive item in the game world.
The timeline format follows Dialogic's text-based event syntax:
  [background arg="path"]
  join character_id (portrait) left
  speaker: text line
  [signal set_flag:flag_name]
  leave character_id
  [end_timeline]
"""

import argparse
import json
import os
import re

STORY_DIR = "data/story_scenes"
VISUAL_DIR = "data/visual_scenes"
OUTPUT_DIR = "dialogic/timelines"

# Maps story JSON character_id → (dialogic_id, portrait)
CHARACTER_MAP = {
    "jizi_xuan": ("jizi_xuan", "phone"),
    "jizixuan": ("jizi_xuan", "phone"),
    "xiali": ("xiali", "default"),
    "wensu": ("wensu", "default"),
    "atang": ("atang", "default"),
    "xiaoyan": ("xiaoyan", "default"),
}

DEFAULT_NARRATOR = "旁白"


def load_json(path: str) -> dict:
    if not os.path.exists(path):
        return {}
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def escape_shortcode_value(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def escape_speaker(speaker: str) -> str:
    if " " in speaker:
        return f'"{speaker.replace(chr(34), chr(92)+chr(34))}"'
    return speaker.replace(":", "\\:")


def escape_identifier(value: str) -> str:
    return re.sub(r"[:\s]", "_", value)


def build_dtl_text(
    item: dict,
    backdrop_path: str,
    character_ids: list[str],
) -> str:
    """Build Dialogic timeline text for a single story item."""
    lines: list[str] = []

    # Background
    if backdrop_path:
        lines.append(f'[background arg="{escape_shortcode_value(backdrop_path)}"]')

    # Join characters
    dialogic_speaker = ""
    dialogic_chars: list[tuple[str, str]] = []
    for cid in character_ids:
        if cid not in CHARACTER_MAP:
            continue
        d_id, portrait = CHARACTER_MAP[cid]
        lines.append(f"join {escape_identifier(d_id)} ({escape_identifier(portrait)}) left")
        if not dialogic_speaker:
            dialogic_speaker = d_id
        dialogic_chars.append((d_id, portrait))

    # Dialogue lines (multi-line format takes priority)
    dialogue: list[dict] = item.get("dialogue", [])
    payload_flags: list[str] = item.get("flags", [])

    if dialogue:
        for entry in dialogue:
            if not isinstance(entry, dict):
                continue
            speaker_raw = entry.get("speaker", DEFAULT_NARRATOR)
            text = str(entry.get("text", "")).replace("\n", "\\\n")
            speaker = _resolve_speaker(speaker_raw, dialogic_speaker)
            lines.append(f"{escape_speaker(speaker)}: {text}")
            for flag in entry.get("flags", []):
                lines.append(f"[signal set_flag:{flag}]")
    else:
        # Single text block
        text = str(item.get("text", "")).replace("\n", "\\\n")
        speaker = dialogic_speaker if dialogic_speaker else DEFAULT_NARRATOR
        lines.append(f"{escape_speaker(speaker)}: {text}")
        # Emit flag signals for all item-level flags
        for flag in payload_flags:
            lines.append(f"[signal set_flag:{flag}]")

    # Leave characters
    for d_id, _ in dialogic_chars:
        lines.append(f"leave {escape_identifier(d_id)}")

    lines.append("[end_timeline]")
    return "\n".join(lines)


def _resolve_speaker(speaker_raw: str, dialogic_speaker: str) -> str:
    """Prefer dialogic character id over display name, fall back to narrator."""
    if speaker_raw in CHARACTER_MAP:
        return CHARACTER_MAP[speaker_raw][0]
    if not speaker_raw or speaker_raw == DEFAULT_NARRATOR:
        return dialogic_speaker if dialogic_speaker else DEFAULT_NARRATOR
    return speaker_raw


def collect_item_character_ids(item: dict) -> list[str]:
    """Return all character IDs referenced by an item."""
    ids: list[str] = []
    if "character_id" in item:
        cid = item["character_id"]
        if cid and cid not in ids:
            ids.append(cid)
    for cid in item.get("characters", []):
        if cid and cid not in ids:
            ids.append(str(cid))
    for entry in item.get("dialogue", []):
        if isinstance(entry, dict):
            speaker = entry.get("speaker", "")
            if speaker and speaker in CHARACTER_MAP and speaker not in ids:
                ids.append(speaker)
    return ids


def generate_for_scene(scene_id: str, dry_run: bool = False) -> int:
    story_path = os.path.join(STORY_DIR, f"{scene_id}.json")
    scene = load_json(story_path)
    if not scene:
        print(f"[skip] no story file: {story_path}")
        return 0

    visual = load_json(os.path.join(VISUAL_DIR, f"{scene_id}.json"))
    out_dir = os.path.join(OUTPUT_DIR, scene_id)

    count = 0
    for location_id, location in scene.get("locations", {}).items():
        visual_loc: dict = visual.get("locations", {}).get(location_id, {})
        backdrop_path: str = visual_loc.get("illustrated_backdrop", "")

        for item_id, item in location.get("items", {}).items():
            dtl_text = build_dtl_text(
                item=item,
                backdrop_path=backdrop_path,
                character_ids=collect_item_character_ids(item),
            )

            rel_path = os.path.join(out_dir, f"{location_id}_{item_id}.dtl")
            if dry_run:
                print(f"[dry-run] would write {rel_path} ({len(dtl_text)} chars)")
                print(dtl_text[:200], "...\n" if len(dtl_text) > 200 else "\n")
            else:
                os.makedirs(out_dir, exist_ok=True)
                with open(rel_path, "w", encoding="utf-8") as f:
                    f.write(dtl_text)
                print(f"[write] {rel_path}")
            count += 1

    return count


def generate_all(dry_run: bool = False) -> int:
    if not os.path.isdir(STORY_DIR):
        print(f"ERROR: story dir not found: {STORY_DIR}")
        return 0
    total = 0
    for fname in sorted(os.listdir(STORY_DIR)):
        if not fname.endswith(".json"):
            continue
        scene_id = fname[: -len(".json")]
        total += generate_for_scene(scene_id, dry_run=dry_run)
    return total


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Dialogic .dtl timelines from story JSON")
    parser.add_argument("--scene", help="Generate only this scene_id (default: all)")
    parser.add_argument("--dry-run", action="store_true", help="Print output without writing files")
    args = parser.parse_args()

    # Run from project root
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    os.chdir(project_root)

    if args.scene:
        count = generate_for_scene(args.scene, dry_run=args.dry_run)
    else:
        count = generate_all(dry_run=args.dry_run)

    action = "would generate" if args.dry_run else "generated"
    print(f"\nTotal: {action} {count} timeline(s).")


if __name__ == "__main__":
    main()
