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

Recommended sources checked on OpenGameArt:

- Existing baseline: [Dungeon Crawl 32x32 tiles](https://opengameart.org/content/dungeon-crawl-32x32-tiles), CC0. Keep this as the primary unified atlas for early fantasy scenes, monsters, items, spell effects, and many UI symbols.
- Additional fantasy maps: [32x32 Dungeon Tileset](https://opengameart.org/content/32x32-dungeon-tileset), CC0, and [Dungeon Tileset 32x32](https://opengameart.org/content/dungeon-tileset-32x32), CC0.
- RPG UI: [RPG UI Icons](https://opengameart.org/content/rpg-ui-icons), CC0, for status effects, action icons, glyph-combat states, and inventory affordances.
- Modern city finale: [City Pixel Tileset](https://opengameart.org/content/city-pixel-tileset), CC0, plus [top down Road Tileset](https://opengameart.org/content/top-down-road-tileset), CC0, for scene 07.
- Sci-fi/lab/space support: [Top-Down tileset](https://opengameart.org/content/top-down-tileset-1), CC0, and [Sci-fi platformer tiles 32x32](https://opengameart.org/content/sci-fi-platformer-tiles-32x32), CC0, for scenes 05-07.

Avoid mixing Hyptosis with the current baseline unless attribution and palette
normalization are handled deliberately; the earlier quick UI pass showed that
mixed atlases made the scene harder to read.

## Next Refactor Targets

- Move combat text that says "edge blanking" into data so each enemy has its own
  wording.
- Add a save/load transcript fixture once the scene data stabilizes.
- When promoting to Godot, preserve the ASCII command structure as acceptance
  tests: walkthrough completion, minimum duration estimate, required flag
  coverage, and UI line-width equivalent checks.
