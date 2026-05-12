class_name PromptOverlay
extends PanelContainer

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")

var location_label: Label
var prompt_label: Label
var feedback_label: Label


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#080a12", 0.68)
	style.border_color = GameThemeScript.COLORS.border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)

	location_label = GameThemeScript.make_label("Location", 22, GameThemeScript.COLORS.gold)
	box.add_child(location_label)

	prompt_label = GameThemeScript.make_label("Prompt", 18, GameThemeScript.COLORS.text)
	prompt_label.custom_minimum_size = Vector2(420, 28)
	box.add_child(prompt_label)

	feedback_label = GameThemeScript.make_label("LatestFeedback", 15, GameThemeScript.COLORS.muted)
	feedback_label.custom_minimum_size = Vector2(420, 24)
	box.add_child(feedback_label)


func refresh(location_name: String, prompt_text: String, latest_feedback: String) -> void:
	location_label.text = location_name
	prompt_label.text = prompt_text
	feedback_label.text = latest_feedback
