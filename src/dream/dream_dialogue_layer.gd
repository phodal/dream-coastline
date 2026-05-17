class_name DreamDialogueLayer
extends CanvasLayer

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")

signal advanced

var _root: Control
var _dim_rect: ColorRect
var _illustration_panel: PanelContainer
var _illustration_texture: TextureRect
var _dialogue_panel: PanelContainer
var _title_label: Label
var _body_label: RichTextLabel
var _hint_label: Label
var _waiting := false
var _review_subtitle_mode := false


func _ready() -> void:
	layer = 20
	_build_controls()
	_root.visible = false
	set_process_unhandled_input(true)


func set_review_subtitle_mode(enabled: bool) -> void:
	_review_subtitle_mode = enabled
	if _root != null:
		_apply_dialogue_layout()


func show_message(title: String, body: String, hint: String = "Space / Enter") -> void:
	_apply_dialogue_layout()
	_illustration_panel.visible = false
	_illustration_texture.texture = null
	_title_label.text = title
	_body_label.text = body
	_hint_label.text = hint
	_root.visible = true
	_waiting = true
	await advanced
	_waiting = false
	_root.visible = false


func show_message_for(title: String, body: String, seconds: float = 1.2, hint: String = "Auto") -> void:
	_apply_dialogue_layout()
	_illustration_panel.visible = false
	_illustration_texture.texture = null
	_title_label.text = title
	_body_label.text = body
	_hint_label.text = hint
	_root.visible = true
	_waiting = false
	await get_tree().create_timer(maxf(0.1, seconds)).timeout
	_root.visible = false


func show_illustration(title: String, body: String, texture_path: String, hint: String = "Space / Enter") -> void:
	_apply_dialogue_layout()
	var texture: Texture2D = null
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		var resource := load(texture_path)
		if resource is Texture2D:
			texture = resource as Texture2D

	if texture == null:
		await show_message(title, body, hint)
		return

	_illustration_texture.texture = texture
	_illustration_panel.visible = true
	_title_label.text = title
	_body_label.text = body
	_hint_label.text = hint
	_root.visible = true
	_waiting = true
	await advanced
	_waiting = false
	_root.visible = false
	_illustration_panel.visible = false
	_illustration_texture.texture = null


func show_illustration_for(title: String, body: String, texture_path: String, seconds: float = 1.2, hint: String = "Auto") -> void:
	_apply_dialogue_layout()
	var texture: Texture2D = null
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		var resource := load(texture_path)
		if resource is Texture2D:
			texture = resource as Texture2D

	if texture == null:
		await show_message_for(title, body, seconds, hint)
		return

	_illustration_texture.texture = texture
	_illustration_panel.visible = true
	_title_label.text = title
	_body_label.text = body
	_hint_label.text = hint
	_root.visible = true
	_waiting = false
	await get_tree().create_timer(maxf(0.1, seconds)).timeout
	_root.visible = false
	_illustration_panel.visible = false
	_illustration_texture.texture = null


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting:
		return
	var accepts_dialogic := InputMap.has_action("dialogic_default_action") and event.is_action_pressed("dialogic_default_action")
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or accepts_dialogic:
		get_viewport().set_input_as_handled()
		advanced.emit()


func _build_controls() -> void:
	_root = Control.new()
	_root.name = "DreamDialogueRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_dim_rect = ColorRect.new()
	_dim_rect.name = "Dim"
	_dim_rect.color = Color(0.02, 0.025, 0.035, 0.42)
	_dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_dim_rect)

	_illustration_panel = PanelContainer.new()
	_illustration_panel.name = "IllustrationPanel"
	_illustration_panel.anchor_left = 0.08
	_illustration_panel.anchor_right = 0.92
	_illustration_panel.anchor_top = 0.06
	_illustration_panel.anchor_bottom = 0.70
	_illustration_panel.clip_contents = true
	GameThemeScript.style_rpg_panel(_illustration_panel, Color("#100c09", 0.78))
	_root.add_child(_illustration_panel)

	_illustration_texture = TextureRect.new()
	_illustration_texture.name = "IllustrationTexture"
	_illustration_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_illustration_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_illustration_texture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_illustration_texture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_illustration_panel.add_child(_illustration_texture)
	_illustration_panel.visible = false

	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.name = "DialoguePanel"
	_root.add_child(_dialogue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	_dialogue_panel.add_child(margin)

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
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.custom_minimum_size = Vector2(0, 82)
	_body_label.add_theme_font_size_override("normal_font_size", 16)
	stack.add_child(_body_label)

	_hint_label = Label.new()
	_hint_label.name = "Hint"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_size_override("font_size", 12)
	stack.add_child(_hint_label)
	_apply_dialogue_layout()


func _apply_dialogue_layout() -> void:
	if _dim_rect != null:
		_dim_rect.visible = not _review_subtitle_mode

	if _illustration_panel != null:
		if _review_subtitle_mode:
			_illustration_panel.anchor_left = 0.06
			_illustration_panel.anchor_right = 0.94
			_illustration_panel.anchor_top = 0.04
			_illustration_panel.anchor_bottom = 0.78
		else:
			_illustration_panel.anchor_left = 0.08
			_illustration_panel.anchor_right = 0.92
			_illustration_panel.anchor_top = 0.06
			_illustration_panel.anchor_bottom = 0.70

	if _dialogue_panel != null:
		if _review_subtitle_mode:
			_dialogue_panel.anchor_left = 0.04
			_dialogue_panel.anchor_right = 0.96
			_dialogue_panel.anchor_top = 0.80
			_dialogue_panel.anchor_bottom = 0.985
			_style_subtitle_panel(_dialogue_panel)
		else:
			_dialogue_panel.anchor_left = 0.08
			_dialogue_panel.anchor_right = 0.92
			_dialogue_panel.anchor_top = 0.68
			_dialogue_panel.anchor_bottom = 0.95
			GameThemeScript.style_dialogue_panel(_dialogue_panel)

	if _title_label != null:
		_title_label.add_theme_font_size_override("font_size", 15 if _review_subtitle_mode else 18)
	if _body_label != null:
		_body_label.fit_content = false if _review_subtitle_mode else true
		_body_label.custom_minimum_size = Vector2(0, 58 if _review_subtitle_mode else 82)
		_body_label.add_theme_font_size_override("normal_font_size", 18 if _review_subtitle_mode else 16)
	if _hint_label != null:
		_hint_label.visible = not _review_subtitle_mode


func _style_subtitle_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#050403", 0.78)
	style.border_color = GameThemeScript.COLORS.border_light
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
