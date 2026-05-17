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
signal visual_style_changed(value: String)

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const SpriteSceneCanvasScript := preload("res://scripts/ui/sprite_scene_canvas.gd")
const PromptOverlayScript := preload("res://scripts/ui/prompt_overlay.gd")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const TitleScreenScript := preload("res://scripts/ui/title_screen.gd")
const SettingsMenuScript := preload("res://scripts/ui/settings_menu.gd")
const MenuBackdropScript := preload("res://scripts/ui/menu_backdrop.gd")

var visual_repository
var top_bar: Control
var title_label: Label
var objective_label: Label
var time_label: Label
var progression_chip_row: HBoxContainer
var progression_chips: Array = []
var scene_canvas
var menu_backdrop
var prompt_overlay
var pause_menu
var title_screen
var settings_menu
var pending_continue_enabled := false
var gameplay_hud_visible := false


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
	scene_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	scene_canvas.offset_left = 0
	scene_canvas.offset_top = 0
	scene_canvas.offset_right = 0
	scene_canvas.offset_bottom = 0
	scene_canvas.size = get_viewport_rect().size
	scene_canvas.set_visual_repository(visual_repository)
	add_child(scene_canvas)

	menu_backdrop = MenuBackdropScript.new()
	menu_backdrop.name = "MenuBackdrop"
	menu_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	menu_backdrop.visible = false
	add_child(menu_backdrop)

	add_child(_build_top_bar())
	add_child(_build_prompt_overlay())
	add_child(_build_pause_menu())
	add_child(_build_title_screen())
	add_child(_build_settings_menu())
	_layout_hud_regions()
	_sync_gameplay_hud_visibility()
	call_deferred("focus_visible_menu")


func _process(_delta: float) -> void:
	size = get_viewport_rect().size
	_layout_hud_regions()


func refresh(session, player_controller) -> void:
	if title_label == null:
		return

	var location: Dictionary = session.current_location()
	title_label.text = "%s/%s  %s" % [session.scene_index + 1, session.scene_count(), session.scene.get("title", "")]
	var objective_text := _objective_text(session)
	objective_label.text = objective_text
	objective_label.visible = not objective_text.is_empty()
	time_label.text = "时长 %s" % session.format_time()
	_refresh_progression_chips(session)

	scene_canvas.refresh(session)
	scene_canvas.set_player_motion(
		player_controller.visual_tile(),
		player_controller.is_moving,
		player_controller.facing,
		player_controller.blocked_tile,
		player_controller.has_blocked_feedback()
	)
	var raw_prompt := str(player_controller.prompt_text())
	var feedback_text: String = session.visible_log(_visible_log_lines(session))
	if feedback_text == "这里没有可以互动的东西。" and not raw_prompt.begins_with("WASD/方向键移动"):
		feedback_text = ""
	if feedback_text.is_empty():
		feedback_text = _ambient_feedback_text(session, location)
	feedback_text = _tutorial_feedback_text(session, raw_prompt, feedback_text)
	prompt_overlay.refresh(
		_display_location_name(session, location),
		_display_prompt_text(raw_prompt),
		feedback_text,
		_history_log_text(session, feedback_text)
	)
	_layout_hud_regions()


func is_title_visible() -> bool:
	return title_screen != null and title_screen.visible


func is_pause_visible() -> bool:
	return pause_menu != null and pause_menu.visible


func is_settings_visible() -> bool:
	return settings_menu != null and settings_menu.visible


func has_menu_focus() -> bool:
	return get_viewport().gui_get_focus_owner() != null


func release_menu_focus() -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		focus_owner.release_focus()


func focus_visible_menu() -> void:
	if is_settings_visible():
		settings_menu.focus_default()
	elif is_pause_visible():
		pause_menu.focus_default()
	elif is_title_visible():
		title_screen.focus_default()


func hide_title() -> void:
	title_screen.visible = false
	release_menu_focus()
	gameplay_hud_visible = true
	_sync_gameplay_hud_visibility()


func show_title(has_save: bool, status: String = "") -> void:
	gameplay_hud_visible = false
	pause_menu.visible = false
	settings_menu.visible = false
	title_screen.visible = true
	title_screen.set_continue_enabled(has_save)
	title_screen.set_status(status)
	_sync_gameplay_hud_visibility()
	title_screen.focus_default()


func set_title_status(text: String) -> void:
	title_screen.set_status(text)


func toggle_pause(status: String) -> bool:
	pause_menu.visible = not pause_menu.visible
	if pause_menu.visible:
		pause_menu.set_status(status)
		pause_menu.focus_default()
	_sync_gameplay_hud_visibility()
	return pause_menu.visible


func hide_pause() -> void:
	pause_menu.visible = false
	release_menu_focus()
	_sync_gameplay_hud_visibility()


func set_pause_status(text: String) -> void:
	pause_menu.set_status(text)


func title_select_next() -> bool:
	if title_screen == null:
		return false
	return title_screen.select_next()


func title_select_previous() -> bool:
	if title_screen == null:
		return false
	return title_screen.select_previous()


func title_activate_selected() -> bool:
	if title_screen == null:
		return false
	return title_screen.activate_selected()


func title_activate_at(global_position: Vector2) -> bool:
	if title_screen == null:
		return false
	return title_screen.activate_at(global_position)


func pause_select_next() -> bool:
	if pause_menu == null:
		return false
	return pause_menu.select_next()


func pause_select_previous() -> bool:
	if pause_menu == null:
		return false
	return pause_menu.select_previous()


func pause_activate_selected() -> bool:
	if pause_menu == null:
		return false
	return pause_menu.activate_selected()


func pause_activate_at(global_position: Vector2) -> bool:
	if pause_menu == null:
		return false
	return pause_menu.activate_at(global_position)


func show_settings(fullscreen: bool, master_volume: float, visual_style: String) -> void:
	title_screen.visible = false
	settings_menu.visible = true
	settings_menu.set_fullscreen(fullscreen)
	settings_menu.set_master_volume(master_volume)
	settings_menu.set_visual_style(visual_style)
	_sync_gameplay_hud_visibility()
	settings_menu.focus_default()


func hide_settings(show_title_after: bool) -> void:
	settings_menu.visible = false
	if show_title_after:
		title_screen.visible = true
		gameplay_hud_visible = false
	else:
		release_menu_focus()
	_sync_gameplay_hud_visibility()
	if show_title_after:
		title_screen.focus_default()


func set_settings_master_volume(value: float) -> void:
	settings_menu.set_master_volume(value)


func set_settings_visual_style(value: String) -> void:
	settings_menu.set_visual_style(value)


func _build_top_bar() -> Control:
	var top_color := Color(
		GameThemeScript.COLORS.panel_alt.r,
		GameThemeScript.COLORS.panel_alt.g,
		GameThemeScript.COLORS.panel_alt.b,
		0.78
	)
	var panel := GameThemeScript.make_rpg_panel("TopBar", top_color)
	top_bar = panel
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	panel.add_child(stack)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	stack.add_child(row)

	title_label = GameThemeScript.make_label("SceneTitle", 17, GameThemeScript.COLORS.paper)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)

	objective_label = GameThemeScript.make_label("SceneObjective", 14, GameThemeScript.COLORS.gold)
	objective_label.custom_minimum_size = Vector2(260, 24)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_label.visible = false
	row.add_child(objective_label)

	time_label = GameThemeScript.make_label("SceneTime", 14, GameThemeScript.COLORS.muted)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.custom_minimum_size = Vector2(118, 24)
	row.add_child(time_label)

	progression_chip_row = HBoxContainer.new()
	progression_chip_row.name = "SceneProgressionChips"
	progression_chip_row.add_theme_constant_override("separation", 6)
	progression_chip_row.visible = false
	stack.add_child(progression_chip_row)
	for index in range(3):
		var chip := GameThemeScript.make_status_chip("ProgressionChip%s" % index, "")
		chip.visible = false
		progression_chip_row.add_child(chip)
		progression_chips.append(chip)
	return panel


func _build_prompt_overlay() -> Control:
	prompt_overlay = PromptOverlayScript.new()
	prompt_overlay.name = "PromptOverlay"
	var panel: Control = prompt_overlay
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE, false)
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
	settings_menu.custom_minimum_size = Vector2(360, 310)
	settings_menu.offset_left = -180
	settings_menu.offset_top = -160
	settings_menu.offset_right = 180
	settings_menu.offset_bottom = 160
	settings_menu.fullscreen_changed.connect(fullscreen_changed.emit)
	settings_menu.master_volume_changed.connect(master_volume_changed.emit)
	settings_menu.visual_style_changed.connect(visual_style_changed.emit)
	settings_menu.back_requested.connect(settings_back_requested.emit)
	return settings_menu


func _layout_hud_regions() -> void:
	var view_size := get_viewport_rect().size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return
	if scene_canvas != null:
		scene_canvas.position = Vector2.ZERO
		scene_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		scene_canvas.offset_left = 0
		scene_canvas.offset_top = 0
		scene_canvas.size = view_size

	if top_bar != null:
		var top_margin := 10.0
		var has_top_details := false
		if objective_label != null and objective_label.visible:
			has_top_details = true
		if progression_chip_row != null and progression_chip_row.visible:
			has_top_details = true
		var top_max_width := 880.0 if has_top_details else 640.0
		var top_width := minf(view_size.x - 48.0, top_max_width)
		top_width = maxf(500.0, top_width)
		var top_height := 42.0
		if progression_chip_row != null and progression_chip_row.visible:
			top_height = 66.0
		top_bar.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		top_bar.offset_left = 20.0
		top_bar.offset_top = top_margin
		top_bar.offset_right = 20.0 + top_width
		top_bar.offset_bottom = top_margin + top_height

	if prompt_overlay != null:
		var side_margin := clampf(view_size.x * 0.04, 36.0, 56.0)
		var bottom_margin := 12.0
		var dialogue_height := clampf(view_size.y * 0.155, 104.0, 124.0)
		prompt_overlay.set_anchors_preset(Control.PRESET_BOTTOM_WIDE, false)
		prompt_overlay.offset_left = side_margin
		prompt_overlay.offset_top = -dialogue_height - bottom_margin
		prompt_overlay.offset_right = -side_margin
		prompt_overlay.offset_bottom = -bottom_margin

	if menu_backdrop != null:
		menu_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT, false)
		menu_backdrop.offset_left = 0.0
		menu_backdrop.offset_top = 0.0
		menu_backdrop.offset_right = 0.0
		menu_backdrop.offset_bottom = 0.0

	if title_screen != null:
		_layout_menu_panel(title_screen, Vector2(380, 340), _title_panel_position(view_size, Vector2(380, 340)))
	if pause_menu != null:
		_layout_menu_panel(pause_menu, Vector2(340, 284), (view_size - Vector2(340, 284)) * 0.5)
	if settings_menu != null:
		_layout_menu_panel(settings_menu, Vector2(360, 306), (view_size - Vector2(360, 306)) * 0.5)


func _sync_gameplay_hud_visibility() -> void:
	var mode := _active_menu_mode()
	if top_bar != null:
		top_bar.visible = gameplay_hud_visible and mode.is_empty()
	if prompt_overlay != null:
		prompt_overlay.visible = gameplay_hud_visible and mode.is_empty()
	if menu_backdrop != null:
		menu_backdrop.visible = not mode.is_empty()
		menu_backdrop.set_menu_mode(mode)


func _layout_menu_panel(panel: Control, panel_size: Vector2, panel_position: Vector2) -> void:
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	panel.custom_minimum_size = panel_size
	panel.offset_left = panel_position.x
	panel.offset_top = panel_position.y
	panel.offset_right = panel_position.x + panel_size.x
	panel.offset_bottom = panel_position.y + panel_size.y


func _title_panel_position(view_size: Vector2, panel_size: Vector2) -> Vector2:
	var x := view_size.x - panel_size.x - 72.0
	if view_size.x < 980.0:
		x = (view_size.x - panel_size.x) * 0.5
	var y := (view_size.y - panel_size.y) * 0.5
	x = clampf(x, 24.0, maxf(24.0, view_size.x - panel_size.x - 24.0))
	y = clampf(y, 72.0, maxf(72.0, view_size.y - panel_size.y - 36.0))
	return Vector2(x, y)


func _active_menu_mode() -> String:
	if settings_menu != null and settings_menu.visible:
		return "settings"
	if pause_menu != null and pause_menu.visible:
		return "pause"
	if title_screen != null and title_screen.visible:
		return "title"
	return ""


func _objective_text(session) -> String:
	if session.scene_id == "00-prologue-lights-out":
		if session.has_flag("entered_moqi"):
			return "目标：灯灭前，记住黑笔"
		if session.has_flag("read_continue_letter"):
			return "目标：触碰黑色钢笔"
		if session.has_flag("checked_phone_signal"):
			return "目标：回房间查看信"
		if session.has_flag("checked_cold_dinner") or session.has_flag("checked_family_photo"):
			return "目标：去书房找线索"
		if session.has_flag("checked_unlocked_door"):
			return "目标：确认家里发生了什么"
		return "目标：回家，确认灯为什么没亮"
	if session.scene_id == "01-illiterate":
		if session.has_flag("learned_name_strokes") or session.has_flag("named_beast") or session.has_flag("defeated_nameless"):
			return "目标：记住它的名，然后活下去"
		return "目标：辨认失字符号"
	if session.scene_id == "04-continuation-institute":
		return _continuation_objective_text(session)
	if session.scene_id == "06-return-star-plan":
		return _return_star_objective_text(session)
	return ""


func _refresh_progression_chips(session) -> void:
	if progression_chip_row == null:
		return
	var texts := _progression_chip_texts(session)
	progression_chip_row.visible = not texts.is_empty()
	for index in range(progression_chips.size()):
		var chip: PanelContainer = progression_chips[index]
		var visible := index < texts.size()
		chip.visible = visible
		if visible:
			var label := chip.get_child(0) as Label
			label.text = texts[index]
			chip.custom_minimum_size = Vector2(maxf(100.0, minf(250.0, float(texts[index].length()) * 8.0)), 24.0)


func _progression_chip_texts(session) -> Array[String]:
	if not session.has_method("progression_text"):
		return []
	var raw_text := str(session.progression_text())
	if raw_text.is_empty():
		return []
	var lines := raw_text.split("\n", false)
	var chips: Array[String] = []
	for line in lines:
		var compact := _compact_progression_line(str(line))
		if compact.is_empty():
			continue
		if compact.length() > 34:
			compact = compact.substr(0, 31) + "..."
		chips.append(compact)
		if chips.size() >= 3:
			break
	return chips


func _compact_progression_line(line: String) -> String:
	var compact := line.strip_edges()
	if compact.begins_with("资源"):
		return compact.replace("资源  ", "资源 ").replace("ink=", "墨 ").replace("focus=", "心 ").replace("stability=", "稳 ")
	if compact.begins_with("字根熟练"):
		return compact.replace("字根熟练  ", "字根 ").replace("door=", "门").replace("fire=", "火").replace("name=", "名").replace("stop=", "止")
	if compact.begins_with("载体"):
		var names := compact.trim_prefix("载体  ").split("  ", false)
		if names.size() <= 2:
			return compact.replace("载体  ", "载体 ")
		return "载体 %s +%s" % [names[0], names.size() - 1]
	if compact.begins_with("补给"):
		return compact.replace("补给  ", "补给 ")
	return compact


func _continuation_objective_text(session) -> String:
	if not session.has_flag("founded_institute"):
		if session.has_flag("chose_royal_books"):
			return "目标：拆王族保管，公开复核"
		if session.has_flag("chose_engineer_books"):
			return "目标：工程优先，补字根课"
		if session.has_flag("chose_parent_books"):
			return "目标：父母线索转公共索引"
		return "目标：公开藏书建成字典"
	if not session.has_flag("published_standard_dictionary"):
		return "目标：把路线写进公共字典"
	if not session.has_flag("archive_tower_built"):
		return "目标：保护学生与字典"
	return "目标：进入百年续页"


func _return_star_objective_text(session) -> String:
	if not session.has_flag("won_return_star_council"):
		if session.has_flag("chose_royal_books"):
			return "目标：证明不是王族远征"
		if session.has_flag("chose_engineer_books"):
			return "目标：工程方案接受授权"
		if session.has_flag("chose_parent_books"):
			return "目标：私事交给公共审判"
		return "目标：用公开证据争取授权"
	if not session.has_flag("built_return_vessel"):
		return "目标：建成续页舰"
	if not session.has_flag("opened_return_gate"):
		return "目标：绑定备份并开启星门"
	return "目标：带墨颀回到现代"


func _display_location_name(session, location: Dictionary) -> String:
	if session.scene_id == "01-illiterate" and not session.has_flag("learned_name_strokes"):
		return "失字之路"
	return str(location.get("name", session.location_id))


func _display_prompt_text(raw_prompt: String) -> String:
	if raw_prompt.begins_with("Space/Enter "):
		return raw_prompt
	if raw_prompt.begins_with("WASD/方向键移动"):
		return "WASD/方向键移动，Space/Enter 互动，Esc 暂停"
	return raw_prompt


func _tutorial_feedback_text(session, raw_prompt: String, fallback: String) -> String:
	if session.scene_id == "00-prologue-lights-out" and session.location_id == "street" and _event_log_size(session) <= 1:
		return "操作：WASD/方向键移动，Space/Enter 互动，Esc 暂停。先靠近发光物件。"
	if raw_prompt.begins_with("WASD/方向键移动") and _event_log_size(session) <= 1:
		return "操作：WASD/方向键移动，Space/Enter 互动，Esc 暂停。"
	return fallback


func _history_log_text(session, current_feedback: String) -> String:
	var history := str(session.visible_log(3)).strip_edges()
	if history.is_empty() or history == current_feedback:
		return ""
	var lines := history.split("\n", false)
	var kept: Array[String] = []
	for line in lines:
		var compact := str(line).strip_edges()
		if compact.is_empty() or compact == current_feedback:
			continue
		if compact.begins_with("开始："):
			continue
		if compact.length() > 42:
			compact = compact.substr(0, 39) + "..."
		kept.append(compact)
	if kept.is_empty():
		return ""
	return " / ".join(kept)


func _event_log_size(session) -> int:
	if session.event_log is Array:
		return session.event_log.size()
	return 0


func _ambient_feedback_text(session, location: Dictionary) -> String:
	var description := str(location.get("description", ""))
	if not description.is_empty():
		return description
	if session.scene_id == "00-prologue-lights-out":
		return "灯、窗、纸和墨迹都像是在等你靠近。"
	return "沿着地图移动，靠近发光或可疑的物件。"


func _visible_log_lines(session) -> int:
	if session.scene_id == "01-illiterate":
		return 2
	return 1
