# Nova Route Readiness

This file used to track the first-act RPG slice. The current mainline is the
Nova full-route runtime at `res://src/nova/main.tscn`, so this snapshot tracks
the gap between the playable 8-scene route and a public release candidate.

## Current Evidence

- Main runtime: `src/nova/main.gd`, `src/nova/scene_director.gd`, and
  `src/nova/world/exploration_view.gd` drive the current title, exploration,
  action menu, Dialogic bridge, save/continue, pause, and screenshot gates.
- Story coverage: `data/story_scenes/*.json` contains 8 authored scenes with a
  canonical walkthrough totaling 257 commands.
- Story continuity: `python3 tools/validate_story_continuity.py --verbose`
  passes for all 8 scenes.
- Route replay: `--smoke-nova-manual-route`, `--smoke-nova-ui-manual-route`,
  `--smoke-nova-keyboard-route`, and `--smoke-nova-gamepad-route` each pass
  the 257-command route.
- Player-facing labels: `story-action-display-names` validates 259 visible
  action, exit, combat, build, encounter, and combo labels so the action menu
  does not fall back to internal IDs.
- Visual coverage: `route-full-screenshots` captures 257 screenshots, one after
  every authored walkthrough command, with `asset_backed_count=257` and no
  procedural fallback or placeholder screenshots. The current manifest sees 0
  `story_review` backdrop paths, 0 visible hotspot markers, and 0 visible debug
  flags.
- Checklist sync: `tools/build_nova_manual_route_checklist.py --check` keeps
  `docs/nova-full-route-manual-qa.md` aligned with story data.
- Dialogic coverage: `tools/validate_dialogic_timelines.py` validates 195
  generated timelines, and the visible Dialogic smokes prove native playback can
  write flags back and return to the Nova action menu.
- Save/menu coverage: `--smoke-nova-save-continue`,
  `--smoke-nova-pause-flow`, and the live input check prove title entry,
  pause/resume, save, return-to-title, and continue-from-title paths.
- Controller automation: `--smoke-nova-gamepad-route` covers the full
  257-command action-menu route, and `--smoke-nova-gamepad-pause-flow` covers
  joypad pause, save, resume, and return-to-title navigation.
- Release export: `desktop-release-exports` produces macOS, Windows, and Linux
  artifacts, validates expected binaries/packs, and scans export logs for
  forbidden packaged resources.
- Audio hygiene: `audio-mix-audit` inspects 151 generated/loaded MP3 assets for
  missing files, Godot import metadata, duration ranges, and obvious
  peak/mean-volume mistakes; it passes with 0 hot-peak warnings after the 36
  long-form music/ambience/stinger MP3 files were mastered down.

## Not Yet Release-Complete

- `docs/nova-full-route-manual-qa.md` still has not been checked row by row by
  a human in the live window. The 257 screenshots are strong evidence, but they
  are not a substitute for observing input feel, text advance cadence, and
  focus recovery through the whole route.
- macOS export is ad-hoc signed. `codesign --verify --deep --strict` passes on
  the unzipped app, but `spctl --assess --type execute` rejects it because there
  is no Developer ID signing or notarization.
- The visual route is reviewable and asset-backed without debug hotspot,
  debug-flag, or `story_review` fallback leakage; final hand-painted art
  direction and selective backdrop replacement/polish are still pending.
- Generated voice/action audio coverage and machine mix hygiene are present,
  but the soundtrack still needs a final creative listening pass for loudness,
  balance, transitions, and emotional fit.
- Controller support now has automated gamepad route and pause/save/title
  smokes through joypad events, but it still needs a physical-controller
  live-window pass before claiming controller-ready release quality.

## Next Implementation Order

1. Run the live-window QA checklist against
   `docs/nova-full-route-manual-qa.md`, using
   `artifacts/scene-screenshots/route-full-latest/index.html` as row-level
   visual evidence.
2. Run a physical gamepad live-window pass for action-menu navigation,
   Dialogic advance, pause/save, and continue.
3. Replace generated or chapter backdrops with final art-direction-approved
   backdrops where needed, then rerun `route-full-screenshots`.
4. Do the final creative loudness/mastering listening pass for music,
   ambience, SFX, and generated voices now that machine hot-peak warnings are
   clear.
5. Configure Developer ID signing/notarization/stapling and rerun the release
   signing checks from `docs/release.md`.
