# UI Implementation Brief Schema

A UI Implementation Brief is the bridge between a reviewed `scene_sprint_map` and actual Godot UI work.

Sprint Sheets decide what a sprint should accomplish. The UI brief decides where the work lands in the current UI code, what data drives it, what the player should see in each state, and how screenshots prove the result.

The brief must preserve the reviewed Sprint Trace Map IDs. Component tasks
should name the `VIS-*`, `PROP-*`, `HUD-*`, or `SHOT-*` ID they implement.
Animation rows should stay as `ANIM-*` references and point to an Animation
Sheet or `animation_sprint_map`.

## Generate

Start with a reviewed `scene_sprint_map` JSON file:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate \
  --mode ui-brief-from-map \
  --map-input /tmp/01-scene-map.json \
  --output /tmp/01-ui-brief-prompt.md
```

Send the prompt to Codex, DeepSeek, or another model. The generated brief must stay implementation-facing.

Validate the brief before giving it to an implementation agent:

```sh
python3 tools/validate_scene_ai_contract.py \
  --scene-id 01-illiterate \
  --map /tmp/01-scene-map.json \
  --brief /tmp/01-ui-brief.md
```

Then build the implementation prompt:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate \
  --mode implementation-from-brief \
  --map-input /tmp/01-scene-map.json \
  --brief-input /tmp/01-ui-brief.md \
  --output /tmp/01-implementation-prompt.md
```

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
| `Component Tasks` | File-level tasks with stable ID, target function or data field, input, output, and acceptance. |
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

If a task lacks a stable Trace Map ID, it is not ready for semi-automated
implementation. Split it into `VIS`, `PROP`, `HUD`, `SHOT`, or `ANIM` work
before asking an agent to modify files.

The implementation is ready only after screenshots are reviewed against the original `scene_sprint_map`. Passing Godot smoke checks without matching `must_read_as` / `must_not_read_as` is not sufficient.
