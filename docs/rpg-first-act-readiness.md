# RPG First Act Readiness

This checklist tracks the gap between the current Godot RPG slice and a
Steam-ready first act.

## Current Evidence

- Real RPG rendering: `scripts/ui/sprite_scene_canvas.gd` draws the play field
  from OpenGameArt spritesheets, not from ASCII art.
- Keyboard play: `scripts/core/rpg_player_controller.gd` owns player tile,
  facing, collision checks, movement timing, exits, investigation targets, and
  prompt text.
- Dialogue shell: `scripts/ui/dialogue_overlay.gd` owns the bottom dialogue and
  prompt surface, so it can evolve toward portraits and paged dialogue without
  bloating `scripts/main.gd`.
- Visual map data: `data/visual_scenes/00-prologue-lights-out.json` defines the
  first act locations, props, exits, spawn points, and solid tiles.
- Story runtime: `scripts/core/game_session.gd` owns flags, metrics, elapsed
  time, combat rules, and story progression.
- Data separation: `data/story_scenes/` holds narrative scene data, while
  `data/visual_scenes/` holds playable map layout.
- Verification: the Godot smoke walkthrough completes every implemented scene
  with `--smoke-autoplay`, and the first act keyboard path is covered by
  `--smoke-rpg-first-act`.

## Not Yet Steam-Ready

- Only the first act has explicit visual map data. Later scenes still rely on
  fallback rendering and need authored `data/visual_scenes/*.json` maps.
- There is no save/load system, pause menu, settings menu, title screen, or quit
  flow.
- Dialogue has a reusable overlay shell, but it still needs speaker portraits,
  paging, skip behavior, and localization-ready text flow.
- Player movement now has step timing, interpolated drawing, basic facing
  frames, and blocked-tile feedback, but it still needs artist-approved
  animation frames and scene transitions.
- There is no audio layer yet: music, ambience, UI sounds, and interaction SFX
  need to be added and licensed.
- There is no release/export setup for Steam: export presets, icon/splash,
  controller mapping, fullscreen/window settings, build metadata, and platform
  smoke checks are missing.
- Automated verification covers story walkthrough rules and a first-act keyboard
  path, but not rendered frame sanity or later-scene keyboard paths.

## Next Implementation Order

1. Add title/pause/settings/save-load flow.
2. Author visual maps and keyboard paths for the remaining scenes.
3. Add rendered frame sanity checks.
4. Replace placeholder facing frames with artist-approved animation frames.
5. Add audio and export presets once the first act loop is stable.
