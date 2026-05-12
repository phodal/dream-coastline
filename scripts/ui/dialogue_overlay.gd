class_name DialogueOverlay
extends PanelContainer

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")

var location_label: Label
var prompt_label: Label
var log_label: RichTextLabel


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#080a12", 0.76)
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

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)

	location_label = GameThemeScript.make_label("Location", 22, GameThemeScript.COLORS.gold)
	left.add_child(location_label)

	prompt_label = GameThemeScript.make_label("Prompt", 17, GameThemeScript.COLORS.text)
	prompt_label.custom_minimum_size = Vector2(0, 44)
	left.add_child(prompt_label)

	log_label = RichTextLabel.new()
	log_label.name = "CompactLog"
	log_label.custom_minimum_size = Vector2(480, 88)
	log_label.fit_content = false
	log_label.scroll_active = false
	log_label.bbcode_enabled = false
	log_label.add_theme_font_size_override("normal_font_size", 16)
	log_label.add_theme_color_override("default_color", GameThemeScript.COLORS.text)
	row.add_child(log_label)


func refresh(location_name: String, prompt_text: String, event_log: String) -> void:
	location_label.text = location_name
	prompt_label.text = prompt_text
	log_label.text = event_log
