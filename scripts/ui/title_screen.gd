class_name TitleScreen
extends PanelContainer

signal new_game_requested
signal continue_requested
signal settings_requested
signal quit_requested

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")

var continue_button: Button
var status_label: Label
var pending_continue_enabled := false
var new_game_button: Button
var menu_buttons: Array[Button] = []
var selected_index := 0


func _ready() -> void:
	_apply_panel_style()
	menu_buttons.clear()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	add_child(box)

	var title := GameThemeScript.make_label("GameTitle", 27, GameThemeScript.COLORS.gold)
	title.text = "Dream Coastline"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var subtitle := GameThemeScript.make_label("Subtitle", 15, GameThemeScript.COLORS.muted)
	subtitle.text = "灯未亮起的夜晚"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	_add_separator(box)

	new_game_button = _make_button("新游戏", new_game_requested.emit)
	box.add_child(new_game_button)
	continue_button = _make_button("继续", continue_requested.emit)
	box.add_child(continue_button)
	box.add_child(_make_button("设置", settings_requested.emit))
	box.add_child(_make_button("退出", quit_requested.emit))

	status_label = GameThemeScript.make_label("TitleStatus", 15, GameThemeScript.COLORS.muted)
	status_label.custom_minimum_size = Vector2(292, 34)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(status_label)
	set_continue_enabled(pending_continue_enabled)


func set_continue_enabled(enabled: bool) -> void:
	pending_continue_enabled = enabled
	if continue_button != null:
		continue_button.disabled = not enabled
		if visible and continue_button.disabled and _selected_button() == continue_button:
			focus_default()


func set_status(text: String) -> void:
	status_label.text = text


func focus_default() -> void:
	if visible:
		_focus_selectable(0, 1)


func select_next() -> bool:
	return _focus_selectable(selected_index + 1, 1)


func select_previous() -> bool:
	return _focus_selectable(selected_index - 1, -1)


func activate_selected() -> bool:
	var button := _selected_button()
	if button == null:
		return false
	button.grab_focus()
	button.pressed.emit()
	return true


func activate_at(global_position: Vector2) -> bool:
	for index in range(menu_buttons.size()):
		var button := menu_buttons[index]
		if _is_button_selectable(button) and button.get_global_rect().has_point(global_position):
			selected_index = index
			button.grab_focus()
			button.pressed.emit()
			return true
	return false


func _make_button(text: String, callback: Callable) -> Button:
	var button := GameThemeScript.make_command_button("TitleButton", text)
	button.custom_minimum_size = Vector2(292, 38)
	button.pressed.connect(callback)
	menu_buttons.append(button)
	button.focus_entered.connect(func() -> void:
		var index := menu_buttons.find(button)
		if index >= 0:
			selected_index = index
	)
	return button


func _selected_button() -> Button:
	if selected_index >= 0 and selected_index < menu_buttons.size():
		var button := menu_buttons[selected_index]
		if _is_button_selectable(button):
			return button
	if _focus_selectable(0, 1):
		return menu_buttons[selected_index]
	return null


func _focus_selectable(start_index: int, step: int) -> bool:
	if menu_buttons.is_empty():
		return false
	var count := menu_buttons.size()
	var index := posmod(start_index, count)
	for _attempt in range(count):
		var button := menu_buttons[index]
		if _is_button_selectable(button):
			selected_index = index
			button.grab_focus()
			return true
		index = posmod(index + step, count)
	return false


func _is_button_selectable(button: Button) -> bool:
	return button != null and button.visible and button.is_inside_tree() and not button.disabled


func _apply_panel_style() -> void:
	GameThemeScript.style_dialogue_panel(self)


func _add_separator(box: VBoxContainer) -> void:
	var separator := ColorRect.new()
	separator.color = Color(GameThemeScript.COLORS.border_light.r, GameThemeScript.COLORS.border_light.g, GameThemeScript.COLORS.border_light.b, 0.38)
	separator.custom_minimum_size = Vector2(0, 2)
	box.add_child(separator)
