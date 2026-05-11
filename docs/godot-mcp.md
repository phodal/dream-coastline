# Godot MCP Setup

This project is configured as a Godot 4 project and uses a local source checkout
of `godot-mcp` for Codex.

## Local Godot Path

Godot is installed at:

```sh
/Applications/Godot.app/Contents/MacOS/Godot
```

Verified version:

```sh
4.6.2.stable.official.71f334935
```

## MCP Server For Codex

The MCP server source is checked out at:

```sh
/Users/phodal/game/dream-coastline/tools/godot-mcp
```

It was installed and built with:

```sh
mkdir -p /Users/phodal/game/dream-coastline/tools
git clone https://github.com/Coding-Solo/godot-mcp.git /Users/phodal/game/dream-coastline/tools/godot-mcp
cd /Users/phodal/game/dream-coastline/tools/godot-mcp
npm ci
```

`tools/godot-mcp/` is ignored by this repository because it is a local checkout
of an external MCP server.

Codex uses TOML in `~/.codex/config.toml`, not Cursor's `mcpServers` JSON. The
configured server is:

```toml
[mcp_servers.godot]
command = "node"
args = ["/Users/phodal/game/dream-coastline/tools/godot-mcp/build/index.js"]

[mcp_servers.godot.env]
DEBUG = "true"
GODOT_PATH = "/Applications/Godot.app/Contents/MacOS/Godot"
```

Restart Codex after changing the MCP configuration so the new server is loaded.

## CLI Checks

Run the project from the terminal:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Open the editor:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
```

Run the game:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```
