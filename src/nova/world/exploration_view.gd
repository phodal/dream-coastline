extends Control

signal inspect_requested(item_id: String)
signal move_requested(location_id: String)

var backdrop: TextureRect
var scene_label: Label
var location_label: Label
var description_label: Label
var flag_label: Label
var quest_label: Label
var choice_list: VBoxContainer
var prop_layer: Control
var protagonist_portrait: TextureRect
var _choice_buttons: Array[Button] = []
var _selected_choice_index := 0
var _scene_id := ""
var _location_id := ""
var _location: Dictionary = {}
var _visual: Dictionary = {}

const PROTAGONIST_PORTRAIT := "res://assets/characters/main/jizi_xuan/portrait_xianjian_phone.png"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	backdrop = TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(backdrop)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.018, 0.024, 0.32)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	prop_layer = Control.new()
	prop_layer.name = "PropLayer"
	prop_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(prop_layer)

	protagonist_portrait = TextureRect.new()
	protagonist_portrait.name = "ProtagonistPortrait"
	protagonist_portrait.anchor_left = 0.0
	protagonist_portrait.anchor_top = 1.0
	protagonist_portrait.anchor_right = 0.0
	protagonist_portrait.anchor_bottom = 1.0
	protagonist_portrait.offset_left = 26.0
	protagonist_portrait.offset_top = -450.0
	protagonist_portrait.offset_right = 286.0
	protagonist_portrait.offset_bottom = 18.0
	protagonist_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	protagonist_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	protagonist_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	protagonist_portrait.z_index = 4
	protagonist_portrait.texture = _load_texture(PROTAGONIST_PORTRAIT)
	add_child(protagonist_portrait)

	var dialogue := PanelContainer.new()
	dialogue.name = "BottomNarration"
	dialogue.anchor_left = 0.18
	dialogue.anchor_top = 1.0
	dialogue.anchor_right = 0.70
	dialogue.anchor_bottom = 1.0
	dialogue.offset_left = 0.0
	dialogue.offset_top = -178.0
	dialogue.offset_right = 0.0
	dialogue.offset_bottom = -32.0
	dialogue.z_index = 5
	add_child(dialogue)
	dialogue.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.03, 0.04, 0.9)))

	var dialogue_margin := MarginContainer.new()
	dialogue_margin.add_theme_constant_override("margin_left", 24)
	dialogue_margin.add_theme_constant_override("margin_top", 14)
	dialogue_margin.add_theme_constant_override("margin_right", 24)
	dialogue_margin.add_theme_constant_override("margin_bottom", 14)
	dialogue.add_child(dialogue_margin)

	var dialogue_rows := VBoxContainer.new()
	dialogue_rows.add_theme_constant_override("separation", 6)
	dialogue_margin.add_child(dialogue_rows)

	scene_label = Label.new()
	scene_label.add_theme_font_size_override("font_size", 16)
	scene_label.add_theme_color_override("font_color", Color(0.78, 0.63, 0.34))
	dialogue_rows.add_child(scene_label)

	location_label = Label.new()
	location_label.add_theme_font_size_override("font_size", 24)
	location_label.add_theme_color_override("font_color", Color(0.94, 0.93, 0.88))
	dialogue_rows.add_child(location_label)

	description_label = Label.new()
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 20)
	description_label.add_theme_color_override("font_color", Color(0.78, 0.81, 0.78))
	dialogue_rows.add_child(description_label)

	var side := PanelContainer.new()
	side.anchor_left = 1.0
	side.anchor_top = 0.0
	side.anchor_right = 1.0
	side.anchor_bottom = 1.0
	side.offset_left = -410.0
	side.offset_top = 54.0
	side.offset_right = -42.0
	side.offset_bottom = -54.0
	add_child(side)
	side.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.028, 0.038, 0.9)))

	var side_margin := MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 18)
	side_margin.add_theme_constant_override("margin_top", 18)
	side_margin.add_theme_constant_override("margin_right", 18)
	side_margin.add_theme_constant_override("margin_bottom", 18)
	side.add_child(side_margin)

	var side_rows := VBoxContainer.new()
	side_rows.add_theme_constant_override("separation", 12)
	side_margin.add_child(side_rows)

	var action_title := Label.new()
	action_title.text = "行动"
	action_title.add_theme_font_size_override("font_size", 22)
	action_title.add_theme_color_override("font_color", Color(0.9, 0.78, 0.46))
	side_rows.add_child(action_title)

	choice_list = VBoxContainer.new()
	choice_list.add_theme_constant_override("separation", 8)
	choice_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	side_rows.add_child(choice_list)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_rows.add_child(spacer)

	quest_label = Label.new()
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_label.add_theme_font_size_override("font_size", 16)
	quest_label.add_theme_color_override("font_color", Color(0.73, 0.76, 0.72))
	quest_label.clip_text = true
	side_rows.add_child(quest_label)

	flag_label = Label.new()
	flag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flag_label.add_theme_font_size_override("font_size", 15)
	flag_label.add_theme_color_override("font_color", Color(0.58, 0.62, 0.6))
	side_rows.add_child(flag_label)


func present(scene_id: String, location_id: String, location: Dictionary, visual: Dictionary, choices: Array[Dictionary]) -> void:
	_scene_id = scene_id
	_location_id = location_id
	_location = location
	_visual = visual
	var location_name := str(location.get("name", location_id))
	scene_label.text = "地点 · %s" % location_name
	location_label.text = "旁白"
	description_label.text = str(location.get("description", ""))
	var backdrop_path := str(visual.get("illustrated_backdrop", ""))
	if not backdrop_path.is_empty() and ResourceLoader.exists(backdrop_path):
		backdrop.texture = load(backdrop_path)
	else:
		backdrop.texture = null
	_render_props(visual.get("props", []))
	_render_choices(choices)
	_refresh_status()


func _render_choices(choices: Array[Dictionary]) -> void:
	for child in choice_list.get_children():
		child.queue_free()
	_choice_buttons.clear()
	_selected_choice_index = 0
	for choice in choices:
		var button := Button.new()
		button.text = str(choice.get("label", ""))
		button.disabled = not bool(choice.get("enabled", true))
		button.focus_mode = Control.FOCUS_ALL
		if bool(choice.get("done", false)):
			button.text += "  ✓"
		var choice_type := str(choice.get("type", ""))
		var choice_id := str(choice.get("id", ""))
		if choice_type == "inspect":
			button.pressed.connect(func() -> void: inspect_requested.emit(choice_id))
		elif choice_type == "move":
			button.pressed.connect(func() -> void: move_requested.emit(choice_id))
		var index := _choice_buttons.size()
		button.focus_entered.connect(func() -> void: _selected_choice_index = index)
		choice_list.add_child(button)
		_choice_buttons.append(button)
	if choice_list.get_child_count() > 0:
		call_deferred("_focus_first_choice")


func _focus_first_choice() -> void:
	_focus_choice(_selected_choice_index)


func _input(event: InputEvent) -> void:
	if not visible or GameMode.current_mode != GameMode.EXPLORATION or _choice_buttons.is_empty():
		return
	if event.is_action_pressed("ui_down"):
		_focus_choice(_next_enabled_choice(1))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_focus_choice(_next_enabled_choice(-1))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		var button := _choice_buttons[_selected_choice_index]
		if not button.disabled:
			button.pressed.emit()
			get_viewport().set_input_as_handled()


func _focus_choice(index: int) -> void:
	if _choice_buttons.is_empty() or not visible:
		return
	_selected_choice_index = clampi(index, 0, _choice_buttons.size() - 1)
	var button := _choice_buttons[_selected_choice_index]
	if not button.disabled:
		button.grab_focus()


func _next_enabled_choice(direction: int) -> int:
	if _choice_buttons.is_empty():
		return 0
	var index := _selected_choice_index
	for step in _choice_buttons.size():
		index = wrapi(index + direction, 0, _choice_buttons.size())
		if not _choice_buttons[index].disabled:
			return index
	return _selected_choice_index


func _render_props(props: Array) -> void:
	for child in prop_layer.get_children():
		child.queue_free()
	for prop in props:
		if typeof(prop) != TYPE_DICTIONARY:
			continue
		var marker := ColorRect.new()
		var kind := str(prop.get("kind", "prop"))
		marker.color = _kind_color(kind)
		var x: float = float(prop.get("x", 7.0)) / 15.0
		var y: float = float(prop.get("y", 4.0)) / 9.0
		var w: float = max(1.0, float(prop.get("w", 1.0))) / 15.0
		var h: float = max(1.0, float(prop.get("h", 1.0))) / 9.0
		marker.anchor_left = clampf(x, 0.0, 0.96)
		marker.anchor_top = clampf(y, 0.0, 0.92)
		marker.anchor_right = clampf(x + w, 0.04, 1.0)
		marker.anchor_bottom = clampf(y + h, 0.08, 1.0)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prop_layer.add_child(marker)


func _refresh_status() -> void:
	var quests := QuestState.active_summary()
	var quest_lines: Array[String] = []
	for quest in quests:
		quest_lines.append("%s：%s" % [quest.get("title", quest.get("id", "")), quest.get("status", "")])
	quest_label.text = "任务\n%s" % "\n".join(quest_lines)
	var flag_names := StoryFlags.export_flags().keys()
	flag_names.sort()
	if flag_names.is_empty():
		flag_label.text = ""
	else:
		flag_label.text = "线索：%s" % "、".join(flag_names.slice(maxi(flag_names.size() - 4, 0), flag_names.size()))


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.75, 0.62, 0.35, 0.78)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _kind_color(kind: String) -> Color:
	match kind:
		"exit", "stairs", "portal":
			return Color(0.35, 0.62, 0.95, 0.22)
		"window", "window_dark", "lamp":
			return Color(0.95, 0.76, 0.28, 0.2)
		"letter", "pen", "photo", "note":
			return Color(0.85, 0.88, 0.72, 0.24)
		_:
			return Color(0.64, 0.82, 0.64, 0.14)
