#!/usr/bin/env python3
"""Build AI prompts for character dialogue and voice direction."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PROFILES = ROOT / "data" / "character_voice_profiles.json"

CORE_SOURCE_FILES = [
    "five/project/overview.md",
    "five/project/seven-act-outline.md",
    "five/project/themes.md",
    "five/system/art-audio-direction.md",
    "five/world/moqi-civilization.md",
    "five/world/text-reality-system.md",
    "five/world/extinguishers-and-silence-protocol.md",
]


def repo_path(path_text: str) -> Path:
    return ROOT / path_text


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip()


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def markdown_block(label: str, path: Path, content: str | None = None) -> str:
    body = read_text(path) if content is None else content.strip()
    return f"### {label}: `{relative(path)}`\n\n```md\n{body}\n```"


def json_block(label: str, path: Path, data: Any | None = None) -> str:
    body = load_json(path) if data is None else data
    return f"### {label}: `{relative(path)}`\n\n```json\n{json.dumps(body, ensure_ascii=False, indent=2)}\n```"


def existing_path(path_text: str) -> Path:
    path = repo_path(path_text)
    if not path.exists():
        raise SystemExit(f"Missing source file: {path_text}")
    return path


def collect_markdown_sources() -> list[str]:
    sections: list[str] = []
    for path_text in CORE_SOURCE_FILES:
        path = existing_path(path_text)
        sections.append(markdown_block("core", path))

    for path in sorted((ROOT / "five" / "people").glob("*.md")):
        sections.append(markdown_block("people", path))
    for path in sorted((ROOT / "five" / "scene").glob("[0-9]*.md")):
        sections.append(markdown_block("scene", path))
    for path in sorted((ROOT / "five" / "script").glob("*.md")):
        if path.name == "README.md":
            continue
        sections.append(markdown_block("script", path))
    return sections


def story_scene_summary(path: Path) -> dict[str, Any]:
    scene = load_json(path)
    locations = {}
    for location_id, location in scene.get("locations", {}).items():
        if not isinstance(location, dict):
            continue
        items = {}
        for item_id, item in location.get("items", {}).items():
            if not isinstance(item, dict):
                continue
            items[item_id] = {
                "name": item.get("name"),
                "flags": item.get("flags", []),
                "requires": item.get("requires", []),
                "text": item.get("text"),
            }
        locations[location_id] = {
            "name": location.get("name"),
            "description": location.get("description"),
            "items": items,
            "combat": location.get("combat"),
        }
    return {
        "id": scene.get("id"),
        "title": scene.get("title"),
        "source": scene.get("source"),
        "min_minutes": scene.get("min_minutes"),
        "start": scene.get("start"),
        "initial_flags": scene.get("initial_flags", []),
        "required_flags": scene.get("required_flags", []),
        "ending_flag": scene.get("ending_flag"),
        "locations": locations,
        "walkthrough": scene.get("walkthrough", []),
    }


def collect_story_json_sections(scene_id: str | None = None) -> list[str]:
    paths = sorted((ROOT / "data" / "story_scenes").glob("*.json"))
    if scene_id:
        selected = ROOT / "data" / "story_scenes" / f"{scene_id}.json"
        if not selected.exists():
            raise SystemExit(f"Missing story scene: {relative(selected)}")
        paths = [selected]
    return [
        json_block("story_scene_summary", path, story_scene_summary(path))
        for path in paths
    ]


def load_profiles(path: Path) -> str:
    if not path.exists():
        return "No existing character voice profiles found."
    return json.dumps(load_json(path), ensure_ascii=False, indent=2)


def source_pack(scene_id: str | None = None, include_all_json: bool = False) -> str:
    sections = collect_markdown_sources()
    if include_all_json or scene_id:
        sections.extend(collect_story_json_sections(scene_id))
    else:
        index = []
        for path in sorted((ROOT / "data" / "story_scenes").glob("*.json")):
            scene = load_json(path)
            index.append(
                {
                    "id": scene.get("id"),
                    "title": scene.get("title"),
                    "source": scene.get("source"),
                    "required_flags": scene.get("required_flags", []),
                    "locations": list(scene.get("locations", {}).keys()),
                }
            )
        sections.append(
            "### story_scene_index: `data/story_scenes/*.json`\n\n"
            f"```json\n{json.dumps(index, ensure_ascii=False, indent=2)}\n```"
        )
    return "\n\n".join(sections)


def profiles_prompt(include_all_json: bool) -> str:
    return f"""你是 Dream Coastline 的角色对白与语音设定助手。

任务：根据完整剧本资料，生成或刷新 `data/character_voice_profiles.json`。

输出要求：
- 只输出合法 JSON，不要 Markdown，不要解释。
- 顶层字段必须包含 `schema_version`、`generated_from`、`global_voice_rules`、`characters`。
- `schema_version` 必须是 1。
- `characters` 必须是以稳定角色 ID 为键的对象，例如 `jizi_xuan`、`xiali`。
- 每个角色必须包含：
  - `display_name`
  - `role`
  - `personality`
  - `arc`
  - `dialogue_rules.sentence_shape`
  - `dialogue_rules.lexicon`
  - `dialogue_rules.avoid`
  - `voice_direction.age_read`
  - `voice_direction.timbre`
  - `voice_direction.pitch`
  - `voice_direction.pace`
  - `voice_direction.energy`
  - `voice_direction.performance_notes`
  - `voice_direction.tts_prompt`
  - `sample_lines`
  - `source_evidence`
- 性格要能指导对白，不要只写抽象形容词。
- 口吻要区分章节变化，特别是纪子轩从迷路学生到文明工程师、夏离从亡国王子到国书守夜人。
- 音色只能使用抽象表演描述，例如年龄感、音色质地、音高、速度、气息、停顿、情绪压力。
- 禁止要求克隆真人、公众人物或具体配音演员声音。
- 如果资料不足，不要虚构复杂设定；用较低置信度的短描述并把依据写进 `source_evidence`。

现有画像：
```json
{load_profiles(DEFAULT_PROFILES)}
```

完整资料：

{source_pack(include_all_json=include_all_json)}
"""


def dialogue_prompt(scene_id: str, profiles_path: Path) -> str:
    return f"""你是 Dream Coastline 的场景对白生成助手。

任务：基于角色声音圣经和 `{scene_id}` 的 scene 资料，生成可落到 `data/dialogue_lines/{scene_id}.json` 的对白草稿。

输出要求：
- 只输出合法 JSON，不要 Markdown，不要解释。
- 顶层字段必须包含 `schema_version`、`scene_id`、`lines`。
- `schema_version` 必须是 1，`scene_id` 必须是 `{scene_id}`。
- 每句对白必须包含：
  - `id`：格式类似 `DLG-{scene_id}-001`
  - `location_id`
  - `character_id`
  - `text`
  - `intent`
  - `emotion`
  - `delivery`
  - `requires`
  - `sets_flags`
  - `source_evidence`
- 生成对白要覆盖关键调查、角色关系变化、失败/复盘/代价、战斗教学和章节收束。
- 不要把所有系统提示都改成角色自言自语；保留调查文本、UI 提示和玩家可操作空间。
- 不要让角色口吻脱离 `data/character_voice_profiles.json`。
- 墨颀语未被纪子轩理解前，可以保留 `□□` 或不可懂表达，但要让动作和表演方向可读。

角色声音圣经：
```json
{load_profiles(profiles_path)}
```

场景资料：

{source_pack(scene_id=scene_id, include_all_json=True)}
"""


def voice_casting_prompt(scene_id: str, profiles_path: Path) -> str:
    return f"""你是 Dream Coastline 的语音制作指导助手。

任务：基于角色声音圣经和 `{scene_id}` 的剧本证据，生成该幕的配音/TTS 制作说明。

输出要求：
- 输出中文 Markdown。
- 不要生成音频文件。
- 不要引用真人、公众人物或具体配音演员。
- 每个出场角色都要写：
  - scene function：这一幕承担的叙事功能
  - voice direction：年龄感、音色、音高、速度、气息、停顿
  - emotional range：这一幕从什么状态到什么状态
  - sample delivery：选 2-4 句关键台词并写表演方向
  - tts prompt：英文或中英混合的抽象 TTS prompt
- 末尾给出本幕语音验收清单。

角色声音圣经：
```json
{load_profiles(profiles_path)}
```

场景资料：

{source_pack(scene_id=scene_id, include_all_json=True)}
"""


def write_or_print(text: str, output: Path | None) -> None:
    if output is None:
        print(text)
        return
    output.write_text(text, encoding="utf-8")
    print(f"Wrote {output}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--mode",
        choices=["profiles", "dialogue", "voice-casting"],
        default="profiles",
    )
    parser.add_argument("--scene-id", help="Required for dialogue and voice-casting modes")
    parser.add_argument("--profiles", type=Path, default=DEFAULT_PROFILES)
    parser.add_argument("--output", type=Path)
    parser.add_argument(
        "--include-all-json",
        action="store_true",
        help="Include summarized JSON for every story scene in profiles mode.",
    )
    args = parser.parse_args()

    if args.mode == "profiles":
        prompt = profiles_prompt(include_all_json=args.include_all_json)
    else:
        if not args.scene_id:
            raise SystemExit(f"--scene-id is required for {args.mode} mode")
        profiles_path = args.profiles if args.profiles.is_absolute() else ROOT / args.profiles
        if args.mode == "dialogue":
            prompt = dialogue_prompt(args.scene_id, profiles_path)
        else:
            prompt = voice_casting_prompt(args.scene_id, profiles_path)

    write_or_print(prompt, args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
