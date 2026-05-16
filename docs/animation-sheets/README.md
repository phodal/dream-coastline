# Animation Sheet Contracts

Animation Sheets are the visual-asset version of Sprint Sheets. They turn a
character or prop animation request into a runtime contract that can be reviewed
before AI-generated art is imported.

Use `animation-sprint-map-schema.md` before writing an Animation Sheet when AI
is involved. The map binds one reviewed `ANIM-*` stable ID to the actor registry
entry, clip JSON, runtime owner, screenshot state, and acceptance gate.

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

## AI Workflow

1. Start from a reviewed `scene_sprint_map` and choose one `ANIM-*` stable ID.
2. Generate or write an `animation_sprint_map` for that ID.
3. Review the map for `must_read_as`, `must_not_read_as`, runtime owners, frame
   contract, screenshot states, and acceptance gates.
4. Generate the Animation Sheet, art prompt, or code patch only for that ID.
5. Accept the work only after the contact sheet or in-game screenshot satisfies
   the referenced `SHOT-*` state.

The schema is documented in `animation-sprint-map-schema.md`.

Validate a generated map before implementation:

```sh
python3 tools/validate_scene_ai_contract.py \
  --scene-id 00-prologue-lights-out \
  --animation-map /tmp/ANIM-JZX-01-map.json
```

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
