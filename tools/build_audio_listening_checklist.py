#!/usr/bin/env python3
"""Build a human listening QA checklist for generated Nova audio assets."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STORY_DIR = ROOT / "data" / "story_scenes"
AUDIO_CUE_DIR = ROOT / "data" / "audio_cues"
ACTION_VOICE_DIR = ROOT / "data" / "action_voice_lines"
DEFAULT_OUTPUT = ROOT / "docs" / "nova-audio-listening-qa.md"
DEFAULT_PROGRESS = ROOT / "docs" / "nova-audio-listening-progress.json"

GLOBAL_ACCEPTANCE_ITEMS = [
    ("game_volume", "Listen with game-like volume, not only Finder preview volume."),
    ("music_and_action_mix", "Check each scene once with music/ambience alone and once under action text."),
    ("repetition_comfort", "Confirm SFX do not become tiring after repeated movement/action triggers."),
    ("voice_direction", "Confirm generated voices are intelligible and match character direction."),
    ("all_assets_reviewed", "Review every generated/listening asset and record every rejection."),
]

SCENE_ACCEPTANCE_ITEMS = [
    ("music_supports_scene", "Music/ambience supports the scene mood without masking action text."),
    ("sfx_repetition_safe", "Repeated SFX remain useful after several menu/action repetitions."),
    ("voices_fit_intent", "Generated voices fit speaker intent and do not fight the UI reading pace."),
    ("rejections_recorded", "Any rejected file has an asset id, problem, and replacement plan."),
]


@dataclass(frozen=True)
class ListeningAsset:
    scene_id: str
    asset_id: str
    kind: str
    usage: str
    target_path: str
    source: str
    prompt: str


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def load_progress(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    progress = load_json(path)
    if not isinstance(progress, dict):
        raise ValueError(f"progress file must contain an object: {path}")
    return progress


def repo_path(path_text: str) -> Path:
    return ROOT / path_text.replace("res://", "", 1)


def record_enabled(record: dict[str, Any]) -> bool:
    if record.get("runtime_enabled") is False:
        return False
    if record.get("sample_generation") is False:
        return False
    return True


def scene_titles() -> dict[str, str]:
    titles: dict[str, str] = {}
    for path in sorted(STORY_DIR.glob("*.json")):
        data = load_json(path)
        scene_id = str(data.get("id", path.stem))
        titles[scene_id] = str(data.get("title", scene_id))
    return titles


def collect_assets() -> tuple[list[ListeningAsset], int]:
    assets: list[ListeningAsset] = []
    skipped = 0

    for cue_path in sorted(AUDIO_CUE_DIR.glob("*.json")):
        data = load_json(cue_path)
        scene_id = str(data.get("scene_id", cue_path.stem))
        for cue in data.get("cues", []):
            if not isinstance(cue, dict):
                continue
            if not record_enabled(cue):
                skipped += 1
                continue
            assets.append(
                ListeningAsset(
                    scene_id=scene_id,
                    asset_id=str(cue.get("cue_id", "")),
                    kind=str(cue.get("type", "music")),
                    usage=str(cue.get("looping_intent") or cue.get("location_id") or ""),
                    target_path=str(cue.get("target_path", "")),
                    source=str(cue_path.relative_to(ROOT)),
                    prompt=str(cue.get("mood") or cue.get("instrumentation_prompt") or ""),
                )
            )
        for sound in data.get("event_sounds", []):
            if not isinstance(sound, dict):
                continue
            if not record_enabled(sound):
                skipped += 1
                continue
            locations = ", ".join(str(location) for location in sound.get("locations", []))
            usage = str(sound.get("event_name", "event"))
            if locations:
                usage = f"{usage}: {locations}"
            assets.append(
                ListeningAsset(
                    scene_id=scene_id,
                    asset_id=str(sound.get("sfx_id", "")),
                    kind="sfx",
                    usage=usage,
                    target_path=str(sound.get("target_path", "")),
                    source=str(cue_path.relative_to(ROOT)),
                    prompt=str(sound.get("mood") or sound.get("instrumentation_prompt") or ""),
                )
            )
        for voice in data.get("voice_samples", []):
            if not isinstance(voice, dict):
                continue
            if not record_enabled(voice):
                skipped += 1
                continue
            assets.append(
                ListeningAsset(
                    scene_id=scene_id,
                    asset_id=str(voice.get("line_id", "")),
                    kind="voice_sample",
                    usage=str(voice.get("character_id") or voice.get("voice_id") or ""),
                    target_path=str(voice.get("target_path", "")),
                    source=str(cue_path.relative_to(ROOT)),
                    prompt=str(voice.get("delivery") or voice.get("source_text") or ""),
                )
            )

    for manifest_path in sorted(ACTION_VOICE_DIR.glob("*.json")):
        data = load_json(manifest_path)
        scene_id = str(data.get("scene_id", manifest_path.stem))
        for action in data.get("actions", []):
            if not isinstance(action, dict):
                continue
            action_id = str(action.get("action_id", ""))
            display_name = str(action.get("display_name", action_id))
            for line in action.get("playback_queue", []):
                if not isinstance(line, dict):
                    continue
                if line.get("status") != "generated":
                    skipped += 1
                    continue
                line_id = str(line.get("line_id", ""))
                speaker = str(line.get("speaker_name") or line.get("speaker_id") or "")
                usage = f"{action_id}"
                if display_name:
                    usage += f" / {display_name}"
                if speaker:
                    usage += f" / {speaker}"
                assets.append(
                    ListeningAsset(
                        scene_id=scene_id,
                        asset_id=line_id,
                        kind="action_voice",
                        usage=usage,
                        target_path=str(line.get("target_path", "")),
                        source=str(manifest_path.relative_to(ROOT)),
                        prompt=str(line.get("delivery") or line.get("text") or ""),
                    )
                )
    assets.sort(key=lambda asset: (asset.scene_id, asset.kind, asset.asset_id, asset.target_path))
    return assets, skipped


def count_by_kind(assets: list[ListeningAsset]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for asset in assets:
        counts[asset.kind] = counts.get(asset.kind, 0) + 1
    return dict(sorted(counts.items()))


def file_status(path_text: str) -> str:
    if not path_text:
        return "missing path"
    path = repo_path(path_text)
    if path.exists() and Path(str(path) + ".import").exists():
        return "file+import"
    if path.exists():
        return "file only"
    return "missing file"


def listening_checks(kind: str) -> str:
    if kind in {"music", "ambience", "stinger"}:
        return "loop/entry/exit, mood fit, fatigue, no hot peak"
    if kind == "sfx":
        return "trigger timing, shortness, repetition, mix under dialogue"
    if kind in {"voice_sample", "action_voice"}:
        return "pronunciation, cadence, character fit, dialogue intelligibility"
    return "mood fit, mix, repetition"


def is_checked(progress_map: Any, key: str) -> bool:
    return isinstance(progress_map, dict) and progress_map.get(key) is True


def render_checkbox(label: str, checked: bool) -> str:
    return f"- [{'x' if checked else ' '}] {label}"


def asset_observation(progress: dict[str, Any], scene_id: str, asset_id: str) -> dict[str, Any]:
    observations = progress.get("asset_observations", {})
    if not isinstance(observations, dict):
        return {}
    scene_observations = observations.get(scene_id, {})
    if not isinstance(scene_observations, dict):
        return {}
    observation = scene_observations.get(asset_id, {})
    return observation if isinstance(observation, dict) else {}


def render_scene_section(
    scene_id: str,
    title: str,
    assets: list[ListeningAsset],
    progress: dict[str, Any],
) -> str:
    rows = [
        "| Done | Result | Asset | Type | Use | File status | Listening checks |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for asset in assets:
        target = asset.target_path or "-"
        observation = asset_observation(progress, scene_id, asset.asset_id)
        status = str(observation.get("status", "pending"))
        notes = str(observation.get("notes", "")).replace("|", "/")
        result = status
        if notes:
            result += f"<br>{notes}"
        rows.append(
            "| [%s] | %s | `%s`<br>`%s` | %s | %s | %s | %s |"
            % (
                "x" if status in {"approved", "rejected"} else " ",
                result,
                asset.asset_id,
                target,
                asset.kind,
                asset.usage.replace("|", "/"),
                file_status(asset.target_path),
                listening_checks(asset.kind),
            )
        )
    scene_progress = progress.get("scene_acceptance", {}).get(scene_id, {})
    acceptance = "\n".join(
        render_checkbox(label, is_checked(scene_progress, key))
        for key, label in SCENE_ACCEPTANCE_ITEMS
    )
    return f"""## {scene_id} - {title}

- Assets to audition: {len(assets)}

{chr(10).join(rows)}

Scene acceptance:

{acceptance}
"""


def validate_progress(progress: dict[str, Any], assets: list[ListeningAsset]) -> list[str]:
    failures: list[str] = []
    known_global_keys = {key for key, _label in GLOBAL_ACCEPTANCE_ITEMS}
    known_scene_keys = {key for key, _label in SCENE_ACCEPTANCE_ITEMS}
    assets_by_scene: dict[str, set[str]] = {}
    for asset in assets:
        assets_by_scene.setdefault(asset.scene_id, set()).add(asset.asset_id)

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
    for scene_id, scene_progress in scene_acceptance.items():
        if scene_id not in assets_by_scene:
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

    observations = progress.get("asset_observations", {})
    if "asset_observations" in progress and not isinstance(observations, dict):
        failures.append("asset_observations must be an object")
        observations = {}
    for scene_id, scene_observations in observations.items():
        if scene_id not in assets_by_scene:
            failures.append(f"asset_observations has unknown scene: {scene_id}")
            continue
        if not isinstance(scene_observations, dict):
            failures.append(f"asset_observations.{scene_id} must be an object")
            continue
        for asset_id, observation in scene_observations.items():
            if asset_id not in assets_by_scene[scene_id]:
                failures.append(f"asset_observations.{scene_id} has unknown asset: {asset_id}")
                continue
            if not isinstance(observation, dict):
                failures.append(f"asset_observations.{scene_id}.{asset_id} must be an object")
                continue
            unknown_fields = set(observation) - {"status", "notes"}
            if unknown_fields:
                failures.append(
                    f"asset_observations.{scene_id}.{asset_id} has unknown fields: "
                    + ", ".join(sorted(unknown_fields))
                )
            status = observation.get("status")
            note = observation.get("notes", "")
            if status not in {"approved", "rejected"}:
                failures.append(f"asset_observations.{scene_id}.{asset_id}.status must be approved or rejected")
            if not isinstance(note, str):
                failures.append(f"asset_observations.{scene_id}.{asset_id}.notes must be a string")
            elif status == "rejected" and not note.strip():
                failures.append(f"asset_observations.{scene_id}.{asset_id} rejected assets require notes")

    incomplete_scenes: list[str] = []
    for scene_id, expected_ids in assets_by_scene.items():
        scene_observations = observations.get(scene_id, {})
        observed_ids = set(scene_observations) if isinstance(scene_observations, dict) else set()
        if observed_ids != expected_ids:
            incomplete_scenes.append(f"{scene_id} ({len(expected_ids - observed_ids)} missing)")
        scene_progress = scene_acceptance.get(scene_id, {})
        if isinstance(scene_progress, dict) and all(scene_progress.get(key) is True for key in known_scene_keys):
            if observed_ids != expected_ids:
                failures.append(
                    f"scene_acceptance.{scene_id} requires all asset observations; "
                    f"missing {len(expected_ids - observed_ids)}"
                )

    if global_acceptance.get("all_assets_reviewed") is True:
        incomplete_acceptance = [
            scene_id
            for scene_id in assets_by_scene
            if not isinstance(scene_acceptance.get(scene_id), dict)
            or not all(scene_acceptance[scene_id].get(key) is True for key in known_scene_keys)
        ]
        if incomplete_acceptance:
            failures.append(
                "global_acceptance.all_assets_reviewed requires all scene acceptance checks; incomplete scenes: "
                + ", ".join(incomplete_acceptance)
            )
        if incomplete_scenes:
            failures.append(
                "global_acceptance.all_assets_reviewed requires all asset observations; incomplete scenes: "
                + ", ".join(incomplete_scenes)
            )
    return failures


def build_markdown(progress: dict[str, Any] | None = None) -> str:
    progress = progress or {}
    titles = scene_titles()
    assets, skipped = collect_assets()
    by_scene: dict[str, list[ListeningAsset]] = {}
    for asset in assets:
        by_scene.setdefault(asset.scene_id, []).append(asset)
    sections = [
        render_scene_section(scene_id, titles.get(scene_id, scene_id), by_scene[scene_id], progress)
        for scene_id in sorted(by_scene)
    ]
    counts = count_by_kind(assets)
    count_rows = "\n".join(f"- `{kind}`: {count}" for kind, count in counts.items())
    observations = progress.get("asset_observations", {})
    flattened = [
        observation
        for scene_observations in observations.values()
        if isinstance(scene_observations, dict)
        for observation in scene_observations.values()
        if isinstance(observation, dict)
    ] if isinstance(observations, dict) else []
    approved = sum(observation.get("status") == "approved" for observation in flattened)
    rejected = sum(observation.get("status") == "rejected" for observation in flattened)
    global_progress = progress.get("global_acceptance", {})
    global_rows = "\n".join(
        render_checkbox(label, is_checked(global_progress, key))
        for key, label in GLOBAL_ACCEPTANCE_ITEMS
    )
    progress_notes = progress.get("progress_notes", [])
    notes_markdown = ""
    if progress_notes:
        notes_markdown = "Progress notes:\n\n" + "\n".join(f"- {note}" for note in progress_notes) + "\n\n"
    return f"""# Nova Audio Listening QA

This checklist is generated from `data/audio_cues/*.json` and
`data/action_voice_lines/*.json` by
`tools/build_audio_listening_checklist.py`. It is a human listening aid, not an
automatic approval result.

Listening progress is sourced from `docs/nova-audio-listening-progress.json`.
Edit that JSON and regenerate this file; do not edit checklist boxes directly.

{notes_markdown}Progress status:

- Approved: {approved}
- Rejected with notes: {rejected}
- Pending: {len(assets) - approved - rejected}

Recommended technical gate before listening:

```sh
python3 tools/run_automated_tests.py --only audio-mix-audit
```

That gate checks files, Godot import metadata, duration ranges, and obvious
volume problems. This checklist covers the creative listening pass that still
requires human judgement.

Global acceptance:

{global_rows}

Coverage summary:

- Generated/listening assets: {len(assets)}
- Planned or disabled assets skipped: {skipped}
{count_rows}

{chr(10).join(sections)}
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
    progress_path = args.progress.expanduser()
    if not progress_path.is_absolute():
        progress_path = ROOT / progress_path
    try:
        progress = load_progress(progress_path)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"audio-listening-checklist: {error}", file=sys.stderr)
        return 1
    assets, _skipped = collect_assets()
    progress_failures = validate_progress(progress, assets)
    if progress_failures:
        for failure in progress_failures:
            print(f"audio-listening-checklist: {failure}", file=sys.stderr)
        return 1
    markdown = build_markdown(progress).rstrip() + "\n"
    if args.check:
        if not output.exists():
            print(f"audio-listening-checklist: missing {output.relative_to(ROOT)}")
            return 1
        current = output.read_text(encoding="utf-8")
        if current != markdown:
            print(f"audio-listening-checklist: stale {output.relative_to(ROOT)}")
            return 1
        print(f"audio-listening-checklist: OK {output.relative_to(ROOT)}")
        return 0

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(markdown, encoding="utf-8")
    print(f"audio-listening-checklist: wrote {output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
