class_name DreamStoryReviewOverlay
extends CanvasLayer

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")

signal scene_requested(index: int)
signal autoplay_requested
signal pause_requested
signal step_requested
signal close_requested

var _root: Control
var _background_texture: TextureRect
var _panel: PanelContainer
var _left_column: VBoxContainer
var _preview_panel: PanelContainer
var _preview_canvas: Control
var _preview_texture: TextureRect
var _character_layer: HBoxContainer
var _visual_title_label: Label
var _visual_caption_label: RichTextLabel
var _scene_list: ItemList
var _status_label: Label
var _last_line_label: RichTextLabel
var _flags_label: Label
var _autoplay_button: Button
var _pause_button: Button
var _step_button: Button
var _command_row: HBoxContainer
var _pending_scenes: Array[Dictionary] = []
var _current_background_path := ""
var _current_focus_path := ""
var _current_character_signature := ""
var _cinema_mode := false


func _ready() -> void:
	layer = 18
	_build_controls()
	if not _pending_scenes.is_empty():
		configure(_pending_scenes)
	_root.visible = false


func _input(event: InputEvent) -> void:
	if _root == null or not _root.visible:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.is_pressed() or key_event.is_echo():
		return
	match key_event.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			scene_requested.emit(selected_scene_index())
		KEY_A:
			autoplay_requested.emit()
		KEY_P:
			pause_requested.emit()
		KEY_N:
			step_requested.emit()
		KEY_ESCAPE:
			close_requested.emit()
		_:
			return
	get_viewport().set_input_as_handled()


func configure(scenes: Array[Dictionary]) -> void:
	if _scene_list == null:
		_pending_scenes = scenes.duplicate(true)
		return
	_pending_scenes.clear()
	_scene_list.clear()
	for index in range(scenes.size()):
		var scene := scenes[index]
		_scene_list.add_item("%02d  %s" % [index, str(scene.get("title", scene.get("id", "")))])
	if scenes.size() > 0:
		_scene_list.select(0)


func show_selector() -> void:
	if _root != null:
		_root.visible = true


func hide_selector() -> void:
	if _root != null:
		_root.visible = false


func selected_scene_index() -> int:
	if _scene_list == null:
		return 0
	var selected := _scene_list.get_selected_items()
	if selected.is_empty():
		return 0
	return int(selected[0])


func scene_count() -> int:
	if _scene_list == null:
		return 0
	return _scene_list.item_count


func set_cinema_mode(enabled: bool) -> void:
	_cinema_mode = enabled
	if _root != null:
		_apply_layout_mode()


func update_status(status: Dictionary) -> void:
	if _status_label == null:
		return
	var running := bool(status.get("running", false))
	var paused := bool(status.get("paused", false))
	var step_index := int(status.get("step_index", 0))
	var step_count := int(status.get("step_count", 0))
	var location_name := str(status.get("location_name", ""))
	var prefix_note := str(status.get("prefix_note", ""))
	_set_illustration(str(status.get("background_path", "")), str(status.get("focus_path", "")))
	_set_character_cutouts(status.get("characters", []))
	_visual_title_label.text = str(status.get("illustration_title", ""))
	_visual_caption_label.text = str(status.get("illustration_caption", ""))
	_status_label.text = "%s\n%s\nStep %d/%d%s" % [
		str(status.get("scene_title", "")),
		location_name,
		step_index,
		step_count,
		"\n" + prefix_note if not prefix_note.is_empty() else "",
	]
	_last_line_label.text = str(status.get("last_line", ""))
	_flags_label.text = "Flags: %s" % str(status.get("flags", ""))
	GameThemeScript.set_command_button_text(_autoplay_button, "停止自动播放" if running else "自动播放")
	GameThemeScript.set_command_button_text(_pause_button, "继续" if paused else "暂停")
	_pause_button.disabled = not running
	_step_button.disabled = running and not paused
	_apply_layout_mode()


func _build_controls() -> void:
	_root = Control.new()
	_root.name = "StoryReviewRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_background_texture = TextureRect.new()
	_background_texture.name = "ChapterIllustrationBackground"
	_background_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_root.add_child(_background_texture)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.02, 0.018, 0.014, 0.44)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	_panel = GameThemeScript.make_rpg_panel("StoryReviewPanel", Color("#100c09", 0.76))
	_root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	margin.add_child(columns)

	_left_column = VBoxContainer.new()
	_left_column.custom_minimum_size = Vector2(210, 0)
	_left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_column.add_theme_constant_override("separation", 10)
	columns.add_child(_left_column)

	var title := GameThemeScript.make_label("Title", 20, GameThemeScript.COLORS.paper)
	title.text = "剧情验收"
	_left_column.add_child(title)

	_scene_list = ItemList.new()
	_scene_list.name = "SceneList"
	_scene_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_list.custom_minimum_size = Vector2(190, 230)
	_scene_list.item_activated.connect(func(index: int) -> void:
		scene_requested.emit(index)
	)
	_left_column.add_child(_scene_list)

	var start_button := GameThemeScript.make_command_button("StartScene", "进入选中章节")
	start_button.custom_minimum_size = Vector2(190, 38)
	start_button.pressed.connect(func() -> void:
		scene_requested.emit(selected_scene_index())
	)
	_left_column.add_child(start_button)

	_autoplay_button = GameThemeScript.make_command_button("Autoplay", "自动播放")
	_autoplay_button.custom_minimum_size = Vector2(190, 38)
	_autoplay_button.pressed.connect(func() -> void:
		autoplay_requested.emit()
	)
	_left_column.add_child(_autoplay_button)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	columns.add_child(right)

	_preview_panel = GameThemeScript.make_rpg_panel("ChapterPreview", Color("#100c09", 0.72))
	_preview_panel.custom_minimum_size = Vector2(0, 390)
	right.add_child(_preview_panel)

	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 10)
	preview_margin.add_theme_constant_override("margin_right", 10)
	preview_margin.add_theme_constant_override("margin_top", 10)
	preview_margin.add_theme_constant_override("margin_bottom", 10)
	_preview_panel.add_child(preview_margin)

	var preview_stack := VBoxContainer.new()
	preview_stack.add_theme_constant_override("separation", 8)
	preview_margin.add_child(preview_stack)

	_preview_canvas = Control.new()
	_preview_canvas.name = "ChapterPreviewCanvas"
	_preview_canvas.clip_contents = true
	_preview_canvas.custom_minimum_size = Vector2(0, 292)
	_preview_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_stack.add_child(_preview_canvas)

	_preview_texture = TextureRect.new()
	_preview_texture.name = "ChapterPreviewTexture"
	_preview_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview_canvas.add_child(_preview_texture)

	_character_layer = HBoxContainer.new()
	_character_layer.name = "CharacterCutoutLayer"
	_character_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_character_layer.anchor_left = 0.03
	_character_layer.anchor_right = 0.97
	_character_layer.anchor_top = 0.16
	_character_layer.anchor_bottom = 0.98
	_character_layer.add_theme_constant_override("separation", 16)
	_character_layer.alignment = BoxContainer.ALIGNMENT_CENTER
	_preview_canvas.add_child(_character_layer)

	_visual_title_label = GameThemeScript.make_label("VisualTitle", 17, GameThemeScript.COLORS.paper)
	_visual_title_label.custom_minimum_size = Vector2(0, 24)
	preview_stack.add_child(_visual_title_label)

	_visual_caption_label = RichTextLabel.new()
	_visual_caption_label.name = "VisualCaption"
	_visual_caption_label.bbcode_enabled = false
	_visual_caption_label.fit_content = false
	_visual_caption_label.scroll_active = false
	_visual_caption_label.custom_minimum_size = Vector2(0, 54)
	_visual_caption_label.add_theme_font_size_override("normal_font_size", 14)
	preview_stack.add_child(_visual_caption_label)

	_status_label = GameThemeScript.make_label("Status", 16, GameThemeScript.COLORS.text)
	_status_label.custom_minimum_size = Vector2(0, 86)
	right.add_child(_status_label)

	_last_line_label = RichTextLabel.new()
	_last_line_label.name = "LastLine"
	_last_line_label.bbcode_enabled = false
	_last_line_label.fit_content = false
	_last_line_label.scroll_active = false
	_last_line_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_last_line_label.add_theme_font_size_override("normal_font_size", 16)
	right.add_child(_last_line_label)

	_flags_label = GameThemeScript.make_label("Flags", 12, GameThemeScript.COLORS.muted)
	_flags_label.custom_minimum_size = Vector2(0, 44)
	right.add_child(_flags_label)

	_command_row = HBoxContainer.new()
	_command_row.add_theme_constant_override("separation", 10)
	right.add_child(_command_row)

	_pause_button = GameThemeScript.make_command_button("Pause", "暂停")
	_pause_button.custom_minimum_size = Vector2(150, 40)
	_pause_button.pressed.connect(func() -> void:
		pause_requested.emit()
	)
	_command_row.add_child(_pause_button)

	_step_button = GameThemeScript.make_command_button("Step", "下一步")
	_step_button.custom_minimum_size = Vector2(150, 40)
	_step_button.pressed.connect(func() -> void:
		step_requested.emit()
	)
	_command_row.add_child(_step_button)

	var close_button := GameThemeScript.make_command_button("Close", "回到游戏")
	close_button.custom_minimum_size = Vector2(150, 40)
	close_button.pressed.connect(func() -> void:
		close_requested.emit()
	)
	_command_row.add_child(close_button)
	_apply_layout_mode()


func _apply_layout_mode() -> void:
	if _panel == null:
		return
	if _cinema_mode:
		_panel.anchor_left = 0.025
		_panel.anchor_top = 0.035
		_panel.anchor_right = 0.975
		_panel.anchor_bottom = 0.785
	else:
		_panel.anchor_left = 0.04
		_panel.anchor_top = 0.08
		_panel.anchor_right = 0.96
		_panel.anchor_bottom = 0.92

	if _left_column != null:
		_left_column.visible = not _cinema_mode
	if _status_label != null:
		_status_label.visible = not _cinema_mode
	if _last_line_label != null:
		_last_line_label.visible = not _cinema_mode
	if _flags_label != null:
		_flags_label.visible = not _cinema_mode
	if _command_row != null:
		_command_row.visible = not _cinema_mode
	if _visual_title_label != null:
		_visual_title_label.visible = not _cinema_mode
	if _visual_caption_label != null:
		_visual_caption_label.visible = not _cinema_mode

	if _preview_panel != null:
		_preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_preview_panel.custom_minimum_size = Vector2(0, 520 if _cinema_mode else 390)
	if _preview_canvas != null:
		_preview_canvas.custom_minimum_size = Vector2(0, 470 if _cinema_mode else 292)


func _set_illustration(background_path: String, focus_path: String) -> void:
	if background_path == _current_background_path and focus_path == _current_focus_path:
		return
	_current_background_path = background_path
	_current_focus_path = focus_path
	var background_texture: Texture2D = _load_texture(background_path)
	var focus_texture: Texture2D = _load_texture(focus_path if not focus_path.is_empty() else background_path)
	if _background_texture != null:
		_background_texture.texture = background_texture
	if _preview_texture != null:
		_preview_texture.texture = focus_texture


func _set_character_cutouts(characters: Array) -> void:
	if _character_layer == null:
		return
	var signature_parts: Array[String] = []
	for character in characters:
		if typeof(character) == TYPE_DICTIONARY:
			signature_parts.append("%s:%s" % [str(character.get("id", "")), str(character.get("asset_path", ""))])
	var signature := "|".join(signature_parts)
	if signature == _current_character_signature:
		return
	_current_character_signature = signature

	for child in _character_layer.get_children():
		child.queue_free()

	for character in characters:
		if typeof(character) != TYPE_DICTIONARY:
			continue
		var path := str(character.get("asset_path", ""))
		var texture := _load_texture(path)
		if texture == null:
			continue
		var cutout := TextureRect.new()
		cutout.name = "Cutout_%s" % str(character.get("id", "character"))
		cutout.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cutout.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cutout.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cutout.custom_minimum_size = Vector2(130, 0)
		cutout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cutout.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cutout.texture = texture
		_character_layer.add_child(cutout)


func _load_texture(path: String) -> Texture2D:
	if not path.is_empty() and ResourceLoader.exists(path):
		var resource := load(path)
		if resource is Texture2D:
			return resource as Texture2D
	return null
