# Creature Walk Spritesheet Sprint Sheet

## Goal

Add the first eight Dream Coastline creature walk assets as Godot-readable 4-direction spritesheets, with one gameplay config JSON and one animation clip JSON per creature.

## Source Scene Contract

- `CREATURE-001` comes from the first-act abandoned station and must read as a nameless, erased humanoid rather than a zombie.
- `CREATURE-002` comes from the "名" system payoff and must read as a fragile named/unnamed phantom deer rather than a mascot.
- `CREATURE-003` comes from the second-act village well and must read as ink ecology tied to water-rune engineering.
- `CREATURE-004` comes from Moqi law/contract systems and must read as a law-bound guardian rather than a machine dog.
- `CREATURE-005` comes from the main statebook hall and must read as a living archive remnant rather than a generic dragon.
- `CREATURE-006` comes from star-chart engineering failures and must read as a coordinate-eating moth hazard.
- `CREATURE-007` comes from the sixth-act silence probe and must read as an alien deletion protocol rather than a robot.
- `CREATURE-008` comes from the return bridge and must read as a neutral otherworld traveler rather than a human costume.

## Inputs

- Imagen-generated source concepts under `assets/characters/creatures/*/concept.png`.
- Normalized walk sheets under `assets/characters/creatures/*/walk4.png`.
- Existing animation owner: `scripts/core/animation_clip_repository.gd`.
- Existing asset registry owner: `data/visual_assets/characters.json`.

## Outputs

- 8 creature config files under `data/creatures/*.json`.
- 8 animation clip files under `data/animation_clips/*_walk.json`.
- 8 normalized 384x512 walk sheets, each using 4 columns by 4 rows.
- Animation repository support for rectangular 96x128 frames through `frame_size`.

## Acceptance

- `walk4.png` for every creature is exactly 384x512.
- Each animation clip exposes `idle_down`, `idle_left`, `idle_right`, `idle_up`, `walk_down`, `walk_left`, `walk_right`, and `walk_up`.
- Every walk animation has 4 in-bounds frames.
- Godot smoke `--smoke-animation-clips` passes for `jizixuan` and all registered creature clips.
- The visual review must confirm row order before gameplay placement: row 1 down/front, row 2 right, row 3 left, row 4 up/back.

## Involved Files

- `assets/characters/creatures/*/concept.png`
- `assets/characters/creatures/*/walk4.png`
- `data/creatures/*.json`
- `data/animation_clips/*_walk.json`
- `data/visual_assets/characters.json`
- `scripts/core/animation_clip_repository.gd`
- `scripts/core/animation_clip_repository_smoke.gd`

## Non-Goals

- Do not place these creatures into story scenes yet.
- Do not add combat balancing or drop tables.
- Do not treat the current Imagen output as final pixel-art polish; it is a first playable asset pass.
