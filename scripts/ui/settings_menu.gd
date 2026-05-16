class_name SettingsMenu
extends PanelContainer

signal fullscreen_changed(enabled: bool)
signal master_volume_changed(value: float)
signal visual_style_changed(value: String)
signal back_requested

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")

var fullscreen_check: CheckBox
var visual_style_button: Button
var volume_slider: HSlider
var volume_label: Label
var selected_visual_style := GameThemeScript.STYLE_SUNLIT_MMO


func _ready() -> void:
	_apply_panel_style()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	add_child(box)

	var title := GameThemeScript.make_label("SettingsTitle", 23, GameThemeScript.COLORS.gold)
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	fullscreen_check = CheckBox.new()
	GameThemeScript.style_command_button(fullscreen_check, "全屏")
	fullscreen_check.custom_minimum_size = Vector2(320, 42)
	fullscreen_check.toggled.connect(func(enabled: bool): fullscreen_changed.emit(enabled))
	box.add_child(fullscreen_check)

	visual_style_button = GameThemeScript.make_command_button("SettingsVisualStyle", "")
	visual_style_button.custom_minimum_size = Vector2(320, 42)
	visual_style_button.pressed.connect(_cycle_visual_style)
	box.add_child(visual_style_button)
	_update_visual_style_label()

	volume_label = GameThemeScript.make_label("SettingsVolumeLabel", 17, GameThemeScript.COLORS.text)
	box.add_child(volume_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.focus_mode = Control.FOCUS_ALL
	volume_slider.custom_minimum_size = Vector2(320, 34)
	volume_slider.add_theme_stylebox_override("slider", _make_slider_track())
	volume_slider.add_theme_stylebox_override("grabber_area", _make_slider_fill())
	volume_slider.add_theme_stylebox_override("grabber_area_highlight", _make_slider_fill(true))
	volume_slider.focus_entered.connect(func() -> void:
		volume_label.add_theme_color_override("font_color", GameThemeScript.COLORS.gold)
	)
	volume_slider.focus_exited.connect(func() -> void:
		volume_label.add_theme_color_override("font_color", GameThemeScript.COLORS.text)
	)
	volume_slider.value_changed.connect(func(value: float):
		_set_volume_label(value)
		master_volume_changed.emit(value)
	)
	box.add_child(volume_slider)

	var back := GameThemeScript.make_command_button("SettingsBack", "返回")
	back.custom_minimum_size = Vector2(320, 42)
	back.pressed.connect(back_requested.emit)
	box.add_child(back)


func set_fullscreen(enabled: bool) -> void:
	fullscreen_check.button_pressed = enabled


func set_master_volume(value: float) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	volume_slider.set_value_no_signal(clamped)
	_set_volume_label(clamped)


func set_visual_style(value: String) -> void:
	selected_visual_style = GameThemeScript.normalize_visual_style(value)
	_update_visual_style_label()


func focus_default() -> void:
	if fullscreen_check != null:
		fullscreen_check.grab_focus()


func _set_volume_label(value: float) -> void:
	volume_label.text = "主音量 %d%%" % int(round(value * 100.0))


func _cycle_visual_style() -> void:
	set_visual_style(GameThemeScript.next_visual_style(selected_visual_style))
	visual_style_changed.emit(selected_visual_style)


func _update_visual_style_label() -> void:
	if visual_style_button != null:
		visual_style_button.text = "  视觉风格：%s" % GameThemeScript.visual_style_label(selected_visual_style)


func _apply_panel_style() -> void:
	GameThemeScript.style_dialogue_panel(self)


func _make_slider_track() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = GameThemeScript.COLORS.panel_deep
	style.border_color = GameThemeScript.COLORS.border_shadow
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style


func _make_slider_fill(highlighted: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = GameThemeScript.COLORS.border_light if highlighted else GameThemeScript.COLORS.gold
	style.border_color = GameThemeScript.COLORS.border_shadow
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style
