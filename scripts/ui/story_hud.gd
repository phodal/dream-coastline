class_name StoryHud
extends VBoxContainer

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const MAX_LOG_LINES := 8

var description_label: Label
var status_label: Label
var metrics_label: Label
var log_label: RichTextLabel


func _ready() -> void:
	add_theme_constant_override("separation", 8)

	description_label = GameThemeScript.make_label("Description", 19, GameThemeScript.COLORS.text)
	description_label.custom_minimum_size = Vector2(0, 92)
	add_child(description_label)

	status_label = GameThemeScript.make_label("Status", 16, GameThemeScript.COLORS.muted)
	status_label.custom_minimum_size = Vector2(0, 56)
	add_child(status_label)

	metrics_label = GameThemeScript.make_label("Metrics", 16, GameThemeScript.COLORS.cyan)
	metrics_label.custom_minimum_size = Vector2(0, 34)
	add_child(metrics_label)

	log_label = RichTextLabel.new()
	log_label.name = "Log"
	log_label.fit_content = false
	log_label.scroll_active = false
	log_label.bbcode_enabled = false
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.custom_minimum_size = Vector2(0, 120)
	log_label.add_theme_font_size_override("normal_font_size", 17)
	log_label.add_theme_color_override("default_color", GameThemeScript.COLORS.text)
	add_child(log_label)


func refresh(session) -> void:
	var location: Dictionary = session.current_location()
	description_label.text = str(location.get("description", ""))
	status_label.text = session.status_text()
	metrics_label.text = session.metrics_text()
	log_label.text = session.visible_log(MAX_LOG_LINES)
