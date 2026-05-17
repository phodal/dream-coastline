# AI Tile Designer

This document defines the second version of the tile authoring workflow for
Dream Coastline. It keeps Godot's TileMap editor as the real level-design
surface, but adds an AI-readable recipe layer above it so scene evidence can be
turned into repeatable TileMap edits and screenshot review states.

## Position

Do not build a standalone Tile Editor first.

Godot already owns the useful TileMap authoring primitives: selecting one or
more tiles, painting, lines, rectangles, bucket fill, scattering, patterns, and
terrain connection modes. The missing layer in this project is not another
canvas UI; it is a contract that lets an AI model say which Godot authoring
primitive should be used, on which `TileMapLayer`, with which semantic tile or
pattern, and which screenshot must prove the result.

The editor remains Godot. The AI layer produces a recipe.

## Godot TileMap Concepts To Preserve

The recipe model mirrors Godot's TileMap workflow instead of inventing new
verbs.

| Godot concept | AI recipe equivalent | Dream Coastline use |
| --- | --- | --- |
| Active `TileMapLayer` | `layer` | Keep `ground`, `walls`, `decor`, `props_shadow`, and `lighting` separate. |
| Single or multi-tile selection | `tile` or `selection` | Paint a prop, a wall fragment, or a repeated multi-tile object. |
| Paint | `paint` | Place a rune, phone, pen, shadow, glow, or single detail. |
| Line | `line` | Draw roads, boundary walls, chase paths, and rune strokes. |
| Rectangle | `rect` | Fill rooms, platforms, wall blocks, and building silhouettes. |
| Bucket Fill | `fill` | Replace a whole layer or bounded area with a base terrain. |
| Eraser | `erase` | Clear old generated details before applying a reviewed recipe. |
| Scattering | `scatter` | Break grid repetition with grass, rubble, ash, paper, or noise. |
| Patterns | `pattern` | Place authored clusters such as a refugee camp or blanking station altar. |
| Terrain `Connect` | `terrain_connect` | Auto-connect walls, floors, forest edges, or ruin boundaries. |
| Terrain `Path` | `terrain_path` | Keep artist control for roads or chase routes that should not over-connect. |
| Specific terrain tile override | `override_tile` | Fix corners or story-critical focal tiles manually. |

The Godot documentation's TileMap sections on [tile selection, painting modes,
scattering, patterns, and terrain modes](https://docs.godotengine.org/en/latest/tutorials/2d/using_tilemaps.html#selecting-tiles-to-use-for-painting)
are the source model for these verbs.

## Pipeline

```text
Scene evidence / Sprint Sheet / Visual JSON
        |
        v
AI Tile Design Prompt
        |
        v
ai_tile_recipe.json
        |
        v
Godot applicator script
        |
        v
scenes/visual_locations/<scene>/<location>.tscn
        |
        v
smoke + screenshot capture
        |
        v
AI screenshot review against the same recipe and scene contract
```

The AI model is allowed to decide composition, pattern choice, density, and
review facts. It is not allowed to directly rewrite `.tscn` files or bypass the
existing screenshot gate.

## Recipe Shape

Recipes are JSON files stored under:

```text
data/tile_recipes/<scene_id>/<location_id>.ai_tile_recipe.json
```

The minimal shape is:

```json
{
  "schema": "dream-coastline.ai_tile_recipe.v1",
  "scene_id": "01-illiterate",
  "location_id": "station",
  "source_contract": {
    "must_read_as": [
      "blanking station",
      "name rune focus",
      "enemy cannot be locked before naming"
    ],
    "must_not_read_as": [
      "generic ruin",
      "normal monster arena"
    ]
  },
  "patterns": {
    "blanking_station_name_rune": {
      "size": [5, 4],
      "layers": {
        "decor": [
          "..r..",
          ".rnr.",
          "..s..",
          "....."
        ],
        "lighting": [
          "..c..",
          ".ccc.",
          "..d..",
          "....."
        ]
      },
      "legend": {
        "r": "rune",
        "n": "node",
        "s": "shadow",
        "c": "cyan_glow",
        "d": "danger_glow"
      }
    }
  },
  "operations": [
    {
      "id": "TILE-01-STATION-001",
      "layer": "ground",
      "tool": "fill",
      "tile": "ruin_floor",
      "area": [0, 0, 15, 9]
    },
    {
      "id": "TILE-01-STATION-002",
      "layer": "decor",
      "tool": "scatter",
      "selection": ["rune", "shadow"],
      "area": [1, 1, 13, 7],
      "density": 0.16,
      "seed": 101
    },
    {
      "id": "TILE-01-STATION-003",
      "tool": "pattern",
      "pattern": "blanking_station_name_rune",
      "at": [5, 2]
    }
  ],
  "screenshot_states": [
    {
      "id": "SHOT-01-STATION-BEFORE-NAME",
      "location": "station",
      "flags": [],
      "expect": [
        "center reads as a name-rune focus",
        "enemy presence is implied by shadow and blank space",
        "screen does not read as a normal ruin combat arena"
      ]
    },
    {
      "id": "SHOT-01-STATION-AFTER-NAME",
      "location": "station",
      "flags": ["learned_name_strokes", "named_beast"],
      "expect": [
        "the nameless beast is now visually targetable",
        "the name rune still owns the visual focus"
      ]
    }
  ]
}
```

The legend is local to each pattern so the AI can describe compact shapes
without exposing Godot's serialized `PackedByteArray`.

## Applicator Contract

The applicator should be a Godot script, not a Python `.tscn` writer.

```text
tools/apply_ai_tile_recipe.gd
```

Responsibilities:

- load `data/visual_assets/tilesets.json`;
- map tile IDs such as `ruin_floor` or `cyan_glow` to atlas coordinates;
- load the target `asset_scene` from `data/visual_scenes/<scene_id>.json`;
- find the required `TileMapLayer` nodes;
- apply v1 operations: `fill`, `paint`, `line`, `rect`, `scatter`, `pattern`,
  and `erase`;
- leave `terrain_connect`, `terrain_path`, and `override_tile` as explicit v2
  extensions once the current normalized TileSet has terrain metadata;
- save the scene through Godot's `ResourceSaver`;
- report changed scene path and recipe operation IDs.

It should reject a recipe when:

- `scene_id` or `location_id` does not match visual JSON;
- a layer name is not one of the project layers;
- a tile ID is absent from `data/visual_assets/tilesets.json`;
- an operation writes outside the 15x9 authored grid;
- a pattern contains an unknown legend symbol;
- `screenshot_states` is empty.

## Godot MCP Role

Godot MCP should orchestrate the loop. It does not need to become a full TileMap
editing API for the first version.

Useful MCP actions:

- `launch_editor`: open the project for human inspection after a recipe is
  applied.
- `run_project`: run the game or a focused scene after the `.tscn` is updated.
- future wrapper: expose `apply_ai_tile_recipe` as a project-specific tool that
  calls Godot with `--script tools/apply_ai_tile_recipe.gd`.

The project-local command remains the stable fallback:

```sh
/Applications/Godot.app/Contents/MacOS/Godot \
  --path . \
  --headless \
  --script tools/apply_ai_tile_recipe.gd \
  -- data/tile_recipes/01-illiterate/station.ai_tile_recipe.json
```

## First-Act MVP

Implement one location recipe at a time. Do not ask AI to redesign all first-act
locations in one pass.

| Recipe | Stable intent | Required pattern |
| --- | --- | --- |
| `mud_road.ai_tile_recipe.json` | phone failure, broken sign, black pen, burning city evidence | `burning_city_evidence` |
| `camp.ai_tile_recipe.json` | refugee survival, Xiaoyan, campfire, live-ink notice | `refugee_camp_cluster` |
| `chase.ai_tile_recipe.json` | pursuit pressure, soldiers, Xiali judgment, half-lit gate | `pursuit_gate_pressure` |
| `station.ai_tile_recipe.json` | blanking station, `名` focus, nameless beast lock state | `blanking_station_name_rune` |

Start with `station`. It tests the whole design because the same location must
support before-name and after-name screenshot states, not just a static layout.

## AI Prompt Contract

The prompt for the AI tile designer should include:

- `docs/sprint-sheets/01-illiterate.md`;
- `docs/sprint-sheets/01-illiterate-ui-brief.md`;
- `data/story_scenes/01-illiterate.json`;
- `data/visual_scenes/01-illiterate.json`;
- `data/visual_assets/tilesets.json`;
- this document;
- the requested location ID and one target stable ID.

The model output must be a single JSON recipe. It should not include prose,
implementation commentary, or changes to gameplay flags.

## Acceptance

For every recipe application:

```sh
python3 -m json.tool data/tile_recipes/01-illiterate/station.ai_tile_recipe.json >/dev/null
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-visual-asset-scenes
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-rpg-illiterate
python3 tools/capture_scene_screenshots.py --scene 01-illiterate --scope locations
python3 tools/build_sprint_sheet_prompt.py 01-illiterate \
  --mode screenshot-review-from-map \
  --map-input /tmp/01-scene-map.json \
  --screenshot-manifest artifacts/scene-screenshots/latest/manifest.json
```

The screenshot review must check the recipe's `must_read_as`,
`must_not_read_as`, and `screenshot_states`. A passing render smoke only proves
that the frame is non-empty.

## Implementation Order

1. Add a JSON validator for `ai_tile_recipe.v1`.
2. Add `tools/apply_ai_tile_recipe.gd` with `fill`, `paint`, `rect`,
  `scatter`, `erase`, and `pattern`.
3. Add `station.ai_tile_recipe.json`.
4. Apply it and capture first-act screenshots.
5. Extend the applicator only if `station` proves the recipe format is useful.
6. Add `mud_road`, `camp`, and `chase` recipes.
7. Wrap the applicator through Godot MCP only after the command-line flow is
   stable.

## Non-Goals

- Do not replace Godot's TileMap editor.
- Do not ask AI to edit `.tscn` serialized tile data directly.
- Do not redesign later acts in the first pass.
- Do not use screenshot review as a purely aesthetic judgment; it must trace to
  scene evidence.
- Do not generate new external tilesheets until the recipe layer proves it can
  use the current normalized tileset.
