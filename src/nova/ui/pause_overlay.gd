extends CanvasLayer

signal resume_requested
signal save_requested
signal settings_requested
signal title_requested
signal quit_requested

var _panel: PanelContainer
var _status_label: Label
var _buttons: Array[Button] = []
var _selected_index := 0


func _ready() -> void:
	layer = 80
	visible = false

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.012, 0.018, 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -180.0
	_panel.offset_top = -170.0
	_panel.offset_right = 180.0
	_panel.offset_bottom = 170.0
	_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margin)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	margin.add_child(rows)

	var title := Label.new()
	title.text = "暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	rows.add_child(title)

	_add_button(rows, "继续", func() -> void: resume_requested.emit())
	_add_button(rows, "保存", func() -> void: save_requested.emit())
	_add_button(rows, "设置与辅助功能", func() -> void: settings_requested.emit())
	_add_button(rows, "返回标题", func() -> void: title_requested.emit())
	_add_button(rows, "退出", func() -> void: quit_requested.emit())

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.72))
	rows.add_child(_status_label)


func open() -> void:
	visible = true
	_selected_index = 0
	_focus_selected()


func close() -> void:
	visible = false
	for button in _buttons:
		button.release_focus()


func set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_selected_index = wrapi(_selected_index + 1, 0, _buttons.size())
		_focus_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_selected_index = wrapi(_selected_index - 1, 0, _buttons.size())
		_focus_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_buttons[_selected_index].pressed.emit()
		get_viewport().set_input_as_handled()


func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(0.0, 44.0)
	button.pressed.connect(callback)
	var index := _buttons.size()
	button.focus_entered.connect(func() -> void: _selected_index = index)
	parent.add_child(button)
	_buttons.append(button)


func _focus_selected() -> void:
	if _buttons.is_empty() or not visible:
		return
	_buttons[_selected_index].grab_focus()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.03, 0.04, 0.94)
	style.border_color = Color(0.78, 0.64, 0.34, 0.75)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style
