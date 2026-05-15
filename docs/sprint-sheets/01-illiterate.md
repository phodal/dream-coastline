# Sprint Sheet: Illiterate Survival And First Glyph

## Diagnosis

第一幕不能只是“异世界荒野 RPG”。`five/scene/01-illiterate.md` 的核心是失语、文盲、生存和第一次学习；如果画面只读成营地、树林、敌人和 Boss，玩家会错过“UI、地名、对话都不可读”的体验。

## Goal

把第一幕做成“失语求生”切片：玩家先在不理解文字和语言的状态下逃生，再通过“名”字让无名兽显形并完成第一次可理解的战斗。

## Source Scene Contract

| Scene Evidence | Required Screen Meaning |
| --- | --- |
| 玩家不会墨颀文字、听不懂语言。 | UI、路牌、任务目标和部分 NPC 文本必须出现乱码/不可读状态。 |
| 手机失效，界面被墨水污染。 | 现代物件应成为断裂线索，不应继续表现为可靠现代工具。 |
| 远处燃烧的城。 | 背景必须提供王城陷落的第一视觉证据。 |
| 无名兽必须先被“命名”才能被攻击。 | Boss 初始不可锁定/不可见，命名后才成为可交互敌人。 |

## Player Loop

1. 玩家在泥路醒来，先看到手机失效和乱码目标。
2. 玩家检查破损路牌、燃烧城市、流民营和小砚。
3. 墨律司追捕触发，夏离救场但不信任玩家。
4. 玩家进入废弃驿站，空间开始空白化。
5. 玩家学习“名”，无名兽显形，完成第一次 glyph combat。

## Inputs

- Scene source: `five/scene/01-illiterate.md`.
- Story data: `data/story_scenes/01-illiterate.json`.
- Visual data: `data/visual_scenes/01-illiterate.json`.
- Systems: `five/system/text-learning-ui-decoding.md`, `five/system/glyph-combat.md`.
- Smoke: `scripts/core/rpg_illiterate_smoke.gd`.
- Renderer: `scripts/ui/sprite_scene_canvas.gd`.

## Outputs

- Scene-aligned visuals for mud road, refugee camp, chase route, and abandoned station.
- UI decoding states before and after learning `名`.
- Enemy visibility/targeting states that distinguish unnamed from named.
- Screenshot checklist for phone corruption, unreadable sign, Xiaoyan, Xiali, and nameless beast.

## Visual Direction

### Must Read As

- Dislocation after crossing worlds.
- Illiteracy and language loss.
- Borderland survival.
- First glyph-learning breakthrough.

### Must Not Read As

- Generic fantasy tutorial.
- Comfortable village hub.
- Fully readable quest UI.
- Ordinary monster encounter.

## UI Contract

### Screen Regions

- Scene Canvas: wilderness/ruin locations with burning city, campfire, soldiers, Xiaoyan, Xiali, and blanking station.
- Dialogue Prompt: must allow corrupted labels before `名` is learned.
- Top Status: can show scene progress, but task meaning should be unstable until decoding improves.

### States

- Mud road: phone and sign are modern/foreign failure signals.
- Camp: NPC labels partially unreadable; Xiaoyan is readable enough to anchor empathy.
- Chase: soldiers and Xiali must read as pressure and judgment, not ordinary party members.
- Station before naming: enemy presence is implied by shadow/blankness, not a normal sprite.
- Station after naming: enemy becomes visible and attack prompt becomes valid.

## Data Contract

- Story JSON changes: only if learning/decoding flags are missing from required states.
- Visual JSON changes: prop kinds may need `burning_city`, `broken_sign`, `blank_space`, or `unnamed_enemy`.
- Renderer changes: add explicit blanking/ink corruption states instead of generic `enemy` only.
- HUD changes: support partially unreadable prompt text when decoding is incomplete.

## Implementation Tasks

1. Audit `01-illiterate` visual props against the source scene.
2. Add a renderer state for corrupted phone/sign text.
3. Add a pre-name enemy state that cannot be mistaken for a normal monster.
4. Ensure learning `名` creates a visible before/after UI difference.
5. Walk the smoke route manually and capture screenshots at phone, sign, camp, Xiali, and Boss reveal.

## Acceptance

- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-illiterate`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --quit-after 120 -- --smoke-render-frame`
- Manual playtest confirms the player is confused first, then gains clarity through `名`.

## Screenshot Review Gate

- Mud road with corrupted phone.
- Broken sign with unreadable location.
- Refugee camp with Xiaoyan.
- Chase route with soldiers/Xiali pressure.
- Station before and after naming the beast.
- Mismatch check: no screenshot should read as a normal readable RPG tutorial.

## Affected Files

- `data/visual_scenes/01-illiterate.json`
- `data/story_scenes/01-illiterate.json`
- `scripts/ui/sprite_scene_canvas.gd`
- `scripts/ui/prompt_overlay.gd`
- `scripts/core/rpg_illiterate_smoke.gd`

## Non-Goals

- 不实现完整手写识别系统。
- 不重写夏离或小砚剧情。
- 不解决后续字根全部教学。
