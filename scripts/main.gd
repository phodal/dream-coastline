extends Node2D

const SceneDatabaseScript := preload("res://scripts/core/scene_database.gd")
const SceneVisualRepositoryScript := preload("res://scripts/core/scene_visual_repository.gd")
const GameSessionScript := preload("res://scripts/core/game_session.gd")
const RpgPlayerControllerScript := preload("res://scripts/core/rpg_player_controller.gd")
const RpgFirstActSmokeScript := preload("res://scripts/core/rpg_first_act_smoke.gd")
const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const SpriteSceneCanvasScript := preload("res://scripts/ui/sprite_scene_canvas.gd")
const DialogueOverlayScript := preload("res://scripts/ui/dialogue_overlay.gd")

var database
var visual_repository
var session
var player_controller
var root: Control
var title_label: Label
var time_label: Label
var scene_canvas
var dialogue_overlay


func _ready() -> void:
	database = SceneDatabaseScript.new()
	database.load_all()
	visual_repository = SceneVisualRepositoryScript.new()
	visual_repository.load_for_scene_ids(database.SCENE_IDS)
	session = GameSessionScript.new(database)
	player_controller = RpgPlayerControllerScript.new(session, visual_repository)
	if OS.get_cmdline_user_args().has("--smoke-autoplay"):
		var ok: bool = session.run_smoke_verification()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-first-act"):
		var ok: bool = RpgFirstActSmokeScript.new(session, player_controller).run()
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
	dialogue_overlay = DialogueOverlayScript.new()
	dialogue_overlay.name = "DialogueOverlay"
	var panel: Control = dialogue_overlay
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE, false)
	panel.offset_left = 16
	panel.offset_top = -120
	panel.offset_right = -16
	panel.offset_bottom = -14
	return panel


func _load_scene(index: int) -> void:
	session.load_scene(index)
	player_controller.reset_for_location()
	_refresh_ui()


func _refresh_ui() -> void:
	if title_label == null:
		return

	var location: Dictionary = session.current_location()
	title_label.text = "%s/%s  %s" % [session.scene_index + 1, session.scene_count(), session.scene.get("title", "")]
	time_label.text = "时长 %s" % session.format_time()

	scene_canvas.refresh(session)
	scene_canvas.set_player_tile(player_controller.tile)
	dialogue_overlay.refresh(
		str(location.get("name", session.location_id)),
		player_controller.prompt_text(),
		session.visible_log(4)
	)
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
	player_controller.try_move(direction)
	_refresh_ui()


func _interact() -> void:
	player_controller.interact()
	_refresh_ui()
