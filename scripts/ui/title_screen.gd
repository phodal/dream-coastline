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


func _ready() -> void:
	_apply_panel_style()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var title := GameThemeScript.make_label("GameTitle", 30, GameThemeScript.COLORS.gold)
	title.text = "Dream Coastline"
	box.add_child(title)

	var subtitle := GameThemeScript.make_label("Subtitle", 16, GameThemeScript.COLORS.muted)
	subtitle.text = "灯未亮起的夜晚"
	box.add_child(subtitle)

	new_game_button = _make_button("新游戏", new_game_requested.emit)
	box.add_child(new_game_button)
	continue_button = _make_button("继续", continue_requested.emit)
	box.add_child(continue_button)
	box.add_child(_make_button("设置", settings_requested.emit))
	box.add_child(_make_button("退出", quit_requested.emit))

	status_label = GameThemeScript.make_label("TitleStatus", 15, GameThemeScript.COLORS.muted)
	status_label.custom_minimum_size = Vector2(320, 36)
	box.add_child(status_label)
	set_continue_enabled(pending_continue_enabled)


func set_continue_enabled(enabled: bool) -> void:
	pending_continue_enabled = enabled
	if continue_button != null:
		continue_button.disabled = not enabled


func set_status(text: String) -> void:
	status_label.text = text


func focus_default() -> void:
	if new_game_button != null:
		new_game_button.grab_focus()


func _make_button(text: String, callback: Callable) -> Button:
	var button := GameThemeScript.make_button("TitleButton", text)
	button.custom_minimum_size = Vector2(320, 42)
	button.pressed.connect(callback)
	return button


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
