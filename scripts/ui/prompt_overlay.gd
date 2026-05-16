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
	box.add_theme_constant_override("separation", 5)
	add_child(box)

	var first_line := HBoxContainer.new()
	first_line.add_theme_constant_override("separation", 10)
	box.add_child(first_line)

	location_label = GameThemeScript.make_label("Location", 17, GameThemeScript.COLORS.gold)
	location_label.custom_minimum_size = Vector2(146, 28)
	first_line.add_child(location_label)

	var divider := ColorRect.new()
	divider.color = Color(GameThemeScript.COLORS.border.r, GameThemeScript.COLORS.border.g, GameThemeScript.COLORS.border.b, 0.7)
	divider.custom_minimum_size = Vector2(2, 28)
	first_line.add_child(divider)

	prompt_label = GameThemeScript.make_label("Prompt", 18, GameThemeScript.COLORS.paper)
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_label.custom_minimum_size = Vector2(420, 28)
	first_line.add_child(prompt_label)

	var accent := ColorRect.new()
	accent.color = Color(GameThemeScript.COLORS.border_light.r, GameThemeScript.COLORS.border_light.g, GameThemeScript.COLORS.border_light.b, 0.42)
	accent.custom_minimum_size = Vector2(0, 2)
	box.add_child(accent)

	feedback_label = GameThemeScript.make_label("LatestFeedback", 16, GameThemeScript.COLORS.text)
	feedback_label.custom_minimum_size = Vector2(420, 42)
	box.add_child(feedback_label)


func refresh(location_name: String, prompt_text: String, latest_feedback: String) -> void:
	location_label.text = location_name
	prompt_label.text = prompt_text
	if latest_feedback.is_empty():
		feedback_label.text = "沿着地图移动，靠近发光或可疑的物件。"
	else:
		feedback_label.text = latest_feedback
