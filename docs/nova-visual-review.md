# Nova Visual Review

## 2026-06-18 Full-Route Row Evidence

Command:

```bash
python3 tools/run_automated_tests.py --only route-full-screenshots --visual-style classic_dark
```

Artifact:

- `artifacts/scene-screenshots/route-full-latest/index.html`
- `artifacts/scene-screenshots/route-full-latest/manifest.json`

Result:

- 257 screenshots captured, one after each authored walkthrough command.
- `route_command_count=257`
- `asset_backed_count=257`
- `procedural_fallback_count=0`
- `framework_placeholder_count=0`
- `/playable/` backdrop references: 257
- `/chapters/` backdrop references: 0
- `story_review` backdrop references: 0
- `hotspot_markers_visible`: 0
- `debug_flags_visible`: 0
- Manifest validation matches every `(scene, scene step, command)` row from
  `data/story_scenes/*.json`.

Spot checks:

| Command | Scene/step | Review |
| ---: | --- | --- |
| 1 | `00-prologue-lights-out` step 1, `inspect window` | Pass. First action returns to the action menu with authored Chinese labels and the modern night-street backdrop. |
| 129 | `04-continuation-institute` step 22, `go seal_tower` | Pass. Seal tower state is visible, route progression has unlocked/completed actions, and focus is on the action menu. |
| 207 | `06-return-star-plan` step 34, `build return` | Pass. Transition lands in the modern home state with readable post-return actions. |
| 257 | `07-lights-on-again` step 50, `inspect parent_bridge_trace` | Pass. Final lab state remains visible with completed route actions and no debug hotspot overlay. |

Follow-up:

- This evidence proves every walkthrough row has a reviewable, asset-backed
  screen after execution, and every captured row now uses location-specific
  playable art. It does not replace live manual observation for text advance
  feel, controller comfort, or final art direction.

## 2026-05-26 Start Contact Sheet

Command:

```bash
python3 tools/capture_scene_screenshots.py --scope starts --output artifacts/scene-screenshots/latest --resolution 640x360 --quit-after 120 --warmup-frames 2 --visual-style classic_dark
python3 tools/validate_scene_screenshot_manifest.py --manifest artifacts/scene-screenshots/latest/manifest.json --scope starts --visual-style classic_dark --require-illustrated-backdrop
```

Artifact:

- `artifacts/scene-screenshots/latest/index.html`
- `artifacts/scene-screenshots/latest/manifest.json`

Result:

| Scene | Start location | Review |
| --- | --- | --- |
| `00-prologue-lights-out` | `street` | Pass. Modern night street, dark-window mood, Dialogic/action panels readable. |
| `01-illiterate` | `mud_road` | Pass. Mud road, damaged station, broken letters, and displaced child read clearly. |
| `02-moqi-academy` | `academy` | Pass. Academy, writing tools, mentors, and glyph-learning tone are visible. |
| `03-dead-kingdom` | `outer_city` | Pass. Dead city mood reads through the illustrated backdrop and action UI without visible debug hotspot or tile overlay artifacts. |
| `04-continuation-institute` | `institute` | Pass. Workshop/institute construction image now establishes the scene better than the previous gray layout. |
| `05-century-continuation` | `industry` | Pass. Industrial city and star-tower scale read clearly behind the UI. |
| `06-return-star-plan` | `astral_tower` | Pass. Astral gate and navigation equipment establish the plan location. |
| `07-lights-on-again` | `home` | Pass. Homecoming, lit windows, and modern shoreline read clearly without visible debug hotspot or tile overlay artifacts. |

Follow-up:

- Start screenshots are now reviewable because all 8 start locations have illustrated backdrops.
- The current Nova screenshot manifest records 0 visible hotspot markers, 0
  debug flags, and 0 `story_review` backdrop references. The old tile-overlay
  follow-up is no longer visible in the current Nova route screenshots.
- This review only covers scene starts. Full `--scope locations` review is still required before treating every location as visually complete.

## 2026-05-26 Location Contact Sheet

Command:

```bash
python3 tools/capture_scene_screenshots.py --scope locations --output artifacts/scene-screenshots/locations-review --resolution 640x360 --quit-after 180 --warmup-frames 2 --visual-style classic_dark
python3 tools/validate_scene_screenshot_manifest.py --manifest artifacts/scene-screenshots/locations-review/manifest.json --scope locations --visual-style classic_dark --require-illustrated-backdrop
```

Artifact:

- `artifacts/scene-screenshots/locations-review/index.html`
- `artifacts/scene-screenshots/locations-review/manifest.json`

Result:

- 41 screenshots captured.
- 41 screenshots are `asset_backed`.
- 41 screenshots have an illustrated backdrop path.
- 41 screenshots report `asset_loaded=true`.
- No framework placeholder or procedural fallback screenshots remain in the location contact sheet.

Coverage:

| Scene | Locations loaded | Review |
| --- | ---: | --- |
| `00-prologue-lights-out` | 6 / 6 | Pass. Uses dedicated playable backdrops for modern street and home spaces. |
| `01-illiterate` | 4 / 4 | Pass. Mud road, camp, chase, and station now read as distinct displaced-war spaces. |
| `02-moqi-academy` | 4 / 4 | Pass. Academy, archive, node, and village now have readable Moqi learning imagery. |
| `03-dead-kingdom` | 5 / 5 | Pass. Dead city, palace, headquarters, hall, and library now use location-specific playable backdrops. |
| `04-continuation-institute` | 6 / 6 | Pass. Mine, school, seal tower, communication tower, and workshop no longer fall back to gray layouts. |
| `05-century-continuation` | 4 / 4 | Pass. Astral engineering, network, and star tower images establish the later-era scale. |
| `06-return-star-plan` | 6 / 6 | Pass. Council, dockyard, gate, rift, and core spaces now have visible route context. |
| `07-lights-on-again` | 6 / 6 | Pass. Lab, orbit, school, store, street, and home are visually reviewable. |

Follow-up:

- This pass makes every location screenshot reviewable; it does not claim final hand-painted art direction for every location.
- `tools/generate_playable_backdrops.py --write --update-json` generated
  playable-location PNGs for all non-playable visual references, bringing
  `assets/illustrations/playable` to 41 PNG backdrops. Current route-full
  manifest evidence reports 41 unique playable paths and 0 `story_review` or
  `/chapters/` backdrop paths.
- The 2026-06-18 refreshed `route-full` manifest reports 257 screenshots,
  257 `/playable/` backdrop uses, 0 `/chapters/` backdrop uses, 0
  `/story_review/` backdrop uses, 0 visible hotspot markers, and 0 visible
  debug flags. Remaining visual work is final art-direction approval and
  selective replacement/polish of generated playable backdrops, not a known
  runtime tile-overlay or fallback-art issue.
