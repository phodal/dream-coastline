# Automated Testing Strategy

Dream Coastline already has several validation surfaces: Python contract
validators, ASCII scene walkthroughs, Rust-backed Godot smoke tests, and
viewport screenshot capture. The automated test design should keep those layers
separate because they answer different questions.

## Goals

- Catch story, data, and asset-contract regressions before opening Godot.
- Verify the current main runtime path, which uses `RustGameSession` and
  `RustRpgPlayerController`, not only the GDScript reference implementation.
- Keep headless CI deterministic and fast enough for every pull request.
- Treat render smoke as render health only; scene style acceptance still needs a
  screenshot manifest and human-visible review facts.
- Make visual work traceable from `VIS/PROP/ANIM/HUD/SHOT-*` IDs to owner files,
  screenshot states, and acceptance commands.

## Test Tiers

| Tier | Purpose | Default runner command | Runs in CI |
|------|---------|------------------------|------------|
| `quick` | Static data, Python tooling, Rust build, and high-signal contract checks. | `python3 tools/run_automated_tests.py --tier quick` | No |
| `headless` | Full pull-request gate without opening a visible renderer. | `python3 tools/run_automated_tests.py --tier headless` | Yes |
| `visual` | Local screenshot and renderer review for scene, prop, HUD, and animation changes. | `python3 tools/run_automated_tests.py --tier visual` | No |
| `release` | Export-facing checks and release-library validation. | `python3 tools/run_automated_tests.py --tier release` | Tag/release only |

The tiers are cumulative. `headless` includes `quick`; `visual` includes
`quick` and `headless`; `release` includes `quick`, `headless`, and release
checks.

## Quick Gate

The quick gate is for normal editing. It should fail before the engine boots if
the repo data is structurally wrong.

- Parse all JSON under `data/`.
- Compile top-level Python tools with `py_compile`.
- Run every authored ASCII scene through `tools/ascii_five.py <scene> --verify`.
- Run `tools/validate_story_continuity.py --verbose`.
- Run `tools/validate_equipment_catalog.py`.
- Run `tools/validate_supply_catalog.py`.
- Build the Rust GDExtension with `cargo build`, so Godot can load the current
  Rust classes.
- Run the headless Godot project-load check.
- Run focused Godot smoke checks for progression, input mapping, animation
  clips, and visual asset scene contracts.

## Headless Gate

The headless gate is the pull-request gate. It proves that the Rust-backed
runtime can boot and complete the current deterministic routes.

- `--smoke-autoplay`
- `--smoke-rpg-first-act`
- `--smoke-rpg-illiterate`
- `--smoke-rpg-moqi-academy`
- `--smoke-rpg-dead-kingdom`
- `--smoke-rpg-continuation-institute`
- `--smoke-rpg-century-continuation`
- `--smoke-rpg-return-star-plan`
- `--smoke-rpg-lights-on-again`
- `--smoke-rpg-progression`
- `--smoke-save-load`
- `--smoke-menu-flow`
- `--smoke-audio-director`
- `--smoke-export-config`
- `--smoke-input-map`
- `--smoke-animation-clips`
- `--smoke-visual-asset-scenes`

This tier should not include visible renderer screenshots. It should be safe on
GitHub Actions Linux runners.

## Visual Gate

Use the visual gate whenever a change touches `scripts/ui/`,
`data/visual_scenes/`, `data/visual_assets/`, `data/animation_clips/`,
`assets/visual_tiles/`, or `scenes/visual_locations/`.

- Run `--smoke-render-frame` without `--headless` to prove a visible frame is
  not blank.
- Run `tools/capture_scene_screenshots.py --scope starts` for a review contact
  sheet.
- For a scene-specific Sprint Sheet or UI brief, run screenshots for that scene
  and review the manifest against the original `SHOT-*` states.
- Reject visual work if the manifest reports unexpected
  `procedural_fallback_count` or if the contact sheet violates
  `must_read_as` / `must_not_read_as` facts from the source map.

Render smoke is not a style test. A passing `render-frame-smoke` only says the
viewport is non-empty and varied enough; it cannot prove a modern apartment, a
black window, a vending machine, or a Moqi archive reads correctly.

## Contract Gate For AI-Assisted Work

Before implementation generated from scene evidence:

```sh
python3 tools/validate_scene_ai_contract.py --scene-id 01-illiterate --map /tmp/01-scene-map.json --brief /tmp/01-ui-brief.md
```

After implementation:

```sh
python3 tools/capture_scene_screenshots.py --scene 01-illiterate --scope locations
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode screenshot-review-from-map --map-input /tmp/01-scene-map.json --screenshot-manifest artifacts/scene-screenshots/latest/manifest.json
```

The generated review prompt is not the acceptance result by itself. Acceptance
requires checking the screenshots and manifest against the source scene
contract.

## CI Shape

Pull requests should run one job:

1. Checkout.
2. Install/download Godot.
3. Run `python3 tools/run_automated_tests.py --tier headless --godot ./godot`.

Release tags should add export templates and run the release tier before
packaging binaries.

## Adding A New Automated Test

Every new test should declare:

- Test tier: `quick`, `headless`, `visual`, or `release`.
- Trigger: which files or feature changes require it.
- Runtime owner: Python tool, Rust build, Godot smoke flag, or screenshot tool.
- Acceptance text: the exact PASS line, manifest field, or failure condition.
- Non-goal: what the test does not prove.

For new visual or animation work, add a stable trace ID first. A test without a
`SHOT-*` or related `VIS/PROP/ANIM/HUD-*` anchor is usually too vague to
automate safely.
