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
- Check player-facing story labels for authored display names so menus do not
  expose internal command IDs like `build institute`.
- Run `tools/build_nova_manual_route_checklist.py --check` so the full-route
  live QA checklist stays aligned with story walkthrough JSON.
- Run `playable-backdrops` to verify every visual location has an illustrated
  backdrop file and no current Nova location points at `story_review` art.
- Run `tools/build_playable_backdrop_imagen_manifest.py --check` to keep the
  final-art Imagen replacement manifest aligned with every playable backdrop.
- Run `--smoke-nova-manual-route` to replay every canonical walkthrough command
  against Nova runtime state in authored order.
- Run `--smoke-nova-ui-manual-route` to replay the same walkthrough through
  `ExplorationView` action-menu choices, proving each command has an enabled
  player-facing menu item and returns to exploration after its payload.
- Run `--smoke-nova-mouse-route` to replay the walkthrough through action-menu
  button click semantics, proving every visible command button can be clicked,
  synchronizes selection, and returns to exploration after its payload.
- Run `--smoke-nova-keyboard-route` to replay the walkthrough by sending
  `ui_down` / `ui_accept` events through the Nova input handlers, proving
  keyboard menu navigation can reach and trigger every authored command.
- Run `--smoke-nova-gamepad-route` to replay the walkthrough by sending
  joypad D-pad/A button events through the `move_down` / `interact` input map,
  proving controller-style action-menu navigation can reach and trigger every
  authored command.
- Run `tools/validate_equipment_catalog.py`.
- Run `tools/validate_supply_catalog.py`.
- Run `tools/validate_action_voice_manifest.py` to keep full playable-action
  VO planning coverage aligned with story JSON.
- Run `tools/build_audio_listening_checklist.py --check` so generated music,
  ambience, SFX, voice samples, and action VO stay aligned with the final
  human listening checklist.
- Run `minimax-action-voice-dry-run` to check the MiniMax generator can build a
  selected playable-action VO job without calling the provider.
- Run the headless Godot project-load check.
- Run `--smoke-nova-runtime` to prove the new exploration/cutscene path can
  read story and visual JSON.
- Run `--smoke-nova-save-continue` to prove the Nova-native save payload can
  restore scene, location, and story flags without the legacy OpenRPG save path.
- Run `--smoke-nova-gamepad-continue` to prove the title splash can restore a
  saved Nova route through joypad input, not only keyboard `C`.
- Run `--smoke-nova-pause-flow` to prove pause, manual save, resume, and
  return-to-title are handled by Nova UI instead of direct process exit.
- Run `--smoke-nova-gamepad-pause-flow` to send joypad B/D-pad/A events through
  the root pause handler and pause overlay, proving controller-style pause,
  save, resume, and return-to-title navigation.
- Run `--smoke-story-audio-targets` to report missing generated story audio
  targets before review playback depends on them.
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

Godot smoke steps must assert their own `status=PASS` output in addition to
checking the process exit code. This catches cases where the project loads but
the expected smoke flag is not handled by the active Nova entrypoint.

## Visual Gate

Use the visual gate whenever a change touches `src/nova/ui/`,
`src/nova/world/`, `data/visual_scenes/`, `data/visual_assets/`,
`assets/visual_tiles/`, or playable illustration assets.

- Run `--smoke-dialogic-runtime` without `--headless` to prove native Dialogic
  playback can finish and write story flags back to Nova.
- Run `--smoke-nova-keyboard-dialogic` without `--headless` to prove keyboard
  action-menu navigation can open native Dialogic, then let Dialogic auto-skip
  finish playback and return to the Nova action menu. This is not a substitute
  for Enter-by-Enter manual Dialogic QA.
- Run `--capture-nova-screenshot` without `--headless` to prove a visible frame is
  not blank.
- Run `tools/capture_scene_screenshots.py --scope starts` for a Nova review
  contact sheet. The tool defaults to `res://src/nova/main.tscn`; use the old
  DreamField/OpenRPG scene only when explicitly reviewing that legacy entry.
- Run `route-screenshots` or `tools/capture_scene_screenshots.py --scope route`
  to capture walkthrough checkpoints at each scene start, midpoint, and
  before-ending state, plus a final route state. This proves late-route action
  menus remain visible and player-facing after the authored route has unlocked
  and completed choices.
- Run `route-full-screenshots` or
  `tools/capture_scene_screenshots.py --scope route-full` when a route change
  needs row-level evidence for `docs/nova-full-route-manual-qa.md`. This
  captures one screenshot after every authored walkthrough command and validates
  the manifest against each scene, scene step, and command string.
- The `screenshots` automated step now validates the resulting
  `manifest.json` with `tools/validate_scene_screenshot_manifest.py`, so the
  gate fails if Nova coverage, PNG files, asset-backed status, or the contact
  sheet artifact is missing. With `--require-illustrated-backdrop`, it also
  rejects non-playable fallback art and visible hotspot/debug-flag overlays.
- `tools/record_story_review.py` is a legacy DreamField/OpenRPG recorder and now
  exits unless `--legacy-openrpg-entrypoint` is passed. Do not use it as a Nova
  complete-flow gate.
- For a scene-specific Sprint Sheet or UI brief, run screenshots for that scene
  and review the manifest against the original `SHOT-*` states.
- Reject visual work if the manifest reports unexpected
  `procedural_fallback_count` or if the contact sheet violates
  `must_read_as` / `must_not_read_as` facts from the source map.
- For final playable backdrop replacement, use
  `data/playable_backdrop_imagen_manifest.json` one `PBG-*` id at a time. The
  current deterministic PNG is the runtime reference, while
  `style_reference_paths` lists existing scene art for Imagen style matching.

Render smoke is not a style test. A passing `render-frame-smoke` only says the
viewport is non-empty and varied enough; it cannot prove a modern apartment, a
black window, a vending machine, or a Moqi archive reads correctly.

## Release Gate

The release tier is for export-facing checks after the quick/headless runtime
suite passes.

- Run `--smoke-export-config` to validate macOS, Windows, and Linux desktop
  presets, local export templates, release branding metadata, and editor/build
  artifact export exclusions.
- Run `tools/build_release_libraries.sh` to build the macOS release library and
  cross-build the Windows/Linux GDExtension libraries.
- Run `--smoke-release-libraries` to confirm all three export libraries exist at
  the paths referenced by the project.
- Run `audio-mix-audit` to inspect generated MP3 files with `ffprobe` and
  `ffmpeg -af volumedetect`, checking required files, Godot import metadata,
  duration ranges, and obvious peak/mean-volume mistakes. Long music hot peaks
  are reported as warnings for final mastering review.
- If `audio-mix-audit` reports long-form hot peaks, run
  `python3 tools/master_audio_hot_peaks.py --apply`, rerun Godot editor import
  so `.mp3.import` metadata is current, and repeat `audio-mix-audit` until
  `hot_peaks=0`. Re-encoding can leave residual peak warnings after the first
  pass.
- Run `desktop-release-exports` to produce macOS, Windows, and Linux artifacts,
  validate their expected binaries/packs, and scan Godot export logs for
  forbidden packaged resources such as `.godot/**`, generated artifacts, local
  config, tools, docs, and build caches.
  The scanner allows Godot's compiled `.godot/imported` and `.godot/exported`
  runtime resources, plus export-generated UID/class caches, but rejects other
  `.godot` paths such as stale extension/editor metadata.

Export templates are still a local Godot installation requirement before
`--export-release` can produce binaries. The release tier validates local
artifact creation and package hygiene; it does not prove Developer ID signing,
notarization, stapling, installer behavior, or store distribution readiness.

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

## Manual Full-Route QA

The current live-window route checklist is generated at
[`docs/nova-full-route-manual-qa.md`](nova-full-route-manual-qa.md). Regenerate
it after changing story walkthroughs or scene order:

```sh
python3 tools/build_nova_manual_route_checklist.py
python3 tools/build_nova_manual_route_checklist.py --check
```

Manual checkbox state lives in
[`docs/nova-full-route-manual-progress.json`](nova-full-route-manual-progress.json).
The generator validates this progress file before rendering the checklist:
unknown keys, non-boolean checkbox values, or a global full-route pass without
all scene acceptance checks will fail `--check`. The route table's `Live
observed` column is sourced from `command_observations`, and the global
full-route pass also requires all 257 command rows to be observed.

Use this checklist for the issue #6 full 8-scene manual pass. Headless
`smoke-nova-all-scenes` proves automated progression, and
`smoke-nova-manual-route` proves the authored walkthrough commands still replay
in order. `smoke-nova-ui-manual-route` additionally proves the route is exposed
through enabled Nova action-menu choices. `smoke-nova-mouse-route` proves those
choices can be triggered through button click semantics.
The checklist includes `route-full #NNN` keys that match the
`route-full-screenshots` manifest `command_index` values, so each live-observed
manual row can be compared against the corresponding screenshot evidence before
sign-off.
`smoke-nova-keyboard-route` proves keyboard navigation can reach and trigger
those choices.
`smoke-nova-gamepad-route` proves the same menu route through joypad D-pad/A
button events and the project `move_down` / `interact` action bindings.
`smoke-nova-gamepad-continue` proves a saved game can be restored from the title
screen with a joypad button instead of requiring keyboard `C`.
`smoke-nova-gamepad-pause-flow` covers joypad pause, save, resume, and
return-to-title navigation.
`smoke-nova-keyboard-dialogic` proves a keyboard-selected action can enter
native Dialogic and return after auto-skipped playback. They still do not prove
that physical controller focus feel, physical mouse hover/click feel,
Enter-by-Enter Dialogic advance, pause/save, and the full 257-step visible
presentation feel correct in a real window.

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
  screenshot tool. Current scene screenshot ownership is `src/nova/main.gd`
  through `--capture-scene-screenshots`.
- Acceptance text: the exact PASS line, manifest field, or failure condition.
- Non-goal: what the test does not prove.

For new visual or animation work, add a stable trace ID first. A test without a
`SHOT-*` or related `VIS/PROP/ANIM/HUD-*` anchor is usually too vague to
automate safely.
