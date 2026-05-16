class_name GameTheme
extends RefCounted

const STYLE_SUNLIT_MMO := "sunlit_mmo"
const STYLE_CLASSIC_DARK := "classic_dark"
const STYLE_ORDER := [STYLE_SUNLIT_MMO, STYLE_CLASSIC_DARK]
const PANEL_TEXTURE_PATH := "res://assets/ui/pixel_panel_9patch.png"

const STYLE_LABELS := {
	STYLE_SUNLIT_MMO: "绿色阳光",
	STYLE_CLASSIC_DARK: "经典暗色",
}

const STYLE_PROFILES := {
	STYLE_SUNLIT_MMO: {
		"background": Color("#172218"),
		"ink": Color("#20351f"),
		"paper": Color("#fff4ce"),
		"panel": Color("#20351f"),
		"panel_alt": Color("#2c4429"),
		"panel_deep": Color("#142416"),
		"border": Color("#96b45e"),
		"border_light": Color("#f3dc8a"),
		"border_shadow": Color("#465b2a"),
		"gold": Color("#e7bd54"),
		"cyan": Color("#bfe2d4"),
		"text": Color("#fff8df"),
		"muted": Color("#ccd79c"),
		"danger": Color("#d45c55"),
		"dialogue_panel": Color("#1d2f1c", 0.9),
		"button_normal": Color("#20351f", 0.86),
		"button_hover": Color("#2f4d2b", 0.92),
		"button_pressed": Color("#45612f", 0.96),
		"button_focus": Color("#3f5f31", 0.95),
		"button_disabled": Color("#0f0d0a", 0.72),
	},
	STYLE_CLASSIC_DARK: {
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
		"dialogue_panel": Color("#100c09", 0.93),
		"button_normal": Color("#120e0a", 0.88),
		"button_hover": Color("#21170f", 0.92),
		"button_pressed": Color("#2b1d10", 0.96),
		"button_focus": Color("#2a1f12", 0.95),
		"button_disabled": Color("#0f0d0a", 0.72),
	},
}

static var current_style := STYLE_SUNLIT_MMO
static var COLORS := STYLE_PROFILES[STYLE_SUNLIT_MMO].duplicate(true)


static func normalize_visual_style(value: String) -> String:
	if STYLE_PROFILES.has(value):
		return value
	return STYLE_SUNLIT_MMO


static func set_visual_style(value: String) -> void:
	current_style = normalize_visual_style(value)
	COLORS = STYLE_PROFILES[current_style].duplicate(true)


static func visual_style() -> String:
	return current_style


static func visual_style_label(value: String = "") -> String:
	var style := normalize_visual_style(current_style if value.is_empty() else value)
	return str(STYLE_LABELS.get(style, style))


static func next_visual_style(value: String = "") -> String:
	var style := normalize_visual_style(current_style if value.is_empty() else value)
	var index := STYLE_ORDER.find(style)
	if index < 0:
		return STYLE_SUNLIT_MMO
	return str(STYLE_ORDER[(index + 1) % STYLE_ORDER.size()])


static func effective_visual_mood(base_mood: String) -> String:
	if current_style == STYLE_CLASSIC_DARK and base_mood == "sunlit":
		return "neutral"
	return base_mood


static func make_panel(panel_name: String, color: Color = Color.TRANSPARENT) -> PanelContainer:
	return make_rpg_panel(panel_name, color)


static func make_rpg_panel(panel_name: String, color: Color = Color.TRANSPARENT) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	style_rpg_panel(panel, color)
	return panel


static func make_dialogue_panel(panel_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	style_dialogue_panel(panel)
	return panel


static func style_rpg_panel(panel: PanelContainer, color: Color = Color.TRANSPARENT) -> void:
	var panel_color: Color = COLORS.panel if color == Color.TRANSPARENT else color
	panel.add_theme_stylebox_override(
		"panel",
		_make_pixel_box(panel_color, COLORS.border, COLORS.border_shadow, 12, 10, 12, 10)
	)


static func style_dialogue_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override(
		"panel",
		_make_pixel_box(COLORS.dialogue_panel, COLORS.border_light, COLORS.border_shadow, 18, 14, 18, 14, 3)
	)


static func make_label(label_name: String, font_size: int, color: Color = Color.TRANSPARENT) -> Label:
	var label := Label.new()
	label.name = label_name
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", COLORS.text if color == Color.TRANSPARENT else color)
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
		_make_pixel_box(COLORS.button_normal, COLORS.border_shadow, COLORS.border_shadow, 12, 7, 12, 7, 2)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_pixel_box(COLORS.button_hover, COLORS.border, COLORS.border_shadow, 12, 7, 12, 7, 2)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_pixel_box(COLORS.button_pressed, COLORS.gold, COLORS.border_shadow, 12, 7, 12, 7, 2)
	)
	button.add_theme_stylebox_override(
		"focus",
		_make_pixel_box(COLORS.button_focus, COLORS.border_light, COLORS.gold, 12, 7, 12, 7, 2)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_make_pixel_box(
			COLORS.button_disabled,
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
