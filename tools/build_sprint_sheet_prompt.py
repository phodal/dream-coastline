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
UI_STACK_CONTRACT = """Current Dream Coastline UI implementation surfaces:

- scripts/ui/game_hud.gd
  - Owns the Godot Control tree.
  - Creates SpriteSceneCanvas, top bar, PromptOverlay, PauseMenu, TitleScreen, SettingsMenu.
  - refresh(session, player_controller) pushes scene title, time, location, prompt text, visible log, player tile, facing, and blocked feedback into UI.
  - _layout_hud_regions() owns responsive top bar and bottom prompt geometry.
- scripts/ui/sprite_scene_canvas.gd
  - Owns full-screen tile rendering.
  - Reads visual_repository.location_visual(session.scene_id, session.location_id).
  - Draws terrain palettes, visual props, actors, blocked feedback, player animation, facing marker, and ending portal/orb state.
  - New prop kinds normally need _draw_visual_prop() routing and a small draw helper.
- scripts/ui/prompt_overlay.gd
  - Owns the bottom RPG text window.
  - refresh(location_name, prompt_text, latest_feedback) sets location, current Space/Enter action, and latest feedback.
- scripts/ui/game_theme.gd
  - Owns shared RPG panel, label, and command-button styling.
  - Use this for shell-level polish before adding local styling.
- scripts/core/rpg_player_controller.gd
  - Owns tile movement, facing, current_interaction(), prompt_text(), interact(), and blocked-tile feedback.
  - Prompt wording for a new interaction should usually be solved here or through visual prop labels.
- scripts/core/scene_visual_repository.gd
  - Owns visual_scenes JSON loading, spawn_for(), interaction_at(), and is_blocked().
  - New clickable/blocking map semantics should usually be expressible through visual JSON props.
- scripts/core/game_session.gd
  - Owns scene flags, metrics, action application, visible_log(), status_text(), combat state, and scene completion.
- scripts/core/rpg_*_smoke.gd and scripts/main.gd
  - Own scene-specific smoke paths and top-level smoke dispatch.
  - Any new UI-critical progression state should have either a smoke expectation or a screenshot review state.
"""


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


def read_required_text(path: Path, label: str) -> str:
    if not path.exists():
        raise SystemExit(f"Missing {label}: {path}")
    return read_text(path)


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
- 必须包含 Stable IDs 与 Sprint Trace Map；每个视觉、prop、HUD、动画、截图点都要有 `VIS/PROP/HUD/ANIM/SHOT-*` ID。
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
11. Sprint Trace Map
12. Acceptance
13. Screenshot Review Gate
14. Affected Files
15. Non-Goals
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
- 每个视觉、prop、动画、HUD、截图验收点都必须有稳定 ID，例如 `VIS-00-01`、`PROP-00-02`、`ANIM-JZX-01`、`HUD-00-01`、`SHOT-00-01`。
- `sprint_trace_map` 必须把每个稳定 ID 串成：scene evidence -> runtime function -> visual object / animation asset -> owner file / function -> screenshot state -> acceptance gate。
- 后续代码或资产生成只能处理某个稳定 ID；不要生成无法追踪到 owner file/function 的宽泛任务。
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
  "stable_ids": [
    {{
      "id": "VIS-00-01",
      "type": "VIS",
      "label": "short Chinese label",
      "owner": "screen|prop|animation|hud|screenshot"
    }}
  ],
  "sprint_trace_map": [
    {{
      "id": "VIS-00-01",
      "scene_evidence": "source scene or JSON evidence",
      "runtime_function": "runtime state, function, command, or data field",
      "visual_object_or_animation_asset": "prop kind, HUD state, animation clip, or generated asset",
      "owner_file": "repo path",
      "owner_function": "function, JSON field, registry key, or command",
      "screenshot_state": "SHOT-00-01",
      "acceptance_gate": "visible fact, command, or review gate"
    }}
  ],
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
      "id": "SHOT-00-01",
      "location": "location_id",
      "flags": ["flag_id"],
      "expect": ["visible acceptance point"]
    }}
  ],
  "implementation_tasks": [
    {{
      "id": "VIS/PROP/HUD/ANIM stable id or TASK-00-01",
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
- `Sprint Trace Map` 必须保留 `scene_sprint_map.stable_ids` 与 `scene_sprint_map.sprint_trace_map`，并让每个任务引用对应 ID。
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
11. Sprint Trace Map
12. Acceptance
13. Screenshot Review Gate
14. Affected Files
15. Non-Goals
"""


def build_ui_brief_from_map_prompt(scene_id: str, map_input: Path) -> str:
    scene_map = load_scene_sprint_map(map_input, scene_id)

    return f"""你是 Dream Coastline 的 Godot RPG UI implementation brief 作者。

任务：把已审查的 `scene_sprint_map` 转换成 `{scene_id}` 的 UI 编写 brief。
这个 brief 给未来写 Godot UI 的工程师或 agent 使用，不是剧情复述，也不是最终 Sprint Sheet。

硬性要求：
- 输出中文 Markdown。
- 所有建议必须落到现有 UI 文件、函数、数据 owner 或 visual JSON 字段。
- 每个 `prop_risks` 都要映射到 renderer、HUD、prompt、data 或 screenshot review 中的至少一个动作。
- 每个 `screenshot_states` 都要变成可执行的 UI 验收状态，说明 location、flags、TopBar、SceneCanvas、PromptOverlay、交互提示和 mismatch check。
- 保留并引用 `stable_ids` / `sprint_trace_map`；Component Tasks 必须写出对应的 `VIS/PROP/HUD/SHOT` ID，动画任务只引用 `ANIM-*` 并指向 Animation Sheet。
- 每个 UI 任务必须写清楚：目标文件、目标函数或数据字段、输入、输出、验收。
- 不要提出重写 UI 框架、换引擎、引入大型资产管线、做通用编辑器或做无关系统。
- 如果需要新增 helper 或 prop kind，写清楚为什么现有函数不足。

当前 UI 实现边界：
```text
{UI_STACK_CONTRACT}
```

Scene Sprint Map `{map_input}`：
```json
{json.dumps(scene_map, ensure_ascii=False, indent=2)}
```

请输出 UI Implementation Brief，章节结构使用：
1. UI Objective
2. Screen Region Contract
3. Data Hook Matrix
4. Scene Canvas Rendering Contract
5. Prompt And Feedback Contract
6. Interaction State Matrix
7. Prop Risk To UI Task Map
8. Component Tasks
9. Screenshot Capture Plan
10. Acceptance Commands
11. Non-Goals
"""


def build_implementation_from_brief_prompt(
    scene_id: str,
    map_input: Path,
    brief_input: Path,
) -> str:
    bundle = load_scene_bundle(scene_id)
    scene_map = load_scene_sprint_map(map_input, scene_id)
    ui_brief = read_required_text(brief_input, "UI Implementation Brief")

    return f"""你是 Dream Coastline 的 Godot UI implementation agent。

任务：根据已审查的 `scene_sprint_map` 和 UI Implementation Brief 实现 `{scene_id}` 的视觉/UI 工作。

硬性执行规则：
- 先检查 `git status --short --branch`，不要覆盖用户未提交改动。
- 只实现 UI brief 明确要求的内容；不要重新解释 scene，也不要扩大到 unrelated systems。
- 每个改动必须能追溯到 UI brief 或 scene map 中的稳定 ID；不要实现没有 `VIS/PROP/HUD/SHOT` ID 的视觉点。
- 视觉语义优先于泛 RPG 风格：如果截图读成错误时代、地点、物件或情绪，即使 smoke 通过也算失败。
- 新增 renderer/helper 时优先落在现有 UI owner；不要引入大型资产管线或远程资源。
- 如果改到 runtime interaction、prompt、save/load 或 Rust-backed 当前主流程，必须同步 Rust 和 GDScript 参考实现，或明确说明为何不需要。
- 实现后必须运行 contract 校验、Godot smoke，并捕获截图到 `/private/tmp/dream-coastline-{scene_id}-<state>.png`。
- 最终报告必须包含：改动摘要、验证命令、截图路径、未覆盖风险、工作树状态。

建议前置校验：
```sh
python3 tools/validate_scene_ai_contract.py --scene-id {scene_id} --map {map_input} --brief {brief_input}
```

当前 UI 实现边界：
```text
{UI_STACK_CONTRACT}
```

Scene 源文件 `{bundle["story"].get("source", "")}`：
```md
{bundle["scene_source"]}
```

Scene Sprint Map `{map_input}`：
```json
{json.dumps(scene_map, ensure_ascii=False, indent=2)}
```

UI Implementation Brief `{brief_input}`：
```md
{ui_brief}
```
"""


def build_screenshot_review_prompt(
    scene_id: str,
    map_input: Path,
    screenshot_manifest: Path | None = None,
) -> str:
    scene_map = load_scene_sprint_map(map_input, scene_id)
    manifest_text = "{}"
    if screenshot_manifest is not None:
        manifest_text = read_required_text(screenshot_manifest, "screenshot manifest")

    return f"""你是 Dream Coastline 的视觉语义审查 agent。

任务：根据 `scene_sprint_map` 和截图清单审查 `{scene_id}` 是否真正符合 scene contract。

审查规则：
- 不要只判断画面是否好看；必须逐条检查 `must_read_as`、`must_not_read_as`、`prop_risks`、`screenshot_states`。
- 必须检查 `stable_ids` 与 `sprint_trace_map`：截图结论要按 `SHOT-*` 和关联的 `VIS/PROP/ANIM/HUD-*` 行输出。
- 如果 smoke 通过但截图读成错误时代、地点、类型或情绪，结论必须是 FAIL。
- 对每张截图输出：state id、PASS/FAIL、证据、需要改的 UI/data/renderer owner。
- 最终输出一个总体结论：PASS、FAIL、或 PASS_WITH_RISK。
- 不要提出超出 Sprint Sheet non-goals 的重做方案。

Scene Sprint Map `{map_input}`：
```json
{json.dumps(scene_map, ensure_ascii=False, indent=2)}
```

截图清单：
```json
{manifest_text}
```
"""


def build_prompt(
    scene_id: str,
    mode: str = "sheet",
    map_input: Path | None = None,
    brief_input: Path | None = None,
    screenshot_manifest: Path | None = None,
) -> str:
    if mode == "map":
        return build_map_prompt(scene_id)
    if mode == "sheet-from-map":
        if map_input is None:
            raise SystemExit("--map-input is required for --mode sheet-from-map")
        return build_sheet_from_map_prompt(scene_id, map_input)
    if mode == "ui-brief-from-map":
        if map_input is None:
            raise SystemExit("--map-input is required for --mode ui-brief-from-map")
        return build_ui_brief_from_map_prompt(scene_id, map_input)
    if mode == "implementation-from-brief":
        if map_input is None:
            raise SystemExit("--map-input is required for --mode implementation-from-brief")
        if brief_input is None:
            raise SystemExit("--brief-input is required for --mode implementation-from-brief")
        return build_implementation_from_brief_prompt(scene_id, map_input, brief_input)
    if mode == "screenshot-review-from-map":
        if map_input is None:
            raise SystemExit("--map-input is required for --mode screenshot-review-from-map")
        return build_screenshot_review_prompt(scene_id, map_input, screenshot_manifest)
    return build_sheet_prompt(scene_id)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scene_id", help="Scene id such as 01-illiterate")
    parser.add_argument(
        "--mode",
        choices=(
            "sheet",
            "map",
            "sheet-from-map",
            "ui-brief-from-map",
            "implementation-from-brief",
            "screenshot-review-from-map",
        ),
        default="sheet",
        help="Prompt type to build. Use map before sheet for AI-assisted review.",
    )
    parser.add_argument(
        "--map-input",
        type=Path,
        help="scene_sprint_map JSON file used by map-derived modes",
    )
    parser.add_argument(
        "--brief-input",
        type=Path,
        help="UI Implementation Brief Markdown file used by --mode implementation-from-brief",
    )
    parser.add_argument(
        "--screenshot-manifest",
        type=Path,
        help="Optional JSON or Markdown screenshot manifest used by --mode screenshot-review-from-map",
    )
    parser.add_argument("--output", help="Optional file path to write the prompt")
    args = parser.parse_args()

    prompt = build_prompt(
        args.scene_id,
        args.mode,
        args.map_input,
        args.brief_input,
        args.screenshot_manifest,
    )
    if args.output:
        output_path = Path(args.output)
        output_path.write_text(prompt, encoding="utf-8")
    else:
        print(prompt)


if __name__ == "__main__":
    main()
