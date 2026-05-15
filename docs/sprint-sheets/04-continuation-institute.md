# Sprint Sheet: Continuation Institute Civilization Build

## Diagnosis

第四幕从冒险切到文明建设。若 Sprint Sheet 只列地点和战斗，会漏掉公开知识、组织责任、工程复盘和多人共同施术这些核心主题。

## Goal

把第四幕做成“公开知识成为制度”的建设切片：续文院、学塾、工坊、矿场、通信塔和封字塔都必须体现教育、工程、复盘与公共档案。

## Source Scene Contract

| Scene Evidence | Required Screen Meaning |
| --- | --- |
| 续文院是开放研究、教育和工程组织。 | 主据点不能像王宫或旧书院，应读成开放协作机构。 |
| 指标回流到任务结果和城市状态。 | UI/反馈要表现识字率、信任、能源、开放度等不是装饰数值。 |
| 防洪符文第一次失败后复盘。 | 工坊/任务状态必须支持失败、记录、修正、再验证。 |
| 封字塔让平民遗忘文字。 | Boss 应表现知识被抹除，再由学生/字典/档案恢复。 |

## Player Loop

1. 玩家建立续文院并选择第一批成员。
2. 玩家在工坊、学塾、矿场和通信塔推动制度化建设。
3. 玩家处理失败和复盘，证明公开知识可承担责任。
4. 玩家对抗封字塔，保护学生和字典。
5. 玩家把封字塔改写成公共档案塔。

## Inputs

- Scene source: `five/scene/04-continuation-institute.md`.
- Story data: `data/story_scenes/04-continuation-institute.json`.
- Visual data: `data/visual_scenes/04-continuation-institute.json`.
- Systems: `five/system/civilization-building.md`, `five/system/chapter-task-template.md`.
- Smoke: `scripts/core/rpg_continuation_institute_smoke.gd`.

## Outputs

- Location visuals for institute, school, workshop, mine, tower, and seal tower.
- Build-action UI/feedback that reads as organizational progress.
- Visual distinction between knowledge record, standard dictionary, communication array, and archive tower.
- Boss state for forgetting/restore pressure.

## Visual Direction

### Must Read As

- Open institute.
- Public school.
- Workshop and engineering process.
- Civilization learning from mistakes.
- Archive replacing censorship.

### Must Not Read As

- Static town upgrade menu only.
- Old royal academy.
- Generic crafting hub.
- Tower Boss without educational stakes.

## UI Contract

### Screen Regions

- Scene Canvas: each site should show what kind of public system is being built.
- Dialogue Prompt: build actions must name institution/process, not only `build`.
- Feedback: should connect actions to metrics and visible civil changes.

### States

- Institute: founding and charter.
- School: first class and error records.
- Workshop: workflow and flood failure review.
- Mine: hazard and safety process.
- Tower: communication restoration.
- Seal tower: students/dictionary under attack, archive conversion.

## Data Contract

- Story JSON changes: expose metric deltas only if current feedback is insufficient.
- Visual JSON changes: use build-state props for school/workshop/tower progression.
- Renderer changes: split `rune` into construction, standardization, hazard, communication, archive.
- HUD changes: consider compact metric feedback only if it remains scene-grounded.

## Implementation Tasks

1. Audit build_actions and visual props for each location.
2. Add visible before/after states for founded institute, public school, safety workflow, communication tower, archive tower.
3. Ensure failure/review/success loop is represented in text feedback and visuals.
4. Capture screenshots for institute, school, workshop, mine, tower, and seal tower.
5. Verify `--smoke-rpg-continuation-institute`.

## Acceptance

- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-continuation-institute`
- Manual playtest confirms civilization building is visible, not just logged.

## Screenshot Review Gate

- Institute founding.
- Public school first class.
- Workshop/flood review.
- Mine safety process.
- Communication tower.
- Seal tower before/after archive conversion.
- Mismatch check: no site should read as generic rune workbench.

## Affected Files

- `data/visual_scenes/04-continuation-institute.json`
- `data/story_scenes/04-continuation-institute.json`
- `scripts/ui/sprite_scene_canvas.gd`
- `scripts/core/rpg_continuation_institute_smoke.gd`

## Non-Goals

- 不做完整城市经营 UI。
- 不平衡长期指标数值。
- 不处理百年时间跳跃表现。
