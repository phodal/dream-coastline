class_name MenuBackdrop
extends Control

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")

var menu_mode := "title"
var animation_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	animation_time += delta
	if visible:
		queue_redraw()


func set_menu_mode(value: String) -> void:
	if menu_mode == value:
		return
	menu_mode = value
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var base_alpha := 0.36
	if menu_mode == "title":
		base_alpha = 0.22
	elif menu_mode == "pause":
		base_alpha = 0.46
	elif menu_mode == "settings":
		base_alpha = 0.5

	draw_rect(rect, Color("#050608", base_alpha))
	_draw_vignette(rect)
	if menu_mode == "title":
		_draw_title_sweep(rect)
	else:
		_draw_menu_focus(rect)


func _draw_vignette(rect: Rect2) -> void:
	var bands := 7
	for index in range(bands):
		var alpha := 0.06 + float(index) * 0.035
		var inset := float(index) * 18.0
		draw_rect(Rect2(rect.position + Vector2(0, inset), Vector2(rect.size.x, 18.0)), Color("#000000", alpha))
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - inset - 18.0), Vector2(rect.size.x, 18.0)), Color("#000000", alpha))
		draw_rect(Rect2(rect.position + Vector2(inset, 0), Vector2(18.0, rect.size.y)), Color("#000000", alpha))
		draw_rect(Rect2(rect.position + Vector2(rect.size.x - inset - 18.0, 0), Vector2(18.0, rect.size.y)), Color("#000000", alpha))


func _draw_title_sweep(rect: Rect2) -> void:
	var warm: Color = GameThemeScript.COLORS.gold
	var pulse := 0.08 + sin(animation_time * 1.6) * 0.025
	var horizon_y := rect.size.y * 0.72
	draw_rect(Rect2(Vector2(0, horizon_y), Vector2(rect.size.x, 2.0)), Color(warm.r, warm.g, warm.b, 0.18))
	draw_rect(Rect2(Vector2(rect.size.x * 0.54, 0), Vector2(rect.size.x * 0.46, rect.size.y)), Color("#050608", 0.2))
	draw_circle(Vector2(rect.size.x * 0.78, rect.size.y * 0.28), rect.size.y * 0.24, Color(warm.r, warm.g, warm.b, pulse))
	for index in range(5):
		var x := rect.size.x * (0.08 + float(index) * 0.1)
		draw_line(Vector2(x, rect.size.y * 0.09), Vector2(x + 90.0, rect.size.y * 0.09), Color(warm.r, warm.g, warm.b, 0.08), 2.0)


func _draw_menu_focus(rect: Rect2) -> void:
	var warm: Color = GameThemeScript.COLORS.border_light
	draw_circle(rect.size * 0.5, minf(rect.size.x, rect.size.y) * 0.28, Color(warm.r, warm.g, warm.b, 0.05))
	draw_rect(Rect2(Vector2(rect.size.x * 0.22, rect.size.y * 0.18), Vector2(rect.size.x * 0.56, 2.0)), Color(warm.r, warm.g, warm.b, 0.13))
	draw_rect(Rect2(Vector2(rect.size.x * 0.22, rect.size.y * 0.82), Vector2(rect.size.x * 0.56, 2.0)), Color(warm.r, warm.g, warm.b, 0.11))
