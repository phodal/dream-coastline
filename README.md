# Dream Coastline

A Godot 4 RPG slice.

The current playable slice loads narrative scene data from `data/story_scenes/`
and renders the first act with explicit visual scene data from
`data/visual_scenes/`. The Godot version uses OpenGameArt spritesheets for the
play field, character markers, props, portals, and action feedback.

## Godot Structure

- `scripts/main.gd` wires the Godot scene together and handles top-level UI
  actions.
- `scripts/core/scene_database.gd` loads narrative scene JSON.
- `scripts/core/game_session.gd` owns progression, flags, combat, metrics, and
  smoke-test walkthrough execution.
- `scripts/core/scene_visual_repository.gd` loads per-location visual maps.
- `scripts/ui/game_hud.gd` composes the canvas, top bar, prompt overlay, title,
  pause, and settings menus behind a small game-facing API.
- `scripts/ui/sprite_scene_canvas.gd` renders the 90s RPG-style tile scene from
  the visual data and OpenGameArt spritesheets.
- `scripts/ui/prompt_overlay.gd` keeps the compact keyboard prompt and latest
  feedback out of the play field.
- `scripts/ui/game_theme.gd` keeps HUD styling separate from gameplay rules.

## Development

Godot is available at:

```sh
/Applications/Godot.app/Contents/MacOS/Godot
```

Open the project:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
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

## DeepSeek AI

The project includes a small DeepSeek client for scene design assistance. Configure
it with `DEEPSEEK_API_KEY` or a local ignored `deepseek.local.cfg`; see
`docs/deepseek-ai.md`.

Controls work with keyboard or gamepad inside the Godot window. Use the title
screen to start or continue. Move with WASD, arrow keys, or D-pad; interact with
Space, Enter, or gamepad south button; pause with Esc, gamepad east button, or
Start.

MCP integration is configured for Codex through `~/.codex/config.toml`. See
`docs/godot-mcp.md` for details.

Sprint Sheet architecture guidance is in `docs/sprint-sheet-architecture.md`.
Release/export notes are in `docs/release.md`.

OpenGameArt sources and license notes are listed in
`assets/opengameart/CREDITS.md`.
