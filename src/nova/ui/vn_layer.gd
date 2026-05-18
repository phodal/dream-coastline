extends CanvasLayer

signal accepted(payload: Dictionary)

var backdrop: TextureRect
var title_label: Label
var speaker_label: Label
var body_label: Label
var accept_button: Button
var _payload: Dictionary = {}


func _ready() -> void:
	visible = false
	layer = 20
	var root := Control.new()
	root.name = "VNRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	backdrop = TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(backdrop)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.035, 0.28)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

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
	accepted.emit(_payload)
