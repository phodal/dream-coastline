# Dream Coastline

A Godot 4 game prototype.

The current playable slice loads the scene data in `data/ascii_scenes/` and
presents it through a Godot UI: scene navigation, location art, story text,
progress, metrics, event log, and action buttons for movement, investigation,
glyph casting, building, choices, combat, and final word combinations.

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

Run the fast ASCII prototype for `five/scene` work:

```sh
python3 tools/ascii_five.py
python3 tools/ascii_five.py --verify
python3 tools/ascii_five.py --report
```

Controls are button-driven inside the Godot window. Use the top bar to switch
scenes and the bottom action panel to move, inspect, cast glyphs, build, choose
routes, fight, or complete word combinations.

MCP integration is configured for Codex through `~/.codex/config.toml`. See
`docs/godot-mcp.md` for details.

OpenGameArt sources and license notes are listed in
`assets/opengameart/CREDITS.md`.
