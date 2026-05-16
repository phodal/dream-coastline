class_name PromptOverlay
extends PanelContainer

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const PLAYER_SHEET_PATH := "res://assets/characters/jizixuan/player_default.png"

var location_label: Label
var prompt_label: Label
var feedback_label: Label
var actor_label: Label
var state_label: Label
var portrait_panel: Control
var player_texture


func _ready() -> void:
	GameThemeScript.style_dialogue_panel(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(PLAYER_SHEET_PATH):
		player_texture = load(PLAYER_SHEET_PATH)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var actor_box := VBoxContainer.new()
	actor_box.custom_minimum_size = Vector2(118, 84)
	actor_box.add_theme_constant_override("separation", 3)
	root.add_child(actor_box)

	portrait_panel = Control.new()
	portrait_panel.custom_minimum_size = Vector2(92, 34)
	portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actor_box.add_child(portrait_panel)

	actor_label = GameThemeScript.make_label("ActorName", 17, GameThemeScript.COLORS.gold)
	actor_label.text = "纪子轩"
	actor_box.add_child(actor_label)

	state_label = GameThemeScript.make_label("ActorState", 13, GameThemeScript.COLORS.muted)
	state_label.text = "独自回家"
	actor_box.add_child(state_label)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	root.add_child(box)

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
	state_label.text = _state_text(location_name)
	if latest_feedback.is_empty():
		feedback_label.text = "沿着地图移动，靠近发光或可疑的物件。"
	else:
		feedback_label.text = latest_feedback
	queue_redraw()


func _draw() -> void:
	if portrait_panel == null:
		return
	var rect := Rect2(portrait_panel.get_global_rect().position - get_global_rect().position, portrait_panel.size)
	draw_rect(rect, Color("#050608", 0.92))
	draw_rect(rect, Color(GameThemeScript.COLORS.border.r, GameThemeScript.COLORS.border.g, GameThemeScript.COLORS.border.b, 0.72), false, 2.0)
	draw_rect(rect.grow(-4.0), Color("#101820", 0.46))
	if player_texture != null:
		var sprite_size := minf(rect.size.x * 0.42, rect.size.y * 1.35)
		var sprite_rect := Rect2(
			rect.position + Vector2(rect.size.x * 0.5 - sprite_size * 0.5, rect.size.y - sprite_size + 8.0),
			Vector2(sprite_size, sprite_size)
		)
		draw_texture_rect_region(player_texture, sprite_rect, Rect2(Vector2(16, 0), Vector2(16, 16)))
	else:
		var head := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.34)
		var body := Rect2(rect.position + Vector2(rect.size.x * 0.38, rect.size.y * 0.48), Vector2(rect.size.x * 0.24, rect.size.y * 0.32))
		draw_circle(head, rect.size.y * 0.16, Color("#eadcae"))
		draw_rect(body, Color("#202833"))
		draw_rect(Rect2(body.position + Vector2(body.size.x * 0.36, 0), Vector2(body.size.x * 0.28, body.size.y)), Color("#d7b15e"))
		draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.3, rect.size.y * 0.78), Vector2(rect.size.x * 0.4, rect.size.y * 0.08)), Color("#050608", 0.72))
	var pulse := 0.36 + sin(Time.get_ticks_msec() / 260.0) * 0.08
	draw_line(rect.position + Vector2(10, rect.size.y - 7), rect.position + Vector2(rect.size.x - 10, rect.size.y - 7), Color(GameThemeScript.COLORS.gold.r, GameThemeScript.COLORS.gold.g, GameThemeScript.COLORS.gold.b, pulse), 2.0)


func _state_text(location_name: String) -> String:
	match location_name:
		"居民楼外":
			return "窗户未亮"
		"居民楼门口":
			return "声控灯沉默"
		"家门口":
			return "门锁半开"
		"客厅":
			return "晚饭已冷"
		"父母书房":
			return "纸页有墨味"
		"纪子轩房间":
			return "黑笔在等"
		_:
			return "独自前进"
