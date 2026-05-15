# UI Implementation Brief Schema

A UI Implementation Brief is the bridge between a reviewed `scene_sprint_map` and actual Godot UI work.

Sprint Sheets decide what a sprint should accomplish. The UI brief decides where the work lands in the current UI code, what data drives it, what the player should see in each state, and how screenshots prove the result.

## Generate

Start with a reviewed `scene_sprint_map` JSON file:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate \
  --mode ui-brief-from-map \
  --map-input /tmp/01-scene-map.json \
  --output /tmp/01-ui-brief-prompt.md
```

Send the prompt to Codex, DeepSeek, or another model. The generated brief must stay implementation-facing.

## Required Sections

| Section | Purpose |
| --- | --- |
| `UI Objective` | One screen-level outcome for the scene. |
| `Screen Region Contract` | What TopBar, SceneCanvas, PromptOverlay, and menus must communicate. |
| `Data Hook Matrix` | Which story JSON, visual JSON, `GameSession`, and controller fields drive each state. |
| `Scene Canvas Rendering Contract` | Terrain, prop kinds, actors, FX, and blocked-feedback rendering requirements. |
| `Prompt And Feedback Contract` | Exact prompt, latest feedback, unreadable text, and decode-state expectations. |
| `Interaction State Matrix` | Location, flags, facing or tile state, current action, result, and acceptance. |
| `Prop Risk To UI Task Map` | Every visual risk mapped to a renderer, data, prompt, or screenshot task. |
| `Component Tasks` | File-level tasks with target function or data field, input, output, and acceptance. |
| `Screenshot Capture Plan` | Review states that prove UI alignment, including mismatch checks. |
| `Acceptance Commands` | Godot load, smoke, and screenshot/manual review commands. |
| `Non-Goals` | Boundaries that prevent UI sprawl. |

## Current UI Owners

| UI Surface | Owner File | Brief Should Specify |
| --- | --- | --- |
| HUD shell and layout | `scripts/ui/game_hud.gd` | Top bar, prompt placement, menu visibility, responsive geometry. |
| Scene rendering | `scripts/ui/sprite_scene_canvas.gd` | Terrain palette, prop rendering, actor state, blocked feedback, scene effects. |
| Bottom prompt | `scripts/ui/prompt_overlay.gd` | Location label, current action, latest feedback, unreadable text behavior. |
| Shared styling | `scripts/ui/game_theme.gd` | Panel, label, and command button styling changes. |
| Movement and prompt selection | `scripts/core/rpg_player_controller.gd` | Facing, interaction lookup, prompt wording, blocked movement. |
| Visual data lookup | `scripts/core/scene_visual_repository.gd` | Prop collision, interaction hotspots, spawn points. |
| Runtime state | `scripts/core/game_session.gd` | Flags, action results, combat, visible log, status text. |
| Regression proof | `scripts/core/rpg_*_smoke.gd`, `scripts/main.gd` | Scene-specific smoke expectations and smoke dispatch. |

## Review Rule

A UI brief is ready only if an engineer can open the listed files and implement the next pass without re-reading the whole scene. If a task says only "make it more RPG" or "improve style", it is not a UI brief.
