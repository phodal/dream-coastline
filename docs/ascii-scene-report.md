# ASCII Scene Verification Report

This report tracks the first playable ASCII pass for every scene listed in
`five/scene/README.md`.

## Verification

Run all scene gates:

```sh
for scene in 00-prologue-lights-out 01-illiterate 02-moqi-academy 03-dead-kingdom 04-continuation-institute 05-century-continuation 06-return-star-plan 07-lights-on-again; do
  python3 tools/ascii_five.py "$scene" --verify
done
```

| Scene | Estimated playtime | Commands | Coverage | UI |
| --- | ---: | ---: | ---: | --- |
| `00-prologue-lights-out` | 12.2 min | 20 | 9/9 | PASS |
| `01-illiterate` | 15.4 min | 22 | 9/9 | PASS |
| `02-moqi-academy` | 20.6 min | 27 | 10/10 | PASS |
| `03-dead-kingdom` | 18.7 min | 23 | 8/8 | PASS |
| `04-continuation-institute` | 28.0 min | 31 | 8/8 | PASS |
| `05-century-continuation` | 22.8 min | 22 | 6/6 | PASS |
| `06-return-star-plan` | 29.3 min | 29 | 8/8 | PASS |
| `07-lights-on-again` | 32.4 min | 32 | 8/8 | PASS |

All scenes pass the 5 minute minimum, completion coverage, and ASCII UI width
gate.

## UI Notes

- The ASCII UI uses a fixed-width layout, explicit exits, inspect targets,
  scene-specific verbs, and an automated line-width check.
- Scene 04 introduced a metrics panel; the verifier caught an over-wide metrics
  line, so the renderer now wraps metric output.
- Current playable verbs are `look`, `go`, `inspect`, `cast`, `write`, `attack`,
  `guard`, `choose`, `build`, `combine`, `status`, and `quit`.

## Asset Direction

The visual direction should stay close to 1990s top-down RPGs: limited palette,
clear 32x32 tile logic, dense but readable UI, and little decorative noise.

Use project-generated tiles from `tools/generate_visual_asset_scenes.gd`.
The atlas should stay close to 1990s top-down RPGs: limited palette, clear
32x32 tile logic, readable silhouettes, and little decorative noise.

Do not add external atlas packs as runtime dependencies. If a scene lacks a
prop or terrain cue, add a small generated pixel primitive to the project
tilesheet or a scoped first-party asset instead.

## Next Refactor Targets

- Move combat text that says "edge blanking" into data so each enemy has its own
  wording.
- Add a save/load transcript fixture once the scene data stabilizes.
- When promoting to Godot, preserve the ASCII command structure as acceptance
  tests: walkthrough completion, minimum duration estimate, required flag
  coverage, and UI line-width equivalent checks.
