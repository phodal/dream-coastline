extends CanvasLayer

signal accepted(payload: Dictionary)

var backdrop: TextureRect
var title_label: Label
var speaker_label: Label
var body_label: Label
var accept_button: Button
var character_layer: HBoxContainer
var _payload: Dictionary = {}


func _ready() -> void:
	visible = false
	layer = 20
	var root := Control.new()
	root.name = "VNRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	backdrop = TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(backdrop)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.035, 0.28)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	character_layer = HBoxContainer.new()
	character_layer.name = "EventCharacters"
	character_layer.anchor_left = 0.54
	character_layer.anchor_right = 0.92
	character_layer.anchor_top = 0.13
	character_layer.anchor_bottom = 0.58
	character_layer.add_theme_constant_override("separation", 16)
	character_layer.visible = false
	root.add_child(character_layer)

	var box := PanelContainer.new()
	box.name = "DialogueBox"
	box.anchor_left = 0.08
	box.anchor_right = 0.92
	box.anchor_top = 0.62
	box.anchor_bottom = 0.92
	root.add_child(box)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.055, 0.92)
	style.border_color = Color(0.82, 0.67, 0.36, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	box.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 18)
	box.add_child(margin)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	margin.add_child(rows)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.78, 0.46))
	rows.add_child(title_label)

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 24)
	speaker_label.add_theme_color_override("font_color", Color(0.93, 0.93, 0.9))
	rows.add_child(speaker_label)

	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 25)
	body_label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.84))
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_child(body_label)

	accept_button = Button.new()
	accept_button.text = "继续"
	accept_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	accept_button.pressed.connect(_accept)
	rows.add_child(accept_button)


func show_payload(payload: Dictionary, backdrop_path: String) -> void:
	_payload = payload.duplicate(true)
	if not backdrop_path.is_empty() and ResourceLoader.exists(backdrop_path):
		backdrop.texture = load(backdrop_path)
	else:
		backdrop.texture = null
	title_label.text = str(payload.get("title", ""))
	speaker_label.text = str(payload.get("speaker", "旁白"))
	body_label.text = str(payload.get("text", ""))
	_render_characters(payload.get("characters", []))
	visible = true
	accept_button.grab_focus()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_accept()
		get_viewport().set_input_as_handled()


func _accept() -> void:
	if not visible:
		return
	visible = false
	accept_button.release_focus()
	_render_characters([])
	accepted.emit(_payload)


func _render_characters(characters: Array) -> void:
	for child in character_layer.get_children():
		child.queue_free()
	character_layer.visible = false
	for raw_character in characters:
		if typeof(raw_character) != TYPE_DICTIONARY:
			continue
		var character: Dictionary = raw_character
		var path := str(character.get("path", ""))
		var name := str(character.get("name", character.get("id", "")))
		if path.is_empty() or not ResourceLoader.exists(path):
			continue
		character_layer.add_child(_build_character_card(name, path))
	character_layer.visible = character_layer.get_child_count() > 0


func _build_character_card(label_text: String, texture_path: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(190.0, 300.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.028, 0.038, 0.5)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	margin.add_child(rows)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(170.0, 238.0)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	portrait.texture = load(texture_path)
	rows.add_child(portrait)

	var name := Label.new()
	name.text = label_text
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 18)
	name.add_theme_color_override("font_color", Color(0.91, 0.83, 0.64))
	rows.add_child(name)
	return card


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.78, 0.64, 0.34, 0.55)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style
