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
