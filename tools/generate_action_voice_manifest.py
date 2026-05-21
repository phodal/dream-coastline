#!/usr/bin/env python3
"""Generate per-action voice-line manifests from playable story JSON."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STORY_DIR = ROOT / "data" / "story_scenes"
VOICE_PROFILES = ROOT / "data" / "character_voice_profiles.json"
OUTPUT_DIR = ROOT / "data" / "action_voice_lines"

ACTION_COLLECTIONS = [
    ("inspect", "items"),
    ("choice", "choices"),
    ("glyph", "glyph_actions"),
    ("build", "build_actions"),
    ("encounter", "encounters"),
    ("combo", "combos"),
]


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def speaker_maps() -> tuple[dict[str, dict[str, Any]], dict[str, str]]:
    profiles = load_json(VOICE_PROFILES)
    characters = profiles.get("characters", {})
    display_to_id = {
        str(data.get("display_name", "")): character_id
        for character_id, data in characters.items()
        if isinstance(data, dict) and data.get("display_name")
    }
    return characters, display_to_id


def list_value(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def source_pointer(scene_id: str, location_id: str, collection_name: str, record_id: str) -> str:
    return f"data/story_scenes/{scene_id}.json#locations.{location_id}.{collection_name}.{record_id}"


def combat_pointer(scene_id: str, location_id: str, suffix: str) -> str:
    return f"data/story_scenes/{scene_id}.json#locations.{location_id}.combat{suffix}"


def speaker_for_record(record: dict[str, Any], characters: dict[str, Any]) -> str:
    character_id = str(record.get("character_id", ""))
    if character_id in characters:
        return character_id
    for raw_id in list_value(record.get("characters")):
        character_id = str(raw_id)
        if character_id in characters:
            return character_id
    return "narrator"


def normalize_speaker(raw_speaker: Any, display_to_id: dict[str, str], characters: dict[str, Any]) -> str:
    speaker = str(raw_speaker or "").strip()
    if not speaker or speaker == "旁白":
        return "narrator"
    if speaker in characters:
        return speaker
    return display_to_id.get(speaker, "narrator")


def speaker_name(speaker_id: str, characters: dict[str, Any]) -> str:
    if speaker_id == "narrator":
        return "旁白"
    character = characters.get(speaker_id, {})
    if isinstance(character, dict):
        return str(character.get("display_name", speaker_id))
    return speaker_id


def delivery_for(speaker_id: str) -> str:
    if speaker_id == "narrator":
        return "克制旁白，保留画面感，不抢角色表演。"
    return "遵循 character_voice_profiles 中该角色的 voice_direction 和 dialogue_rules。"


def add_line(
    queue: list[dict[str, Any]],
    line_counter: list[int],
    scene_prefix: str,
    scene_id: str,
    speaker_id: str,
    text: str,
    characters: dict[str, Any],
) -> None:
    clean_text = " ".join(str(text).split())
    if not clean_text:
        return
    line_counter[0] += 1
    line_id = f"AVL-{scene_prefix}-{line_counter[0]:03d}"
    line: dict[str, Any] = {
        "line_id": line_id,
        "speaker_id": speaker_id,
        "speaker_name": speaker_name(speaker_id, characters),
        "text": clean_text,
        "delivery": delivery_for(speaker_id),
        "status": "planned",
        "target_path": f"assets/audio/generated/action_voices/{scene_id}/{line_id}.mp3",
    }
    if speaker_id != "narrator":
        line["voice_profile_ref"] = f"data/character_voice_profiles.json#characters.{speaker_id}"
    queue.append(line)


def playback_queue_for_record(
    record: dict[str, Any],
    line_counter: list[int],
    scene_prefix: str,
    scene_id: str,
    characters: dict[str, Any],
    display_to_id: dict[str, str],
) -> list[dict[str, Any]]:
    queue: list[dict[str, Any]] = []
    dialogue = list_value(record.get("dialogue"))
    if dialogue:
        for entry in dialogue:
            if not isinstance(entry, dict):
                continue
            speaker_id = normalize_speaker(entry.get("speaker"), display_to_id, characters)
            add_line(queue, line_counter, scene_prefix, scene_id, speaker_id, str(entry.get("text", "")), characters)
        return queue
    speaker_id = speaker_for_record(record, characters)
    add_line(
        queue,
        line_counter,
        scene_prefix,
        scene_id,
        speaker_id,
        str(record.get("text", record.get("success_text", ""))),
        characters,
    )
    return queue


def action_entry(
    scene_id: str,
    location_id: str,
    action_type: str,
    collection_name: str,
    record_id: str,
    record: dict[str, Any],
    line_counter: list[int],
    scene_prefix: str,
    characters: dict[str, Any],
    display_to_id: dict[str, str],
) -> dict[str, Any]:
    return {
        "action_id": f"{location_id}.{action_type}.{record_id}",
        "scene_id": scene_id,
        "location_id": location_id,
        "action_type": action_type,
        "record_id": record_id,
        "display_name": str(record.get("name", record_id)),
        "requires": list_value(record.get("requires")),
        "sets_flags": list_value(record.get("flags")),
        "source_evidence": [source_pointer(scene_id, location_id, collection_name, record_id)],
        "playback_queue": playback_queue_for_record(
            record,
            line_counter,
            scene_prefix,
            scene_id,
            characters,
            display_to_id,
        ),
    }


def combat_entries(
    scene_id: str,
    location_id: str,
    combat: dict[str, Any],
    line_counter: list[int],
    scene_prefix: str,
    characters: dict[str, Any],
) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    hidden_name = str(combat.get("hidden_name", "敌人"))
    revealed_name = str(combat.get("revealed_name", hidden_name))
    identify_record = {
        "text": f"“名”字亮起。目标显形：{revealed_name}。",
        "flags": [flag for flag in [combat.get("lock_flag")] if flag] + list_value(combat.get("success_flags")),
    }
    entries.append(
        {
            "action_id": f"{location_id}.combat_identify.identify",
            "scene_id": scene_id,
            "location_id": location_id,
            "action_type": "combat_identify",
            "record_id": "identify",
            "display_name": f"识名 {hidden_name}",
            "requires": [flag for flag in [combat.get("learn_flag")] if flag],
            "sets_flags": identify_record["flags"],
            "source_evidence": [combat_pointer(scene_id, location_id, "")],
            "playback_queue": playback_queue_for_record(
                identify_record,
                line_counter,
                scene_prefix,
                scene_id,
                characters,
                {},
            ),
        }
    )
    for spell_id, spell in combat.get("spells", {}).items():
        if not isinstance(spell, dict):
            continue
        entries.append(
            action_entry(
                scene_id,
                location_id,
                "combat_spell",
                "combat.spells",
                str(spell_id),
                spell,
                line_counter,
                scene_prefix,
                characters,
                {},
            )
        )
    resolve_record = {
        "text": f"{revealed_name} 被击退。",
        "flags": [flag for flag in [combat.get("win_flag")] if flag] + list_value(combat.get("reward_flags")),
    }
    entries.append(
        {
            "action_id": f"{location_id}.combat_resolve.resolve",
            "scene_id": scene_id,
            "location_id": location_id,
            "action_type": "combat_resolve",
            "record_id": "resolve",
            "display_name": f"终局 {revealed_name}",
            "requires": list_value(combat.get("required_attack_flags")),
            "sets_flags": resolve_record["flags"],
            "source_evidence": [combat_pointer(scene_id, location_id, "")],
            "playback_queue": playback_queue_for_record(
                resolve_record,
                line_counter,
                scene_prefix,
                scene_id,
                characters,
                {},
            ),
        }
    )
    return entries


def generate_scene_manifest(scene_path: Path, characters: dict[str, Any], display_to_id: dict[str, str]) -> dict[str, Any]:
    scene = load_json(scene_path)
    scene_id = str(scene.get("id", scene_path.stem))
    scene_prefix = scene_id.split("-", 1)[0]
    line_counter = [0]
    actions: list[dict[str, Any]] = []

    for location_id, location in scene.get("locations", {}).items():
        if not isinstance(location, dict):
            continue
        for action_type, collection_name in ACTION_COLLECTIONS:
            collection = location.get(collection_name, {})
            if not isinstance(collection, dict):
                continue
            for record_id, record in collection.items():
                if not isinstance(record, dict):
                    continue
                actions.append(
                    action_entry(
                        scene_id,
                        str(location_id),
                        action_type,
                        collection_name,
                        str(record_id),
                        record,
                        line_counter,
                        scene_prefix,
                        characters,
                        display_to_id,
                    )
                )
        combat = location.get("combat", {})
        if isinstance(combat, dict) and combat:
            actions.extend(combat_entries(scene_id, str(location_id), combat, line_counter, scene_prefix, characters))

    return {
        "schema_version": 1,
        "scene_id": scene_id,
        "scene_title": str(scene.get("title", scene_id)),
        "source": f"data/story_scenes/{scene_id}.json",
        "generated_from": [
            f"data/story_scenes/{scene_id}.json",
            "data/character_voice_profiles.json",
        ],
        "coverage_scope": "full_playable_action_voice_manifest",
        "line_status_values": ["planned", "generated", "skipped"],
        "actions": actions,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene-id", help="Generate only one scene manifest.")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    characters, display_to_id = speaker_maps()
    scene_paths = sorted(STORY_DIR.glob("*.json"))
    if args.scene_id:
        scene_paths = [STORY_DIR / f"{args.scene_id}.json"]

    total_actions = 0
    total_lines = 0
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for scene_path in scene_paths:
        manifest = generate_scene_manifest(scene_path, characters, display_to_id)
        total_actions += len(manifest["actions"])
        total_lines += sum(len(action.get("playback_queue", [])) for action in manifest["actions"])
        output_path = OUTPUT_DIR / f"{manifest['scene_id']}.json"
        text = json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
        if args.dry_run:
            print(f"[dry-run] {output_path.relative_to(ROOT)} actions={len(manifest['actions'])}")
        else:
            output_path.write_text(text, encoding="utf-8")
            print(f"[write] {output_path.relative_to(ROOT)} actions={len(manifest['actions'])}")

    print(f"action-voice-manifest generated scenes={len(scene_paths)} actions={total_actions} lines={total_lines}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
