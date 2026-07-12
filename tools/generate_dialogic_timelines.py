#!/usr/bin/env python3
"""
tools/generate_dialogic_timelines.py

Generate Dialogic .dtl timeline files from data/story_scenes/*.json.

Output: dialogic/timelines/{scene_id}/{location_id}_{item_id}.dtl

Usage:
    python3 tools/generate_dialogic_timelines.py [--scene SCENE_ID] [--dry-run]

Each .dtl file corresponds to one interactive item or location-level choice in the game world.
The timeline format follows Dialogic's text-based event syntax:
  [background arg="path"]
  join character_id (portrait) left
  speaker: text line
  [signal arg="set_flag:flag_name"]
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
PROJECT_FILE = "project.godot"

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
        emitted_flags: set[str] = set()
        for entry in dialogue:
            if not isinstance(entry, dict):
                continue
            speaker_raw = entry.get("speaker", DEFAULT_NARRATOR)
            text = str(entry.get("text", "")).replace("\n", "\\\n")
            speaker = _resolve_speaker(speaker_raw, dialogic_speaker)
            lines.append(f"{escape_speaker(speaker)}: {text}")
            for flag in entry.get("flags", []):
                emitted_flags.add(str(flag))
                lines.append(f'[signal arg="set_flag:{escape_shortcode_value(str(flag))}"]')
        for flag in payload_flags:
            if str(flag) not in emitted_flags:
                lines.append(f'[signal arg="set_flag:{escape_shortcode_value(str(flag))}"]')
    else:
        # Single text block
        text = str(item.get("text", "")).replace("\n", "\\\n")
        speaker = DEFAULT_NARRATOR
        lines.append(f"{escape_speaker(speaker)}: {text}")
        # Emit flag signals for all item-level flags
        for flag in payload_flags:
            lines.append(f'[signal arg="set_flag:{escape_shortcode_value(str(flag))}"]')

    # Leave characters
    for d_id, _ in dialogic_chars:
        lines.append(f"leave {escape_identifier(d_id)}")

    lines.append("[end_timeline]")
    return "\n".join(lines)


def _resolve_speaker(speaker_raw: str, dialogic_speaker: str) -> str:
    """Resolve authored speakers without turning narration into character speech."""
    if speaker_raw in CHARACTER_MAP:
        return CHARACTER_MAP[speaker_raw][0]
    if not speaker_raw or speaker_raw == DEFAULT_NARRATOR:
        return DEFAULT_NARRATOR
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

        for choice_id, choice in location.get("choices", {}).items():
            dtl_text = build_dtl_text(
                item=choice,
                backdrop_path=backdrop_path,
                character_ids=collect_item_character_ids(choice),
            )

            rel_path = os.path.join(out_dir, f"{location_id}_choice_{choice_id}.dtl")
            if dry_run:
                print(f"[dry-run] would write {rel_path} ({len(dtl_text)} chars)")
                print(dtl_text[:200], "...\n" if len(dtl_text) > 200 else "\n")
            else:
                os.makedirs(out_dir, exist_ok=True)
                with open(rel_path, "w", encoding="utf-8") as f:
                    f.write(dtl_text)
                print(f"[write] {rel_path}")
            count += 1

        for action_type, collection_name in [
            ("glyph", "glyph_actions"),
            ("build", "build_actions"),
            ("encounter", "encounters"),
            ("combo", "combos"),
        ]:
            for action_id, action in location.get(collection_name, {}).items():
                rel_path = os.path.join(out_dir, f"{location_id}_{action_type}_{action_id}.dtl")
                dtl_text = build_dtl_text(
                    item=action,
                    backdrop_path=backdrop_path,
                    character_ids=collect_item_character_ids(action),
                )
                if dry_run:
                    print(f"[dry-run] would write {rel_path} ({len(dtl_text)} chars)")
                    print(dtl_text[:200], "...\n" if len(dtl_text) > 200 else "\n")
                else:
                    os.makedirs(out_dir, exist_ok=True)
                    with open(rel_path, "w", encoding="utf-8") as f:
                        f.write(dtl_text)
                    print(f"[write] {rel_path}")
                count += 1

        combat = location.get("combat", {})
        if isinstance(combat, dict) and combat:
            identify_payload = {
                "text": f"“名”字亮起。目标显形：{combat.get('revealed_name', '敌人')}。",
                "flags": [flag for flag in [combat.get("lock_flag")] if flag] + list(combat.get("success_flags", [])),
            }
            count += write_generated_timeline(
                out_dir=out_dir,
                location_id=location_id,
                item_id="combat_identify",
                item=identify_payload,
                backdrop_path=backdrop_path,
                dry_run=dry_run,
            )
            for spell_id, spell in combat.get("spells", {}).items():
                count += write_generated_timeline(
                    out_dir=out_dir,
                    location_id=location_id,
                    item_id=f"combat_spell_{spell_id}",
                    item=spell,
                    backdrop_path=backdrop_path,
                    dry_run=dry_run,
                )
            resolve_payload = {
                "text": f"{combat.get('revealed_name', '敌人')} 被击退。",
                "flags": [flag for flag in [combat.get("win_flag")] if flag] + list(combat.get("reward_flags", [])),
            }
            count += write_generated_timeline(
                out_dir=out_dir,
                location_id=location_id,
                item_id="combat_resolve",
                item=resolve_payload,
                backdrop_path=backdrop_path,
                dry_run=dry_run,
            )

    return count


def write_generated_timeline(
    out_dir: str,
    location_id: str,
    item_id: str,
    item: dict,
    backdrop_path: str,
    dry_run: bool,
) -> int:
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
    return 1


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


def sync_project_dtl_directory(dry_run: bool = False) -> None:
    project_path = PROJECT_FILE
    if not os.path.exists(project_path):
        return
    entries: list[tuple[str, str]] = []
    for root, _, files in os.walk(OUTPUT_DIR):
        for fname in files:
            if not fname.endswith(".dtl"):
                continue
            path = os.path.join(root, fname).replace(os.sep, "/")
            key = path.removeprefix(f"{OUTPUT_DIR}/").removesuffix(".dtl")
            entries.append((key, f"res://{path}"))
    entries.sort()
    block_lines = ["directories/dtl_directory={"]
    for index, (key, path) in enumerate(entries):
        suffix = "," if index + 1 < len(entries) else ""
        block_lines.append(f'"{key}": "{path}"{suffix}')
    block_lines.append("}")
    new_block = "\n".join(block_lines)

    with open(project_path, "r", encoding="utf-8") as f:
        content = f.read()
    marker = "directories/dtl_directory={"
    start = content.find(marker)
    if start == -1:
        return
    end = content.find("\n}", start)
    if end == -1:
        return
    end += len("\n}")
    updated = content[:start] + new_block + content[end:]
    if dry_run:
        print(f"[dry-run] would sync {project_path} ({len(entries)} timeline entries)")
        return
    if updated != content:
        with open(project_path, "w", encoding="utf-8") as f:
            f.write(updated)
        print(f"[write] synced {project_path} ({len(entries)} timeline entries)")


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
    sync_project_dtl_directory(dry_run=args.dry_run)

    action = "would generate" if args.dry_run else "generated"
    print(f"\nTotal: {action} {count} timeline(s).")


if __name__ == "__main__":
    main()
