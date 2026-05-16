class_name DreamRoomRenderer
extends Node2D

var grid_size := Vector2i(13, 9)
var cell_size := Vector2i(32, 32)
var location_tone := Color(0.12, 0.14, 0.18)


func configure(new_grid_size: Vector2i, new_cell_size: Vector2i, tone_seed: int) -> void:
	grid_size = new_grid_size
	cell_size = new_cell_size
	var hue := float(abs(tone_seed) % 360) / 360.0
	location_tone = Color.from_hsv(hue, 0.22, 0.18)
	queue_redraw()


func _draw() -> void:
	var room_size := Vector2(grid_size * cell_size)
	draw_rect(Rect2(Vector2.ZERO, room_size), location_tone)
	draw_rect(Rect2(Vector2.ZERO, room_size), Color(0.03, 0.035, 0.045), false, 3.0)

	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Vector2(x * cell_size.x, y * cell_size.y)
			var tint := Color(1, 1, 1, 0.025 + float((x + y) % 2) * 0.025)
			draw_rect(Rect2(cell, Vector2(cell_size)), tint)

	for x in range(grid_size.x + 1):
		var px := float(x * cell_size.x)
		draw_line(Vector2(px, 0), Vector2(px, room_size.y), Color(0.9, 0.95, 1.0, 0.05))
	for y in range(grid_size.y + 1):
		var py := float(y * cell_size.y)
		draw_line(Vector2(0, py), Vector2(room_size.x, py), Color(0.9, 0.95, 1.0, 0.05))
