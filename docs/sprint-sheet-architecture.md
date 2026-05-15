# Sprint Sheet Architecture

This document turns a Sprint Sheet from a vision note into an implementation-ready UI contract for the Dream Coastline Godot RPG slice.

The target reader is a designer, UI artist, or implementation agent that needs to understand what to draw and what to build without reverse-engineering the story files.

## Problem

The current scene material already contains narrative intent, playable JSON, visual map data, runtime systems, and readiness notes. A Sprint Sheet that only repeats the story goal is not enough for implementation because it does not say:

- what the player sees first;
- what the source scene says the screen must mean;
- what data drives each visible UI region;
- which screenshots exposed the current mismatch;
- which files must change;
- what counts as done;
- what is explicitly out of scope.

So the Sprint Sheet needs to become a compact architecture surface, not a prose-only plan.

## Sprint Sheet Contract

Every Sprint Sheet should use this structure.

| Section | Purpose | UI Drawing Impact |
| --- | --- | --- |
| Goal | One sentence describing the player-visible outcome. | Decides the primary screen state to mock. |
| Source Scene Contract | Scene evidence mapped to required screen meaning. | Prevents a generic RPG look that contradicts the story. |
| Player Loop | The repeated action sequence in play order. | Defines control prompts, focus order, and feedback placement. |
| Inputs | Existing files, scene IDs, assets, and constraints. | Tells the UI artist what data labels and assets are real. |
| Outputs | Concrete files or screens produced by the sprint. | Prevents vague deliverables like "improve UI". |
| Visual Direction | What the screen must and must not read as. | Keeps era, tone, and material choices aligned. |
| Screenshot Review Gate | Concrete screenshots and mismatch checks. | Makes style review evidence-based, not preference-only. |
| Acceptance | Observable checks, commands, and visual criteria. | Makes review objective. |
| Affected Files | Exact modules or data files expected to change. | Keeps implementation scoped. |
| Non-Goals | Things the sprint must not solve yet. | Prevents UI sprawl and accidental systems work. |

## Scene Alignment Gate

Before implementing visual or UI work, the Sprint Sheet must answer three questions:

1. Which source scene lines define the emotional tone and era?
2. Which visual elements would make the screen read as the wrong genre, era, or location?
3. Which screenshot states will prove the implementation matches the scene instead of only passing smoke tests?

For Dream Coastline this matters because "RPG" is not specific enough. A modern silent prologue, an ancient Moqi city, a continuation institute, and a star-engineering chapter should not share the same visual semantics just because they share the same HUD shell.

## AI Generation

Use `tools/build_sprint_sheet_prompt.py` to package a scene for AI-assisted Sprint Sheet generation. The safest flow is two-step:

1. Generate a `scene_sprint_map` intermediate JSON object.
2. Review that map, then generate or edit the final Sprint Sheet.

The map prompt includes the source scene, full Story JSON, full Visual JSON, and art direction. It exists because an AI model can usually infer the scene-to-screen mapping, but a raw Sprint Sheet prompt makes it too easy to skip evidence and write generic RPG advice.

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode map
```

After the map is reviewed, convert it into the final Sprint Sheet prompt:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode sheet-from-map --map-input /tmp/01-scene-map.json
```

For UI implementation work, convert the same map into a file-level UI brief:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode ui-brief-from-map --map-input /tmp/01-scene-map.json
```

The UI brief is different from the Sprint Sheet. It must name the real Godot owner files, data hooks, screen regions, prop renderer changes, prompt states, screenshot states, and smoke checks that make the UI task executable.

Before implementation, validate the contracts and build an implementation prompt from the reviewed brief:

```sh
python3 tools/validate_scene_ai_contract.py --scene-id 01-illiterate --map /tmp/01-scene-map.json --brief /tmp/01-ui-brief.md
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode implementation-from-brief --map-input /tmp/01-scene-map.json --brief-input /tmp/01-ui-brief.md
```

After implementation, use the same map for screenshot review:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode screenshot-review-from-map --map-input /tmp/01-scene-map.json --screenshot-manifest /tmp/01-screenshots.json
```

This keeps the mapper, planner, implementer, and reviewer roles separate. The implementer can write code, but the source scene contract and screenshots decide whether the result is accepted.

The direct Sprint Sheet prompt remains available when the mapping is already understood. It includes the scene source, story JSON summary, visual prop summary, art direction, and this architecture guide.

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate
```

Both generated prompts are inputs to an AI model, not acceptance gates. The output still needs source review, screenshot review states, and file-level implementation tasks before it is considered usable.

The `scene_sprint_map` schema lives in `docs/sprint-sheets/scene-sprint-map-schema.md`.

## Current Architecture Evidence

The current implementation already separates story, runtime state, visual layout, and rendering.

```text
five/scene/*.md
        |
        v
data/story_scenes/*.json  --->  SceneDatabase
        |                         |
        v                         v
GameSession  <-------------  RpgPlayerController
        |                         |
        v                         v
main.gd  -------------------->  GameHud
                                  |
                                  v
                         SpriteSceneCanvas
                                  ^
                                  |
                         data/visual_scenes/*.json
```

### Source Layers

- `five/scene/*.md`: readable scene cards and design intent.
- `data/story_scenes/*.json`: playable narrative state, locations, items, exits, flags, metrics, walkthroughs.
- `data/visual_scenes/*.json`: tile coordinates, props, collision, exits, item hotspots, spawn points.
- `scripts/core/scene_database.gd`: loads story JSON in scene order.
- `scripts/core/game_session.gd`: owns progression, flags, metrics, combat, action execution, and smoke verification.
- `scripts/core/scene_visual_repository.gd`: reads visual maps and answers spawn, collision, and interaction queries.
- `scripts/core/rpg_player_controller.gd`: owns tile movement, facing, prompt selection, and interaction dispatch.
- `scripts/ui/game_hud.gd`: composes the game canvas, top bar, prompt overlay, title screen, pause menu, and settings menu behind game-level methods and signals.
- `scripts/ui/sprite_scene_canvas.gd`: renders tile maps, props, actors, and visual fallback.
- `scripts/ui/prompt_overlay.gd`: renders the compact location, keyboard prompt, and latest feedback.
- `scripts/ui/game_theme.gd`: centralizes panel, label, button styling.
- `scripts/main.gd`: owns startup, smoke dispatch, input routing, persistence, audio event selection, and high-level UI state calls.

## UI Information Architecture

The Sprint Sheet should describe UI as a screen contract with named regions.

```text
+--------------------------------------------------------------+
| Top Bar: scene progress / title / elapsed time               |
+--------------------------------------------------------------+
| Prompt Overlay                                               |
| Location / current Space-Enter action / latest feedback      |
|                                                              |
| Full-screen RPG Scene Canvas                                 |
| - tile terrain                                               |
| - player marker                                              |
| - props / exits / investigation hotspots                     |
| - scene-state effects                                        |
|                                                              |
+--------------------------------------------------------------+
```

### UI Regions

| Region | Data Owner | Current File | Must Communicate |
| --- | --- | --- | --- |
| Top Bar | `GameSession` | `scripts/ui/game_hud.gd` | scene number, title, elapsed time. |
| Scene Canvas | `SceneVisualRepository` + `GameSession` | `scripts/ui/sprite_scene_canvas.gd` | where the player is, what can be approached, what has changed. |
| Player Controls | `RpgPlayerController` | `scripts/core/rpg_player_controller.gd` | movement, facing, current interaction target. |
| Prompt Overlay | `RpgPlayerController` + `GameSession` | `scripts/ui/prompt_overlay.gd` | exact action available at the current tile and latest consequence. |
| Menus | `GameHud` + menu widgets | `scripts/ui/game_hud.gd` | title, pause, settings, save/load entry points, and keyboard focus. |
| Theme | `GameTheme` | `scripts/ui/game_theme.gd` | restrained 90s RPG HUD style, readable text, no decorative clutter. |

## Data Contract For UI Drawing

When a Sprint Sheet asks for a new scene or UI state, it should list the data the UI can consume.

### Story Scene Data

Required fields in `data/story_scenes/<scene_id>.json`:

- `id`: stable scene ID.
- `title`: shown in the top bar.
- `source`: design source file in `five/scene`.
- `min_minutes`: smoke-test pacing target.
- `start`: initial location ID.
- `ending_flag`: completion signal.
- `required_flags`: smoke-test coverage targets.
- `locations`: player-facing location graph.
- `walkthrough`: deterministic smoke path.

Location-level UI fields:

- `name`: location label.
- `description`: fallback contextual text.
- `exits`: interaction labels for movement.
- `items`: investigation target names, requirements, flags, text.
- optional `glyph_actions`, `build_actions`, `choices`, `combat`, `combos`.

### Visual Scene Data

Required fields in `data/visual_scenes/<scene_id>.json`:

- `id`: matches story scene ID.
- `tile_size`: base authoring tile size.
- `locations`: visual layout keyed by story location ID.

Visual location fields:

- `terrain`: palette hint such as `street`, `interior`, or `room`.
- `spawn`: player tile on location entry.
- `props`: visible objects, exits, item hotspots, and collision rectangles.

Prop fields:

- `kind`: renderer hint such as `building`, `table`, `window_dark`, `portal`.
- `x`, `y`, optional `w`, `h`: tile coordinates.
- `solid`: whether movement is blocked.
- optional `item`: story item ID for investigation.
- optional `exit`: story exit ID for movement.

## Sprint Sheet Template

Use this exact template for future sprint tickets.

```md
# Sprint Sheet: <short name>

## Goal

<One player-visible outcome.>

## Source Scene Contract

| Scene Evidence | Required Screen Meaning |
| --- | --- |
| <line or summary from five/scene or system doc> | <what the player must understand visually> |

## Player Loop

1. <Player action.>
2. <System feedback.>
3. <Resulting new choice or state.>

## Inputs

- Story source:
- Existing runtime file:
- Existing visual file:
- Asset source:
- Constraints:

## Outputs

- <file or screen>
- <file or screen>

## Visual Direction

### Must Read As

- <era, place, mood>

### Must Not Read As

- <wrong genre, wrong era, wrong material language>

## UI Contract

### Screen Regions

- Top Bar:
- Scene Canvas:
- Prompt Overlay:

### States

- Empty/default:
- Interactable nearby:
- Action succeeded:
- Action blocked:
- Chapter complete:

## Data Contract

- Story JSON changes:
- Visual JSON changes:
- Runtime state changes:

## Acceptance

- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-autoplay`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-first-act`
- Visual review: <what must be visible on screen>

## Screenshot Review Gate

- Title:
- First playable screen:
- First required interaction:
- Scene-specific state:
- Menu overlay:
- Mismatch check:

## Affected Files

- <file>
- <file>

## Non-Goals

- <thing not handled in this sprint>
```

## Example: Prologue Modern Silence Map Sprint

### Goal

Turn the prologue from a text-driven scene into a playable modern-silence RPG map where the player can walk through a familiar night street, enter the apartment building, inspect the home, and trigger the black pen transition.

### Source Scene Contract

| Scene Evidence | Required Screen Meaning |
| --- | --- |
| Modern city, early night. | Street, apartment, vending machine, windows, and home props must read as modern. |
| Familiar but slightly wrong. | Abnormality should come from darkness, silence, blankness, and ink traces, not from fantasy scenery. |
| Home lights and voice lamp do not turn on. | Lamps and dark windows must be readable scene signals. |
| Phone signal and text changes foreshadow later UI decoding. | UI feedback can glitch or lose information, but should not become a generic sci-fi dashboard. |

### Player Loop

1. Player moves with WASD or arrow keys.
2. Facing or standing on a modern hotspot updates the bottom dialogue prompt.
3. Space or Enter applies the current exit or investigation.
4. The event log records one abnormal detail for that room.
5. The visual canvas keeps modern material cues while gradually introducing ink/paper intrusion.

### Inputs

- Story source: `five/scene/00-prologue-lights-out.md`.
- Story data: `data/story_scenes/00-prologue-lights-out.json`.
- Visual data: `data/visual_scenes/00-prologue-lights-out.json`.
- Runtime: `GameSession`, `SceneVisualRepository`, `RpgPlayerController`.
- Renderer: `SpriteSceneCanvas`.
- Assets: RPG character atlas, paper icon, spell effects, scoped pixel primitives for modern props when atlas tiles read as the wrong era.

### Outputs

- A modern-silence visual scene map for each location in the prologue.
- Collision and interaction props for all required story flags.
- A compact prompt that always tells the player what Space/Enter will do.
- Smoke verification that still completes all story scenes.

### Visual Direction

#### Must Read As

- Modern night street.
- Apartment common area.
- Domestic interior.
- Quiet abnormality.

#### Must Not Read As

- Dungeon.
- Ancient city.
- Generic fantasy village.
- Web app dashboard.

### UI Contract

#### Screen Regions

- Top Bar: show `1/8`, scene title, elapsed time only during gameplay.
- Scene Canvas: fill screen behind HUD with tile map, modern props, player, and portal state.
- Dialogue Prompt: bottom RPG text window with movement help or exact interaction label plus the latest consequence.

#### States

- Empty/default: movement prompt.
- Interactable nearby: `Space/Enter 调查：<item>` or `Space/Enter 进入：<exit>`.
- Action succeeded: new story text appears in log.
- Action blocked: player stays on tile; prompt remains stable.
- Chapter complete: portal/magic effect appears after `entered_moqi`.
- Title: command menu over scene background, without gameplay top bar or prompt.

### Data Contract

- Every required flag in story data must have an accessible item or action in the map.
- Every story exit used by walkthrough must have a matching visual `exit` prop.
- Every location must define a spawn tile that is not blocked.
- Solid props must not block all routes to required interactions.

### Acceptance

- Godot headless load passes.
- Godot smoke autoplay passes all eight scenes.
- First-act RPG smoke passes.
- Manual visual review confirms the prologue reads as a modern night street/home scene, not a dungeon with modern labels.

### Screenshot Review Gate

- Title screen over modern street background.
- Street near vending machine.
- Building near voice lamp.
- Living room after cold dinner investigation.
- Pause menu over gameplay.
- Mismatch check: no modern prop should use chest, crate, rune, altar, or castle-room semantics.

### Non-Goals

- Save/load.
- Dialogue portraits.
- Audio.
- Visual maps for scenes 01-07.

## Review Checklist

Before a Sprint Sheet is considered ready for UI drawing:

- It names the screen regions and their data source.
- It maps scene evidence to required screen meaning.
- It states what the screen must not read as.
- It maps every player action to a visible prompt or feedback state.
- It lists the exact JSON and GDScript files expected to change.
- It includes concrete screenshot states for visual review.
- It states what the sprint is not solving.
- It is narrow enough for one implementation pass and one review pass.
