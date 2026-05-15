# Sprint Sheet: Century Continuation Time And Civilization

## Diagnosis

第五幕不是普通地图连续推进，而是百年尺度的文明成长。如果 Sprint Sheet 仍按单场景冒险写，会漏掉时间推进、制度继承、代价、老去和星象工程这些核心体验。

## Goal

把第五幕做成“文明继续”的长时间切片：玩家推动文字工业、国书网络、星象工程和归星前置条件，并看到成果、继承和代价。

## Source Scene Contract

| Scene Evidence | Required Screen Meaning |
| --- | --- |
| 多个时代节点组成。 | UI/视觉必须表现时间跳跃和阶段成果。 |
| 第一批学生变成教师。 | NPC/场景应表现代际传承，不只是任务完成。 |
| 夏离绑定国书，逐渐像文明记忆。 | Xiali 的视觉/反馈要体现个人代价。 |
| 星象塔让墨颀看见现代星球变暗。 | 星象工程必须读成观测与坐标系统，不是普通高塔。 |

## Player Loop

1. 玩家完成一个文明目标。
2. 系统推进数年或数十年。
3. 城市/机构/角色状态变化。
4. 玩家处理下一个时代节点。
5. 星象塔竣工，现代星球变暗成为下一幕动员理由。

## Inputs

- Scene source: `five/scene/05-century-continuation.md`.
- Story data: `data/story_scenes/05-century-continuation.json`.
- Visual data: `data/visual_scenes/05-century-continuation.json`.
- Systems: `five/system/civilization-building.md`, `five/system/continue-save-continuation.md`.
- Smoke: `scripts/core/rpg_century_continuation_smoke.gd`.

## Outputs

- Visual stages for industry, network, astral engineering, and star tower.
- Time-passage UI state.
- Xiali binding/weakening state.
- Modern star darkening reveal.

## Visual Direction

### Must Read As

- Civilization growing across generations.
- Engineering infrastructure, not miracle.
- Public systems becoming everyday life.
- Star observation as a civil project.

### Must Not Read As

- Four disconnected quest rooms.
- Static tech tree.
- Single-character power fantasy.
- Generic tower dungeon.

## UI Contract

### Screen Regions

- Scene Canvas: each location should encode the civilization stage.
- Dialogue Prompt: build actions should be framed as civil projects.
- Feedback: should mention time, inheritance, and cost when relevant.

### States

- Industry: text industry and first teachers.
- Network: Xiali binding and statebook network.
- Astral: star map, cross beacon, engineering preparation.
- Star tower: completed tower, silent probe, modern star darkening.

## Data Contract

- Story JSON changes: only if time passage and generation effects are not represented.
- Visual JSON changes: add era/state hints to locations if needed.
- Renderer changes: split `node` and `rune` visuals by industry/network/astral meaning.
- HUD changes: add time-jump feedback only if compact and scene-grounded.

## Implementation Tasks

1. Audit stage locations against the four technology phases.
2. Add visible stage differences for industry, network, astral, and star tower.
3. Represent Xiali binding as cost, not upgrade glow only.
4. Add a screenshot state for modern star darkening.
5. Verify smoke and manual route.

## Acceptance

- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-century-continuation`
- Manual playtest confirms time passage changes the screen, not only text.

## Screenshot Review Gate

- Text industry stage.
- Statebook network stage.
- Xiali binding state.
- Astral engineering stage.
- Star tower and modern star darkening.
- Mismatch check: no stage should read as a static generic node room.

## Affected Files

- `data/visual_scenes/05-century-continuation.json`
- `data/story_scenes/05-century-continuation.json`
- `scripts/ui/sprite_scene_canvas.gd`
- `scripts/core/rpg_century_continuation_smoke.gd`

## Non-Goals

- 不实现完整时代模拟器。
- 不新增复杂 NPC 年龄系统。
- 不处理归星议会争议。
