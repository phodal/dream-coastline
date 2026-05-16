# Scene Sprint Map Schema

`scene_sprint_map` is the intermediate contract between a source scene and a Sprint Sheet.

Use it when AI helps generate Sprint Sheets. The model should first map scene evidence, playable JSON, and visual JSON into this structured object; only then should a human or second prompt turn the map into a full Sprint Sheet. This prevents a direct jump from prose to vague UI work.

Every visual, prop, HUD, animation, and screenshot point must have a stable ID.
Those IDs are the coordinate system for later UI briefs, Animation Sheets, code
changes, generated assets, screenshots, and review notes.

## Generate

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode map --output /tmp/01-scene-map-prompt.md
codex exec --cd . --sandbox read-only --output-last-message /tmp/01-scene-map.json "$(cat /tmp/01-scene-map-prompt.md)"
```

The prompt asks for strict JSON with one top-level key:

```json
{
  "scene_sprint_map": {
    "scene_id": "01-illiterate",
    "stable_ids": [],
    "sprint_trace_map": []
  }
}
```

Then convert the reviewed map into a Sprint Sheet prompt:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate \
  --mode sheet-from-map \
  --map-input /tmp/01-scene-map.json \
  --output /tmp/01-sheet-from-map-prompt.md
```

Or convert the same map into an implementation-facing UI brief prompt:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate \
  --mode ui-brief-from-map \
  --map-input /tmp/01-scene-map.json \
  --output /tmp/01-ui-brief-prompt.md
```

Before either conversion, run the repository validator:

```sh
python3 tools/validate_scene_ai_contract.py \
  --scene-id 01-illiterate \
  --map /tmp/01-scene-map.json
```

For semi-automated implementation, use the validated map as the source of truth:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate \
  --mode implementation-from-brief \
  --map-input /tmp/01-scene-map.json \
  --brief-input /tmp/01-ui-brief.md
```

## Fields

| Field | Purpose | Review Rule |
| --- | --- | --- |
| `scene_id` | Stable scene id. | Must match `data/story_scenes/<id>.json` and `data/visual_scenes/<id>.json`. |
| `title` | Scene title from story JSON. | Do not invent a marketing title. |
| `sources` | Source scene, story JSON, and visual JSON paths. | Paths must exist in the repo. |
| `source_scene_contract` | Evidence-to-screen-meaning rows. | Each row must be traceable to source text or JSON. |
| `must_read_as` | Required player-visible reading. | Must include era, place, emotion, and core interaction meaning. |
| `must_not_read_as` | Explicit wrong readings to avoid. | This is mandatory for visual UI work. |
| `stable_ids` | Stable IDs for visual, prop, animation, HUD, task, and screenshot work. | Must use prefixes such as `VIS`, `PROP`, `ANIM`, `HUD`, and `SHOT`; implementation prompts must name one of these IDs. |
| `sprint_trace_map` | One-to-one chain from evidence to runtime owner, visual object or asset, screenshot state, and acceptance gate. | Every visual or animation task needs a trace row with a real owner file/function or data field. |
| `location_map` | Location, terrain, spawn, exits, prop semantics, and visual risks. | Every story location must appear. |
| `prop_risks` | Props that can visually mislead the player. | State the required visual or UI correction. |
| `screenshot_states` | Review screenshots and expected visible facts. | IDs must be `SHOT-*` entries from `stable_ids`; include initial state and at least one scene-specific progression state. |
| `implementation_tasks` | Concrete work units. | Each task should use a stable ID or `TASK-*` id and needs inputs, outputs, and observable acceptance. |
| `acceptance_commands` | Repo commands for validation. | Do not leave empty when implementation tasks touch game data, rendering, HUD, or runtime. |
| `affected_files` | Files likely to change. | Keep scope narrow and real; do not include the prompt builder unless the sprint changes generation tooling. |
| `non_goals` | Boundaries for the Sprint Sheet. | Prevents AI from expanding into unrelated systems. |

## Stable ID Rows

`stable_ids` is a compact index. Keep it short, but make it complete enough that
an implementation or asset-generation prompt can name exactly one target.

```json
{
  "id": "PROP-00-02",
  "type": "PROP",
  "label": "声控灯失效",
  "owner": "screen|prop|animation|hud|screenshot"
}
```

Supported prefixes:

- `VIS`: screen-level visual reading.
- `PROP`: interactable or semantic prop.
- `ANIM`: character or prop motion asset.
- `HUD`: HUD, menu, prompt, or overlay state.
- `SHOT`: screenshot review state.

## Sprint Trace Map Rows

`sprint_trace_map` is the executable one-to-one mapping table. It is more
important than a reference image because it says which system must make the
visible fact true.

```json
{
  "id": "PROP-00-02",
  "scene_evidence": "声控灯没有因为你的咳嗽亮起",
  "runtime_function": "RpgPlayerController.current_interaction -> GameSession.apply_action",
  "visual_object_or_animation_asset": "data/visual_scenes/00-prologue-lights-out.json prop kind lamp",
  "owner_file": "scripts/ui/sprite_scene_canvas.gd",
  "owner_function": "_draw_voice_lamp",
  "screenshot_state": "SHOT-00-02",
  "acceptance_gate": "building-lobby screenshot reads as failed voice light, not a torch"
}
```

## Conversion Rule

A Sprint Sheet can be generated from this map only after these checks pass:

- `source_scene_contract` explains why each visual decision exists.
- `must_not_read_as` catches obvious style mismatches.
- `stable_ids` gives every visual, prop, HUD, animation, and screenshot point a
  reviewable ID.
- `sprint_trace_map` maps each stable ID to runtime function, owner file,
  screenshot state, and acceptance gate.
- `location_map` covers every playable location and required exit.
- `screenshot_states` can be captured or simulated.
- `implementation_tasks` are specific enough for an engineer or agent to edit files without re-reading the whole scene.
- `acceptance_commands` includes Godot load and relevant smoke checks.

If any of these fail, regenerate or patch the map before writing the Sprint Sheet.

The validator is intentionally structural. It proves the map is complete enough for automation, not that the art direction is correct. Screenshot review still decides whether the implementation reads as the intended scene.
