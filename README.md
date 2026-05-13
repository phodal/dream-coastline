# Dream Coastline

A Godot 4.6 RPG slice with keyboard and gamepad support, save/load, and
desktop export readiness for macOS, Windows, and Linux.

The playable slice loads narrative scene data from `data/story_scenes/` and
renders multiple story arcs with explicit visual scene data from
`data/visual_scenes/`. The Godot version uses OpenGameArt spritesheets for the
play field, character markers, props, portals, and action feedback.
The repository-backed data, save, and settings services also have Rust
GDExtension equivalents under `src/`, loaded through
`dream_coastline.gdextension`.

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

- `scripts/main.gd` wires the Godot scene together and handles top-level UI
  actions.
- `scripts/core/scene_database.gd` loads narrative scene JSON.
- `scripts/core/game_session.gd` owns progression, flags, combat, metrics, and
  smoke-test walkthrough execution.
- `scripts/core/rpg_player_controller.gd` handles tile movement, facing, and
  blocked feedback.
- `scripts/core/scene_visual_repository.gd` loads per-location visual maps.
- `scripts/core/audio_director.gd` provides generated fallback audio streams.
- `scripts/core/settings_repository.gd` persists volume and preferences.
- `scripts/core/save_game_repository.gd` handles save/load serialization.
- `scripts/ui/game_hud.gd` composes the canvas, top bar, prompt overlay, title,
  pause, and settings menus behind a small game-facing API.
- `scripts/ui/title_screen.gd` renders the title with new game and continue
  options.
- `scripts/ui/pause_menu.gd` provides in-game pause with save/load/settings.
- `scripts/ui/settings_menu.gd` exposes volume and preference controls.
- `scripts/ui/sprite_scene_canvas.gd` renders the tile scene from the visual
  data and OpenGameArt spritesheets.
- `scripts/ui/prompt_overlay.gd` keeps the compact keyboard prompt and latest
  feedback out of the play field.
- `scripts/ui/game_theme.gd` keeps HUD styling separate from gameplay rules.

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

Validate the project can load:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

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

Validate keyboard/gamepad input mapping:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-input-map
```

Validate a rendered game frame. This uses the real renderer, so run it without
`--headless`:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --quit-after 120 -- --smoke-render-frame
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
Release/export notes are in `docs/release.md`.

OpenGameArt sources and license notes are listed in
`assets/opengameart/CREDITS.md`.
