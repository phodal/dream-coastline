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
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	var title := GameThemeScript.make_label("GameTitle", 28, GameThemeScript.COLORS.gold)
	title.text = "Dream Coastline"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var subtitle := GameThemeScript.make_label("Subtitle", 15, GameThemeScript.COLORS.muted)
	subtitle.text = "灯未亮起的夜晚"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	if new_game_button != null and new_game_button.is_inside_tree():
		new_game_button.grab_focus()


func _make_button(text: String, callback: Callable) -> Button:
	var button := GameThemeScript.make_command_button("TitleButton", text)
	button.custom_minimum_size = Vector2(320, 42)
	button.pressed.connect(callback)
	return button


func _apply_panel_style() -> void:
	GameThemeScript.style_dialogue_panel(self)
