# Sprint Sheet: Prologue Modern Silence RPG Pass

## Diagnosis

这次 playtest 暴露的问题不是“是否像 RPG”这么简单。当前 UI 已经有底部对话窗、命令框和 tile map，但它仍然和 `five/scene/00-prologue-lights-out.md` 的 scene 气质不一致：序幕是现代日常被轻微异常撕开，而画面容易滑向普通 dungeon / 复古奇幻 RPG。

前一版 Sprint Sheet 失败点：

- 只要求“90s RPG 风格”，没有要求“现代街区、楼道、家中未亮的灯、手机黑墨痕”等 scene 语义。
- 只检查 HUD 区域，不检查道具是否属于当前时代；自动售货机被画成箱子时，交互文字正确但 scene 已经错了。
- 只写 render smoke，不要求人工按真实路径玩一遍并截图比较。
- 没有把 `five/system/art-audio-direction.md` 的“现代静默视觉”转成可执行验收。

## Goal

把序幕做成“现代静默 RPG”切片：保留 RPG 的地图、底部文本窗和命令操作，但第一眼必须是现代夜晚、熟悉但不安，而不是普通古风、地牢或泛复古 RPG。

## Source Scene Contract

| Scene Evidence | Required Screen Meaning |
| --- | --- |
| 现代城市，初入夜。 | 街道、居民楼、自动售货机、公告/窗户等必须读成现代日常。 |
| 核心情绪：熟悉中的异常，先不恐怖，逐步失控。 | 画面不能一开始就魔法化；异常应来自灯不亮、黑墨痕、空白、静默。 |
| 家里灯没亮、楼道声控灯没亮。 | 灯、窗、楼道应是主要视觉焦点，不只是 generic prop。 |
| 手机信号、家中灯光、文字变化是 UI 伏笔。 | HUD 和道具反馈要支持“信息被擦掉/失真”，但不能变成普通 sci-fi panel。 |
| 黑色钢笔不像现代钢笔，更像权杖或仪器。 | 最终关键道具可以不完全现代，但必须显得特殊，不能和普通物件同级。 |

## Player Loop

1. 玩家从现代街道回家。
2. 面向现代物件时，底部对话窗显示可执行动作和一条异常反馈。
3. 玩家进入楼道、家门、客厅、书房、卧室。
4. 每个空间只暴露一个异常信息：灯、门锁、冷饭、电视、眼镜/笔记、信和黑笔。
5. 玩家触发黑笔后，现代声画被抽空，转入下一幕。

## Inputs

- Scene source: `five/scene/00-prologue-lights-out.md`.
- Art source: `five/system/art-audio-direction.md`.
- Story data: `data/story_scenes/00-prologue-lights-out.json`.
- Visual data: `data/visual_scenes/00-prologue-lights-out.json`.
- Runtime: `scripts/core/game_session.gd`, `scripts/core/rpg_player_controller.gd`.
- Renderer: `scripts/ui/sprite_scene_canvas.gd`.
- HUD: `scripts/ui/game_hud.gd`, `scripts/ui/prompt_overlay.gd`, `scripts/ui/game_theme.gd`.
- Menus: `scripts/ui/title_screen.gd`, `scripts/ui/pause_menu.gd`, `scripts/ui/settings_menu.gd`.
- Existing assets: OpenGameArt RPG character atlas, dungeon crawl atlas, paper icon, spell effects.
- Constraint: existing atlas assets may be used only when their meaning matches the scene; otherwise draw simple pixel primitives or add a scoped asset.

## Outputs

- A scene-aligned visual pass for the prologue street, building, home, living room, study, and bedroom.
- A modern-object renderer path for vending machine, phone, TV, mailbox, open door, dark window, lamp, note, letter, and black pen.
- A HUD that feels like RPG interaction UI without making the modern scene look like a fantasy dungeon.
- A playtest checklist with required screenshots and route coverage.

## Visual Direction

### Must Read As

- Modern night street.
- Familiar apartment building.
- Home interior with missing parents.
- Slightly wrong silence.
- Paper/ink intrusion only where the scene calls for it.

### Must Not Read As

- Dungeon room.
- Ancient kingdom.
- Generic fantasy village.
- Web app dashboard.
- Pure retro nostalgia detached from the story.

### Palette Rule

The global RPG UI may use ink, paper, gold, and pixel borders. The scene canvas must still preserve modern material cues:

- street asphalt/sidewalk should not look like castle stone;
- apartment walls and doors should not look like dungeon walls;
- modern props must not use chest, crate, rune, altar, or generic cabinet tiles;
- black ink effects are accents, not the base palette.

## UI Contract

### Screen Regions

- Scene Canvas: full-screen map remains primary, but prop choices must match `Source Scene Contract`.
- Top Status: small RPG status strip only; it must not become an app navigation bar.
- Dialogue Prompt: bottom RPG text window, 17% screen height target at 720p, never covering the player spawn or current interaction.
- Command Menu: title/pause/settings use RPG command windows, but title background should remain the modern street scene.
- Scene Feedback: latest feedback must describe the abnormal detail, not generic success text.

### States

- Title: show modern street background and command menu only; do not show gameplay prompt or top status.
- Street default: player, residential building, dark window, vending machine, poster, entry point.
- Street interactable: vending machine and poster must look modern before the prompt text is read.
- Building: lamp/mailbox/stairs must read as apartment common area, not castle interior.
- Home/living room: door, sofa/table, cold dinner, TV, photo must read as domestic modern interior.
- Study/bedroom: note, phone, letter, black pen, portal transition must make the ink intrusion progressively stronger.
- Pause/settings: command windows may overlay the map, but they should not hide the fact that the scene is modern.

## Data Contract

- Story JSON changes: only if scene text is missing the state required for visual feedback.
- Visual JSON changes: add or rename `kind` values when the renderer needs era-specific semantics.
- Renderer changes: prefer explicit `kind` drawing functions for modern props over atlas fallback.
- HUD changes: only when screenshot review shows title/gameplay/menu state conflict.

## Implementation Tasks

1. Audit every `kind` in `data/visual_scenes/00-prologue-lights-out.json` against the source scene.
2. Replace any dungeon/fantasy atlas fallback that represents a modern object.
3. Add explicit renderer branches for modern props before adding new assets.
4. Keep the RPG HUD, but hide gameplay HUD on title and title-settings states.
5. Walk the first-act route manually and capture screenshots at:
   - title screen;
   - street near vending machine;
   - building near voice lamp;
   - home/living room after one investigation;
   - pause menu over gameplay.
6. Compare each screenshot against `Source Scene Contract`, not just against generic RPG style.

## Acceptance

- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-rpg-first-act`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-menu-flow`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --quit-after 120 -- --smoke-render-frame`
- Manual playtest:
  - Start a new game from title.
  - Walk to the vending machine and inspect it.
  - Enter the building and inspect the voice lamp.
  - Enter home and inspect the door lock.
  - Enter living room and inspect the cold dinner.
  - Open pause and settings once.

## Screenshot Review Gate

A sprint is not accepted until screenshots prove:

- the first playable screen reads as modern night street;
- the vending machine, phone, TV, mailbox, open door, lamp, and dark window do not use fantasy/dungeon semantics;
- the bottom dialogue window supports RPG play but does not erase the modern scene;
- the title screen hides gameplay HUD;
- pause/settings keep the scene visible enough to preserve context;
- at least one screenshot shows the quiet abnormality, not only a functional tile map.

## Affected Files

- `data/visual_scenes/00-prologue-lights-out.json`
- `scripts/ui/sprite_scene_canvas.gd`
- `scripts/ui/game_hud.gd`
- `scripts/ui/prompt_overlay.gd`
- `scripts/ui/game_theme.gd`
- `scripts/ui/title_screen.gd`
- `scripts/ui/pause_menu.gd`
- `scripts/ui/settings_menu.gd`
- `docs/sprint-sheets/rpg-ui-style-pass.md`

## Non-Goals

- 不重写剧情、旗标、存档或输入系统。
- 不把整个游戏改成现代 UI；RPG 操作语言仍然保留。
- 不在本 sprint 处理墨颀古代章节的视觉体系。
- 不做完整角色立绘、头像对话或战斗 UI。
- 不用“更复古”替代“更贴合 scene”。
