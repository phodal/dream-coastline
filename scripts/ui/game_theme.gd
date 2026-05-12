class_name GameTheme
extends RefCounted

const COLORS := {
	"background": Color("#07090d"),
	"panel": Color("#11161c"),
	"panel_alt": Color("#171c25"),
	"panel_deep": Color("#0b0e13"),
	"border": Color("#758ba0"),
	"gold": Color("#d7b15e"),
	"cyan": Color("#65cbd8"),
	"text": Color("#f1ead4"),
	"muted": Color("#a9b0ad"),
	"danger": Color("#d45c55"),
}


static func make_panel(panel_name: String, color: Color = COLORS.panel) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = COLORS.border
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
	panel.add_theme_stylebox_override("panel", style)
	return panel


static func make_label(label_name: String, font_size: int, color: Color = COLORS.text) -> Label:
	var label := Label.new()
	label.name = label_name
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


static func make_button(button_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(270, 40)
	button.add_theme_font_size_override("font_size", 16)
	return button
