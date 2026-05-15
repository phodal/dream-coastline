#!/usr/bin/env python3
"""Build AI prompts for the scene-to-Sprint Sheet pipeline."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GAME_ACCEPTANCE_COMMANDS = [
    "/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit",
    "/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-autoplay",
    "/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-first-act",
]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_scene_sprint_map(path: Path, scene_id: str) -> dict:
    if not path.exists():
        raise SystemExit(f"Missing scene_sprint_map file: {path}")
    data = load_json(path)
    scene_map = data.get("scene_sprint_map")
    if not isinstance(scene_map, dict):
        raise SystemExit("Map input must be JSON with a scene_sprint_map object")
    if scene_map.get("scene_id") != scene_id:
        raise SystemExit(
            "Map scene_id mismatch: "
            f"expected {scene_id}, got {scene_map.get('scene_id')}"
        )
    return scene_map


def scene_summary(story: dict, visual: dict) -> str:
    location_lines = []
    for location_id, location in story.get("locations", {}).items():
        visual_location = visual.get("locations", {}).get(location_id, {})
        kinds = []
        for prop in visual_location.get("props", []):
            kind = str(prop.get("kind", ""))
            if kind and kind not in kinds:
                kinds.append(kind)
        location_lines.append(
            "- {id}: name={name}; terrain={terrain}; prop_kinds={kinds}".format(
                id=location_id,
                name=location.get("name", location_id),
                terrain=visual_location.get("terrain", "missing"),
                kinds=", ".join(kinds) if kinds else "none",
            )
        )
    return "\n".join(location_lines)


def load_scene_bundle(scene_id: str) -> dict:
    story_path = ROOT / "data" / "story_scenes" / f"{scene_id}.json"
    visual_path = ROOT / "data" / "visual_scenes" / f"{scene_id}.json"
    if not story_path.exists():
        raise SystemExit(f"Missing story data: {story_path.relative_to(ROOT)}")
    if not visual_path.exists():
        raise SystemExit(f"Missing visual data: {visual_path.relative_to(ROOT)}")

    story = load_json(story_path)
    visual = load_json(visual_path)
    source_path = ROOT / str(story.get("source", ""))
    if not source_path.exists():
        raise SystemExit(f"Missing scene source: {source_path.relative_to(ROOT)}")

    architecture = read_text(ROOT / "docs" / "sprint-sheet-architecture.md")
    art_direction = read_text(ROOT / "five" / "system" / "art-audio-direction.md")
    scene_source = read_text(source_path)

    return {
        "scene_id": scene_id,
        "story": story,
        "visual": visual,
        "story_path": story_path,
        "visual_path": visual_path,
        "source_path": source_path,
        "architecture": architecture,
        "art_direction": art_direction,
        "scene_source": scene_source,
    }


def build_sheet_prompt(scene_id: str) -> str:
    bundle = load_scene_bundle(scene_id)
    story = bundle["story"]
    visual = bundle["visual"]

    return f"""你是 Dream Coastline 的剧情 RPG Sprint Sheet 生成助手。

任务：基于 scene 源文件和当前 playable JSON，为 `{scene_id}` 生成一张可执行 Sprint Sheet。

硬性要求：
- 输出中文 Markdown。
- 不要只写“像 RPG”；必须写 Source Scene Contract、Visual Direction、Screenshot Review Gate。
- 每条视觉要求都要回到 scene evidence，避免泛泛审美词。
- 明确 Must Read As / Must Not Read As。
- 必须列出 Story JSON、Visual JSON、Renderer、HUD/Menu、Smoke 和截图验收。
- 如果现有 prop kind 或 terrain 会让画面读成错误时代/地点，要明确指出。
- 不要虚构不存在的文件路径；需要新增文件时写成建议。

参考架构：
```md
{bundle["architecture"]}
```

美术与音频方向：
```md
{bundle["art_direction"]}
```

Scene 源文件 `{story.get("source", "")}`：
```md
{bundle["scene_source"]}
```

Story JSON 摘要：
```json
{json.dumps({
    "id": story.get("id"),
    "title": story.get("title"),
    "start": story.get("start"),
    "ending_flag": story.get("ending_flag"),
    "required_flags": story.get("required_flags", []),
    "locations": list(story.get("locations", {}).keys()),
}, ensure_ascii=False, indent=2)}
```

Visual JSON 摘要：
```text
{scene_summary(story, visual)}
```

请输出完整 Sprint Sheet，章节结构使用：
1. Diagnosis
2. Goal
3. Source Scene Contract
4. Player Loop
5. Inputs
6. Outputs
7. Visual Direction
8. UI Contract
9. Data Contract
10. Implementation Tasks
11. Acceptance
12. Screenshot Review Gate
13. Affected Files
14. Non-Goals
"""


def build_map_prompt(scene_id: str) -> str:
    bundle = load_scene_bundle(scene_id)
    story = bundle["story"]
    visual = bundle["visual"]

    return f"""你是 Dream Coastline 的 scene-to-Sprint-Sheet 映射助手。

任务：根据 scene 源文件、Story JSON、Visual JSON 和美术方向，为 `{scene_id}` 生成中间格式 `scene_sprint_map`。
这个中间格式不是 Sprint Sheet；它是后续生成 Sprint Sheet 前必须审查的可追溯映射。

输出要求：
- 只输出合法 JSON，不要 Markdown，不要解释。
- 顶层必须是一个对象，并且只包含一个键：`scene_sprint_map`。
- 每个字段必须来自输入证据；如果输入没有证据，使用空数组或 `null`，不要虚构。
- 所有 screen meaning、risk、task、acceptance 都要具体到玩家能在画面或操作中验证。
- `must_not_read_as` 必须列出会让场景读错时代、类型、地点或情绪的画面误读。
- `acceptance_commands` 不能留空；如果 implementation_tasks 涉及游戏画面、数据或运行时，至少包含下面的默认 Godot 检查。
- `affected_files` 只列实现 Sprint 时可能要改的仓库文件；不要把本 prompt builder 当成受影响文件，除非任务本身是修改生成器。

默认 Godot 检查：
```json
{json.dumps(DEFAULT_GAME_ACCEPTANCE_COMMANDS, ensure_ascii=False, indent=2)}
```

`scene_sprint_map` schema：
```json
{{
  "scene_id": "string",
  "title": "string",
  "sources": {{
    "scene": "path",
    "story_json": "path",
    "visual_json": "path"
  }},
  "source_scene_contract": [
    {{
      "evidence": "source scene or JSON evidence",
      "screen_meaning": "required player-visible meaning"
    }}
  ],
  "must_read_as": ["string"],
  "must_not_read_as": ["string"],
  "location_map": [
    {{
      "location_id": "string",
      "story_name": "string",
      "terrain": "string",
      "spawn": {{"x": 0, "y": 0}},
      "key_props": [
        {{
          "kind": "string",
          "item": "string or null",
          "exit": "string or null",
          "screen_meaning": "string"
        }}
      ],
      "exits": ["location_id"],
      "visual_risks": ["string"]
    }}
  ],
  "prop_risks": [
    {{
      "prop": "kind or item id",
      "risk": "what the player may misread",
      "required_state": "specific visual or UI state"
    }}
  ],
  "screenshot_states": [
    {{
      "id": "stable_snake_case",
      "location": "location_id",
      "flags": ["flag_id"],
      "expect": ["visible acceptance point"]
    }}
  ],
  "implementation_tasks": [
    {{
      "id": "stable_snake_case",
      "goal": "one implementation goal",
      "inputs": ["file or data field"],
      "outputs": ["file, screen, state, or data field"],
      "acceptance": ["observable check"]
    }}
  ],
  "acceptance_commands": ["command"],
  "affected_files": ["path"],
  "non_goals": ["string"]
}}
```

美术与音频方向：
```md
{bundle["art_direction"]}
```

Scene 源文件 `{story.get("source", "")}`：
```md
{bundle["scene_source"]}
```

Story JSON `{bundle["story_path"].relative_to(ROOT)}`：
```json
{json.dumps(story, ensure_ascii=False, indent=2)}
```

Visual JSON `{bundle["visual_path"].relative_to(ROOT)}`：
```json
{json.dumps(visual, ensure_ascii=False, indent=2)}
```
"""


def build_sheet_from_map_prompt(scene_id: str, map_input: Path) -> str:
    bundle = load_scene_bundle(scene_id)
    scene_map = load_scene_sprint_map(map_input, scene_id)

    return f"""你是 Dream Coastline 的剧情 RPG Sprint Sheet 转换助手。

任务：把已经审查过的 `scene_sprint_map` 转换成 `{scene_id}` 的完整中文 Sprint Sheet。

硬性要求：
- 输出中文 Markdown。
- 以 `scene_sprint_map` 为主合同；不要绕过它直接写泛泛的 RPG 建议。
- `Source Scene Contract` 必须来自 `scene_sprint_map.source_scene_contract`。
- `Visual Direction` 必须保留 `must_read_as` 与 `must_not_read_as`。
- `Implementation Tasks` 必须由 `scene_sprint_map.implementation_tasks` 转换，保持 inputs、outputs、acceptance。
- `Screenshot Review Gate` 必须由 `scene_sprint_map.screenshot_states` 转换。
- `Acceptance` 必须包含 `scene_sprint_map.acceptance_commands` 和截图验收。
- `Affected Files` 只能列 `scene_sprint_map.affected_files` 中真实存在或需要新增的文件。
- 如果 map 中信息不足，写成风险或 TODO，不要虚构。

参考 Sprint Sheet 架构：
```md
{bundle["architecture"]}
```

Scene Sprint Map `{map_input}`：
```json
{json.dumps(scene_map, ensure_ascii=False, indent=2)}
```

请输出完整 Sprint Sheet，章节结构使用：
1. Diagnosis
2. Goal
3. Source Scene Contract
4. Player Loop
5. Inputs
6. Outputs
7. Visual Direction
8. UI Contract
9. Data Contract
10. Implementation Tasks
11. Acceptance
12. Screenshot Review Gate
13. Affected Files
14. Non-Goals
"""


def build_prompt(
    scene_id: str,
    mode: str = "sheet",
    map_input: Path | None = None,
) -> str:
    if mode == "map":
        return build_map_prompt(scene_id)
    if mode == "sheet-from-map":
        if map_input is None:
            raise SystemExit("--map-input is required for --mode sheet-from-map")
        return build_sheet_from_map_prompt(scene_id, map_input)
    return build_sheet_prompt(scene_id)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scene_id", help="Scene id such as 01-illiterate")
    parser.add_argument(
        "--mode",
        choices=("sheet", "map", "sheet-from-map"),
        default="sheet",
        help="Prompt type to build. Use map before sheet for AI-assisted review.",
    )
    parser.add_argument(
        "--map-input",
        type=Path,
        help="scene_sprint_map JSON file used by --mode sheet-from-map",
    )
    parser.add_argument("--output", help="Optional file path to write the prompt")
    args = parser.parse_args()

    prompt = build_prompt(args.scene_id, args.mode, args.map_input)
    if args.output:
        output_path = Path(args.output)
        output_path.write_text(prompt, encoding="utf-8")
    else:
        print(prompt)


if __name__ == "__main__":
    main()
