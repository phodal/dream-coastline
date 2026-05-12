extends Node2D

const SceneDatabaseScript := preload("res://scripts/core/scene_database.gd")
const SceneVisualRepositoryScript := preload("res://scripts/core/scene_visual_repository.gd")
const GameSessionScript := preload("res://scripts/core/game_session.gd")
const RpgPlayerControllerScript := preload("res://scripts/core/rpg_player_controller.gd")
const RpgFirstActSmokeScript := preload("res://scripts/core/rpg_first_act_smoke.gd")
const RpgIlliterateSmokeScript := preload("res://scripts/core/rpg_illiterate_smoke.gd")
const RpgMoqiAcademySmokeScript := preload("res://scripts/core/rpg_moqi_academy_smoke.gd")
const RpgDeadKingdomSmokeScript := preload("res://scripts/core/rpg_dead_kingdom_smoke.gd")
const RpgContinuationInstituteSmokeScript := preload("res://scripts/core/rpg_continuation_institute_smoke.gd")
const RpgCenturyContinuationSmokeScript := preload("res://scripts/core/rpg_century_continuation_smoke.gd")
const RpgReturnStarPlanSmokeScript := preload("res://scripts/core/rpg_return_star_plan_smoke.gd")
const SaveGameRepositoryScript := preload("res://scripts/core/save_game_repository.gd")
const SaveLoadSmokeScript := preload("res://scripts/core/save_load_smoke.gd")
const SettingsRepositoryScript := preload("res://scripts/core/settings_repository.gd")
const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const SpriteSceneCanvasScript := preload("res://scripts/ui/sprite_scene_canvas.gd")
const DialogueOverlayScript := preload("res://scripts/ui/dialogue_overlay.gd")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const TitleScreenScript := preload("res://scripts/ui/title_screen.gd")
const SettingsMenuScript := preload("res://scripts/ui/settings_menu.gd")

var database
var visual_repository
var save_repository
var settings_repository
var session
var player_controller
var root: Control
var title_label: Label
var time_label: Label
var scene_canvas
var dialogue_overlay
var pause_menu
var title_screen
var settings_menu
var game_started := false


func _ready() -> void:
	database = SceneDatabaseScript.new()
	database.load_all()
	visual_repository = SceneVisualRepositoryScript.new()
	visual_repository.load_for_scene_ids(database.SCENE_IDS)
	save_repository = SaveGameRepositoryScript.new()
	settings_repository = SettingsRepositoryScript.new()
	settings_repository.load()
	settings_repository.apply()
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
	if OS.get_cmdline_user_args().has("--smoke-rpg-illiterate"):
		var ok: bool = RpgIlliterateSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-moqi-academy"):
		var ok: bool = RpgMoqiAcademySmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-dead-kingdom"):
		var ok: bool = RpgDeadKingdomSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-continuation-institute"):
		var ok: bool = RpgContinuationInstituteSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-century-continuation"):
		var ok: bool = RpgCenturyContinuationSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-return-star-plan"):
		var ok: bool = RpgReturnStarPlanSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-save-load"):
		var ok: bool = SaveLoadSmokeScript.new(session, player_controller, save_repository).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-menu-flow"):
		_build_ui()
		_load_scene(0)
		var ok := _run_menu_smoke()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-render-frame"):
		_build_ui()
		_start_new_game()
		call_deferred("_finish_render_smoke")
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
	root.add_child(_build_title_screen())
	root.add_child(_build_settings_menu())


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


func _build_title_screen() -> Control:
	title_screen = TitleScreenScript.new()
	title_screen.name = "TitleScreen"
	title_screen.set_anchors_preset(Control.PRESET_CENTER, false)
	title_screen.custom_minimum_size = Vector2(360, 330)
	title_screen.offset_left = -180
	title_screen.offset_top = -180
	title_screen.offset_right = 180
	title_screen.offset_bottom = 180
	title_screen.new_game_requested.connect(_start_new_game)
	title_screen.continue_requested.connect(_continue_from_title)
	title_screen.settings_requested.connect(_open_settings)
	title_screen.quit_requested.connect(func(): get_tree().quit())
	title_screen.set_continue_enabled(save_repository.has_save())
	return title_screen


func _build_settings_menu() -> Control:
	settings_menu = SettingsMenuScript.new()
	settings_menu.name = "SettingsMenu"
	settings_menu.visible = false
	settings_menu.set_anchors_preset(Control.PRESET_CENTER, false)
	settings_menu.custom_minimum_size = Vector2(340, 180)
	settings_menu.offset_left = -170
	settings_menu.offset_top = -100
	settings_menu.offset_right = 170
	settings_menu.offset_bottom = 100
	settings_menu.fullscreen_changed.connect(_set_fullscreen)
	settings_menu.back_requested.connect(_close_settings)
	return settings_menu


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
	if settings_menu != null and settings_menu.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_settings()
		return
	if title_screen != null and title_screen.visible:
		return
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
	if pause_menu == null or not game_started:
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
		game_started = true
		pause_menu.visible = false
		_refresh_ui()
	else:
		pause_menu.set_status("没有可读取的存档")


func _start_new_game() -> void:
	game_started = true
	title_screen.visible = false
	_load_scene(0)


func _continue_from_title() -> void:
	var ok: bool = save_repository.load_into(session, player_controller)
	if ok:
		game_started = true
		title_screen.visible = false
		_refresh_ui()
	else:
		title_screen.set_status("没有可读取的存档")


func _open_settings() -> void:
	title_screen.visible = false
	settings_menu.visible = true
	settings_menu.set_fullscreen(settings_repository.fullscreen)


func _close_settings() -> void:
	settings_menu.visible = false
	if not game_started:
		title_screen.visible = true


func _set_fullscreen(enabled: bool) -> void:
	settings_repository.fullscreen = enabled
	settings_repository.apply()
	settings_repository.save()


func _run_menu_smoke() -> bool:
	var failures: Array[String] = []
	if not title_screen.visible:
		failures.append("title screen should be visible at boot")
	if game_started:
		failures.append("game should not be marked started at boot")

	_start_new_game()
	if title_screen.visible:
		failures.append("title screen should hide after new game")
	if not game_started:
		failures.append("new game should mark game started")

	_toggle_pause()
	if not pause_menu.visible:
		failures.append("pause should open after ESC")
	_resume_game()
	if pause_menu.visible:
		failures.append("pause should close on resume")

	_open_settings()
	if not settings_menu.visible:
		failures.append("settings should open")
	_close_settings()
	if settings_menu.visible:
		failures.append("settings should close")
	if title_screen.visible:
		failures.append("title should not return when settings closes during game")

	var ok := failures.is_empty()
	print("menu-flow-smoke status=%s title=%s pause=%s settings=%s" % [
		"PASS" if ok else "FAIL",
		title_screen.visible,
		pause_menu.visible,
		settings_menu.visible,
	])
	for failure in failures:
		print("failure=", failure)
	return ok


func _finish_render_smoke() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var image: Image = get_viewport().get_texture().get_image()
	var ok: bool = _verify_render_image(image)
	get_tree().quit(0 if ok else 1)


func _verify_render_image(image: Image) -> bool:
	if image == null:
		print("render-frame-smoke status=FAIL reason=no-image")
		return false

	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		print("render-frame-smoke status=FAIL reason=empty-image size=%sx%s" % [width, height])
		return false

	var step_x: int = int(ceil(float(width) / 48.0))
	var step_y: int = int(ceil(float(height) / 36.0))
	if step_x < 1:
		step_x = 1
	if step_y < 1:
		step_y = 1

	var sampled_count := 0
	var non_dark_count := 0
	var color_keys := {}
	for y in range(0, height, step_y):
		for x in range(0, width, step_x):
			var color: Color = image.get_pixel(x, y)
			sampled_count += 1
			if color.r > 0.08 or color.g > 0.08 or color.b > 0.08:
				non_dark_count += 1
			var key := "%02x%02x%02x" % [
				int(color.r * 255.0) / 32,
				int(color.g * 255.0) / 32,
				int(color.b * 255.0) / 32,
			]
			color_keys[key] = true

	var distinct_count: int = color_keys.size()
	var ok := sampled_count > 0 and non_dark_count >= 16 and distinct_count >= 6
	print("render-frame-smoke status=%s size=%sx%s sampled=%s non_dark=%s distinct=%s" % [
		"PASS" if ok else "FAIL",
		width,
		height,
		sampled_count,
		non_dark_count,
		distinct_count,
	])
	return ok
