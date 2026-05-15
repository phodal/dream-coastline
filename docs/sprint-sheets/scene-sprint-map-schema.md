# Scene Sprint Map Schema

`scene_sprint_map` is the intermediate contract between a source scene and a Sprint Sheet.

Use it when AI helps generate Sprint Sheets. The model should first map scene evidence, playable JSON, and visual JSON into this structured object; only then should a human or second prompt turn the map into a full Sprint Sheet. This prevents a direct jump from prose to vague UI work.

## Generate

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode map --output /tmp/01-scene-map-prompt.md
codex exec --cd . --sandbox read-only --output-last-message /tmp/01-scene-map.json "$(cat /tmp/01-scene-map-prompt.md)"
```

The prompt asks for strict JSON with one top-level key:

```json
{
  "scene_sprint_map": {}
}
```

Then convert the reviewed map into a Sprint Sheet prompt:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate \
  --mode sheet-from-map \
  --map-input /tmp/01-scene-map.json \
  --output /tmp/01-sheet-from-map-prompt.md
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
| `location_map` | Location, terrain, spawn, exits, prop semantics, and visual risks. | Every story location must appear. |
| `prop_risks` | Props that can visually mislead the player. | State the required visual or UI correction. |
| `screenshot_states` | Review screenshots and expected visible facts. | Must include initial state and at least one scene-specific progression state. |
| `implementation_tasks` | Concrete work units. | Each task needs inputs, outputs, and observable acceptance. |
| `acceptance_commands` | Repo commands for validation. | Do not leave empty when implementation tasks touch game data, rendering, HUD, or runtime. |
| `affected_files` | Files likely to change. | Keep scope narrow and real; do not include the prompt builder unless the sprint changes generation tooling. |
| `non_goals` | Boundaries for the Sprint Sheet. | Prevents AI from expanding into unrelated systems. |

## Conversion Rule

A Sprint Sheet can be generated from this map only after these checks pass:

- `source_scene_contract` explains why each visual decision exists.
- `must_not_read_as` catches obvious style mismatches.
- `location_map` covers every playable location and required exit.
- `screenshot_states` can be captured or simulated.
- `implementation_tasks` are specific enough for an engineer or agent to edit files without re-reading the whole scene.
- `acceptance_commands` includes Godot load and relevant smoke checks.

If any of these fail, regenerate or patch the map before writing the Sprint Sheet.
