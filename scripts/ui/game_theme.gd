class_name GameTheme
extends RefCounted

const COLORS := {
	"background": Color("#090807"),
	"ink": Color("#17110d"),
	"paper": Color("#eadcae"),
	"panel": Color("#17110d"),
	"panel_alt": Color("#1e1710"),
	"panel_deep": Color("#0d0b08"),
	"border": Color("#8f7040"),
	"border_light": Color("#f0d18a"),
	"border_shadow": Color("#3f2a18"),
	"gold": Color("#d7b15e"),
	"cyan": Color("#b9d1c4"),
	"text": Color("#f7edcf"),
	"muted": Color("#b7a780"),
	"danger": Color("#d45c55"),
}
const PANEL_TEXTURE_PATH := "res://assets/ui/pixel_panel_9patch.png"


static func make_panel(panel_name: String, color: Color = COLORS.panel) -> PanelContainer:
	return make_rpg_panel(panel_name, color)


static func make_rpg_panel(panel_name: String, color: Color = COLORS.panel) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	style_rpg_panel(panel, color)
	return panel


static func make_dialogue_panel(panel_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	style_dialogue_panel(panel)
	return panel


static func style_rpg_panel(panel: PanelContainer, color: Color = COLORS.panel) -> void:
	panel.add_theme_stylebox_override(
		"panel",
		_make_pixel_box(color, COLORS.border, COLORS.border_shadow, 12, 10, 12, 10)
	)


static func style_dialogue_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override(
		"panel",
		_make_pixel_box(Color("#100c09", 0.93), COLORS.border_light, COLORS.border_shadow, 18, 14, 18, 14, 3)
	)


static func make_label(label_name: String, font_size: int, color: Color = COLORS.text) -> Label:
	var label := Label.new()
	label.name = label_name
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#050608", 0.82))
	label.add_theme_constant_override("outline_size", 2)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


static func make_button(button_name: String, text: String) -> Button:
	return make_command_button(button_name, text)


static func make_command_button(button_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = button_name
	style_command_button(button, text)
	return button


static func style_command_button(button: Button, text: String) -> void:
	var idle_text := "  %s" % text
	var focus_text := "> %s" % text
	button.text = idle_text
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(270, 40)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", COLORS.text)
	button.add_theme_color_override("font_hover_color", COLORS.paper)
	button.add_theme_color_override("font_pressed_color", COLORS.gold)
	button.add_theme_color_override("font_focus_color", COLORS.paper)
	button.add_theme_color_override("font_disabled_color", Color(COLORS.muted.r, COLORS.muted.g, COLORS.muted.b, 0.52))
	button.add_theme_stylebox_override(
		"normal",
		_make_pixel_box(Color("#120e0a", 0.88), COLORS.border_shadow, COLORS.border_shadow, 12, 7, 12, 7, 2)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_pixel_box(Color("#21170f", 0.92), COLORS.border, COLORS.border_shadow, 12, 7, 12, 7, 2)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_pixel_box(Color("#2b1d10", 0.96), COLORS.gold, COLORS.border_shadow, 12, 7, 12, 7, 2)
	)
	button.add_theme_stylebox_override(
		"focus",
		_make_pixel_box(Color("#2a1f12", 0.95), COLORS.border_light, COLORS.gold, 12, 7, 12, 7, 2)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_make_pixel_box(
			Color("#0f0d0a", 0.72),
			Color(COLORS.border_shadow.r, COLORS.border_shadow.g, COLORS.border_shadow.b, 0.8),
			COLORS.border_shadow,
			12,
			7,
			12,
			7,
			2
		)
	)
	button.focus_entered.connect(func() -> void:
		button.text = focus_text
	)
	button.focus_exited.connect(func() -> void:
		button.text = idle_text
	)


static func _make_pixel_box(
	bg_color: Color,
	border_color: Color,
	shadow_color: Color,
	margin_left: int,
	margin_top: int,
	margin_right: int,
	margin_bottom: int,
	border_width: int = 2
) -> StyleBox:
	if ResourceLoader.exists(PANEL_TEXTURE_PATH):
		var texture_resource: Resource = load(PANEL_TEXTURE_PATH)
		if texture_resource is Texture2D:
			var texture_style := StyleBoxTexture.new()
			texture_style.texture = texture_resource as Texture2D
			texture_style.texture_margin_left = 6
			texture_style.texture_margin_top = 6
			texture_style.texture_margin_right = 6
			texture_style.texture_margin_bottom = 6
			texture_style.content_margin_left = margin_left
			texture_style.content_margin_top = margin_top
			texture_style.content_margin_right = margin_right
			texture_style.content_margin_bottom = margin_bottom
			return texture_style
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = margin_left
	style.content_margin_top = margin_top
	style.content_margin_right = margin_right
	style.content_margin_bottom = margin_bottom
	style.shadow_color = shadow_color
	style.shadow_size = 4
	style.shadow_offset = Vector2(3, 3)
	return style
