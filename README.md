# Dream Coastline

A Godot 4.6 RPG slice now re-architected around the copied
`godot-open-rpg` field runtime: autoloaded field services, grid movement,
gamepieces, cutscenes, and interactions drive the playable spine.

The current main scene is `res://src/main.tscn`. It loads Dream Coastline story
data from `data/story_scenes/`, loads the original asset-backed location scenes
from `data/visual_scenes/` and `scenes/visual_locations/`, then presents them
through OpenRPG-style `Gameboard`, `Gamepiece`, `PlayerController`,
`Interaction`, and `Cutscene` objects. The previous `scripts/ui/*`
HUD/title/pause stack is retained in the repository for reference, but it is not
part of the current main runtime.

## Features

- Tile-based 90s RPG exploration with animated player sprites and facing
- Eight complete story paths: First Act, Illiterate, Moqi Academy, Dead Kingdom,
  Continuation Institute, Century Continuation, Return Star Plan, Lights On Again
- Title screen with new game, continue, and return-to-title confirmations
- Pause menu and settings with volume control
- Save/load via `SaveGameRepository`
- Fallback audio director for generated sound streams
- Gamepad and left stick support alongside keyboard
- Desktop export presets for macOS, Windows, and Linux

## Godot Structure

- `src/main.tscn` is the active main scene.
- `src/common/` and `src/field/` are copied OpenRPG runtime components:
  directions, player state, field camera, gameboard/pathfinder, gamepieces,
  player controller, cutscenes, triggers, and interactions.
- `project.godot` autoloads `Camera`, `FieldEvents`, `Gameboard`,
  `GamepieceRegistry`, and `Player` for the OpenRPG field model.
- `src/dream/dream_field.gd` adapts Dream Coastline data to OpenRPG rooms,
  player movement, original location scenes, world labels, and interactions.
- `src/dream/dream_story_repository.gd` loads all eight story JSON files and
  applies inspect/go/cast/build/choose/engage/combat/combo progression.
- `src/dream/dream_visual_repository.gd` loads `data/visual_scenes/*.json`,
  verifies every `asset_scene`, and gives OpenRPG the original prop/spawn
  coordinates.
- `src/dream/dream_story_interaction.gd` turns story records into OpenRPG
  `Interaction` cutscenes.
- `src/dream/dream_dialogue_layer.gd` provides the new minimal dialogue layer;
  it does not reuse the previous HUD/title/pause UI.

## Development

Godot 4.6.2 is available at:

```sh
/Applications/Godot.app/Contents/MacOS/Godot
```

Open the project:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
```

Build the Rust GDExtension library:

```sh
cargo build
```

Build release GDExtension libraries for desktop export:

```sh
tools/build_release_libraries.sh
```

Validate the project can load:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Validate the OpenRPG migration:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-open-rpg-story
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-open-rpg-runtime
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-open-rpg-actions
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-open-rpg-visual-scenes
```

Run the tiered automated test gates:

```sh
python3 tools/run_automated_tests.py --tier quick
python3 tools/run_automated_tests.py --tier headless
python3 tools/run_automated_tests.py --tier visual
```

The test strategy and tier definitions live in
`docs/automated-testing.md`.

Validate the Godot scene runner can complete every implemented scene:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-autoplay
```

Validate the first act RPG keyboard path:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-first-act
```

Validate the illiterate scene RPG keyboard path:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-illiterate
```

Validate the Moqi Academy RPG keyboard path:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-moqi-academy
```

Validate the dead kingdom RPG keyboard path:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-dead-kingdom
```

Validate the continuation institute RPG keyboard path:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-continuation-institute
```

Validate the century continuation RPG keyboard path:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-century-continuation
```

Validate the return star plan RPG keyboard path:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-return-star-plan
```

Validate the lights on again RPG keyboard path:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-lights-on-again
```

Validate the RPG progression data slice:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-progression
```

Validate save/load:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-save-load
```

Validate title/pause/settings flow:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-menu-flow
```

Validate generated fallback audio streams:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-audio-director
```

Validate export preset configuration:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-export-config
```

Validate release GDExtension libraries for macOS, Windows, and Linux:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-release-libraries
```

Validate keyboard/gamepad input mapping:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-input-map
```

Validate animation clip contracts for the current player actor:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-animation-clips
```

Validate a rendered game frame. This uses the real renderer, so run it without
`--headless`:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --quit-after 120 -- --smoke-render-frame
```

Capture a visual review set for every authored location. This also writes
`manifest.json` and a local `index.html` contact sheet under
`artifacts/scene-screenshots/latest/`:

```sh
python3 tools/capture_scene_screenshots.py
```

Compare the same scene under the classic dark profile:

```sh
python3 tools/capture_scene_screenshots.py --scene 02-moqi-academy --visual-style classic_dark
```

Capture only the opening state for each scene:

```sh
python3 tools/capture_scene_screenshots.py --scope starts
```

## Controls

Keyboard or gamepad inside the Godot window. Use the title screen to start or
continue.

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | WASD / Arrow keys | D-pad / Left stick |
| Interact | Space / Enter | South button |
| Pause | Esc | East button / Start |

## DeepSeek AI

The project includes a small DeepSeek client for scene design assistance. Configure
it with `DEEPSEEK_API_KEY` or a local ignored `deepseek.local.cfg`; see
`docs/deepseek-ai.md`.

MCP integration is configured for Codex through `~/.codex/config.toml`. See
`docs/godot-mcp.md` for details.

Sprint Sheet architecture guidance is in `docs/sprint-sheet-architecture.md`.
Scene-aligned Sprint Sheets, the `scene_sprint_map` AI mapping contract, UI implementation brief workflow, and prompt workflow are in
`docs/sprint-sheets/`.
Release/export notes are in `docs/release.md`.

Runtime scene tiles are generated in-repo by
`tools/generate_visual_asset_scenes.gd` and written to
`assets/visual_tiles/dream_scene_tiles.png` plus
`assets/visual_tiles/dream_scene_tileset.tres`.
