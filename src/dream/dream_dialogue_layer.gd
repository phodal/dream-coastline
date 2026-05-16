class_name DreamDialogueLayer
extends CanvasLayer

signal advanced

var _root: Control
var _title_label: Label
var _body_label: RichTextLabel
var _hint_label: Label
var _waiting := false


func _ready() -> void:
	layer = 20
	_build_controls()
	_root.visible = false
	set_process_unhandled_input(true)


func show_message(title: String, body: String, hint: String = "Space / Enter") -> void:
	_title_label.text = title
	_body_label.text = body
	_hint_label.text = hint
	_root.visible = true
	_waiting = true
	await advanced
	_waiting = false
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("dialogic_default_action"):
		get_viewport().set_input_as_handled()
		advanced.emit()


func _build_controls() -> void:
	_root = Control.new()
	_root.name = "DreamDialogueRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.02, 0.025, 0.035, 0.42)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "DialoguePanel"
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.68
	panel.anchor_bottom = 0.95
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.add_theme_font_size_override("font_size", 18)
	stack.add_child(_title_label)

	_body_label = RichTextLabel.new()
	_body_label.name = "Body"
	_body_label.bbcode_enabled = false
	_body_label.fit_content = true
	_body_label.scroll_active = false
	_body_label.custom_minimum_size = Vector2(0, 82)
	_body_label.add_theme_font_size_override("normal_font_size", 16)
	stack.add_child(_body_label)

	_hint_label = Label.new()
	_hint_label.name = "Hint"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_size_override("font_size", 12)
	stack.add_child(_hint_label)
