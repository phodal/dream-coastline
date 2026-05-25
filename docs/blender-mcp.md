# Blender MCP Setup

This project can use `blender-mcp` from Codex to inspect and generate Blender
assets. It has two moving parts:

1. Blender runs the Blender MCP addon and listens on `localhost:9876`.
2. Codex starts the MCP stdio server with `uvx blender-mcp`.

## Local Blender Path

Blender is installed at:

```sh
/Applications/Blender.app/Contents/MacOS/Blender
```

Verified version:

```sh
Blender 5.1.2
```

## Blender Addon

The addon file is installed at:

```sh
/Users/phodal/Library/Application Support/Blender/5.1/scripts/addons/addon.py
```

In Blender:

1. Open `Edit > Preferences > Add-ons`.
2. Enable `Blender MCP`.
3. Open the 3D View sidebar and switch to the `BlenderMCP` panel.
4. Click `Connect to MCP server`.

The addon should listen on:

```sh
localhost:9876
```

Quick socket check:

```sh
python3 - <<'PY'
import socket
s = socket.socket()
s.settimeout(2)
s.connect(("127.0.0.1", 9876))
print("Blender MCP addon socket is open")
s.close()
PY
```

## MCP Server For Codex

Codex uses TOML in `~/.codex/config.toml`. Configure the server as:

```toml
[mcp_servers.blender]
type = "stdio"
command = "/Users/phodal/.local/bin/uvx"
args = ["blender-mcp"]
enabled = true
```

Using the absolute `uvx` path avoids PATH differences when Codex is launched
from the macOS app.

Restart Codex or open a new Codex session after changing this file so the new
MCP server is loaded.

## Smoke Checks

When Blender has the addon connected, `uvx blender-mcp` should connect on
startup:

```sh
/Users/phodal/.local/bin/uvx blender-mcp --help
```

A successful check logs that it connected to Blender and read the addon status.
If it says `Connection refused`, open Blender and click `Connect to MCP server`
in the BlenderMCP panel.

For an end-to-end MCP call, run:

```sh
/Users/phodal/.local/bin/uvx --from blender-mcp python - <<'PY'
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def main():
    params = StdioServerParameters(
        command="/Users/phodal/.local/bin/uvx",
        args=["blender-mcp"],
    )
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            result = await session.call_tool(
                "get_scene_info",
                {"user_prompt": "Verify the current Blender scene."},
            )
            for item in result.content:
                print(getattr(item, "text", item))

asyncio.run(main())
PY
```

## Character Asset Workflow

For Dream Coastline character modeling:

1. Start from `data/character_visual_models.json`.
2. Keep the existing UI image, usually `assets/characters/main/<id>/model_sheet.png`,
   visible as a Blender reference plane.
3. Preserve the stable silhouette and palette before adding detail.
4. Save the `.blend` file next to the character assets.
5. Render a preview PNG next to the `.blend` so the model can be reviewed
   against the UI sheet without reopening Blender.

