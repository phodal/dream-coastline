class_name SettingsMenu
extends PanelContainer

signal fullscreen_changed(enabled: bool)
signal back_requested

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")

var fullscreen_check: CheckBox


func _ready() -> void:
	_apply_panel_style()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	var title := GameThemeScript.make_label("SettingsTitle", 26, GameThemeScript.COLORS.gold)
	title.text = "设置"
	box.add_child(title)

	fullscreen_check = CheckBox.new()
	fullscreen_check.text = "全屏"
	fullscreen_check.add_theme_font_size_override("font_size", 18)
	fullscreen_check.add_theme_color_override("font_color", GameThemeScript.COLORS.text)
	fullscreen_check.toggled.connect(func(enabled: bool): fullscreen_changed.emit(enabled))
	box.add_child(fullscreen_check)

	var back := GameThemeScript.make_button("SettingsBack", "返回")
	back.custom_minimum_size = Vector2(300, 42)
	back.pressed.connect(back_requested.emit)
	box.add_child(back)


func set_fullscreen(enabled: bool) -> void:
	fullscreen_check.button_pressed = enabled


func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#080a12", 0.94)
	style.border_color = GameThemeScript.COLORS.border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 20
	style.content_margin_top = 18
	style.content_margin_right = 20
	style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", style)
