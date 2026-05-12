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
- Visual map data: `data/visual_scenes/00-prologue-lights-out.json`,
  `data/visual_scenes/01-illiterate.json`, and
  `data/visual_scenes/02-moqi-academy.json`, and
  `data/visual_scenes/03-dead-kingdom.json`, and
  `data/visual_scenes/04-continuation-institute.json`, and
  `data/visual_scenes/05-century-continuation.json`,
  `data/visual_scenes/06-return-star-plan.json`, and
  `data/visual_scenes/07-lights-on-again.json` define authored locations, props,
  exits, spawn points, and solid tiles.
- Story runtime: `scripts/core/game_session.gd` owns flags, metrics, elapsed
  time, combat rules, and story progression.
- Data separation: `data/story_scenes/` holds narrative scene data, while
  `data/visual_scenes/` holds playable map layout.
- Verification: the Godot smoke walkthrough completes every implemented scene
  with `--smoke-autoplay`, and all eight authored keyboard paths are
  covered by `--smoke-rpg-first-act`, `--smoke-rpg-illiterate`, and
  `--smoke-rpg-moqi-academy`, `--smoke-rpg-dead-kingdom`, and
  `--smoke-rpg-continuation-institute`, and
  `--smoke-rpg-century-continuation`, `--smoke-rpg-return-star-plan`, and
  `--smoke-rpg-lights-on-again`.
- Save/load verification: `--smoke-save-load` writes a save, mutates runtime
  state, reloads it, and checks the restored location, tile, and elapsed time.
- Menu verification: `--smoke-menu-flow` builds the UI and checks title, new
  game, pause/resume, and settings open/close states.
- Render verification: `--smoke-render-frame` starts the real Godot renderer,
  captures the viewport image, and checks that the game frame is not blank.
- Audio verification: `--smoke-audio-director` checks that the generated
  fallback SFX streams are available before licensed audio assets are added.
- Export configuration: `export_presets.cfg` defines macOS, Windows Desktop,
  and Linux/X11 desktop presets, and `--smoke-export-config` verifies preset
  presence while reporting whether local export templates are installed.

## Not Yet Steam-Ready

- All eight current scenes have explicit visual map data and keyboard smoke
  paths.
- Title, settings, pause, and save/load foundations exist, but the settings
  surface is still minimal and the quit flow is not polished for release.
- Dialogue has a reusable overlay shell, but it still needs speaker portraits,
  paging, skip behavior, and localization-ready text flow.
- Player movement now has step timing, interpolated drawing, sprite-sheet
  walking frames, facing rows, and blocked-tile feedback, but it still needs
  artist-approved bespoke hero frames and scene transitions.
- The audio layer has generated fallback SFX for UI, movement, blocked movement,
  interaction, transitions, and success events, but licensed music, ambience,
  and final SFX assets still need to be added.
- Release/export setup has desktop presets and a preset smoke check, but release
  exports are still blocked until export templates, icon/splash, controller
  mapping, final fullscreen/window settings, build metadata, and platform smoke
  checks are completed.
- Automated verification covers story walkthrough rules, all authored keyboard
  paths, save/load restoration, menu state flow, generated fallback audio, and a
  rendered frame sanity check. Export preset configuration is covered by
  `--smoke-export-config`, but binary export is not covered until local export
  templates are installed.

## Next Implementation Order

1. Replace generic sheet player frames with artist-approved bespoke hero frames.
2. Expand settings beyond fullscreen and polish quit/title transitions.
3. Install export templates and add platform export smoke checks.
