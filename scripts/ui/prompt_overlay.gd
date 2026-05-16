class_name PromptOverlay
extends PanelContainer

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const PLAYER_SHEET_PATH := "res://assets/characters/jizixuan/player_default.png"

var location_label: Label
var prompt_label: Label
var feedback_label: Label
var actor_label: Label
var state_label: Label
var action_label: Label
var action_chip: PanelContainer
var history_label: Label
var location_divider: ColorRect
var portrait_panel: Control
var player_texture


func _ready() -> void:
	GameThemeScript.style_compact_dialogue_panel(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(PLAYER_SHEET_PATH):
		player_texture = load(PLAYER_SHEET_PATH)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var actor_box := VBoxContainer.new()
	actor_box.custom_minimum_size = Vector2(84, 54)
	actor_box.add_theme_constant_override("separation", 1)
	root.add_child(actor_box)

	portrait_panel = Control.new()
	portrait_panel.custom_minimum_size = Vector2(60, 22)
	portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actor_box.add_child(portrait_panel)

	actor_label = GameThemeScript.make_label("ActorName", 14, GameThemeScript.COLORS.gold)
	actor_label.text = "纪子轩"
	actor_box.add_child(actor_label)

	state_label = GameThemeScript.make_label("ActorState", 11, GameThemeScript.COLORS.muted)
	state_label.clip_text = true
	state_label.text = "独自回家"
	actor_box.add_child(state_label)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	root.add_child(box)

	var first_line := HBoxContainer.new()
	first_line.add_theme_constant_override("separation", 8)
	box.add_child(first_line)

	location_label = GameThemeScript.make_label("Location", 15, GameThemeScript.COLORS.gold)
	location_label.custom_minimum_size = Vector2(0, 0)
	location_label.clip_text = true
	location_label.visible = false
	first_line.add_child(location_label)

	location_divider = ColorRect.new()
	location_divider.color = Color(GameThemeScript.COLORS.border.r, GameThemeScript.COLORS.border.g, GameThemeScript.COLORS.border.b, 0.7)
	location_divider.custom_minimum_size = Vector2(2, 22)
	location_divider.visible = false
	first_line.add_child(location_divider)

	action_chip = GameThemeScript.make_status_chip("PromptActionChip", "移动", GameThemeScript.COLORS.gold)
	action_chip.custom_minimum_size = Vector2(58, 22)
	action_label = action_chip.get_child(0) as Label
	action_label.custom_minimum_size = Vector2(42, 18)
	first_line.add_child(action_chip)

	prompt_label = GameThemeScript.make_label("Prompt", 15, GameThemeScript.COLORS.paper)
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_label.custom_minimum_size = Vector2(300, 22)
	prompt_label.clip_text = true
	first_line.add_child(prompt_label)

	var accent := ColorRect.new()
	accent.color = Color(GameThemeScript.COLORS.border_light.r, GameThemeScript.COLORS.border_light.g, GameThemeScript.COLORS.border_light.b, 0.42)
	accent.custom_minimum_size = Vector2(0, 2)
	box.add_child(accent)

	feedback_label = GameThemeScript.make_label("LatestFeedback", 13, GameThemeScript.COLORS.text)
	feedback_label.custom_minimum_size = Vector2(360, 24)
	feedback_label.clip_text = true
	box.add_child(feedback_label)

	history_label = GameThemeScript.make_label("FeedbackHistory", 12, GameThemeScript.COLORS.muted)
	history_label.custom_minimum_size = Vector2(360, 20)
	history_label.clip_text = true
	history_label.visible = false
	box.add_child(history_label)


func refresh(location_name: String, prompt_text: String, latest_feedback: String, history_text: String = "") -> void:
	location_label.text = _compact_location_name(location_name)
	location_label.add_theme_color_override("font_color", GameThemeScript.COLORS.gold)
	action_label.text = _action_text(prompt_text)
	action_label.add_theme_color_override("font_color", _action_color(prompt_text))
	prompt_label.text = prompt_text
	state_label.text = _state_text(location_name)
	if latest_feedback.is_empty():
		feedback_label.text = "%s：沿着地图移动，靠近发光或可疑的物件。" % location_name
	else:
		feedback_label.text = "%s：%s" % [location_name, latest_feedback]
	history_label.visible = not history_text.is_empty()
	if history_label.visible:
		history_label.text = "记录：%s" % history_text.replace("\n", " / ")
	queue_redraw()


func _draw() -> void:
	if portrait_panel == null:
		return
	var rect := Rect2(portrait_panel.get_global_rect().position - get_global_rect().position, portrait_panel.size)
	draw_rect(rect, Color("#050608", 0.92))
	draw_rect(rect, Color(GameThemeScript.COLORS.border.r, GameThemeScript.COLORS.border.g, GameThemeScript.COLORS.border.b, 0.72), false, 2.0)
	draw_rect(rect.grow(-4.0), Color("#101820", 0.46))
	if player_texture != null:
		var sprite_size := minf(rect.size.x * 0.52, rect.size.y * 1.62)
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


func _compact_location_name(location_name: String) -> String:
	if location_name.length() > 7:
		return location_name.substr(0, 6) + "..."
	return location_name


func _action_text(prompt_text: String) -> String:
	if prompt_text.begins_with("进入："):
		return "出口"
	if prompt_text.begins_with("调查："):
		return "调查"
	if prompt_text.find("无法锁定") >= 0:
		return "锁定"
	if prompt_text.find("攻击") >= 0 or prompt_text.find("守住") >= 0:
		return "战斗"
	if prompt_text.find("选择") >= 0 or prompt_text.find("建立") >= 0:
		return "抉择"
	if prompt_text.begins_with("WASD/方向键移动") or prompt_text.find("移动探索") >= 0:
		return "移动"
	return "行动"


func _action_color(prompt_text: String) -> Color:
	if prompt_text.find("无法锁定") >= 0:
		return GameThemeScript.COLORS.danger
	if prompt_text.begins_with("进入："):
		return GameThemeScript.COLORS.cyan
	if prompt_text.begins_with("调查："):
		return GameThemeScript.COLORS.gold
	return GameThemeScript.COLORS.paper
