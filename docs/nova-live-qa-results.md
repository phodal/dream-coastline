# Nova Live QA Results

## 2026-06-18 Live Window Refresh

Commands:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/phodal/game/dream-coastline --quit-after 100 -- --smoke-nova-all-scenes
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/phodal/game/dream-coastline --quit-after 100 -- --smoke-nova-manual-route
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/phodal/game/dream-coastline --quit-after 100 -- --smoke-nova-ui-manual-route
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/phodal/game/dream-coastline --quit-after 100 -- --smoke-nova-keyboard-route
python3 tools/run_automated_tests.py --tier quick
python3 tools/run_automated_tests.py --only smoke-nova-ui-manual-route
python3 tools/run_automated_tests.py --only smoke-nova-keyboard-route
python3 tools/run_automated_tests.py --only smoke-nova-gamepad-route
python3 tools/run_automated_tests.py --only smoke-nova-gamepad-pause-flow
python3 tools/run_automated_tests.py --only playable-backdrops
python3 tools/run_automated_tests.py --only smoke-dialogic-runtime
python3 tools/run_automated_tests.py --only smoke-nova-keyboard-dialogic
python3 tools/run_automated_tests.py --only screenshots --visual-scope starts --visual-style classic_dark
python3 tools/run_automated_tests.py --only route-screenshots --visual-style classic_dark
python3 tools/run_automated_tests.py --only route-full-screenshots --visual-style classic_dark
python3 tools/run_automated_tests.py --only smoke-export-config,smoke-release-libraries
python3 tools/run_automated_tests.py --only audio-mix-audit
python3 tools/run_automated_tests.py --only desktop-release-exports
codesign --verify --deep --strict --verbose=2 "/tmp/dream-coastline-signcheck/Dream Coastline.app"
codesign -dv --verbose=4 "/tmp/dream-coastline-signcheck/Dream Coastline.app"
spctl --assess --type execute --verbose=4 "/tmp/dream-coastline-signcheck/Dream Coastline.app"
```

Results:

- Non-headless Nova all-scenes smoke passed: `scenes=8`, `flags=205`, `current=07-lights-on-again/orbit`.
- Quick gate passed with 34 steps, including `story-action-display-names status=PASS records=259`.
- Non-headless Nova manual-route smoke passed: `scenes=8`, `commands=257`, `flags=205`, `current=07-lights-on-again/lab`.
- Non-headless Nova UI manual-route smoke passed through `ExplorationView` action-menu choices: `scenes=8`, `commands=257`, `flags=205`, `current=07-lights-on-again/lab`.
- Non-headless Nova keyboard-route smoke passed via `ui_down` / `ui_accept` input handlers: `scenes=8`, `commands=257`, `flags=205`, `current=07-lights-on-again/lab`.
- Headless Nova gamepad-route smoke passed via joypad D-pad/A events and the
  project `move_down` / `interact` bindings: `scenes=8`, `commands=257`,
  `flags=205`, `current=07-lights-on-again/lab`.
- Headless Nova gamepad pause-flow smoke passed via joypad B/D-pad/A events:
  `saved=true`, `scene=00-prologue-lights-out`, `location=street`,
  `mode=menu`.
- Playable backdrop gate passed for all 41 visual locations, with no current
  `story_review` backdrop references.
- Visible Dialogic runtime smoke passed with the widened runner quit window: `finished=true`, `flag=true`.
- Visible Nova keyboard/Dialogic smoke passed: keyboard action-menu input opened native Dialogic, auto-skip finished playback, `noticed_dark_window` was written, and the action menu returned.
- Screenshot manifest gate passed for all 8 scene starts with `classic_dark` style and illustrated backdrops.
- Route screenshot manifest gate passed with 25 walkthrough checkpoints, `route_command_count=257`, `asset_backed_count=25`, and no procedural fallback or placeholder shots. The review sheet is `artifacts/scene-screenshots/route-latest/index.html`.
- Full-route screenshot manifest gate passed with 257 row-level screenshots,
  `route_command_count=257`, `asset_backed_count=257`, and no procedural
  fallback or placeholder shots. The review sheet is
  `artifacts/scene-screenshots/route-full-latest/index.html`; the manifest
  includes 34 playable backdrop paths and 0 `story_review` backdrop paths.
- Visual spot-check of the scene 04 start screenshot confirmed build actions now show authored Chinese names (`建设 续文院`, `建设 标准字典`) instead of leaking internal IDs.
- Visual spot-checks of the full-route sheet covered command 1
  (`inspect window`), command 129 (`go seal_tower`), command 207
  (`build return`), and command 257 (`inspect parent_bridge_trace`), all with
  visible action-menu recovery.
- Release-facing smoke passed for export presets, local export templates, release branding, export excludes, and all three release libraries.
- Audio mix audit passed for 151 generated/loaded MP3 assets, skipped 198
  planned or `sample_generation: false` targets, and recorded 0 hot-peak
  warnings after mastering 36 long music/ambience/stinger MP3 files down.
- Desktop release export passed for macOS, Windows, and Linux: five artifacts
  validated, export logs written under `artifacts/release-export-logs/`, and no
  forbidden packaged resources detected.
- Fresh export logs include generated playable backdrop import metadata for all
  desktop targets, spot-checked on `03-dead-kingdom/library`,
  `04-continuation-institute/mine`, and `07-lights-on-again/lab`.
- The unzipped macOS app passes local `codesign --verify --deep --strict`; its
  signature is ad-hoc (`Signature=adhoc`, `TeamIdentifier=not set`), and
  Gatekeeper rejects it with `spctl --assess --type execute`.

Live window input check:

- Title splash accepted `Return` and entered the Nova gameplay screen.
- The default gameplay HUD no longer showed raw story flags or hotspot debug markers.
- The first action accepted `Return`, opened the story text layer, and returned to the action menu after additional `Return` input.
- Pause opened with `Escape`, preserved the scene background, and resumed with `Return`.
- Pause save showed `已保存`; return-to-title worked; pressing `C` from the title restored the saved gameplay state.

Remaining manual QA:

- The current build has refreshed visible-window smoke coverage, 257-step UI
  menu coverage, 257-step keyboard-navigation coverage, 257-row screenshot
  evidence, 257-step gamepad-navigation automation, gamepad pause/save/title
  automation, focused Dialogic runtime/keyboard smokes, and a focused input
  check, but
  `docs/nova-full-route-manual-qa.md` still has not been checked row-by-row
  through the entire route with human observation.
- Store-grade Developer ID signing, notarization, stapling, and
  installer/distribution validation are still outside the proven scope.

## 2026-05-26 Window Route Baseline

Commands:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/phodal/game/dream-coastline --quit-after 100 -- --smoke-nova-all-scenes
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/phodal/game/dream-coastline --quit-after 100 -- --smoke-nova-manual-route
python3 tools/run_automated_tests.py --only smoke-dialogic-bridge,smoke-dialogic-runtime
```

Results:

- Non-headless Nova all-scenes smoke passed: `scenes=8`, `flags=205`, `current=07-lights-on-again/orbit`.
- Visible-window Nova manual-route smoke passed: `scenes=8`, `commands=257`, `flags=205`, `current=07-lights-on-again/lab`.
- Dialogic bridge smoke passed: addon installed, multi-line timeline generation available, variable bridge available.
- Dialogic runtime smoke passed in a visible window: `finished=true`, `flag=true`.

Computer Use check:

- Title splash accepted `Return` and entered Nova.
- Action menu accepted `Return` on the first action and opened native Dialogic playback.
- Dialogic playback advanced with raw keyboard input and returned to the Nova action menu.
- Pause overlay opened with `Escape` and resumed with `Return`.

Remaining manual QA:

- This now has automated command-by-command coverage for story walkthrough rows, but it is still not a visible UI checklist pass.
- A later manual pass should still mark each scene checklist row after playing the route through the visible UI with keyboard/mouse focus.
