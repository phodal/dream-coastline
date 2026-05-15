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
