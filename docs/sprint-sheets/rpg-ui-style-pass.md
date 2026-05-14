# Sprint Sheet: RPG UI Style Pass

## Diagnosis

当前画面不是渲染失败，而是风格契约不够硬。`--smoke-render-frame` 已经能证明画面非空，但它只检查颜色和像素变化，不能判断 UI 是否像 RPG。

主要问题：

- `scripts/ui/game_theme.gd` 只有通用深色面板、圆角边框、普通按钮，缺少 RPG 常见的像素边框、内外描边、命令框、对话框和纸墨纹理约束。
- `scripts/ui/game_hud.gd` 的 Top Bar 像应用仪表盘，Prompt Overlay 固定浮在左上角，标题/暂停/设置都是居中的通用卡片，和 90s RPG 的底部对话窗、右侧/中部命令窗不一致。
- `scripts/ui/sprite_scene_canvas.gd` 已经有 tile map、角色和道具，但 HUD 没有给玩家明确的 RPG 阅读顺序：先看地图，再看底部文本，再选命令。
- 现有验收只要求 Godot 能跑、画面不空，没有要求“玩家一眼能识别为 RPG UI”。

## Goal

把当前通用 Godot HUD 改成 90s 剧情 RPG 风格：全屏 tile 场景优先，底部对话/提示窗承载交互文本，标题、暂停、设置使用 RPG 命令菜单语言。

## Player Loop

1. 玩家在 tile map 中移动。
2. 玩家面向可交互物时，底部对话窗显示地点、操作名和最近反馈。
3. 玩家按 Space/Enter 执行动作。
4. 成功、阻挡、章节完成都在同一套 RPG 文本窗口中反馈。
5. 玩家按 Esc 时，暂停命令窗覆盖在画面上，但仍能看出背后是 RPG 地图。

## Inputs

- 风格方向：`five/system/art-audio-direction.md`。
- 架构契约：`docs/sprint-sheet-architecture.md`。
- 主题代码：`scripts/ui/game_theme.gd`。
- HUD 布局：`scripts/ui/game_hud.gd`。
- 提示窗：`scripts/ui/prompt_overlay.gd`。
- 标题、暂停、设置菜单：`scripts/ui/title_screen.gd`、`scripts/ui/pause_menu.gd`、`scripts/ui/settings_menu.gd`。
- 场景画布：`scripts/ui/sprite_scene_canvas.gd`。
- 视觉数据：`data/visual_scenes/*.json`。
- 可用资产：OpenGameArt dungeon crawl atlas、castle tileset、RPG character atlas、paper icon、spell effects。
- 约束：保留现有键盘、手柄、save/load、smoke test 行为；不引入未提交的外部字体或远程资源。

## Outputs

- RPG 专用主题 primitive：像素风面板、底部对话窗、命令按钮、焦点态、禁用态、提示态。
- 新 HUD 布局：地图全屏，顶部状态降噪，交互提示移动到底部 RPG 对话窗。
- 标题/暂停/设置菜单改成命令窗口，不再像通用应用卡片。
- 视觉验收清单，明确什么样的截图才算 RPG 风格达标。

## UI Contract

### Screen Regions

- Scene Canvas：全屏优先，继续使用 15x9 tile map、玩家、道具、出口、阻挡反馈。
- Top Status：只显示章节序号、标题、时长；高度更低，像 RPG 状态条或角标，不做整条应用导航栏。
- Dialogue Prompt：底部主 UI，占屏幕高度约 18% 到 24%，用双层边框或像素描边；第一行显示地点和可执行操作，第二行显示最近反馈。
- Command Menu：标题、暂停、设置均使用 RPG 命令框；垂直选项、清晰焦点、禁用项可读。
- Completion Feedback：章节完成时保留 portal/magic effect，同时对话窗文本明确反馈变化。

### States

- Empty/default：底部对话窗显示移动帮助，不遮住玩家所在 tile。
- Interactable nearby：底部对话窗显示 `Space/Enter 调查：<item>`、`Space/Enter 进入：<exit>` 或对应动作。
- Action succeeded：最近反馈进入对话窗第二行，地图状态同步更新。
- Action blocked：被阻挡 tile 有短暂高亮，对话窗显示稳定的阻挡反馈，不弹出新卡片。
- Chapter complete：地图出现魔法/传送效果，对话窗说明下一步。
- Title visible：标题是 RPG 标题菜单，不是设置页卡片；菜单选项像命令列表。
- Pause/settings visible：菜单覆盖时保留背景地图可见，焦点态明显，Esc/手柄返回路径不变。

## Data Contract

- Story JSON changes：本 sprint 不改剧情字段。
- Visual JSON changes：只有发现 UI 遮挡关键 tile 或 hotspot 时才允许微调 spawn/prop。
- Runtime state changes：不新增进度状态，只消费 `GameSession`、`RpgPlayerController` 已有状态。
- UI data sources：
  - `session.scene_index`、`session.scene_count()`、`session.scene.title` 驱动 Top Status。
  - `session.current_location().name` 驱动地点文本。
  - `player_controller.prompt_text()` 驱动当前操作。
  - `session.visible_log(1)` 驱动最近反馈。

## Implementation Tasks

1. 在 `scripts/ui/game_theme.gd` 增加 RPG theme API：
   - `make_rpg_panel`
   - `make_dialogue_panel`
   - `make_command_button`
   - 统一色板：ink、paper、gold、border_light、border_shadow、danger。
2. 修改 `scripts/ui/prompt_overlay.gd`：
   - 从左上浮层改成底部对话窗内容组件。
   - 保留地点、prompt、feedback 三段信息，但降低字号层级，避免抢地图。
3. 修改 `scripts/ui/game_hud.gd`：
   - Top Bar 降低高度和视觉重量。
   - Prompt Overlay 锚定到底部宽屏区域。
   - 菜单打开时保留场景画布可见。
4. 修改 `scripts/ui/title_screen.gd`、`scripts/ui/pause_menu.gd`、`scripts/ui/settings_menu.gd`：
   - 使用命令窗口样式。
   - 按钮改成 RPG 选项行，焦点态用边框/底色/箭头提示。
5. 如有必要，微调 `scripts/ui/sprite_scene_canvas.gd`：
   - 确保底部对话窗不会遮住 spawn 和关键交互点。
   - 阻挡反馈、传送效果和角色 marker 与新 UI 色板协调。

## Acceptance

- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-headless.log -- --smoke-menu-flow`
- `/Applications/Godot.app/Contents/MacOS/Godot --path . --quit-after 120 -- --smoke-render-frame`
- Manual visual review:
  - 新游戏第一屏必须先读到 tile RPG 场景，而不是应用式仪表盘。
  - 底部必须有 RPG 对话/提示窗，当前可执行操作不再浮在左上角。
  - 标题、暂停、设置菜单必须像 RPG command window，而不是普通 app card。
  - 按钮焦点和禁用态在键盘/手柄操作下清晰可见。
  - 截图中不能主要由 slate/cyan web-app 质感主导；应读成 ink、paper、gold、pixel border 的剧情 RPG。
  - 不允许出现 UI 文本挤压、遮挡关键角色、遮挡当前交互目标。

## Affected Files

- `scripts/ui/game_theme.gd`
- `scripts/ui/game_hud.gd`
- `scripts/ui/prompt_overlay.gd`
- `scripts/ui/title_screen.gd`
- `scripts/ui/pause_menu.gd`
- `scripts/ui/settings_menu.gd`
- `scripts/ui/sprite_scene_canvas.gd`
- `README.md` only if validation instructions change.

## Non-Goals

- 不重写剧情、旗标、存档或输入系统。
- 不新增人物立绘、头像对话系统或完整战斗 UI。
- 不替换整个 tileset。
- 不做字体授权或远程资源接入。
- 不处理 01-07 章的地图美术细节，只保证全局 UI 风格能覆盖它们。
