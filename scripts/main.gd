extends Node2D

const PLAYER_SPEED := 320.0

var player_position := Vector2(640.0, 380.0)
var shoreline_points := PackedVector2Array()


func _ready() -> void:
	_build_shoreline()


func _process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_position += direction * PLAYER_SPEED * delta
	player_position = player_position.clamp(Vector2(24.0, 24.0), get_viewport_rect().size - Vector2(24.0, 24.0))
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#7fc9d8"))
	draw_rect(Rect2(Vector2(0.0, viewport_size.y * 0.52), Vector2(viewport_size.x, viewport_size.y * 0.48)), Color("#f2d38b"))
	draw_polyline(shoreline_points, Color("#ffffff"), 9.0, true)
	draw_polyline(shoreline_points, Color("#2f8da1"), 3.0, true)

	for i in range(9):
		var cloud_origin := Vector2(110.0 + i * 145.0, 82.0 + sin(i * 1.7) * 24.0)
		draw_circle(cloud_origin, 24.0, Color(0.973, 0.984, 1.0, 0.78))
		draw_circle(cloud_origin + Vector2(27.0, -6.0), 18.0, Color(0.973, 0.984, 1.0, 0.78))
		draw_circle(cloud_origin + Vector2(48.0, 8.0), 20.0, Color(0.973, 0.984, 1.0, 0.78))

	draw_circle(player_position, 18.0, Color("#203647"))
	draw_circle(player_position + Vector2(0.0, -6.0), 8.0, Color("#ffcc66"))
	draw_line(player_position + Vector2(-16.0, 20.0), player_position + Vector2(16.0, 20.0), Color("#203647"), 4.0, true)


func _build_shoreline() -> void:
	shoreline_points.clear()
	for i in range(33):
		var x := i * 40.0
		var y := 372.0 + sin(i * 0.72) * 26.0 + cos(i * 0.31) * 12.0
		shoreline_points.append(Vector2(x, y))
