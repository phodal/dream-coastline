#!/usr/bin/env python3
"""Build a human listening QA checklist for generated Nova audio assets."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STORY_DIR = ROOT / "data" / "story_scenes"
AUDIO_CUE_DIR = ROOT / "data" / "audio_cues"
ACTION_VOICE_DIR = ROOT / "data" / "action_voice_lines"
DEFAULT_OUTPUT = ROOT / "docs" / "nova-audio-listening-qa.md"


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


def render_scene_section(scene_id: str, title: str, assets: list[ListeningAsset]) -> str:
    rows = [
        "| Done | Asset | Type | Use | File status | Listening checks |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for asset in assets:
        target = asset.target_path or "-"
        rows.append(
            "| [ ] | `%s`<br>`%s` | %s | %s | %s | %s |"
            % (
                asset.asset_id,
                target,
                asset.kind,
                asset.usage.replace("|", "/"),
                file_status(asset.target_path),
                listening_checks(asset.kind),
            )
        )
    return f"""## {scene_id} - {title}

- Assets to audition: {len(assets)}

{chr(10).join(rows)}

Scene acceptance:

- [ ] Music/ambience supports the scene mood without masking action text.
- [ ] Repeated SFX remain useful after several menu/action repetitions.
- [ ] Generated voices fit speaker intent and do not fight the UI reading pace.
- [ ] Any rejected file is recorded with asset id, problem, and replacement plan.
"""


def build_markdown() -> str:
    titles = scene_titles()
    assets, skipped = collect_assets()
    by_scene: dict[str, list[ListeningAsset]] = {}
    for asset in assets:
        by_scene.setdefault(asset.scene_id, []).append(asset)
    sections = [
        render_scene_section(scene_id, titles.get(scene_id, scene_id), by_scene[scene_id])
        for scene_id in sorted(by_scene)
    ]
    counts = count_by_kind(assets)
    count_rows = "\n".join(f"- `{kind}`: {count}" for kind, count in counts.items())
    return f"""# Nova Audio Listening QA

This checklist is generated from `data/audio_cues/*.json` and
`data/action_voice_lines/*.json` by
`tools/build_audio_listening_checklist.py`. It is a human listening aid, not an
automatic approval result.

Recommended technical gate before listening:

```sh
python3 tools/run_automated_tests.py --only audio-mix-audit
```

That gate checks files, Godot import metadata, duration ranges, and obvious
volume problems. This checklist covers the creative listening pass that still
requires human judgement.

Global acceptance:

- [ ] Listen with game-like volume, not only Finder preview volume.
- [ ] Check each scene once with music/ambience alone and once under action text.
- [ ] Confirm SFX do not become tiring after repeated movement/action triggers.
- [ ] Confirm generated voices are intelligible and match character direction.
- [ ] Record replacements or mastering notes before marking the scene done.

Coverage summary:

- Generated/listening assets: {len(assets)}
- Planned or disabled assets skipped: {skipped}
{count_rows}

{chr(10).join(sections)}
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
