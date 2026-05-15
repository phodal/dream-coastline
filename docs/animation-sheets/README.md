# Animation Sheet Contracts

Animation Sheets are the visual-asset version of Sprint Sheets. They turn a
character or prop animation request into a runtime contract that can be reviewed
before AI-generated art is imported.

## Runtime Path

```text
visual scene semantic actor/state
  -> data/visual_assets/*.json
  -> data/animation_clips/*.json
  -> AnimationClipRepository.resolve_frame()
  -> SpriteSceneCanvas
```

`SpriteSceneCanvas` should not hard-code player frame selection. It asks the
asset registry for the current actor clip, asks the animation repository for the
frame matching motion/facing/time, then renders that frame. Missing textures can
fall back to procedural markers, but missing animation states should fail the
animation clip smoke.

## Contract Template

```md
# Animation Sheet: <asset_id>_<motion>

## Goal
One sentence describing the visible action and emotion.

## Source Scene Contract
| Scene Evidence | Animation Meaning |
| --- | --- |
| <story or visual evidence> | <motion implication> |

## Runtime Contract
- actor: <actor_id>
- visual asset record: data/visual_assets/characters.json
- clip: data/animation_clips/<clip_id>.json
- required animations: idle_down, idle_up, idle_left, idle_right, walk_down,
  walk_up, walk_left, walk_right
- tile_size: 16
- render_size: 0.74
- anchor: foot center
- loop: true

## Asset Output
- assets/characters/<actor_id>/atlas.png
- data/animation_clips/<clip_id>.json
- preview gif
- contact sheet
- source prompt and review notes

## Review Gate
- Feet do not drift between walking frames.
- The silhouette stays consistent across all directions.
- Walking loops cleanly from last frame to first frame.
- Facing direction matches controller input.
- The character remains readable at the current tile scale.
```

## Current Player Contract

The current player actor is `jizixuan`. Its default compatibility clip is
`data/animation_clips/player_default.json`, selected through
`data/visual_assets/characters.json`.
