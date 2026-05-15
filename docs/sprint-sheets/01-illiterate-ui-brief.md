# UI Implementation Brief: 01 Illiterate

This brief turns `docs/sprint-sheets/01-illiterate.md` into file-level UI work.

## UI Objective

Make the first act readable as illiterate survival: the player should see that Ji Zixuan cannot read Moqi, the phone is useless, the black pen is dangerous, Moqi soldiers react to written authority, and writing `名` changes whether the Boss can be locked and attacked.

## Screen Region Contract

| Region | Owner | Contract |
| --- | --- | --- |
| Top Bar | `scripts/ui/game_hud.gd` | Keep scene progress and time; add objective state. Before `learned_name_strokes`, show `目标：□□□`; after learning `名`, show `目标：记住它的名，然后活下去。` |
| Scene Canvas | `scripts/ui/sprite_scene_canvas.gd` | Carry the main visual meaning: corrupted phone, unreadable sign, city fire, live-ink notice, soldiers' blade text, half-lit gate, blanking station, and nameless lock state. |
| Prompt Overlay | `scripts/ui/prompt_overlay.gd` | Keep location, current `Space/Enter` action, and latest feedback readable without revealing Moqi too early. |
| Interaction Hint | `scripts/core/rpg_player_controller.gd` | Enemy prompt must change with `named_beast`: before naming, `无法锁定：？？？`; after naming, `攻击无名兽`. |
| Runtime State | `scripts/core/game_session.gd` | Flags drive UI state. `_write_name()` failures need a durable failure flag such as `name_broke_once`, not only log text. |

## Data Hook Matrix

| Data | Owner | UI Hook | Output |
| --- | --- | --- | --- |
| `scene_id=01-illiterate` | `GameSession.scene_id` | `GameHud.refresh()`, `SpriteSceneCanvas.refresh()` | Enable first-act decode and rendering rules. |
| `locations.*.name` | `data/story_scenes/01-illiterate.json` | `GameHud._display_location_name()` | Do not expose readable Moqi location names before the learning state. |
| `locations.*.items.*.text` | Story JSON + `GameSession._inspect_item()` | `PromptOverlay.feedback_label` | Phone, sign, city, Xiaoyan, notice, soldiers, gate, and Xiali feedback. |
| `visual_scenes.locations.*.props.*` | `data/visual_scenes/01-illiterate.json` | `SceneVisualRepository` + `_draw_visual_prop()` | Prop kind, item, action, exit, and collision semantics. |
| `combat.*` | Story JSON station combat | `_write_name()`, `_attack()`, `prompt_text()`, `_draw_nameless_enemy()` | Hidden name, revealed name, lock flag, failure flag, and win flag. |

## Scene Canvas Rendering Contract

| Location | Required Rendering | Target Surface |
| --- | --- | --- |
| `mud_road` | `city_fire` should be a burning city silhouette, not only a fireball. `sign` shows block text. `phone` corrupts after inspection. `pen` reads as dangerous identity proof. | `SpriteSceneCanvas._draw_visual_prop()` plus helpers such as `_draw_city_fire()`, `_draw_text_surface()`, `_draw_phone_device(corrupted)`, `_draw_pen_threat()`. |
| `camp` | Tent, campfire, Xiaoyan, and notice are visible together. The notice looks like live ink. Xiaoyan reads as frightened and gesturing, not a calm tutorial NPC. | `_draw_text_surface(variant="live_ink")`, `_draw_xiaoyan_state()`. |
| `chase` | Soldier is not a bandit: dark robe, blade text, pursuit pressure. Gate has half-lit runes. Xiali stands as judge near the gate. | `_draw_soldier_threat()`, `_draw_gate_rune(half_lit=true)`, `_draw_xiali_judgement()`. |
| `station` | Wall text disappears, door has no outside, nameless silhouette starts un-lockable, `名` rune is the teaching focus. | `_draw_station_blankening()`, `_draw_name_rune()`, `_draw_nameless_enemy()`, `_draw_xiaoyan_name_state()`. |

## Prompt And Feedback Contract

`GameHud.refresh()` should pass a display-safe location name into `PromptOverlay.refresh()` instead of raw `location.name` when the scene is still undecoded.

`RpgPlayerController.prompt_text()` should handle lock-state wording for station combat. Do not expose `攻击无名兽` before `named_beast` exists.

`GameSession._write_name()` should add combat failure flags on failed attempts. The current log text already says the rune breaks and the UI name becomes blocks, but screenshot states need durable flags to reproduce that state.

## Interaction State Matrix

| State | Input | Output | UI Acceptance |
| --- | --- | --- | --- |
| Phone failure | `inspect phone` | `checked_phone_no_service` | Phone feedback includes no service, black ink, and unreadable system language. Canvas phone is visibly corrupted. |
| Sign unreadable | `inspect sign` | `checked_broken_sign` | Sign shows block text; feedback says the player cannot read the language. |
| City fall | `inspect city` | `saw_burning_city` | City fire reads as a falling city, not sunset or campfire. |
| Xiaoyan contact | `inspect xiaoyan` | `met_xiaoyan` | Dialogue contains blocks and gesture meaning, not a normal tutorial line. |
| Moqi pursuit | `inspect soldiers` | `saw_molusi` | Soldier threat is tied to the black pen and blade text. |
| Gate blocked | `inspect gate` | `checked_broken_gate` | Half-lit rune and "I cannot write" state are visible or logged. |
| Xiali judgment | `inspect xiali` | `met_xiali` | Xiali reads as suspicious judge, not warm mentor. |
| Learn name | `inspect strokes` | `learned_name_strokes` | Objective text decodes and `名` becomes a visual focus. |
| Write failure | first or second `write name` | `name_broke_once` or equivalent | Rune breaks or burns; enemy remains un-lockable. |
| Write success | third `write name` | `named_beast` | Enemy becomes `无名兽`; attack prompt becomes available. |
| Name breaks again | after two attacks | lock flag removed | Enemy returns to `？？？` or fades; attack prompt is blocked again. |
| Victory | defeat enemy | `defeated_nameless` | Enemy is gone and an exit/transition is visible. |

## Prop Risk To UI Task Map

| Risk | Required UI Task |
| --- | --- |
| `city_fire` can read as a campfire or generic spell effect. | Route it to a burning-city silhouette helper and verify it in the mud-road opening screenshot. |
| `sign` and `notice` can look like normal readable signs. | Render block text/live ink and keep prompt feedback unreadable before learning `名`. |
| `phone` can read as a normal modern prop. | Corrupt the phone after `checked_phone_no_service` and include black-ink/no-service feedback. |
| `soldier`, `xiali`, and `gate` can read as generic fantasy NPCs/props. | Add threat, judgment, and half-lit rune helpers with screenshot states in `chase`. |
| `rune` and `enemy` can read as ordinary combat markers. | Gate enemy lock and attack prompt on `named_beast`, with failure-state screenshots. |

## Component Tasks

| ID | Target | Inputs | Output | Acceptance |
| --- | --- | --- | --- | --- |
| UI-01 Decode HUD | `scripts/ui/game_hud.gd` | `session.scene_id`, `session.flags`, `location.name` | Objective label and display-safe location name | Opening shows `□□□`; after `learned_name_strokes`, objective is readable. |
| UI-02 Prop Routing | `scripts/ui/sprite_scene_canvas.gd` | `kind`, `item`, `action`, optional `variant` | Dedicated draw helpers for first-act props | `sign`, `notice`, `city_fire`, `gate`, `rune`, and `enemy` no longer fall through as generic tiles. |
| UI-03 Mud Road Evidence | `sprite_scene_canvas.gd` + visual JSON | `mud_road.props`, `checked_*` flags | Corrupted phone, unreadable sign, city fire, pen threat | First screenshot contains all four evidence props. |
| UI-04 Camp Survival | `sprite_scene_canvas.gd`, `prompt_overlay.gd` | `camp.props`, `met_xiaoyan` | Xiaoyan and notice states | Camp reads as refugee survival and failed communication. |
| UI-05 Chase Judgment | `sprite_scene_canvas.gd` | `chase.props`, `checked_broken_gate`, `met_xiali` | Soldier, gate, and Xiali variants | Xiali is not visually treated as a party helper. |
| UI-06 Station Blankening | `sprite_scene_canvas.gd` | `station.props`, name flags | Blanking wall, `名` rune, fading Xiaoyan name, nameless silhouette | Station is not a generic ruin. |
| UI-07 Nameless Lock | `rpg_player_controller.gd`, `game_session.gd` | station combat data | Correct prompt and flags for write/attack cycle | `named_beast` gates attack; failure state can be screenshot. |
| UI-08 Review Hooks | `scripts/core/rpg_illiterate_smoke.gd`, `scripts/main.gd` | screenshot states | Smoke or review path for key UI states | `--smoke-rpg-illiterate` stays green; screenshot states are reproducible. |

## Screenshot Capture Plan

| ID | Setup | Required Check |
| --- | --- | --- |
| `mud_road_opening_illiterate_ui` | `location=mud_road`, no flags | TopBar objective is blocks; phone, sign, city fire, and pen are visible. |
| `mud_road_after_phone_sign_city` | `checked_phone_no_service`, `checked_broken_sign`, `saw_burning_city` | Feedback proves no service, unreadable sign, and falling city. |
| `camp_xiaoyan_unreadable_dialogue` | `location=camp`, `met_xiaoyan` | Xiaoyan and notice communicate without readable language. |
| `chase_xiali_judgement_gate` | `checked_broken_gate`, `met_xiali` | Gate is half-lit and Xiali reads as judgment. |
| `station_blankening_before_name` | `location=station`, before `learned_name_strokes` | Enemy is `？？？` or un-lockable; station blanks out. |
| `station_name_learning_feedback` | `learned_name_strokes` | Objective decodes and `名` is the focus. |
| `station_after_name_break` | failure flag present | Rune breaks and enemy becomes un-lockable again. |
| `station_after_defeated_nameless` | `defeated_nameless` | Enemy is gone and exit/transition is visible. |

## Acceptance Commands

```sh
python3 -m json.tool data/story_scenes/01-illiterate.json >/dev/null
python3 -m json.tool data/visual_scenes/01-illiterate.json >/dev/null
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-illiterate
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-autoplay
/Applications/Godot.app/Contents/MacOS/Godot --path . --quit-after 120 -- --smoke-render-frame
```

## Non-Goals

- Do not replace the existing Godot UI framework.
- Do not introduce a large asset pipeline.
- Do not build a general screenshot system in this pass.
- Do not expand second-act or later-scene UI.
- Do not rebalance combat numbers beyond UI-visible lock and naming behavior.
