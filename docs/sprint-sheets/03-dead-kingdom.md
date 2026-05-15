# Sprint Sheet: Dead Kingdom Investigation

## Diagnosis

第三幕的核心不是“废墟探索”，而是拆掉复国幻觉。视觉和 UI 必须把死城秩序、知识垄断、国书封锁和王权锁呈现出来，否则玩家只会读成一段普通王都副本。

## Goal

把第三幕做成“死去王国调查”切片：玩家通过外城、藏书楼、墨律司总部、宫城和国书殿，证明危机来自封闭制度和系统失修。

## Source Scene Contract

| Scene Evidence | Required Screen Meaning |
| --- | --- |
| 旧王都仍被墨律司控制。 | 外城不是荒废空城，而是死板秩序和宣传控制。 |
| 文献调查显示改革与封锁真相。 | 藏书、记录和封锁日志必须是主要交互物。 |
| 王城陷落由系统封锁引发连锁崩坏。 | 宫城要有路线复原和崩坏痕迹。 |
| 王权锁质问“无王之国”。 | Boss UI 要表现规则/合法性压力，不只是敌人血量。 |

## Player Loop

1. 玩家进入外城，看见死城秩序和罪人宣传。
2. 玩家调查文献、日志和名册。
3. 玩家复原王城陷落路线。
4. 玩家处理藏书归属选择。
5. 玩家破除王权锁并打开主国书核心。

## Inputs

- Scene source: `five/scene/03-dead-kingdom.md`.
- Story data: `data/story_scenes/03-dead-kingdom.json`.
- Visual data: `data/visual_scenes/03-dead-kingdom.json`.
- Systems: `five/world/moqi-civilization.md`, `five/system/civilization-building.md`.
- Smoke: `scripts/core/rpg_dead_kingdom_smoke.gd`.

## Outputs

- Dead city visual states for order, archive evidence, ministry records, palace ruin, and statebook hall.
- Choice feedback for public books / restoration capital / engineering use / parent clues.
- Boss state for royal shadow and rule-breaking glyph actions.

## Visual Direction

### Must Read As

- Controlled dead capital.
- Institutional archive and propaganda.
- Ruined palace with reconstructable history.
- Ideological Boss about state legitimacy.

### Must Not Read As

- Empty ruin dungeon.
- Simple royal revenge story.
- Generic library fetch quest.
- Boss room detached from investigation evidence.

## UI Contract

### Screen Regions

- Scene Canvas: city, library, HQ, palace, and hall must have different authority/evidence readings.
- Dialogue Prompt: investigation prompts should name evidence, not generic records.
- Feedback: must connect discoveries to the anti-restoration argument.

### States

- Outer city: propaganda/order is visible.
- Library: reform records and forbidden records are distinct.
- HQ: lockdown logs and missing roster matter.
- Palace: fall route and Xiali memory pressure.
- Hall: royal shadow,王权锁, parent full plan.

## Data Contract

- Story JSON changes: only if choice outcomes or evidence states are not exposed.
- Visual JSON changes: split generic `record` into reform, lockdown, roster, parent plan where useful.
- Renderer changes: dead city should not share cheerful village/academy material cues.
- HUD changes: choice and evidence feedback must remain readable in dialogue window.

## Implementation Tasks

1. Audit `record`, `poster`, `node`, and `rune` props for evidence semantics.
2. Add visual distinction for propaganda, reform records, lockdown logs, and parent plan.
3. Add city-state cues that read as controlled dead order.
4. Capture screenshots across outer city, library, HQ, palace, and hall.
5. Verify choice/Boss route through smoke.

## Acceptance

- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-dead-kingdom`
- Manual playtest confirms the chapter argues against simple restoration.

## Screenshot Review Gate

- Outer city propaganda/dead order.
- Library reform evidence.
- HQ lockdown evidence.
- Palace fall route.
- Hall with royal shadow/core.
- Mismatch check: no location should read as unrelated ruin tiles.

## Affected Files

- `data/visual_scenes/03-dead-kingdom.json`
- `data/story_scenes/03-dead-kingdom.json`
- `scripts/ui/sprite_scene_canvas.gd`
- `scripts/core/rpg_dead_kingdom_smoke.gd`

## Non-Goals

- 不完整实现政治路线系统。
- 不重写夏离选择分支。
- 不处理续文院建设 UI。
