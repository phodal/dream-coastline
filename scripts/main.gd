extends Node2D

const SceneDatabaseScript := preload("res://scripts/core/scene_database.gd")
const SceneVisualRepositoryScript := preload("res://scripts/core/scene_visual_repository.gd")
const GameSessionScript := preload("res://scripts/core/game_session.gd")
const RpgPlayerControllerScript := preload("res://scripts/core/rpg_player_controller.gd")
const RpgFirstActSmokeScript := preload("res://scripts/core/rpg_first_act_smoke.gd")
const SaveGameRepositoryScript := preload("res://scripts/core/save_game_repository.gd")
const SaveLoadSmokeScript := preload("res://scripts/core/save_load_smoke.gd")
const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const SpriteSceneCanvasScript := preload("res://scripts/ui/sprite_scene_canvas.gd")
const DialogueOverlayScript := preload("res://scripts/ui/dialogue_overlay.gd")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")

var database
var visual_repository
var save_repository
var session
var player_controller
var root: Control
var title_label: Label
var time_label: Label
var scene_canvas
var dialogue_overlay
var pause_menu


func _ready() -> void:
	database = SceneDatabaseScript.new()
	database.load_all()
	visual_repository = SceneVisualRepositoryScript.new()
	visual_repository.load_for_scene_ids(database.SCENE_IDS)
	save_repository = SaveGameRepositoryScript.new()
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
	if OS.get_cmdline_user_args().has("--smoke-save-load"):
		var ok: bool = SaveLoadSmokeScript.new(session, player_controller, save_repository).run()
		get_tree().quit(0 if ok else 1)
		return

	_build_ui()
	_load_scene(0)


func _process(delta: float) -> void:
	if root != null:
		root.size = get_viewport_rect().size
	if player_controller != null and player_controller.update(delta):
		_refresh_ui()


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
	root.add_child(_build_pause_menu())


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


func _build_pause_menu() -> Control:
	pause_menu = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false
	pause_menu.set_anchors_preset(Control.PRESET_CENTER, false)
	pause_menu.custom_minimum_size = Vector2(340, 280)
	pause_menu.offset_left = -170
	pause_menu.offset_top = -150
	pause_menu.offset_right = 170
	pause_menu.offset_bottom = 150
	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.save_requested.connect(_save_game)
	pause_menu.load_requested.connect(_load_game)
	pause_menu.quit_requested.connect(func(): get_tree().quit())
	return pause_menu


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
	scene_canvas.set_player_motion(
		player_controller.visual_tile(),
		player_controller.is_moving,
		player_controller.facing,
		player_controller.blocked_tile,
		player_controller.has_blocked_feedback()
	)
	dialogue_overlay.refresh(
		str(location.get("name", session.location_id)),
		player_controller.prompt_text(),
		session.visible_log(4)
	)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		return
	if pause_menu != null and pause_menu.visible:
		return
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


func _toggle_pause() -> void:
	if pause_menu == null:
		return
	pause_menu.visible = not pause_menu.visible
	if pause_menu.visible:
		pause_menu.set_status("ESC 返回游戏")


func _resume_game() -> void:
	pause_menu.visible = false


func _save_game() -> void:
	var ok: bool = save_repository.save(session, player_controller)
	pause_menu.set_status("已保存" if ok else "保存失败")


func _load_game() -> void:
	var ok: bool = save_repository.load_into(session, player_controller)
	if ok:
		pause_menu.visible = false
		_refresh_ui()
	else:
		pause_menu.set_status("没有可读取的存档")
