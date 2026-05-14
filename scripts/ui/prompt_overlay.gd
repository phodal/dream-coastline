class_name PromptOverlay
extends PanelContainer

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")

var location_label: Label
var prompt_label: Label
var feedback_label: Label


func _ready() -> void:
	GameThemeScript.style_dialogue_panel(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	var first_line := HBoxContainer.new()
	first_line.add_theme_constant_override("separation", 12)
	box.add_child(first_line)

	location_label = GameThemeScript.make_label("Location", 17, GameThemeScript.COLORS.gold)
	location_label.custom_minimum_size = Vector2(150, 26)
	first_line.add_child(location_label)

	prompt_label = GameThemeScript.make_label("Prompt", 18, GameThemeScript.COLORS.text)
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_label.custom_minimum_size = Vector2(420, 28)
	first_line.add_child(prompt_label)

	feedback_label = GameThemeScript.make_label("LatestFeedback", 16, GameThemeScript.COLORS.paper)
	feedback_label.custom_minimum_size = Vector2(420, 36)
	box.add_child(feedback_label)


func refresh(location_name: String, prompt_text: String, latest_feedback: String) -> void:
	location_label.text = location_name
	prompt_label.text = prompt_text
	if latest_feedback.is_empty():
		feedback_label.text = "沿着地图移动，靠近发光或可疑的物件。"
	else:
		feedback_label.text = latest_feedback
