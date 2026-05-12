class_name GameHud
extends Control

signal resume_requested
signal save_requested
signal load_requested
signal return_to_title_requested
signal new_game_requested
signal continue_requested
signal settings_requested
signal title_quit_requested
signal settings_back_requested
signal fullscreen_changed(enabled: bool)
signal master_volume_changed(value: float)

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const SpriteSceneCanvasScript := preload("res://scripts/ui/sprite_scene_canvas.gd")
const PromptOverlayScript := preload("res://scripts/ui/prompt_overlay.gd")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const TitleScreenScript := preload("res://scripts/ui/title_screen.gd")
const SettingsMenuScript := preload("res://scripts/ui/settings_menu.gd")

var visual_repository
var title_label: Label
var time_label: Label
var scene_canvas
var prompt_overlay
var pause_menu
var title_screen
var settings_menu
var pending_continue_enabled := false


func configure(repository, has_save: bool) -> void:
	visual_repository = repository
	pending_continue_enabled = has_save
	if scene_canvas != null:
		scene_canvas.set_visual_repository(visual_repository)
	if title_screen != null:
		title_screen.set_continue_enabled(has_save)


func _ready() -> void:
	name = "GodotRpgHud"
	position = Vector2.ZERO
	size = get_viewport_rect().size

	scene_canvas = SpriteSceneCanvasScript.new()
	scene_canvas.name = "SpriteSceneCanvas"
	scene_canvas.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	scene_canvas.offset_left = 0
	scene_canvas.offset_top = 0
	scene_canvas.offset_right = 0
	scene_canvas.offset_bottom = 0
	scene_canvas.set_visual_repository(visual_repository)
	add_child(scene_canvas)

	add_child(_build_top_bar())
	add_child(_build_prompt_overlay())
	add_child(_build_pause_menu())
	add_child(_build_title_screen())
	add_child(_build_settings_menu())
	call_deferred("focus_visible_menu")


func _process(_delta: float) -> void:
	size = get_viewport_rect().size


func refresh(session, player_controller) -> void:
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
	prompt_overlay.refresh(
		str(location.get("name", session.location_id)),
		player_controller.prompt_text(),
		session.visible_log(1)
	)


func is_title_visible() -> bool:
	return title_screen != null and title_screen.visible


func is_pause_visible() -> bool:
	return pause_menu != null and pause_menu.visible


func is_settings_visible() -> bool:
	return settings_menu != null and settings_menu.visible


func has_menu_focus() -> bool:
	return get_viewport().gui_get_focus_owner() != null


func focus_visible_menu() -> void:
	if is_settings_visible():
		settings_menu.focus_default()
	elif is_pause_visible():
		pause_menu.focus_default()
	elif is_title_visible():
		title_screen.focus_default()


func hide_title() -> void:
	title_screen.visible = false


func show_title(has_save: bool, status: String = "") -> void:
	pause_menu.visible = false
	settings_menu.visible = false
	title_screen.visible = true
	title_screen.set_continue_enabled(has_save)
	title_screen.set_status(status)
	title_screen.focus_default()


func set_title_status(text: String) -> void:
	title_screen.set_status(text)


func toggle_pause(status: String) -> bool:
	pause_menu.visible = not pause_menu.visible
	if pause_menu.visible:
		pause_menu.set_status(status)
		pause_menu.focus_default()
	return pause_menu.visible


func hide_pause() -> void:
	pause_menu.visible = false


func set_pause_status(text: String) -> void:
	pause_menu.set_status(text)


func show_settings(fullscreen: bool, master_volume: float) -> void:
	title_screen.visible = false
	settings_menu.visible = true
	settings_menu.set_fullscreen(fullscreen)
	settings_menu.set_master_volume(master_volume)
	settings_menu.focus_default()


func hide_settings(show_title_after: bool) -> void:
	settings_menu.visible = false
	if show_title_after:
		title_screen.visible = true
		title_screen.focus_default()


func set_settings_master_volume(value: float) -> void:
	settings_menu.set_master_volume(value)


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


func _build_prompt_overlay() -> Control:
	prompt_overlay = PromptOverlayScript.new()
	prompt_overlay.name = "PromptOverlay"
	var panel: Control = prompt_overlay
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	panel.offset_left = 16
	panel.offset_top = 74
	panel.offset_right = 482
	panel.offset_bottom = 166
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
	pause_menu.resume_requested.connect(resume_requested.emit)
	pause_menu.save_requested.connect(save_requested.emit)
	pause_menu.load_requested.connect(load_requested.emit)
	pause_menu.quit_requested.connect(return_to_title_requested.emit)
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
	title_screen.new_game_requested.connect(new_game_requested.emit)
	title_screen.continue_requested.connect(continue_requested.emit)
	title_screen.settings_requested.connect(settings_requested.emit)
	title_screen.quit_requested.connect(title_quit_requested.emit)
	title_screen.set_continue_enabled(pending_continue_enabled)
	title_screen.call_deferred("focus_default")
	return title_screen


func _build_settings_menu() -> Control:
	settings_menu = SettingsMenuScript.new()
	settings_menu.name = "SettingsMenu"
	settings_menu.visible = false
	settings_menu.set_anchors_preset(Control.PRESET_CENTER, false)
	settings_menu.custom_minimum_size = Vector2(360, 250)
	settings_menu.offset_left = -180
	settings_menu.offset_top = -130
	settings_menu.offset_right = 180
	settings_menu.offset_bottom = 130
	settings_menu.fullscreen_changed.connect(fullscreen_changed.emit)
	settings_menu.master_volume_changed.connect(master_volume_changed.emit)
	settings_menu.back_requested.connect(settings_back_requested.emit)
	return settings_menu
