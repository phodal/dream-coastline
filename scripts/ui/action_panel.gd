class_name ActionPanel
extends ScrollContainer

signal action_requested(action: Dictionary)

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
var grid: GridContainer


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	grid = GridContainer.new()
	grid.name = "ActionGrid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(grid)


func refresh(session) -> void:
	for child in grid.get_children():
		child.queue_free()

	for group in session.action_groups():
		_add_header(str(group["title"]))
		for action in group["actions"]:
			_add_button(action)


func _add_header(text: String) -> void:
	var label := GameThemeScript.make_label("Header", 16, GameThemeScript.COLORS.gold)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(270, 30)
	grid.add_child(label)


func _add_button(action: Dictionary) -> void:
	var button := GameThemeScript.make_button("Action", str(action.get("label", "")))
	button.tooltip_text = str(action.get("label", ""))
	button.pressed.connect(func(): action_requested.emit(action))
	grid.add_child(button)
