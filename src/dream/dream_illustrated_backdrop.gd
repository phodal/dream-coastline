class_name DreamIllustratedBackdrop
extends Node2D

var texture: Texture2D
var board_size := Vector2(480, 288)
var tint := Color(1, 1, 1, 1)


func configure(new_texture: Texture2D, new_board_size: Vector2, new_tint: Color = Color.WHITE) -> void:
	texture = new_texture
	board_size = new_board_size
	tint = new_tint
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, board_size), Color("#050608"))
	if texture != null and texture.get_width() > 0 and texture.get_height() > 0:
		_draw_cover_texture()
	_draw_playable_grade()


func _draw_cover_texture() -> void:
	var source_size := Vector2(texture.get_width(), texture.get_height())
	var scale := maxf(board_size.x / source_size.x, board_size.y / source_size.y)
	var crop_size := board_size / scale
	var source_rect := Rect2((source_size - crop_size) * 0.5, crop_size)
	draw_texture_rect_region(texture, Rect2(Vector2.ZERO, board_size), source_rect, tint)


func _draw_playable_grade() -> void:
	draw_rect(Rect2(Vector2.ZERO, board_size), Color("#061016", 0.18))
	draw_rect(Rect2(Vector2.ZERO, Vector2(board_size.x, board_size.y * 0.2)), Color("#000000", 0.18))
	draw_rect(Rect2(Vector2(0, board_size.y * 0.72), Vector2(board_size.x, board_size.y * 0.28)), Color("#000000", 0.28))
	draw_rect(Rect2(Vector2.ZERO, board_size), Color("#f0d18a", 0.055), false, 2.0)
