# Release Checklist

This project targets Godot 4.6.2 desktop exports for Steam-oriented testing.

## Presets

`export_presets.cfg` defines:

- `macOS` -> `builds/macos/Dream Coastline.zip`
- `Windows Desktop` -> `builds/windows/Dream Coastline.exe`
- `Linux/X11` -> `builds/linux/dream-coastline.x86_64`

`project.godot` defines version, description, project icon, and boot splash
image. Branding assets live under `assets/branding/`: the app icon is a compact
square PNG and the splash is a separate 16:9 image.

Resize local branding assets after regeneration:

```sh
tools/resize_branding_assets.py
```

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
python3 tools/run_automated_tests.py --only audio-mix-audit
python3 tools/run_automated_tests.py --only desktop-release-exports
```

Current local status:

- macOS, Windows, and Linux release exports succeed after
  `tools/build_release_libraries.sh`.
- `desktop-release-exports` writes compact logs to
  `artifacts/release-export-logs/`, validates expected binaries and pack files,
  and fails if Godot stores forbidden resources in the player package.
  Godot's compiled `.godot/imported` and `.godot/exported` runtime resources,
  plus export-generated UID/class caches, are expected in those logs.
- The latest export logs show the generated playable backdrops being packaged
  for all three desktop targets, including
  `assets/illustrations/playable/01-illiterate/mud_road.png.import`,
  `assets/illustrations/playable/03-dead-kingdom/library.png.import`,
  `assets/illustrations/playable/04-continuation-institute/institute.png.import`,
  and `assets/illustrations/playable/07-lights-on-again/home.png.import`.
- The latest export logs also include the mastered generated music imports for
  all three desktop targets, spot-checked on
  `assets/audio/generated/music/00-prologue-lights-out/AMB-00-001.mp3.import`,
  `assets/audio/generated/music/06-return-star-plan/MUS-06-001.mp3.import`,
  and `assets/audio/generated/music/07-lights-on-again/MUS-07-006.mp3.import`.
- The Windows and Linux release libraries are cross-linked with `zig` through
  `cargo-zigbuild`, then copied to the `target/release/` paths validated by
  the release smoke gate.
- `audio-mix-audit` passes for 151 generated/loaded MP3 assets and writes a
  local JSON report to `artifacts/audio-mix-audit/latest.json`. It skips 198
  planned or `sample_generation: false` targets, matching runtime missing-audio
  rules, and reports 0 hot-peak warnings after 36 long music/ambience/stinger
  MP3 files were lowered with `tools/master_audio_hot_peaks.py --apply`.
- The exported macOS app currently has a valid ad-hoc signature
  (`Signature=adhoc`, `TeamIdentifier=not set`); `codesign --verify --deep
  --strict` passes after unzipping, but `spctl --assess --type execute` rejects
  the app because it is not Developer ID signed or notarized.

## Distribution Signing

Local export validation does not prove store/distribution readiness. Before a
public macOS release, export with a Developer ID certificate, notarize with
Apple, staple the ticket, and rerun:

```sh
codesign --verify --deep --strict --verbose=2 "Dream Coastline.app"
spctl --assess --type execute --verbose=4 "Dream Coastline.app"
```

Pack-only export can be used before templates are installed to validate resource
selection. The presets exclude `tools/**`, `docs/**`, `five/**`, `.godot/**`,
local config, logs, build/output directories, and editor-only Dialogic/Yarn
Spinner subtrees so MCP tooling, local notes, design sources, generated review
artifacts, editor caches, and editor UI code are not shipped:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --export-pack "macOS" "/private/tmp/dream-coastline-export-smoke.pck"
```

Release candidates should pass the README smoke suite before export.
