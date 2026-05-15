# Sprint Sheet: Lights On Again Final Modern Merge

## Diagnosis

第七幕回到序幕的现代空间，重点是闭环和文明合流。若只做最终 Boss 或现代地图，玩家会看不到“灯未亮起”到“灯重新亮起”的回扣，也看不到墨颀系统如何在现代落地。

## Goal

把第七幕做成“现代静默被拒绝”的终章切片：家、学校、街道、便利店、实验室和轨道静默层都要表现现代世界正在被删除，以及两个文明如何共同恢复意义。

## Source Scene Contract

| Scene Evidence | Required Screen Meaning |
| --- | --- |
| 回到序幕地点，熟悉空间半静默化。 | 家和街道必须复用/呼应序幕，但被明显改写。 |
| 学校走廊没有尽头、联系人未知、无脸市民。 | 现代静默要体现在日常物件和人名消失。 |
| 临时国书节点连接现代物理系统。 | 墨颀技术在现代不稳定，需要建立节点才能工作。 |
| 最终 Boss 删除意义。 | Boss 阶段必须删除技能、队友名、任务目标、地图，再由文明备份恢复。 |
| 结尾家里的灯重新亮起。 | 最终画面必须闭合序幕核心悬念。 |

## Player Loop

1. 玩家回到家，确认同一空间已半静默。
2. 玩家在学校和街道确认名字、路径、联系人正在消失。
3. 玩家建立临时国书节点并救回普通市民。
4. 玩家连接父母实验室与墨颀系统。
5. 玩家进入轨道静默层，拒绝静默协议。

## Inputs

- Scene source: `five/scene/07-lights-on-again.md`.
- Story data: `data/story_scenes/07-lights-on-again.json`.
- Visual data: `data/visual_scenes/07-lights-on-again.json`.
- Systems: `five/world/extinguishers-and-silence-protocol.md`, `five/world/modern-star-and-return.md`.
- Smoke: `scripts/core/rpg_lights_on_again_smoke.gd`.

## Outputs

- Semi-silenced modern visuals for home, school, street, store, lab, and orbit.
- Temporary statebook node build states.
- Name restoration and final UI restoration states.
- Final protocol Boss states and ending-light feedback.

## Visual Direction

### Must Read As

- Same modern world as prologue, now damaged.
- Names, paths, contacts, and lights being erased.
- Moqi civilization support entering modern space.
- Final restoration of meaning.

### Must Not Read As

- New unrelated sci-fi level.
- Ordinary post-apocalypse city.
- Generic final boss arena.
- Pure fantasy magic replacing modern reality.

## UI Contract

### Screen Regions

- Scene Canvas: modern props must remain modern but partially blanked.
- Dialogue Prompt: name recovery and node building actions must be explicit.
- Feedback: should show deletion, restoration, and Continue closure.

### States

- Home: half-silenced version of prologue home.
- School: endless corridor and deleted names.
- Street: grid/node construction.
- Store: faceless clerk and call-name action.
- Lab: modern beacon, bridge, parent system.
- Orbit: final protocol, UI deletion/restoration, Continue.

## Data Contract

- Story JSON changes: only if final recovery state is not exposed.
- Visual JSON changes: add semi-silence variants for modern props and locations.
- Renderer changes: support faceless, blank signage, contact corruption, final protocol geometry.
- HUD changes: temporary deletion/restoration of UI labels must be reversible and smoke-safe.

## Implementation Tasks

1. Audit reuse opportunities from prologue visual language.
2. Add semi-silence variants for home, school, street, store, lab, and orbit.
3. Add name restoration and node stabilization visual states.
4. Add final protocol deletion/restoration UI states.
5. Capture screenshots for each final chapter location and final Continue state.
6. Verify lights-on-again smoke.

## Acceptance

- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-lights-on-again`
- Manual playtest confirms the ending closes the prologue visual promise.

## Screenshot Review Gate

- Home matching prologue but semi-silenced.
- Endless school corridor / deleted names.
- Street grid and temporary node.
- Store clerk before/after naming.
- Lab bridge to Moqi systems.
- Orbit final protocol and restored final UI.
- Ending light/Continue closure.
- Mismatch check: final chapter must not read as unrelated sci-fi arena.

## Affected Files

- `data/visual_scenes/07-lights-on-again.json`
- `data/story_scenes/07-lights-on-again.json`
- `scripts/ui/sprite_scene_canvas.gd`
- `scripts/ui/prompt_overlay.gd`
- `scripts/core/rpg_lights_on_again_smoke.gd`

## Non-Goals

- 不实现多结局完整演出。
- 不真实删除玩家存档。
- 不替换全部现代场景资产。
