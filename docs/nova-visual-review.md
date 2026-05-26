# Nova Visual Review

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
| `03-dead-kingdom` | `outer_city` | Pass with follow-up. Dead city mood reads, but tile overlays still show as translucent blocks over the backdrop. |
| `04-continuation-institute` | `institute` | Pass. Workshop/institute construction image now establishes the scene better than the previous gray layout. |
| `05-century-continuation` | `industry` | Pass. Industrial city and star-tower scale read clearly behind the UI. |
| `06-return-star-plan` | `astral_tower` | Pass. Astral gate and navigation equipment establish the plan location. |
| `07-lights-on-again` | `home` | Pass with follow-up. Homecoming and lit windows read clearly, but tile overlays still add translucent blocks. |

Follow-up:

- Start screenshots are now reviewable because all 8 start locations have illustrated backdrops.
- Some old tile overlays remain visible on top of the backdrop. They are acceptable for this pass but should be faded or hidden in a later visual polish slice.
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
| `03-dead-kingdom` | 5 / 5 | Pass with follow-up. Dead city and archive imagery read, but repeated review-art reuse should be replaced by location-specific art later. |
| `04-continuation-institute` | 6 / 6 | Pass. Mine, school, seal tower, communication tower, and workshop no longer fall back to gray layouts. |
| `05-century-continuation` | 4 / 4 | Pass. Astral engineering, network, and star tower images establish the later-era scale. |
| `06-return-star-plan` | 6 / 6 | Pass. Council, dockyard, gate, rift, and core spaces now have visible route context. |
| `07-lights-on-again` | 6 / 6 | Pass. Lab, orbit, school, store, street, and home are visually reviewable. |

Follow-up:

- This pass makes every location screenshot reviewable; it does not claim final bespoke art for every location.
- Several locations intentionally reuse the nearest story-review illustration. Later art polish should replace repeated backdrops with location-specific playable images.
- Translucent tile overlays still appear over some backdrops. They are useful for interaction positioning, but should be visually softened before a final public build.
