class_name PauseMenu
extends PanelContainer

signal resume_requested
signal save_requested
signal load_requested
signal quit_requested

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")

var status_label: Label


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#080a12", 0.92)
	style.border_color = GameThemeScript.COLORS.border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 18
	style.content_margin_top = 18
	style.content_margin_right = 18
	style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var title := GameThemeScript.make_label("PauseTitle", 26, GameThemeScript.COLORS.gold)
	title.text = "暂停"
	box.add_child(title)

	box.add_child(_make_menu_button("继续", resume_requested.emit))
	box.add_child(_make_menu_button("保存", save_requested.emit))
	box.add_child(_make_menu_button("读取", load_requested.emit))
	box.add_child(_make_menu_button("退出", quit_requested.emit))

	status_label = GameThemeScript.make_label("PauseStatus", 15, GameThemeScript.COLORS.muted)
	status_label.custom_minimum_size = Vector2(300, 40)
	box.add_child(status_label)


func set_status(text: String) -> void:
	status_label.text = text


func _make_menu_button(text: String, callback: Callable) -> Button:
	var button := GameThemeScript.make_button("PauseButton", text)
	button.custom_minimum_size = Vector2(300, 42)
	button.pressed.connect(callback)
	return button
