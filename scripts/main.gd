extends Node2D

const DeepSeekClientScript := preload("res://scripts/deepseek_client.gd")
const SceneDatabaseScript := preload("res://scripts/core/scene_database.gd")
const SceneVisualRepositoryScript := preload("res://scripts/core/scene_visual_repository.gd")
const GameSessionScript := preload("res://scripts/core/game_session.gd")
const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const SpriteSceneCanvasScript := preload("res://scripts/ui/sprite_scene_canvas.gd")
const StoryHudScript := preload("res://scripts/ui/story_hud.gd")
const ActionPanelScript := preload("res://scripts/ui/action_panel.gd")

var database
var visual_repository
var session
var root: Control
var title_label: Label
var time_label: Label
var location_label: Label
var scene_canvas
var story_hud
var action_panel
var prev_button: Button
var next_button: Button
var reset_button: Button
var ai_button: Button
var deepseek_client: Node


func _ready() -> void:
	database = SceneDatabaseScript.new()
	database.load_all()
	visual_repository = SceneVisualRepositoryScript.new()
	visual_repository.load_for_scene_ids(database.SCENE_IDS)
	session = GameSessionScript.new(database)
	if OS.get_cmdline_user_args().has("--smoke-autoplay"):
		var ok: bool = session.run_smoke_verification()
		get_tree().quit(0 if ok else 1)
		return

	_build_ui()
	_setup_deepseek()
	_load_scene(0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), GameThemeScript.COLORS.background)


func _build_ui() -> void:
	root = Control.new()
	root.name = "GodotPlayableSceneUI"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 8)
	outer.offset_left = 16
	outer.offset_top = 14
	outer.offset_right = -16
	outer.offset_bottom = -14
	root.add_child(outer)

	outer.add_child(_build_top_bar())

	var main_row := HBoxContainer.new()
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 10)
	outer.add_child(main_row)

	main_row.add_child(_build_scene_panel())
	main_row.add_child(_build_info_panel())
	outer.add_child(_build_action_panel())


func _build_top_bar() -> Control:
	var panel := GameThemeScript.make_panel("TopBar", GameThemeScript.COLORS.panel_alt)
	panel.custom_minimum_size = Vector2(0, 54)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	prev_button = GameThemeScript.make_button("<", "上一幕")
	prev_button.custom_minimum_size = Vector2(54, 38)
	prev_button.pressed.connect(func(): _load_scene(max(session.scene_index - 1, 0)))
	row.add_child(prev_button)

	next_button = GameThemeScript.make_button(">", "下一幕")
	next_button.custom_minimum_size = Vector2(54, 38)
	next_button.pressed.connect(func(): _load_scene(min(session.scene_index + 1, session.scene_count() - 1)))
	row.add_child(next_button)

	title_label = GameThemeScript.make_label("SceneTitle", 24, GameThemeScript.COLORS.text)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)

	time_label = GameThemeScript.make_label("SceneTime", 18, GameThemeScript.COLORS.cyan)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.custom_minimum_size = Vector2(180, 34)
	row.add_child(time_label)

	reset_button = GameThemeScript.make_button("Reset", "重置本幕")
	reset_button.custom_minimum_size = Vector2(110, 38)
	reset_button.pressed.connect(func(): _load_scene(session.scene_index))
	row.add_child(reset_button)

	ai_button = GameThemeScript.make_button("AI", "AI 解读")
	ai_button.custom_minimum_size = Vector2(112, 38)
	ai_button.pressed.connect(_request_ai_scene_notes)
	row.add_child(ai_button)
	return panel


func _build_scene_panel() -> Control:
	var panel := GameThemeScript.make_panel("ScenePanel", GameThemeScript.COLORS.panel)
	panel.custom_minimum_size = Vector2(610, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	location_label = GameThemeScript.make_label("Location", 22, GameThemeScript.COLORS.gold)
	box.add_child(location_label)

	scene_canvas = SpriteSceneCanvasScript.new()
	scene_canvas.name = "SpriteSceneCanvas"
	scene_canvas.set_visual_repository(visual_repository)
	box.add_child(scene_canvas)
	return panel


func _build_info_panel() -> Control:
	var panel := GameThemeScript.make_panel("InfoPanel", GameThemeScript.COLORS.panel)
	panel.custom_minimum_size = Vector2(610, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	story_hud = StoryHudScript.new()
	story_hud.name = "StoryHud"
	story_hud.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(story_hud)
	return panel


func _build_action_panel() -> Control:
	var panel := GameThemeScript.make_panel("ActionPanel", GameThemeScript.COLORS.panel_alt)
	panel.custom_minimum_size = Vector2(0, 188)

	action_panel = ActionPanelScript.new()
	action_panel.name = "ActionPanelScroll"
	action_panel.action_requested.connect(_on_action_requested)
	panel.add_child(action_panel)
	return panel


func _load_scene(index: int) -> void:
	session.load_scene(index)
	_refresh_ui()


func _refresh_ui() -> void:
	if title_label == null:
		return

	var location: Dictionary = session.current_location()
	title_label.text = "%s/%s  %s" % [session.scene_index + 1, session.scene_count(), session.scene.get("title", "")]
	time_label.text = "时长 %s" % session.format_time()
	prev_button.disabled = session.scene_index <= 0
	next_button.disabled = session.scene_index >= session.scene_count() - 1
	if ai_button != null:
		ai_button.disabled = deepseek_client != null and deepseek_client.is_pending()

	location_label.text = str(location.get("name", session.location_id))
	scene_canvas.refresh(session)
	story_hud.refresh(session)
	action_panel.refresh(session)
	queue_redraw()


func _on_action_requested(action: Dictionary) -> void:
	session.apply_action(action)
	_refresh_ui()


func _setup_deepseek() -> void:
	deepseek_client = DeepSeekClientScript.new()
	deepseek_client.name = "DeepSeekClient"
	deepseek_client.completed.connect(_on_ai_completed)
	deepseek_client.failed.connect(_on_ai_failed)
	add_child(deepseek_client)


func _request_ai_scene_notes() -> void:
	if deepseek_client == null:
		session.event_log.append("AI 客户端尚未初始化。")
		_refresh_ui()
		return
	if not deepseek_client.is_configured():
		session.event_log.append("DeepSeek 未配置：设置 DEEPSEEK_API_KEY，或复制 deepseek.local.cfg.example 为 deepseek.local.cfg。")
		_refresh_ui()
		return

	session.event_log.append("正在请求 DeepSeek 解读本幕...")
	_refresh_ui()
	var recent_log: Array[String] = []
	for line in session.event_log.slice(max(0, session.event_log.size() - StoryHudScript.MAX_LOG_LINES), session.event_log.size()):
		recent_log.append(str(line))
	deepseek_client.request_scene_notes(session.scene, session.current_location(), recent_log, session.metrics)


func _on_ai_completed(text: String) -> void:
	session.event_log.append("AI 解读：%s" % text)
	_refresh_ui()


func _on_ai_failed(message: String) -> void:
	session.event_log.append("AI 请求失败：%s" % message)
	_refresh_ui()
