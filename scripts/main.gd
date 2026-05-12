extends Node2D

const SceneDatabaseScript := preload("res://scripts/core/scene_database.gd")
const SceneVisualRepositoryScript := preload("res://scripts/core/scene_visual_repository.gd")
const GameSessionScript := preload("res://scripts/core/game_session.gd")
const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const SpriteSceneCanvasScript := preload("res://scripts/ui/sprite_scene_canvas.gd")

const TILE_COLUMNS := 15
const TILE_ROWS := 9

var database
var visual_repository
var session
var root: Control
var title_label: Label
var time_label: Label
var location_label: Label
var scene_canvas
var prompt_label: Label
var log_label: RichTextLabel
var player_tile := Vector2i(7, 6)
var facing := Vector2i(0, -1)


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
	_load_scene(0)


func _process(_delta: float) -> void:
	if root != null:
		root.size = get_viewport_rect().size


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), GameThemeScript.COLORS.background)


func _build_ui() -> void:
	root = Control.new()
	root.name = "GodotRpgScene"
	root.position = Vector2.ZERO
	root.size = get_viewport_rect().size
	add_child(root)

	scene_canvas = SpriteSceneCanvasScript.new()
	scene_canvas.name = "SpriteSceneCanvas"
	scene_canvas.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	scene_canvas.offset_left = 0
	scene_canvas.offset_top = 0
	scene_canvas.offset_right = 0
	scene_canvas.offset_bottom = 0
	scene_canvas.set_visual_repository(visual_repository)
	root.add_child(scene_canvas)

	root.add_child(_build_top_bar())
	root.add_child(_build_status_overlay())


func _build_top_bar() -> Control:
	var panel := GameThemeScript.make_panel("TopBar", GameThemeScript.COLORS.panel_alt)
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE, false)
	panel.offset_left = 16
	panel.offset_top = 14
	panel.offset_right = -16
	panel.offset_bottom = 62
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	title_label = GameThemeScript.make_label("SceneTitle", 24, GameThemeScript.COLORS.text)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)

	time_label = GameThemeScript.make_label("SceneTime", 18, GameThemeScript.COLORS.cyan)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.custom_minimum_size = Vector2(180, 34)
	row.add_child(time_label)
	return panel


func _build_status_overlay() -> Control:
	var panel := GameThemeScript.make_panel("StatusOverlay", Color("#080a12", 0.76))
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE, false)
	panel.offset_left = 16
	panel.offset_top = -120
	panel.offset_right = -16
	panel.offset_bottom = -14

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)

	location_label = GameThemeScript.make_label("Location", 22, GameThemeScript.COLORS.gold)
	left.add_child(location_label)

	prompt_label = GameThemeScript.make_label("Prompt", 17, GameThemeScript.COLORS.text)
	prompt_label.custom_minimum_size = Vector2(0, 44)
	left.add_child(prompt_label)

	log_label = RichTextLabel.new()
	log_label.name = "CompactLog"
	log_label.custom_minimum_size = Vector2(480, 88)
	log_label.fit_content = false
	log_label.scroll_active = false
	log_label.bbcode_enabled = false
	log_label.add_theme_font_size_override("normal_font_size", 16)
	log_label.add_theme_color_override("default_color", GameThemeScript.COLORS.text)
	row.add_child(log_label)
	return panel


func _load_scene(index: int) -> void:
	session.load_scene(index)
	_reset_player_for_location()
	_refresh_ui()


func _refresh_ui() -> void:
	if title_label == null:
		return

	var location: Dictionary = session.current_location()
	title_label.text = "%s/%s  %s" % [session.scene_index + 1, session.scene_count(), session.scene.get("title", "")]
	time_label.text = "时长 %s" % session.format_time()

	location_label.text = str(location.get("name", session.location_id))
	scene_canvas.refresh(session)
	scene_canvas.set_player_tile(player_tile)
	prompt_label.text = _prompt_text()
	log_label.text = session.visible_log(4)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_try_move(Vector2i(0, -1))
	elif event.is_action_pressed("move_down"):
		_try_move(Vector2i(0, 1))
	elif event.is_action_pressed("move_left"):
		_try_move(Vector2i(-1, 0))
	elif event.is_action_pressed("move_right"):
		_try_move(Vector2i(1, 0))
	elif event.is_action_pressed("ui_accept"):
		_interact()


func _try_move(direction: Vector2i) -> void:
	facing = direction
	var target := player_tile + direction
	if visual_repository.is_blocked(session.scene_id, session.location_id, target):
		_refresh_ui()
		return
	player_tile = target
	_refresh_ui()


func _interact() -> void:
	var target := player_tile + facing
	var interaction: Dictionary = visual_repository.interaction_at(session.scene_id, session.location_id, target)
	if interaction.is_empty():
		interaction = visual_repository.interaction_at(session.scene_id, session.location_id, player_tile)
	if interaction.is_empty():
		session.event_log.append("这里没有可以互动的东西。")
		_refresh_ui()
		return

	if interaction.has("exit"):
		session.apply_action({"verb": "go", "arg": str(interaction["exit"])})
		_reset_player_for_location()
	elif interaction.has("item"):
		session.apply_action({"verb": "inspect", "arg": str(interaction["item"])})
	_refresh_ui()


func _reset_player_for_location() -> void:
	player_tile = visual_repository.spawn_for(session.scene_id, session.location_id)
	facing = Vector2i(0, -1)


func _prompt_text() -> String:
	var target := player_tile + facing
	var interaction: Dictionary = visual_repository.interaction_at(session.scene_id, session.location_id, target)
	if interaction.is_empty():
		interaction = visual_repository.interaction_at(session.scene_id, session.location_id, player_tile)
	if interaction.has("exit"):
		var exit_id := str(interaction["exit"])
		var exits: Dictionary = session.current_location().get("exits", {})
		return "Space/Enter 进入：%s" % exits.get(exit_id, exit_id)
	if interaction.has("item"):
		var item_id := str(interaction["item"])
		var items: Dictionary = session.current_location().get("items", {})
		return "Space/Enter 调查：%s" % items.get(item_id, {}).get("name", item_id)
	return "WASD/方向键移动，Space/Enter 互动"
