# Dream Coastline

将遇到的问题，更新到这里，用一两句话，避免下次犯错。

- Sprint Sheet 如果只有叙事/愿景描述，AI 很难直接执行；需要补成“目标、输入、输出、验收、涉及文件、非目标”的任务契约。
- godot-rust 的集合与字符串参数常区分 ByRef/ByValue；写 `Dictionary`/`Json` 逻辑时，最好显式标注 `VarDictionary` 并传引用，能少踩很多编译坑。
- UI 的 render smoke 只能证明画面不空，不能证明风格像 RPG；涉及视觉风格时，Sprint Sheet 要写清楚屏幕区域、状态、截图验收和非目标。
- 视觉 Sprint Sheet 不能只写“像 RPG”；必须把 scene 的时代、情绪、物件语义和“不能读成什么”写成验收，否则会出现 UI 对但 scene 错的实现。
- 要基于 scene 借助 AI 生成 Sprint Sheet 时，先用 `tools/build_sprint_sheet_prompt.py <scene-id>` 打包 scene、story JSON、visual JSON、美术方向和架构模板，再审查输出是否有 Source Scene Contract 和 Screenshot Review Gate。
- AI 可以读懂 scene 和 playable JSON，但直接生成 Sprint Sheet 仍容易跳步；先用 `--mode map` 生成 `scene_sprint_map`，审查后再用 `--mode sheet-from-map` 转成 Sheet，能把证据、地点、物件风险和截图验收固定下来。
- 未来写 UI 时不要只给 Sprint Sheet；用 `--mode ui-brief-from-map` 把映射转换成 UI brief，明确 `GameHud`、`SpriteSceneCanvas`、`PromptOverlay`、数据 hook、prop renderer 和截图状态。
- 当前主流程使用 `RustGameSession` / `RustRpgPlayerController`；改交互或存档状态时要同步 Rust 与 GDScript 参考实现，否则窗口验证不会反映 GDScript 修复。
- 半自动实现前先跑 `tools/validate_scene_ai_contract.py` 校验 map/brief，再用 `--mode implementation-from-brief` 生成实现提示，最后用 `--mode screenshot-review-from-map` 按截图审查语义是否跑偏。
- 改 background 时只画 canvas backdrop 不够，因为满屏 tile 会盖住它；需要同步改 terrain tile / overlay，否则截图仍会像重复素材铺底。
- 现代楼体不能只画方块外壳；要有楼层线、窗格、邻居窗光和关键黑窗/灯具对比，否则“大楼”“灯未亮”都读不出来。
- 做视觉对比不要依赖 macOS 窗口截图；优先跑 `python3 tools/capture_scene_screenshots.py`，用 Godot viewport 直接生成 PNG、manifest 和 contact sheet。
- 角色动画不要再写死在 `SpriteSceneCanvas`；新角色包先落到 `data/visual_assets/characters.json` 和 `data/animation_clips/*.json`，再用 Animation Sheet Contract 和 `--smoke-animation-clips` 验证状态。
- AI 视觉/动画任务必须先落到 `VIS/PROP/ANIM/HUD/SHOT-*` 稳定 ID 和 Sprint Trace Map；实现或生成资产时一次只处理一个 ID。
- visual JSON 的 `kind` 不一定会走旧的 item renderer；新增现代物件时要在 `_draw_visual_prop()` 显式路由，否则售货机、电视、信箱会退回成泛用方块。
- 交互提示不要画成编辑器选框；用物件本身的光、闪点、影子或环境对比表达焦点，否则截图会像调试视图而不是游戏。
- 场景视觉不要长期靠 `draw_rect` / `draw_line` 修补；读感不对时应切到资产化 TileMap 管线，并让截图 manifest 标出 asset/fallback 状态。
- 外部 spritesheet 即使文件名写 transparent，也可能带洋红导线或占位网格；导入前要看图并归一化成项目 tilesheet，不能直接拷贝原图格子。
- 占位地面不要在 tile 内画强十字线或边界线；一旦铺满 15x9 就会读成棋盘格，应改用低对比噪点、场景陈设和大块构图来破重复。
- Rust GDExtension 的存档 payload 如果要从 Godot 再回传 Rust，数组优先用 `VarArray` 装 `Variant`；typed `Array<GString>` 可能导致 `dict_value_as_array()` 读不到 flags。
- 改生成 tilesheet 后要跑一次 Godot editor import 再截图；否则运行时可能还读旧 `.godot/imported` 缓存，截图会误判为生成器没生效。
- 剧本时长 gate 不能长期都写 `min_minutes: 5.0`；它只会证明 smoke 够跑，不会暴露“七幕梗概感”，需要按每幕目标调高并补失败、停顿、证据和角色转折。
- 批量重生成 `scenes/visual_locations` 会重写 Godot `unique_id`；提交前先过滤只含 `unique_id` 的 `.tscn` 噪声，只保留 `tile_map_data` 等真实视觉变更。
- UI 主题不能只改 `COLORS`；如果 NinePatch 贴图本身带强色相，暗色主题仍会被贴图染色，截图验收前要确认面板贴图/StyleBox 跟随当前风格。
- 标题/暂停/设置不要做成脱离游戏世界的纯功能弹窗；优先让 `SpriteSceneCanvas` 作为背景，再加 menu backdrop 和像素面板保持场景氛围。
- 整体连贯性 review 要查“首次登场/已被打败”这种跨幕矛盾，也要查选择是否只在 canonical walkthrough 里可通关；必要时用共同 flag 防止非 canonical 选择死路。
- 改剧情分支或跨幕前史后跑 `python3 tools/validate_story_continuity.py --verbose`；普通 smoke 不会发现“选择有文本但没后果”或“上一幕结尾没继承”。
- 改跨幕分支 carryover 时要同步 `scripts/core/game_session.gd` 和 `src/game_session.rs`，并跑 `--smoke-rpg-progression`；否则 Godot 当前 Rust 主流程不会体现 GDScript 参考修复。
- 改剧情连续性或 flag 命名后要同步 scene RPG smoke 和 `data/visual_scenes` 交互点；否则 headless gate 会停在旧 flag 或旧视觉标签上。
- 补角色 payoff 的 inspect 节点后，不能只更新 walkthrough；关键 build/ending 要要求对应 flag，`data/visual_scenes` 也要有可交互点，否则键盘 RPG 仍能跳过情感转折。
- 试玩输入问题不能只靠 `_unhandled_input`；隐藏菜单焦点可能吞掉真实窗口按键，gameplay 键要走 `_input` 并在退出菜单时释放 focus，再用 menu smoke 模拟移动验证。
- Computer Use 看到 Godot 窗口不代表键鼠已经送进游戏；如果点击只出现 hover、按键无效，先显式激活 Godot，再复测标题页进入、移动、交互和暂停恢复。
- 菜单按钮如果同时支持 Godot GUI 焦点和根节点兜底输入，`focus_entered` 要同步 selected index，并给 Enter/Space 加原始 keycode 兜底；否则保存后返回标题可能选中了“继续”却无法触发读取。
