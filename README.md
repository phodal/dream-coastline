# Dream Coastline

![Dream Coastline title art](assets/branding/dream-coastline-title-loop.png)

Dream Coastline is a 90s-style narrative RPG prototype built with Godot. It
follows a city where names, memory, and light have started to fail, and turns
the story into explorable scenes, inspectable objects, and short cutscene
moments.

The project is currently a playable development slice, not a finished game.
The main runtime is the Nova narrative layer at `res://src/nova/main.tscn`,
with Dialogic used as the cutscene frontend when available.

## Status

- Pre-alpha RPG/narrative prototype.
- Godot 4.6 project with a small optional Rust GDExtension crate.
- Story, visual scene, audio cue, character, creature, and animation data live
  in versioned JSON files under `data/`.
- Automated gates cover static data validation, headless runtime smoke tests,
  Dialogic bridge checks, and local visual screenshot review.

## Features

- Keyboard-driven RPG exploration with visible locations, exits, and
  inspectable story objects.
- Eight authored story chapters, from the prologue through `Lights On Again`.
- Nova runtime for scene progression, story flags, location choices, and
  story-action payloads.
- Nova-native save/continue for restoring the current scene, location, and
  story flags.
- Nova pause menu for resume, save, return-to-title, and exit.
- Dialogic timeline generation and bridge support for native Godot dialogue
  playback.
- Data-backed visual scenes, character models, creature records, equipment,
  supplies, Moqi script glyphs, and animation clip contracts.
- Screenshot and contact-sheet tooling for reviewing scene readability.
- Desktop export notes for macOS, Windows, and Linux.

## Quick Start

Install Godot 4.6.x, then open the project:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
```

Run the current playable runtime:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

On first import, let Godot finish importing project resources before running
smoke tests or taking screenshots.

## Controls

| Action | Keyboard |
| --- | --- |
| Move | WASD / Arrow keys |
| Interact / advance | Space / Enter |
| Continue from title | C, when a Nova save exists |
| Pause / back | Esc |

Gamepad support is available through the Godot input map for movement,
interaction, and cancel/start-style actions.

## Development Setup

The repository expects these local tools for the full workflow:

- Godot 4.6.x
- Python 3
- Rust toolchain, only when working on the GDExtension crate
- Node.js / npm, only for selected audio-generation helpers
- .NET toolchain with `ysc`, only when regenerating Yarn Spinner artifacts

Build the optional Rust GDExtension library:

```sh
cargo build
```

Build release libraries for export presets:

```sh
tools/build_release_libraries.sh
```

## Testing

Most changes should start with the quick gate:

```sh
python3 tools/run_automated_tests.py --tier quick
```

Use the headless gate before opening a pull request:

```sh
python3 tools/run_automated_tests.py --tier headless
```

Use the visual gate when touching scene layout, HUD, visual assets, tile
generation, character art, or animation clips:

```sh
python3 tools/run_automated_tests.py --tier visual
```

The tier definitions and acceptance rules are documented in
[`docs/automated-testing.md`](docs/automated-testing.md).

Useful focused checks:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-nova-runtime
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-nova-progression
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-nova-save-continue
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-nova-pause-flow
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 -- --smoke-dialogic-bridge
python3 tools/validate_story_continuity.py --verbose
python3 tools/validate_dialogic_timelines.py
```

Capture a visual review set from the active Nova screenshot path:

```sh
python3 tools/capture_scene_screenshots.py --scope starts
```

This writes review artifacts under `artifacts/scene-screenshots/latest/`.
Screenshot review is required for visual readability; render smoke only proves
that the frame is not blank.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `src/nova/` | Current runtime: scene director, exploration view, VN layer, Dialogic bridge, and autoload state. |
| `data/story_scenes/` | Authored chapter and location content. |
| `data/visual_scenes/` | Visual scene metadata consumed by Nova. |
| `dialogic/` | Generated Dialogic characters and timelines. |
| `assets/` | Branding, character art, illustrations, fonts, UI assets, and visual tiles. |
| `tools/` | Validation, generation, screenshot, audio, and release helper scripts. |
| `docs/` | Testing, release, Sprint Sheet, visual, audio, and design notes. |
| `addons/` | Vendored Godot plugins such as Dialogic and Yarn Spinner experiments. |

## Content Pipeline

The project treats story and scene data as source files. Common workflows:

- Generate Dialogic timelines from story data with
  `tools/generate_dialogic_timelines.py`.
- Validate timeline drift with `tools/validate_dialogic_timelines.py`.
- Validate cross-chapter story continuity with
  `tools/validate_story_continuity.py --verbose`.
- Build and validate Moqi script font assets with `tools/build_moqi_font.py`
  and `res://tools/validate_moqi_font.gd`.
- Prepare AI-assisted scene work with `tools/build_sprint_sheet_prompt.py`
  and validate the resulting contracts with
  `tools/validate_scene_ai_contract.py`.

More detail is available in:

- [`docs/sprint-sheet-architecture.md`](docs/sprint-sheet-architecture.md)
- [`docs/sprint-sheets/`](docs/sprint-sheets/)
- [`docs/character-visual-models.md`](docs/character-visual-models.md)
- [`docs/ai-dialogue-voice-pipeline.md`](docs/ai-dialogue-voice-pipeline.md)
- [`docs/release.md`](docs/release.md)

## Contributing

Contributions should keep runtime behavior, source data, and validation in
sync. A good change usually includes:

1. A focused code or data diff.
2. The smallest relevant automated gate from the testing section.
3. Screenshot evidence when the change affects visual readability.
4. Updated docs when a workflow, command, or data contract changes.

Please avoid committing generated review artifacts unless they are part of the
change being reviewed.

## License

See [`LICENSE`](LICENSE) for repository license details.
