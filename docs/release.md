# Release Checklist

This project targets Godot 4.6.2 desktop exports for Steam-oriented testing.

## Presets

`export_presets.cfg` defines:

- `macOS` -> `builds/macos/Dream Coastline.zip`
- `Windows Desktop` -> `builds/windows/Dream Coastline.exe`
- `Linux/X11` -> `builds/linux/dream-coastline.x86_64`

`project.godot` defines version, description, project icon, and boot splash
image. The current icon/splash image is a CC0 derivative placeholder from the
bundled 16x16 RPG character sheet and should be replaced before final store
submission.

## Local Checks

Validate export preset configuration and report whether local export templates
are installed:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-export-config
```

Export templates must be installed before release/debug exports can produce
platform binaries. On macOS, Godot 4.6.2 expects them under:

```sh
~/Library/Application Support/Godot/export_templates/4.6.2.stable
```

Once templates are installed, create build directories and export:

```sh
tools/build_release_libraries.sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-release-libraries
mkdir -p builds/macos builds/windows builds/linux
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --export-release "macOS" "builds/macos/Dream Coastline.zip"
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --export-release "Windows Desktop" "builds/windows/Dream Coastline.exe"
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --export-release "Linux/X11" "builds/linux/dream-coastline.x86_64"
```

Current local status:

- macOS, Windows, and Linux release exports succeed after
  `tools/build_release_libraries.sh`.
- The Windows and Linux release libraries are cross-linked with `zig` through
  `cargo-zigbuild`, then copied to the `target/release/` paths referenced by
  `dream_coastline.gdextension`.

Pack-only export can be used before templates are installed to validate resource
selection. The presets exclude `tools/**`, `docs/**`, and `five/**` so MCP
tooling, local notes, and design sources are not shipped:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --export-pack "macOS" "/private/tmp/dream-coastline-export-smoke.pck"
```

Release candidates should pass the README smoke suite before export.
