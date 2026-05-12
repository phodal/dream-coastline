# RPG First Act Readiness

This checklist tracks the gap between the current Godot RPG slice and a
Steam-ready first act.

## Current Evidence

- Real RPG rendering: `scripts/ui/sprite_scene_canvas.gd` draws the play field
  from OpenGameArt spritesheets, not from ASCII art.
- Keyboard play: `scripts/core/rpg_player_controller.gd` owns player tile,
  facing, collision checks, exits, investigation targets, and prompt text.
- Visual map data: `data/visual_scenes/00-prologue-lights-out.json` defines the
  first act locations, props, exits, spawn points, and solid tiles.
- Story runtime: `scripts/core/game_session.gd` owns flags, metrics, elapsed
  time, combat rules, and story progression.
- Data separation: `data/story_scenes/` holds narrative scene data, while
  `data/visual_scenes/` holds playable map layout.
- Verification: the Godot smoke walkthrough completes every implemented scene
  with `--smoke-autoplay`.

## Not Yet Steam-Ready

- Only the first act has explicit visual map data. Later scenes still rely on
  fallback rendering and need authored `data/visual_scenes/*.json` maps.
- There is no save/load system, pause menu, settings menu, title screen, or quit
  flow.
- Dialogue is still a compact log overlay; it needs a proper dialogue/cutscene
  system with speaker portraits, paging, skip behavior, and localization-ready
  text flow.
- Player movement is tile-step only. It needs animation frames, movement timing,
  facing sprites, blocked feedback, and scene transitions.
- There is no audio layer yet: music, ambience, UI sounds, and interaction SFX
  need to be added and licensed.
- There is no release/export setup for Steam: export presets, icon/splash,
  controller mapping, fullscreen/window settings, build metadata, and platform
  smoke checks are missing.
- Automated verification covers story walkthrough rules, but not keyboard
  movement paths, collision, interaction prompts, or rendered frame sanity.

## Next Implementation Order

1. Add an automated first-act keyboard path smoke test that verifies movement,
   exits, investigation prompts, and expected flags.
2. Replace the compact log overlay with a reusable dialogue box node.
3. Add animated player sprites and movement timing.
4. Add title/pause/settings/save-load flow.
5. Author visual maps for the remaining scenes.
6. Add audio and export presets once the first act loop is stable.
