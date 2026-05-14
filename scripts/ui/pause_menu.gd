class_name PauseMenu
extends PanelContainer

signal resume_requested
signal save_requested
signal load_requested
signal quit_requested

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")

var status_label: Label
var resume_button: Button


func _ready() -> void:
	GameThemeScript.style_dialogue_panel(self)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	var title := GameThemeScript.make_label("PauseTitle", 23, GameThemeScript.COLORS.gold)
	title.text = "暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	resume_button = _make_menu_button("继续", resume_requested.emit)
	box.add_child(resume_button)
	box.add_child(_make_menu_button("保存", save_requested.emit))
	box.add_child(_make_menu_button("读取", load_requested.emit))
	box.add_child(_make_menu_button("返回标题", quit_requested.emit))

	status_label = GameThemeScript.make_label("PauseStatus", 15, GameThemeScript.COLORS.muted)
	status_label.custom_minimum_size = Vector2(300, 40)
	box.add_child(status_label)


func set_status(text: String) -> void:
	status_label.text = text


func focus_default() -> void:
	if resume_button != null:
		resume_button.grab_focus()


func _make_menu_button(text: String, callback: Callable) -> Button:
	var button := GameThemeScript.make_command_button("PauseButton", text)
	button.custom_minimum_size = Vector2(300, 42)
	button.pressed.connect(callback)
	return button
