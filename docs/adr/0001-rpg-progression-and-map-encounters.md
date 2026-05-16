# ADR 0001: RPG Progression and Map Encounters

## Status

Accepted

## Context

Dream Coastline already defines the core loop as exploration, glyph learning,
problem solving, civilization building, unlocks, and main story progression.
The runtime also has data-driven locations, flags, metrics, glyph actions,
build actions, choices, and scripted combat.

The missing layer is not a traditional grinding loop. The game needs enough
RPG structure for maps, encounters, resources, and growth to be playable, while
keeping the story's identity: language comprehension and civilization repair
matter more than generic experience points.

## Decision

Use a light data-driven progression layer on top of the existing scene JSON.
The first implementation keeps existing scene walkthroughs valid and adds:

- `player_stats`: scene-scoped resources such as `ink`, `focus`, and
  `stability`.
- `glyph_mastery`: per-glyph integer mastery values.
- `encounters`: optional location-level map encounters resolved by the session
  rules through an `engage` action.
- Action-level `stat_costs`, `stats`, and `glyph_mastery` deltas on existing
  inspect, glyph, build, choice, combo, combat, and encounter data.

The first slice is deterministic. Map encounters are authored actions rather
than random battles. They can be hidden after a clear flag, require story flags
or glyph mastery, consume resources, and grant flags, metrics, stat recovery,
or glyph mastery.

## Consequences

- The system can prove "map fight and growth" without adding random encounter
  state, enemy databases, or visual-scene rewrites.
- Growth rewards stay theme-aligned: learning glyphs, stabilizing resources,
  and changing civilization metrics.
- Combat can later expand into turn-based or tactical rules without changing
  the scene JSON ownership model.
- Existing story smoke paths remain deterministic because encounters are
  explicit walkthrough commands.

## Current Vertical Slice

The second scene, `02-moqi-academy`, owns the first RPG progression slice:

- Learning `名`, `门`, `火`, and `止` grants glyph mastery.
- The village map contains a `contract_patrol` encounter.
- The encounter consumes `ink` and `focus`, requires `learned_stop`, and grants
  `cleared_contract_patrol`, trust, stability, and extra `stop` mastery.
- A new progression smoke checks the data layer without depending on visual
  tile coordinates.

## Non-goals

- No random battles yet.
- No global enemy database yet.
- No traditional player level or EXP bar yet.
- No visual map or TileMap changes in this ADR.
- No rebalancing of existing chapter boss fights beyond reading optional
  progression deltas.
