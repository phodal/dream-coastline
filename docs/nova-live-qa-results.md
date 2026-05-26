# Nova Live QA Results

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
