# Sprint Sheet: Moqi Academy Literacy Engineering

## Diagnosis

第二幕不是普通学院关卡。Scene 要证明墨颀文字不是魔法咒语，而是可学习、可验证、可修复世界的工程系统；如果只做书院、村庄和符文道具，玩家会看不到“文字技术”的结构。

## Goal

把第二幕做成“从识字到修复”的学习系统切片：玩家学会 `名`、`门`、`火`、`止`，并用它们解决村落问题、找回字典、修复第一个国书节点。

## Source Scene Contract

| Scene Evidence | Required Screen Meaning |
| --- | --- |
| 闻素解释日常文字、律文字、真文字三层结构。 | 书院/藏书室必须读成知识分层和教学空间。 |
| 村落水井符文损坏。 | 字根必须落到民生修复，不是抽象技能栏。 |
| 基础字典被封存。 | 字典既是剧情道具，也是 UI 解码能力来源。 |
| 第一个国书节点几乎失效。 | 节点要读成基础设施，不是普通魔法祭坛。 |

## Player Loop

1. 玩家在书院见闻素，建立学习据点。
2. 玩家学习并使用四个基础字根。
3. 玩家在村庄、档案/学塾遗址、国书节点中应用字根。
4. 字典和节点修复推动 UI 可读性和世界稳定度。
5. 玩家击败执契官并读取父母第一段影像。

## Inputs

- Scene source: `five/scene/02-moqi-academy.md`.
- Story data: `data/story_scenes/02-moqi-academy.json`.
- Visual data: `data/visual_scenes/02-moqi-academy.json`.
- Systems: `five/system/text-learning-ui-decoding.md`, `five/system/core-loop.md`.
- Smoke: `scripts/core/rpg_moqi_academy_smoke.gd`.

## Outputs

- Academy, village, archive, and node visuals that express literacy engineering.
- Glyph use states for `名`、`门`、`火`、`止`.
- Dictionary recovery and node repair feedback.
- Contract Officer Boss state tied to contract locks.

## Visual Direction

### Must Read As

- Hidden academy and teaching refuge.
- Text as infrastructure.
- Village repair through literacy.
- First statebook node repair.

### Must Not Read As

- Generic wizard school.
- Spell pickup checklist.
- Decorative rune room without engineering meaning.
- Pure combat chapter.

## UI Contract

### Screen Regions

- Scene Canvas: academy/archive/node areas must distinguish teaching, storage, and infrastructure.
- Dialogue Prompt: action labels should show which glyph root is being applied.
- Feedback: must explain repair consequence and UI decoding progress.

### States

- Academy: Wensu and Xiali establish teaching tension.
- Village: well/crack/source repair must visibly change after glyph actions.
- Archive: dictionary cabinet/records must read as restricted knowledge.
- Node: damaged node, contract lock, officer, and parent record must be distinct.

## Data Contract

- Story JSON changes: add missing flags only if glyph learning cannot be represented.
- Visual JSON changes: use prop kinds such as `teaching_rune`, `damaged_well`, `dictionary_cabinet`, `statebook_node`.
- Renderer changes: avoid drawing all `rune` props identically when they have different system meaning.
- HUD changes: show decoded/locked labels when dictionary progress changes.

## Implementation Tasks

1. Audit academy/village/archive/node prop semantics.
2. Split generic `rune` rendering into teaching, repair, lock, and node variants.
3. Add visual before/after for well repair and node repair.
4. Ensure Boss prompts show contract logic, not generic attack only.
5. Capture screenshots for learning, repair, dictionary, node, and parent-record states.

## Acceptance

- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-moqi-academy`
- Manual playtest confirms glyph roots are understood as tools for repair.

## Screenshot Review Gate

- Academy teaching state.
- Village well before/after repair.
- Archive dictionary cabinet.
- Node under contract lock.
- Parent record after repair.
- Mismatch check: scene should not read as generic magic school.

## Affected Files

- `data/visual_scenes/02-moqi-academy.json`
- `data/story_scenes/02-moqi-academy.json`
- `scripts/ui/sprite_scene_canvas.gd`
- `scripts/core/rpg_moqi_academy_smoke.gd`

## Non-Goals

- 不做完整技能树 UI。
- 不重写字根系统规则。
- 不处理王都调查线。
