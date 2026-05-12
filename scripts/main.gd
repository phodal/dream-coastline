extends Node2D

const BASE_SIZE := Vector2(1280.0, 720.0)
const SCENE_DIR := "res://data/ascii_scenes"
const MAX_LOG_LINES := 8
const SCENE_IDS := [
	"00-prologue-lights-out",
	"01-illiterate",
	"02-moqi-academy",
	"03-dead-kingdom",
	"04-continuation-institute",
	"05-century-continuation",
	"06-return-star-plan",
	"07-lights-on-again",
]

const COLORS := {
	"background": Color("#080a12"),
	"panel": Color("#111723"),
	"panel_alt": Color("#172030"),
	"border": Color("#6f8ca5"),
	"gold": Color("#d8b45d"),
	"cyan": Color("#6ed2df"),
	"text": Color("#f1ead4"),
	"muted": Color("#aab5bd"),
	"danger": Color("#d65d55"),
}

var scene_db := {}
var scene_index := 0
var scene := {}
var location_id := ""
var flags := {}
var metrics := {}
var elapsed_seconds := 0
var enemy_hp := 0
var player_hp := 5
var name_attempts := 0
var attacks_since_name := 0
var event_log: Array[String] = []

var root: Control
var title_label: Label
var time_label: Label
var location_label: Label
var art_label: Label
var description_label: Label
var status_label: Label
var metrics_label: Label
var log_label: RichTextLabel
var action_grid: GridContainer
var prev_button: Button
var next_button: Button
var reset_button: Button


func _ready() -> void:
	_load_scene_database()
	if OS.get_cmdline_user_args().has("--smoke-autoplay"):
		var ok := _run_smoke_verification()
		get_tree().quit(0 if ok else 1)
		return

	_build_ui()
	_load_scene(0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), COLORS.background)


func _load_scene_database() -> void:
	for scene_id in SCENE_IDS:
		var path := "%s/%s.json" % [SCENE_DIR, scene_id]
		var text := FileAccess.get_file_as_string(path)
		var parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("Could not parse scene data: %s" % path)
			continue
		scene_db[scene_id] = parsed


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
	var panel := _make_panel("TopBar", COLORS.panel_alt)
	panel.custom_minimum_size = Vector2(0, 54)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	prev_button = _make_button("<", "上一幕")
	prev_button.custom_minimum_size = Vector2(54, 38)
	prev_button.pressed.connect(func(): _load_scene(max(scene_index - 1, 0)))
	row.add_child(prev_button)

	next_button = _make_button(">", "下一幕")
	next_button.custom_minimum_size = Vector2(54, 38)
	next_button.pressed.connect(func(): _load_scene(min(scene_index + 1, SCENE_IDS.size() - 1)))
	row.add_child(next_button)

	title_label = _make_label("SceneTitle", 24, COLORS.text)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)

	time_label = _make_label("SceneTime", 18, COLORS.cyan)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.custom_minimum_size = Vector2(180, 34)
	row.add_child(time_label)

	reset_button = _make_button("Reset", "重置本幕")
	reset_button.custom_minimum_size = Vector2(110, 38)
	reset_button.pressed.connect(func(): _load_scene(scene_index))
	row.add_child(reset_button)
	return panel


func _build_scene_panel() -> Control:
	var panel := _make_panel("ScenePanel", COLORS.panel)
	panel.custom_minimum_size = Vector2(610, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	location_label = _make_label("Location", 22, COLORS.gold)
	box.add_child(location_label)

	art_label = _make_label("AsciiArt", 18, COLORS.text)
	art_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	art_label.add_theme_color_override("font_shadow_color", Color("#000000", 0.8))
	art_label.add_theme_constant_override("shadow_offset_x", 2)
	art_label.add_theme_constant_override("shadow_offset_y", 2)
	art_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(art_label)

	return panel


func _build_info_panel() -> Control:
	var panel := _make_panel("InfoPanel", COLORS.panel)
	panel.custom_minimum_size = Vector2(610, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	description_label = _make_label("Description", 19, COLORS.text)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(0, 82)
	box.add_child(description_label)

	status_label = _make_label("Status", 16, COLORS.muted)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 48)
	box.add_child(status_label)

	metrics_label = _make_label("Metrics", 16, COLORS.cyan)
	metrics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	metrics_label.custom_minimum_size = Vector2(0, 30)
	box.add_child(metrics_label)

	log_label = RichTextLabel.new()
	log_label.name = "Log"
	log_label.fit_content = false
	log_label.scroll_active = false
	log_label.bbcode_enabled = false
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.custom_minimum_size = Vector2(0, 92)
	log_label.add_theme_font_size_override("normal_font_size", 17)
	log_label.add_theme_color_override("default_color", COLORS.text)
	box.add_child(log_label)

	return panel


func _build_action_panel() -> Control:
	var panel := _make_panel("ActionPanel", COLORS.panel_alt)
	panel.custom_minimum_size = Vector2(0, 188)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	action_grid = GridContainer.new()
	action_grid.columns = 4
	action_grid.add_theme_constant_override("h_separation", 8)
	action_grid.add_theme_constant_override("v_separation", 8)
	action_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(action_grid)
	return panel


func _make_panel(panel_name: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = COLORS.border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_label(label_name: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_button(button_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(286, 38)
	button.add_theme_font_size_override("font_size", 16)
	return button


func _load_scene(index: int) -> void:
	scene_index = clamp(index, 0, SCENE_IDS.size() - 1)
	scene = scene_db[SCENE_IDS[scene_index]]
	location_id = str(scene.get("start", ""))
	flags.clear()
	for flag in scene.get("initial_flags", []):
		flags[str(flag)] = true
	metrics = scene.get("metrics", {}).duplicate(true)
	elapsed_seconds = 0
	enemy_hp = 0
	player_hp = 5
	name_attempts = 0
	attacks_since_name = 0
	event_log.clear()
	_enter_combat_if_needed()
	_log("开始：%s" % scene.get("title", ""))
	_refresh_ui()


func _current_location() -> Dictionary:
	return scene.get("locations", {}).get(location_id, {})


func _refresh_ui() -> void:
	if title_label == null:
		return

	var location := _current_location()
	title_label.text = "%s/%s  %s" % [scene_index + 1, SCENE_IDS.size(), scene.get("title", "")]
	time_label.text = "时长 %s" % _format_time(elapsed_seconds)
	prev_button.disabled = scene_index <= 0
	next_button.disabled = scene_index >= SCENE_IDS.size() - 1

	location_label.text = str(location.get("name", location_id))
	art_label.text = "\n".join(location.get("art", []))
	description_label.text = str(location.get("description", ""))
	status_label.text = _status_text()
	metrics_label.text = _metrics_text()
	log_label.text = "\n".join(event_log.slice(max(0, event_log.size() - MAX_LOG_LINES), event_log.size()))

	_rebuild_actions()
	queue_redraw()


func _rebuild_actions() -> void:
	for child in action_grid.get_children():
		child.queue_free()

	var location := _current_location()
	_add_action_header("移动")
	for exit_id in location.get("exits", {}).keys():
		_add_action_button("去：%s" % location["exits"][exit_id], func(exit_key = exit_id): _move(str(exit_key)))

	_add_action_header("调查")
	for item_id in location.get("items", {}).keys():
		var item = location["items"][item_id]
		_add_action_button("查：%s" % item.get("name", item_id), func(item_key = item_id): _inspect_item(str(item_key)))

	var casts := _available_casts()
	if not casts.is_empty():
		_add_action_header("字根")
		for glyph in casts:
			_add_action_button("写/施：%s" % glyph, func(glyph_key = glyph): _cast_glyph(str(glyph_key)))

	if location.has("build_actions"):
		_add_action_header("建设")
		for project in location["build_actions"].keys():
			_add_action_button("建：%s" % project, func(project_key = project): _build_project(str(project_key)))

	if location.has("choices"):
		_add_action_header("选择")
		for route in location["choices"].keys():
			_add_action_button("选：%s" % route, func(route_key = route): _choose_route(str(route_key)))

	if location.has("combat"):
		_add_action_header("战斗")
		_add_action_button("写：名", func(): _write_name())
		_add_action_button("攻击", func(): _attack())
		_add_action_button("防御", func(): _guard())

	if location.has("combos"):
		_add_action_header("组合")
		for combo in location["combos"].keys():
			_add_action_button("组合：%s" % combo, func(combo_key = combo): _combine_words(str(combo_key)))


func _add_action_header(text: String) -> void:
	var label := _make_label("Header", 16, COLORS.gold)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(286, 30)
	action_grid.add_child(label)


func _add_action_button(text: String, callback: Callable) -> void:
	var button := _make_button("Action", text)
	button.pressed.connect(callback)
	action_grid.add_child(button)


func _move(exit_id: String) -> void:
	var location := _current_location()
	if not location.get("exits", {}).has(exit_id):
		_log("这里不能去那里。")
		_refresh_ui()
		return
	location_id = exit_id
	elapsed_seconds += 20
	_enter_combat_if_needed()
	_log("前往：%s" % _current_location().get("name", exit_id))
	_refresh_ui()


func _inspect_item(item_id: String) -> void:
	var item = _current_location().get("items", {}).get(item_id)
	if item == null:
		_log("这里没有这个调查对象。")
		_refresh_ui()
		return
	if not _requirements_met(item.get("requires", [])):
		_log("前置条件不足。")
		_refresh_ui()
		return
	elapsed_seconds += int(item.get("time_seconds", 30))
	_add_flags(item.get("flags", []))
	_log(str(item.get("text", "")))
	_refresh_ui()


func _available_casts() -> Array[String]:
	var casts: Array[String] = []
	var location := _current_location()
	for glyph in location.get("glyph_actions", {}).keys():
		casts.append(str(glyph))
	for glyph in location.get("combat", {}).get("spells", {}).keys():
		if not casts.has(str(glyph)):
			casts.append(str(glyph))
	return casts


func _cast_glyph(glyph: String) -> void:
	var combat_active := _combat_active()
	if glyph in ["name", "名"] and combat_active:
		_write_name()
		return

	var location := _current_location()
	var action = null
	if combat_active:
		action = location.get("combat", {}).get("spells", {}).get(glyph)
	if action == null:
		action = location.get("glyph_actions", {}).get(glyph)
	if action == null:
		action = location.get("combat", {}).get("spells", {}).get(glyph)
	if action == null:
		_log("这个字根现在派不上用场。")
		_refresh_ui()
		return
	if not _requirements_met(action.get("requires", [])):
		_log("术式前置条件不足。")
		_refresh_ui()
		return
	elapsed_seconds += int(action.get("time_seconds", 45))
	_add_flags(action.get("flags", []))
	_apply_metrics(action.get("metrics", {}))
	_log(str(action.get("text", "")))
	_refresh_ui()


func _build_project(project: String) -> void:
	var action = _current_location().get("build_actions", {}).get(project)
	if action == null:
		_log("这里不能建设这个项目。")
		_refresh_ui()
		return
	if not _requirements_met(action.get("requires", [])):
		_log("建设条件不足。")
		_refresh_ui()
		return
	elapsed_seconds += int(action.get("time_seconds", 60))
	_add_flags(action.get("flags", []))
	_apply_metrics(action.get("metrics", {}))
	_log(str(action.get("text", "")))
	_refresh_ui()


func _choose_route(route: String) -> void:
	var choice = _current_location().get("choices", {}).get(route)
	if choice == null:
		_log("这里没有这个选择。")
		_refresh_ui()
		return
	if not _requirements_met(choice.get("requires", [])):
		_log("选择条件不足。")
		_refresh_ui()
		return
	elapsed_seconds += int(choice.get("time_seconds", 45))
	_add_flags(choice.get("flags", []))
	_log(str(choice.get("text", "")))
	_refresh_ui()


func _combine_words(combo: String) -> void:
	var action = _current_location().get("combos", {}).get(combo)
	if action == null:
		_log("这里不能组合这组字。")
		_refresh_ui()
		return
	if not _requirements_met(action.get("requires", [])):
		_log("字义还不稳定，组合会碎掉。")
		_refresh_ui()
		return
	elapsed_seconds += int(action.get("time_seconds", 90))
	_add_flags(action.get("flags", []))
	_log(str(action.get("text", "")))
	_refresh_ui()


func _write_name() -> void:
	var combat: Dictionary = _current_location().get("combat", {})
	if combat.is_empty():
		_log("现在不需要写“名”。")
		_refresh_ui()
		return
	if combat.get("learn_flag", "") != "" and not _has_flag(str(combat["learn_flag"])):
		_log("你还没有理解“名”的笔画。")
		_refresh_ui()
		return

	elapsed_seconds += int(combat.get("write_seconds", 45))
	name_attempts += 1
	if name_attempts < int(combat.get("success_attempt", 1)):
		player_hp -= 1
		_log("符文碎开。敌人继续逼近，UI 上的名字短暂变成□□。")
	else:
		_add_flags([combat["lock_flag"]])
		_add_flags(combat.get("success_flags", []))
		attacks_since_name = 0
		_log("“名”字亮起。目标显形：%s。" % combat.get("revealed_name", "敌人"))
	_refresh_ui()


func _attack() -> void:
	var combat: Dictionary = _current_location().get("combat", {})
	if combat.is_empty():
		_log("这里没有敌人。")
		_refresh_ui()
		return
	if not _has_flag(str(combat.get("lock_flag", ""))):
		elapsed_seconds += 25
		player_hp -= 1
		_log("无法锁定目标，攻击穿过空白。")
		_refresh_ui()
		return
	if not _requirements_met(combat.get("required_attack_flags", [])):
		elapsed_seconds += 25
		_log("目标已显形，但战场规则还没破解。")
		_refresh_ui()
		return

	elapsed_seconds += int(combat.get("attack_seconds", 35))
	enemy_hp -= 1
	attacks_since_name += 1
	if enemy_hp <= 0:
		_add_flags([combat["win_flag"]])
		_add_flags(combat.get("reward_flags", []))
		_log("%s 被击退。" % combat.get("revealed_name", "敌人"))
	elif attacks_since_name >= int(combat.get("lose_name_every", 2)):
		flags.erase(str(combat.get("lock_flag", "")))
		attacks_since_name = 0
		_log("%s 开始失名，必须重新写“名”。" % combat.get("revealed_name", "敌人"))
	else:
		_log("攻击命中：%s。" % combat.get("revealed_name", "敌人"))
	_refresh_ui()


func _guard() -> void:
	elapsed_seconds += 30
	_log("你稳住阵线，争取到半步距离。")
	_refresh_ui()


func _enter_combat_if_needed() -> void:
	var combat: Dictionary = _current_location().get("combat", {})
	if combat.is_empty() or enemy_hp > 0 or _has_flag(str(combat.get("win_flag", ""))):
		return
	enemy_hp = int(combat.get("enemy_hp", 1))
	player_hp = int(combat.get("player_hp", 5))
	name_attempts = 0
	attacks_since_name = 0


func _combat_active() -> bool:
	var combat: Dictionary = _current_location().get("combat", {})
	return not combat.is_empty() and enemy_hp > 0 and not _has_flag(str(combat.get("win_flag", "")))


func _requirements_met(required: Array) -> bool:
	for flag in required:
		if not _has_flag(str(flag)):
			return false
	return true


func _add_flags(new_flags: Array) -> void:
	for flag in new_flags:
		flags[str(flag)] = true


func _apply_metrics(delta: Dictionary) -> void:
	for key in delta.keys():
		var metric_key := str(key)
		metrics[metric_key] = int(metrics.get(metric_key, 0)) + int(delta[key])


func _has_flag(flag: String) -> bool:
	return flag != "" and flags.has(flag)


func _log(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	event_log.append(text)


func _status_text() -> String:
	var required: Array = scene.get("required_flags", [])
	var found := 0
	for flag in required:
		if _has_flag(str(flag)):
			found += 1
	var text := "目标覆盖 %s/%s" % [found, required.size()]
	if scene.has("min_minutes"):
		text += "  最低时长 %.1f 分钟" % float(scene["min_minutes"])
	var combat: Dictionary = _current_location().get("combat", {})
	if not combat.is_empty():
		var enemy_name := str(combat.get("revealed_name", combat.get("hidden_name", "敌人"))) if _has_flag(str(combat.get("lock_flag", ""))) else str(combat.get("hidden_name", "???"))
		text += "\n敌人 %s HP %s/%s  我方 HP %s" % [enemy_name, enemy_hp, combat.get("enemy_hp", 0), player_hp]
	if _has_flag(str(scene.get("ending_flag", ""))):
		text += "\n章节完成，可以切到下一幕。"
	return text


func _metrics_text() -> String:
	if metrics.is_empty():
		return ""
	var parts: Array[String] = []
	for key in metrics.keys():
		parts.append("%s=%s" % [key, metrics[key]])
	return "指标  " + "  ".join(parts)


func _format_time(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _run_smoke_verification() -> bool:
	var all_ok := true
	for scene_id in SCENE_IDS:
		var ok := _verify_scene(scene_id)
		all_ok = all_ok and ok
	return all_ok


func _verify_scene(scene_id: String) -> bool:
	scene = scene_db[scene_id]
	location_id = str(scene.get("start", ""))
	flags.clear()
	for flag in scene.get("initial_flags", []):
		flags[str(flag)] = true
	metrics = scene.get("metrics", {}).duplicate(true)
	elapsed_seconds = 0
	enemy_hp = 0
	player_hp = 5
	name_attempts = 0
	attacks_since_name = 0
	_enter_combat_if_needed()

	for command in scene.get("walkthrough", []):
		_apply_text_command(str(command))
		if _has_flag(str(scene.get("ending_flag", ""))):
			break

	var missing: Array[String] = []
	for flag in scene.get("required_flags", []):
		if not _has_flag(str(flag)):
			missing.append(str(flag))
	var duration_ok := float(elapsed_seconds) / 60.0 >= float(scene.get("min_minutes", 0.0))
	var complete := _has_flag(str(scene.get("ending_flag", ""))) and missing.is_empty()
	var ok := duration_ok and complete
	print("%s duration=%.1fmin required=%s/%s status=%s" % [
		scene_id,
		float(elapsed_seconds) / 60.0,
		scene.get("required_flags", []).size() - missing.size(),
		scene.get("required_flags", []).size(),
		"PASS" if ok else "FAIL",
	])
	if not ok:
		print("missing=", missing)
	return ok


func _apply_text_command(command: String) -> void:
	var parts := command.split(" ", false)
	if parts.is_empty():
		return
	var verb := parts[0]
	var arg := parts[1] if parts.size() > 1 else ""
	match verb:
		"go":
			_move(arg)
		"inspect":
			_inspect_item(arg)
		"cast":
			_cast_glyph(arg)
		"write":
			_write_name()
		"attack":
			_attack()
		"guard":
			_guard()
		"choose":
			_choose_route(arg)
		"build":
			_build_project(arg)
		"combine":
			_combine_words(arg)
