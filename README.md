# Dream Coastline

A Godot 4 game prototype.

The current playable slice implements `five/scene/1.md` as a short interactive
opening: a modern room, the strange letter, the black engraved pen, ink
spreading over the page, a flickering-light transition, and the first arrival in
the ancient world with Xia Li. It now uses OpenGameArt CC0 spritesheets for RPG
tiles, characters, spell effects, paper props, and castle scenery.

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

Controls:

- `Space` or left mouse click: advance the scene.
- `Esc`: restart the opening scene.

MCP integration is configured for Codex through `~/.codex/config.toml`. See
`docs/godot-mcp.md` for details.

OpenGameArt sources and license notes are listed in
`assets/opengameart/CREDITS.md`.
