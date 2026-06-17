extends Control

var accent := Color(0.95, 0.76, 0.28, 0.78)
var kind := "prop"


func configure(marker_kind: String, marker_color: Color) -> void:
	kind = marker_kind
	accent = marker_color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.28
	var glow := Color(accent.r, accent.g, accent.b, 0.16)
	var core := Color(accent.r, accent.g, accent.b, 0.64)
	var rim := Color(1.0, 0.96, 0.78, 0.68)

	draw_circle(center, radius * 1.7, glow)
	if _is_exit_kind():
		_draw_exit_marker(center, radius, core, rim)
	else:
		_draw_inspect_marker(center, radius, core, rim)


func _draw_inspect_marker(center: Vector2, radius: float, core: Color, rim: Color) -> void:
	draw_circle(center, radius * 0.38, core)
	draw_arc(center, radius, -PI * 0.78, PI * 0.28, 22, rim, 2.0, true)
	draw_arc(center, radius * 1.28, PI * 0.52, PI * 1.06, 12, Color(accent.r, accent.g, accent.b, 0.34), 1.5, true)
	draw_line(center + Vector2(0.0, -radius * 1.45), center + Vector2(0.0, -radius * 0.72), rim, 1.5, true)
	draw_line(center + Vector2(-radius * 1.45, 0.0), center + Vector2(-radius * 0.72, 0.0), rim, 1.5, true)


func _draw_exit_marker(center: Vector2, radius: float, core: Color, rim: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius * 0.92, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius * 0.92, 0.0),
	])
	draw_colored_polygon(points, Color(core.r, core.g, core.b, 0.42))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), rim, 2.0, true)
	draw_line(center + Vector2(-radius * 0.38, 0.0), center + Vector2(radius * 0.38, 0.0), rim, 1.6, true)


func _is_exit_kind() -> bool:
	return kind in ["exit", "stairs", "portal", "door", "door_open"]
