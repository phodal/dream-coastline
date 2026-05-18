# Automated Testing Strategy

Dream Coastline now uses the Nova narrative runtime as the main path. The
automated tests keep static story/data validation separate from Godot runtime
smoke checks and visible screenshot review because those layers answer
different questions.

## Goals

- Catch story, data, and asset-contract regressions before opening Godot.
- Verify the current main runtime path: `SceneDirector` + `ExplorationView` +
  `VNLayer` with Dialogic available as the cutscene frontend.
- Keep headless CI deterministic and fast enough for every pull request.
- Treat render smoke as render health only; scene style acceptance still needs a
  screenshot manifest and human-visible review facts.
- Make visual work traceable from `VIS/PROP/ANIM/HUD/SHOT-*` IDs to owner files,
  screenshot states, and acceptance commands.

## Test Tiers

| Tier | Purpose | Default runner command | Runs in CI |
|------|---------|------------------------|------------|
| `quick` | Static data, Python tooling, story contracts, and high-signal runtime checks. | `python3 tools/run_automated_tests.py --tier quick` | No |
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
- Run the headless Godot project-load check.
- Run `--smoke-nova-runtime` to prove the new exploration/cutscene path can
  read story and visual JSON.
- Run `--smoke-dialogic-bridge` to prove Dialogic is installed and the Nova
  payload can be converted to a Dialogic timeline.

## Headless Gate

The headless gate is the pull-request gate. It proves that the Nova runtime can
boot from the preserved story/material data and that Dialogic is available for
non-headless cutscene playback.

- `--smoke-nova-runtime`
- `--smoke-dialogic-bridge`

This tier should not include visible renderer screenshots. It should be safe on
GitHub Actions Linux runners.

## Visual Gate

Use the visual gate whenever a change touches `src/nova/ui/`,
`src/nova/world/`, `data/visual_scenes/`, `data/visual_assets/`,
`assets/visual_tiles/`, or playable illustration assets.

- Run `--capture-nova-screenshot` without `--headless` to prove a visible frame is
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
- Runtime owner: Python tool, Godot smoke flag, Dialogic bridge check, or
  screenshot tool.
- Acceptance text: the exact PASS line, manifest field, or failure condition.
- Non-goal: what the test does not prove.

For new visual or animation work, add a stable trace ID first. A test without a
`SHOT-*` or related `VIS/PROP/ANIM/HUD-*` anchor is usually too vague to
automate safely.
