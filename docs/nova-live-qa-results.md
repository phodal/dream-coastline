# Nova Live QA Results

## 2026-07-15 First-Act Portrait Follow-Up

- Used an isolated `/tmp` Nova save to replay `inspect xiaoyan` at the refugee
  camp and `inspect xiali` on the forest chase route in the real Godot window.
- Xiaoyan now renders a dedicated child portrait without Dialogic's invalid
  `default` portrait warning; Xiali now renders a dedicated portrait instead
  of the full character model sheet. Both portraits use a dark ink-paper
  background and remain clear of the dialogue text box.
- This pass verifies the two portrait defects only. It does not mark remaining
  first-act walkthrough steps 19-24 or any other command row as observed.

## 2026-07-14 First-Act Live Route Continuation

- Resumed the isolated Nova QA save at `01-illiterate/mud_road` and observed
  walkthrough steps 1-18 in the real Godot window through the third `write
  name` action at the abandoned station.
- Dialogic text advanced across mud road, refugee camp, forest chase, and
  station actions; location transitions and combat resources remained visible.
- The final Return on a Dialogic timeline could reach the still-focused action
  button and reopen the first action. Nova now releases exploration action
  focus before starting a cutscene; a live replay of Xiali's eight-line
  timeline returned to the menu without reopening `inspect soldiers`.
- The visible keyboard/Dialogic smoke reports `focus_released=true`, but the
  runner still correctly fails it on the known macOS Godot 4.6.2
  `ObjectDB::cleanup()` signal 11 after `status=PASS`.
- Remaining first-act rows are steps 19-24. Visual follow-up is also required:
  Xiali's dialogue portrait is a full character reference sheet, and Dialogic
  warns that Xiaoyan's `default` portrait is invalid.

## 2026-06-23 Live Window Partial QA Refresh

Commands:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/phodal/game/dream-coastline
```

Computer Use check:

- Title splash accepted `Return` and entered the Nova gameplay screen.
- The first live gameplay screen was `居民楼外`, with player-facing action
  labels for `调查 自家窗户`, `调查 寻人启事`, `调查 自动售货机`, and
  `前往 居民楼门口`.
- The initial gameplay HUD did not show raw story flags, hotspot markers, or
  debug overlays.
- The first action accepted `Return`, opened the story/Dialogic-style text
  layer with a character portrait, advanced through multiple `Return` inputs,
  and returned to the action menu.
- Pause opened with `Escape`, preserved the Nova scene as a dimmed backdrop,
  resumed with `Return`, and restored the action-menu focus.
- Pause save selected through the real keyboard focus path, showed `已保存`,
  returned to title through the pause menu, and `C` from the title restored the
  saved gameplay state.
- Continued the visible-window route through all 20 prologue commands across
  the six prologue locations: `居民楼外`, `居民楼门口`, `家门口`, `客厅`,
  `父母书房`, and `纪子轩房间`. The route ended by triggering `黑色钢笔`.
- Because this pass resumed from an earlier partial save, the first required
  flag `noticed_dark_window` was missing until `自家窗户` was replayed at the
  end of the session. After that replay, the visible window advanced from
  `00-prologue-lights-out` to `01-illiterate` at `mud_road`.
- The live save file confirmed `scene_id=01-illiterate`,
  `location_id=mud_road`, and both `entered_moqi` and `noticed_dark_window`
  persisted.

Issues found:

- Quitting the visible Godot session through macOS after the route check crashed
  with `signal 11` during Godot cleanup (`ObjectDB::cleanup` /
  `GDScriptInstance::~GDScriptInstance`). The route state was saved before the
  crash, but release QA should still verify the player-facing quit path does
  not crash.
- Follow-up on 2026-06-24 added `--smoke-nova-player-quit`, routes the pause
  menu quit and window close request through Nova shutdown, and disconnects the
  Dialogic bridge before quitting. Headless and visible player-quit smokes
  passed without crash diagnostics. Dialogic's project autoload still reports
  `ObjectDB instances leaked` / `26 resources still in use` on any project
  exit, including bare `--quit`, so those warnings are tracked separately from
  player quit crashes.

Remaining manual QA:

- This refresh covers the first scene route, title, pause, save,
  return-to-title, and continue paths in a visible Godot window. It is still a
  partial live-window QA pass, not a row-by-row completion of the full
  257-command route in `docs/nova-full-route-manual-qa.md`.
- The remaining human QA is the full 8-scene visible route pass against the
  checklist rows, plus the separate physical-controller live-window pass and
  final creative approvals for art/audio.

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
python3 tools/run_automated_tests.py --only smoke-nova-gamepad-continue
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
- Headless Nova mouse-route smoke passed through action-menu button click
  semantics: `scenes=8`, `commands=257`, `flags=205`,
  `current=07-lights-on-again/lab`.
- Non-headless Nova keyboard-route smoke passed via `ui_down` / `ui_accept` input handlers: `scenes=8`, `commands=257`, `flags=205`, `current=07-lights-on-again/lab`.
- Headless Nova gamepad-route smoke passed via joypad D-pad/A events and the
  project `move_down` / `interact` bindings: `scenes=8`, `commands=257`,
  `flags=205`, `current=07-lights-on-again/lab`.
- Headless Nova gamepad continue smoke passed from the title splash via joypad
  X after creating a save: `scene=00-prologue-lights-out`, `location=building`,
  `flag=true`.
- Headless Nova gamepad pause-flow smoke passed via joypad B/D-pad/A events:
  `saved=true`, `scene=00-prologue-lights-out`, `location=street`,
  `mode=menu`.
- Playable backdrop gate passed for all 41 visual locations, with no current
  non-playable or `story_review` backdrop references.
- Visible Dialogic runtime smoke passed with the widened runner quit window: `finished=true`, `flag=true`.
- Visible Nova keyboard/Dialogic smoke passed: keyboard action-menu input opened native Dialogic, auto-skip finished playback, `noticed_dark_window` was written, and the action menu returned.
- Screenshot manifest gate passed for all 8 scene starts with `classic_dark` style and illustrated backdrops.
- Route screenshot manifest gate passed with 25 walkthrough checkpoints, `route_command_count=257`, `asset_backed_count=25`, and no procedural fallback or placeholder shots. The review sheet is `artifacts/scene-screenshots/route-latest/index.html`.
- Full-route screenshot manifest gate passed with 257 row-level screenshots,
  `route_command_count=257`, `asset_backed_count=257`, and no procedural
  fallback or placeholder shots. The review sheet is
  `artifacts/scene-screenshots/route-full-latest/index.html`; the manifest
  includes 41 unique playable backdrop paths, 257 `/playable/` uses, 0
  `/chapters/` uses, and 0 `story_review` backdrop paths.
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
  desktop targets, spot-checked on `01-illiterate/mud_road`,
  `03-dead-kingdom/library`, `04-continuation-institute/institute`, and
  `07-lights-on-again/home`.
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
  menu coverage, 257-step button-click semantics coverage, 257-step
  keyboard-navigation coverage, 257-row screenshot evidence, 257-step
  gamepad-navigation automation, gamepad pause/save/title automation, focused
  Dialogic runtime/keyboard smokes, and a focused input check, but
  `docs/nova-full-route-manual-qa.md` still has not been checked row-by-row
  through the entire route with human observation. The checklist rows now carry
  `route-full #NNN` evidence keys that match the screenshot manifest
  `command_index` values.
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
