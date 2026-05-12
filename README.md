# Dream Coastline

A Godot 4 RPG slice.

The current playable slice loads narrative scene data from `data/story_scenes/`
and renders the first act with explicit visual scene data from
`data/visual_scenes/`. The Godot version uses OpenGameArt spritesheets for the
play field, character markers, props, portals, and action feedback instead of
showing ASCII art in the window.

## Godot Structure

- `scripts/main.gd` wires the Godot scene together and handles top-level UI
  actions.
- `scripts/core/scene_database.gd` loads narrative scene JSON.
- `scripts/core/game_session.gd` owns progression, flags, combat, metrics, and
  smoke-test walkthrough execution.
- `scripts/core/scene_visual_repository.gd` loads per-location visual maps.
- `scripts/ui/sprite_scene_canvas.gd` renders the 90s RPG-style tile scene from
  the visual data and OpenGameArt spritesheets.
- `scripts/ui/game_theme.gd` keeps the small HUD styling separate from gameplay
  rules.

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

Validate save/load:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-save-load
```

Validate title/pause/settings flow:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-menu-flow
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

Run the fast scene verifier for `five/scene` work:

```sh
python3 tools/ascii_five.py
python3 tools/ascii_five.py --verify
python3 tools/ascii_five.py --report
```

Controls are keyboard-driven inside the Godot window. Use the title screen to
start or continue, WASD or the arrow keys to move, Space or Enter to interact
with nearby exits and investigation targets, and Esc to pause, save, or load.

MCP integration is configured for Codex through `~/.codex/config.toml`. See
`docs/godot-mcp.md` for details.

Sprint Sheet architecture guidance is in `docs/sprint-sheet-architecture.md`.

OpenGameArt sources and license notes are listed in
`assets/opengameart/CREDITS.md`.
