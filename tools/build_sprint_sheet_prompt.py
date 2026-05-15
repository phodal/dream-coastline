#!/usr/bin/env python3
"""Build an AI prompt for generating a scene-aligned Sprint Sheet."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


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


def build_prompt(scene_id: str) -> str:
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
{architecture}
```

美术与音频方向：
```md
{art_direction}
```

Scene 源文件 `{story.get("source", "")}`：
```md
{scene_source}
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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scene_id", help="Scene id such as 01-illiterate")
    parser.add_argument("--output", help="Optional file path to write the prompt")
    args = parser.parse_args()

    prompt = build_prompt(args.scene_id)
    if args.output:
        output_path = Path(args.output)
        output_path.write_text(prompt, encoding="utf-8")
    else:
        print(prompt)


if __name__ == "__main__":
    main()
