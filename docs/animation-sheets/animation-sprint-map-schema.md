# Animation Sprint Map Schema

`animation_sprint_map` is the intermediate contract between a reviewed Sprint
Trace Map row and an Animation Sheet or generated asset task.

Use it only after a `scene_sprint_map` has introduced a stable `ANIM-*` ID. The
map exists to stop AI from generating a nice-looking sprite package that cannot
enter the current runtime.

## Generate

Start from the reviewed `scene_sprint_map` and choose exactly one animation ID:

```text
ANIM-JZX-01 纪子轩现代步行动画
```

The model should output strict JSON with one top-level key:

```json
{
  "animation_sprint_map": {
    "map_id": "ANIM-JZX-01",
    "scene_id": "00-prologue-lights-out"
  }
}
```

Do not ask an art or coding agent to implement multiple animation IDs in one
prompt unless the IDs share the same actor, atlas, runtime owner, screenshot
states, and acceptance gates.

Validate the generated map before writing an Animation Sheet or generating
assets:

```sh
python3 tools/validate_scene_ai_contract.py \
  --scene-id 00-prologue-lights-out \
  --animation-map /tmp/ANIM-JZX-01-map.json
```

## Fields

| Field | Purpose | Review Rule |
| --- | --- | --- |
| `map_id` | Stable animation trace ID, such as `ANIM-JZX-01`. | Must match a reviewed `scene_sprint_map.stable_ids` entry. |
| `scene_id` | Scene where the animation meaning is proven. | Must point to the scene that owns the evidence or screenshot state. |
| `source_trace_ids` | Related `VIS`, `PROP`, `HUD`, or `SHOT` IDs. | Every referenced ID must exist in the reviewed scene map. |
| `actor_id` | Semantic actor or prop id. | Must match an asset registry key or a proposed registry key. |
| `clip_id` | Runtime animation clip id. | Must match `data/animation_clips/<clip_id>.json` if already implemented. |
| `scene_evidence` | Source evidence that defines the movement meaning. | Must explain emotion and context, not only "walking". |
| `must_read_as` | Required visible reading. | Include age, role, effort, injury/non-injury, and scene mood when relevant. |
| `must_not_read_as` | Explicit wrong animation readings. | Use this to block combat, fantasy, injury, or mascot-like output when wrong. |
| `runtime_contract` | Godot data and function owners. | Must name registry, clip file, repository, renderer, and state inputs. |
| `required_animations` | Required state list. | Current player baseline needs `idle_*` and `walk_*` in four directions. |
| `frame_contract` | Frame size, anchor, render scale, loop, fps, and direction assumptions. | Missing foot anchor or facing rules should block asset import. |
| `asset_outputs` | Files the art or import pass will create. | Include atlas, clip JSON, preview/contact sheet, and source notes. |
| `owner_files` | Repo files expected to change. | Keep this narrow and real. |
| `screenshot_states` | Screenshots or contact sheets used for review. | Must include gameplay-scale proof, not just a large isolated sprite. |
| `acceptance_gates` | Commands and visual checks. | Must include `--smoke-animation-clips` for player clips. |
| `non_goals` | Boundaries for the animation pass. | Prevents broad character redesign or unrelated UI changes. |

## JSON Shape

```json
{
  "animation_sprint_map": {
    "map_id": "ANIM-JZX-01",
    "scene_id": "00-prologue-lights-out",
    "source_trace_ids": ["VIS-00-01", "SHOT-00-01"],
    "actor_id": "jizixuan",
    "clip_id": "player_default",
    "scene_evidence": [
      "普通现代少年",
      "回家道路",
      "灯没亮"
    ],
    "must_read_as": [
      "modern teenager walking home",
      "tired and unsettled but not wounded"
    ],
    "must_not_read_as": [
      "combat injury",
      "fantasy warrior",
      "comic mascot bounce"
    ],
    "runtime_contract": {
      "visual_asset_registry": "data/visual_assets/characters.json",
      "clip_file": "data/animation_clips/player_default.json",
      "repository": "scripts/core/animation_clip_repository.gd",
      "renderer": "scripts/ui/sprite_scene_canvas.gd",
      "state_inputs": [
        "actor_id",
        "moving",
        "facing",
        "elapsed"
      ]
    },
    "required_animations": [
      "idle_down",
      "idle_up",
      "idle_left",
      "idle_right",
      "walk_down",
      "walk_up",
      "walk_left",
      "walk_right"
    ],
    "frame_contract": {
      "tile_size": 16,
      "render_size": 0.74,
      "anchor": "foot center",
      "loop": true,
      "fps_idle": 4,
      "fps_walk": 8
    },
    "asset_outputs": [
      "assets/characters/jizixuan/atlas.png",
      "data/animation_clips/player_default.json",
      "artifacts/animation-sheets/ANIM-JZX-01-contact-sheet.png",
      "artifacts/animation-sheets/ANIM-JZX-01-review.md"
    ],
    "owner_files": [
      "data/visual_assets/characters.json",
      "data/animation_clips/player_default.json",
      "scripts/core/animation_clip_repository.gd",
      "scripts/ui/sprite_scene_canvas.gd"
    ],
    "screenshot_states": [
      {
        "id": "SHOT-00-03",
        "setup": "00-prologue-lights-out street, player moving right",
        "expect": [
          "facing matches controller direction",
          "feet do not drift",
          "motion reads tired but not wounded"
        ]
      }
    ],
    "acceptance_gates": [
      "python3 -m json.tool data/visual_assets/characters.json >/dev/null",
      "python3 -m json.tool data/animation_clips/player_default.json >/dev/null",
      "/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-animation-clips",
      "screenshot/contact-sheet review satisfies SHOT-00-03"
    ],
    "non_goals": [
      "do not redesign the HUD",
      "do not change combat movement rules",
      "do not import unrelated actor packs"
    ]
  }
}
```

## Review Rule

An `animation_sprint_map` is ready only if it answers two questions:

- Which `ANIM-*` ID is being implemented?
- Which runtime registry entry, clip JSON, renderer path, screenshot state, and
  acceptance gate will prove the generated asset actually works in-game?

If either answer is missing, write or repair the map before generating art.
