extends Control

signal inspect_requested(item_id: String)
signal move_requested(location_id: String)
signal choice_requested(choice_id: String)
signal story_action_requested(action_type: String, action_id: String)

const MoqiText := preload("res://src/nova/ui/moqi_text.gd")
const HotspotMarker := preload("res://src/nova/world/hotspot_marker.gd")

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
var _moqi_font: Font

const PROTAGONIST_PORTRAIT := "res://assets/characters/main/jizi_xuan/portrait_xianjian_phone.png"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_moqi_font = MoqiText.load_font()

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
		_configure_choice_button_display(button, choice)
		var choice_type := str(choice.get("type", ""))
		var choice_id := str(choice.get("id", ""))
		var action_type := str(choice.get("action_type", ""))
		button.set_meta("choice_type", choice_type)
		button.set_meta("choice_id", choice_id)
		button.set_meta("action_type", action_type)
		if choice_type == "inspect":
			button.pressed.connect(func() -> void: inspect_requested.emit(choice_id))
		elif choice_type == "move":
			button.pressed.connect(func() -> void: move_requested.emit(choice_id))
		elif choice_type == "choice":
			button.pressed.connect(func() -> void: choice_requested.emit(choice_id))
		elif choice_type == "story_action":
			button.pressed.connect(func() -> void: story_action_requested.emit(action_type, choice_id))
		var index := _choice_buttons.size()
		button.focus_entered.connect(func() -> void: _selected_choice_index = index)
		choice_list.add_child(button)
		_choice_buttons.append(button)
	if choice_list.get_child_count() > 0:
		call_deferred("_focus_first_choice")


func has_enabled_choice(choice_type: String, choice_id: String, action_type: String = "") -> bool:
	var button := _choice_button_for(choice_type, choice_id, action_type)
	return button != null and not button.disabled


func press_choice(choice_type: String, choice_id: String, action_type: String = "") -> bool:
	var button := _choice_button_for(choice_type, choice_id, action_type)
	if button == null or button.disabled:
		return false
	_selected_choice_index = _choice_buttons.find(button)
	button.pressed.emit()
	return true


func current_choice_labels() -> Array[String]:
	var labels: Array[String] = []
	for button in _choice_buttons:
		labels.append(str(button.text if not str(button.text).is_empty() else button.tooltip_text))
	return labels


func choice_index_for(choice_type: String, choice_id: String, action_type: String = "") -> int:
	for index in range(_choice_buttons.size()):
		var button := _choice_buttons[index]
		if str(button.get_meta("choice_type", "")) != choice_type:
			continue
		if str(button.get_meta("choice_id", "")) != choice_id:
			continue
		if not action_type.is_empty() and str(button.get_meta("action_type", "")) != action_type:
			continue
		return index
	return -1


func selected_choice_index() -> int:
	return _selected_choice_index


func hotspot_markers_visible() -> bool:
	return _show_hotspot_markers()


func debug_flags_visible() -> bool:
	return _show_debug_flags()


func _choice_button_for(choice_type: String, choice_id: String, action_type: String = "") -> Button:
	for button in _choice_buttons:
		if str(button.get_meta("choice_type", "")) != choice_type:
			continue
		if str(button.get_meta("choice_id", "")) != choice_id:
			continue
		if not action_type.is_empty() and str(button.get_meta("action_type", "")) != action_type:
			continue
		return button
	return null


func _configure_choice_button_display(button: Button, choice: Dictionary) -> void:
	var glyph := str(choice.get("moqi_glyph", ""))
	if glyph.is_empty() or _moqi_font == null:
		return

	button.text = ""
	button.tooltip_text = str(choice.get("label", ""))
	button.custom_minimum_size = Vector2(0.0, 48.0)

	var row := HBoxContainer.new()
	row.name = "MoqiChoiceRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14.0
	row.offset_top = 4.0
	row.offset_right = -14.0
	row.offset_bottom = -4.0
	row.add_theme_constant_override("separation", 8)
	button.add_child(row)

	var prefix := _choice_row_label(str(choice.get("moqi_prefix", "")), button.disabled, false)
	row.add_child(prefix)

	var glyph_label := _choice_row_label(glyph, button.disabled, true)
	glyph_label.add_theme_font_override(&"font", _moqi_font)
	glyph_label.add_theme_font_size_override("font_size", 30)
	row.add_child(glyph_label)

	var label_text := str(choice.get("moqi_label", ""))
	if bool(choice.get("done", false)):
		label_text += "  ✓"
	row.add_child(_choice_row_label(label_text, button.disabled, false))


func _choice_row_label(text: String, disabled: bool, is_glyph: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 18)
	var enabled_color := Color(0.88, 0.86, 0.78)
	if is_glyph:
		enabled_color = Color(0.98, 0.75, 0.34)
	label.add_theme_color_override("font_color", Color(0.46, 0.47, 0.43) if disabled else enabled_color)
	return label


func _focus_first_choice() -> void:
	_focus_choice(_selected_choice_index)


func _input(event: InputEvent) -> void:
	if not visible or GameMode.current_mode != GameMode.EXPLORATION or _choice_buttons.is_empty():
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_focus_choice(_next_enabled_choice(1))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
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
	if not _show_hotspot_markers():
		return
	for prop in props:
		if typeof(prop) != TYPE_DICTIONARY:
			continue
		if not _is_interactive_prop(prop):
			continue
		var kind := str(prop.get("kind", "prop"))
		var marker := HotspotMarker.new()
		marker.configure(kind, _kind_color(kind))
		var x: float = float(prop.get("x", 7.0)) / 15.0
		var y: float = float(prop.get("y", 4.0)) / 9.0
		var w: float = max(1.0, float(prop.get("w", 1.0))) / 15.0
		var h: float = max(1.0, float(prop.get("h", 1.0))) / 9.0
		var center_x := clampf(x + w * 0.5, 0.03, 0.97)
		var center_y := clampf(y + h * 0.5, 0.06, 0.94)
		marker.anchor_left = center_x
		marker.anchor_top = center_y
		marker.anchor_right = center_x
		marker.anchor_bottom = center_y
		marker.offset_left = -18.0
		marker.offset_top = -18.0
		marker.offset_right = 18.0
		marker.offset_bottom = 18.0
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prop_layer.add_child(marker)


func _refresh_status() -> void:
	var quests := QuestState.active_summary()
	var quest_lines: Array[String] = []
	for quest in quests:
		if str(quest.get("status", "")) == QuestState.ACTIVE:
			quest_lines.append("当前章节：%s" % quest.get("title", quest.get("id", "")))
	if quest_lines.is_empty():
		quest_label.text = ""
	else:
		quest_label.text = "章节进度\n%s" % "\n".join(quest_lines)

	if not _show_debug_flags():
		flag_label.text = ""
		flag_label.visible = false
	else:
		flag_label.visible = true
		var flag_names := StoryFlags.export_flags().keys()
		flag_names.sort()
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
			return Color(0.35, 0.68, 0.96, 0.78)
		"window", "window_dark", "lamp":
			return Color(0.95, 0.76, 0.28, 0.78)
		"letter", "pen", "photo", "note":
			return Color(0.86, 0.88, 0.72, 0.74)
		_:
			return Color(0.64, 0.82, 0.64, 0.64)


func _is_interactive_prop(prop: Dictionary) -> bool:
	return prop.has("item") or prop.has("exit") or bool(prop.get("interactive", false))


func _show_debug_flags() -> bool:
	if OS.get_environment("DREAM_COASTLINE_SHOW_DEBUG_FLAGS") == "1":
		return true
	return OS.get_cmdline_user_args().has("--debug-story-flags")


func _show_hotspot_markers() -> bool:
	if OS.get_environment("DREAM_COASTLINE_SHOW_HOTSPOTS") == "1":
		return true
	return OS.get_cmdline_user_args().has("--show-hotspots")
