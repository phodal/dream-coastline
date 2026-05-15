# Sprint Sheet: Return Star Plan Mobilization

## Diagnosis

第六幕要证明前期文明建设成果能转化为跨世界救援能力。若只做星门和 Boss，玩家会看不到支持度、资源动员、备份系统和静默探针删除理解的压力。

## Goal

把第六幕做成“文明动员对抗静默”的切片：归星议会、浮空船坞、国书核心、归星门和现代裂隙共同证明墨颀能以文明系统抵抗删除。

## Source Scene Contract

| Scene Evidence | Required Screen Meaning |
| --- | --- |
| 支持度结算体现前期成果。 | 议会不能只是对话点，应显示派系、资源和长期选择回报。 |
| 反对派有合理担忧。 | UI 反馈不能把反对派画成普通敌人。 |
| 静默探针删除坐标、档案和名字。 | Boss 必须攻击 UI/地图/字根/名字，而不是普通伤害。 |
| 胜利来自标准字典、档案馆、国书网络和学生共同书写。 | 恢复状态必须读成文明备份生效。 |

## Player Loop

1. 玩家在星象塔确认现代坐标消失。
2. 玩家进入归星议会并结算支持度。
3. 玩家建造续页舰、绑定备份、校准归星门。
4. 静默探针入侵并删除信息。
5. 玩家调用文明系统恢复并开启归星门。

## Inputs

- Scene source: `five/scene/06-return-star-plan.md`.
- Story data: `data/story_scenes/06-return-star-plan.json`.
- Visual data: `data/visual_scenes/06-return-star-plan.json`.
- Systems: `five/world/extinguishers-and-silence-protocol.md`, `five/system/core-loop.md`.
- Smoke: `scripts/core/rpg_return_star_plan_smoke.gd`.

## Outputs

- Mobilization visuals for astral tower, council, dockyard, core, gate, and rift.
- Support/opposition feedback state.
- Backup binding and return gate build states.
- Silence probe UI deletion/restoration state.

## Visual Direction

### Must Read As

- Civilizational debate.
- Cross-world engineering.
- Backup systems as defense.
- Enemy as protocol, not monster.

### Must Not Read As

- Simple spaceship crafting.
- Good faction vs bad faction voting.
- Generic portal dungeon.
- Normal Boss with only HP pressure.

## UI Contract

### Screen Regions

- Scene Canvas: show the engineering function of each location.
- Dialogue Prompt: build actions must name mandate, vessel, backups, gate, return.
- Feedback: deletion/restoration must be visible in text and UI labels.

### States

- Astral tower: disappearing modern coordinates.
- Council: support/opposition and mandate.
- Dockyard: vessel blueprint/building.
- Core: backups and Xiali stabilization.
- Gate: calibration/opening.
- Rift: probe deletes, civilization restores.

## Data Contract

- Story JSON changes: only if support or backup feedback is not present.
- Visual JSON changes: add prop kinds for mandate, vessel, backup chain, gate calibration, silence deletion.
- Renderer changes: enemy/protocol visuals should use geometric/erasure language.
- HUD changes: allow temporary corrupted labels without breaking real saves.

## Implementation Tasks

1. Audit build actions and required flags for each mobilization step.
2. Add visible build progression for vessel, backups, and gate.
3. Add UI corruption/restoration state for static screenshots and smoke-safe behavior.
4. Capture screenshots for council, dockyard, core, gate, and rift.
5. Verify return-star smoke.

## Acceptance

- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-return-star-plan`
- Manual playtest confirms victory feels civilization-backed.

## Screenshot Review Gate

- Astral tower with disappearing coordinate.
- Council mandate decision.
- Dockyard/vessel build.
- Core backup binding.
- Gate calibration.
- Rift under silence probe.
- Mismatch check: probe must not read as ordinary creature.

## Affected Files

- `data/visual_scenes/06-return-star-plan.json`
- `data/story_scenes/06-return-star-plan.json`
- `scripts/ui/sprite_scene_canvas.gd`
- `scripts/ui/prompt_overlay.gd`
- `scripts/core/rpg_return_star_plan_smoke.gd`

## Non-Goals

- 不实现完整派系模拟。
- 不真实破坏玩家存档。
- 不处理最终现代战场。
