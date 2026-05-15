class_name SpriteSceneCanvas
extends Control

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const DUNGEON_CRAWL := preload("res://assets/opengameart/dungeon_crawl/DungeonCrawl_ProjectUtumnoTileset.png")
const RPG_CHARACTERS := preload("res://assets/opengameart/rpg_characters/rpg_16x16.png")
const FIREBALL := preload("res://assets/opengameart/spells/png/fireball.png")
const MAGIC_ORB := preload("res://assets/opengameart/spells/png/magic_orb.png")
const PAPER_ICON := preload("res://assets/opengameart/paper_icons/Paper.png")

const ATLAS_TILE := 32.0
const CHAR_TILE := 16.0
const PLAYER_FRAME_ORIGIN := Vector2i(6, 0)
const COLUMNS := 15
const ROWS := 9

var session
var visual_repository
var player_tile := Vector2(7, 6)
var player_moving := false
var player_facing := Vector2i(0, -1)
var blocked_tile := Vector2i.ZERO
var show_blocked_feedback := false


func _ready() -> void:
	custom_minimum_size = Vector2(560, 420)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_visual_repository(repository) -> void:
	visual_repository = repository


func refresh(game_session) -> void:
	session = game_session
	queue_redraw()


func set_player_tile(tile: Vector2) -> void:
	player_tile = tile
	queue_redraw()


func set_player_motion(tile: Vector2, moving: bool, facing: Vector2i, blocked: Vector2i, blocked_feedback: bool) -> void:
	player_tile = tile
	player_moving = moving
	player_facing = facing
	blocked_tile = blocked
	show_blocked_feedback = blocked_feedback
	queue_redraw()


func _draw() -> void:
	if session == null:
		return
	var canvas_size := size
	draw_rect(Rect2(Vector2.ZERO, canvas_size), GameThemeScript.COLORS.panel_deep)
	var tile_size: float = floor(min(canvas_size.x / COLUMNS, canvas_size.y / ROWS))
	tile_size = maxf(tile_size, 32.0)
	var map_size := Vector2(tile_size * COLUMNS, tile_size * ROWS)
	var origin := (canvas_size - map_size) * 0.5

	var visual := _current_visual()
	_draw_map(origin, tile_size, visual)
	_draw_location_objects(origin, tile_size, visual)
	_draw_blocked_feedback(origin, tile_size)
	_draw_actors(origin, tile_size, visual)


func _draw_map(origin: Vector2, tile_size: float, visual: Dictionary) -> void:
	var terrain := str(visual.get("terrain", ""))
	if _uses_modern_scene_tiles(terrain):
		for y in range(ROWS):
			for x in range(COLUMNS):
				_draw_modern_scene_tile(terrain, x, y, origin + Vector2(x, y) * tile_size, tile_size)
		return

	var palette := _palette_for_scene(terrain)
	for y in range(ROWS):
		for x in range(COLUMNS):
			var tile: Vector2i = palette.floor
			if y == 0 or y == ROWS - 1 or x == 0 or x == COLUMNS - 1:
				tile = palette.wall
			elif _is_road_location() and y in [4, 5]:
				tile = palette.path
			elif _is_modern_home() and y < 3:
				tile = palette.room_shadow
			elif _is_moqi_location() and (x + y) % 7 == 0:
				tile = palette.accent
			_draw_dungeon_tile(tile, origin + Vector2(x, y) * tile_size, tile_size)


func _draw_modern_scene_tile(terrain: String, x: int, y: int, top_left: Vector2, tile_size: float) -> void:
	var rect := Rect2(top_left, Vector2(tile_size, tile_size))
	var edge := y == 0 or y == ROWS - 1 or x == 0 or x == COLUMNS - 1
	if terrain == "street":
		if edge:
			draw_rect(rect, Color("#111515"))
			_draw_tile_noise(top_left, tile_size, Color("#242923", 0.28))
		elif y <= 2:
			draw_rect(rect, Color("#262523"))
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.82), Vector2(tile_size, tile_size * 0.08)), Color("#3a332b"))
			if (x + y) % 3 == 0:
				draw_rect(Rect2(top_left + Vector2(tile_size * 0.12, tile_size * 0.18), Vector2(tile_size * 0.3, tile_size * 0.18)), Color("#11100f"))
		elif y in [4, 5]:
			draw_rect(rect, Color("#30343a"))
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.48), Vector2(tile_size, maxf(1.0, tile_size * 0.025))), Color("#555a60", 0.55))
		else:
			draw_rect(rect, Color("#181c20"))
			if (x + y) % 2 == 0:
				draw_rect(Rect2(top_left + Vector2(tile_size * 0.08, tile_size * 0.1), Vector2(tile_size * 0.1, tile_size * 0.04)), Color("#2b3036", 0.35))
	elif terrain == "interior":
		if edge or y <= 1:
			draw_rect(rect, Color("#24201c"))
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.84), Vector2(tile_size, tile_size * 0.08)), Color("#3f2a18"))
		else:
			draw_rect(rect, Color("#20252a"))
			draw_rect(rect, Color("#343a40", 0.38), false, maxf(1.0, tile_size * 0.015))
			if (x + y) % 2 == 0:
				draw_rect(Rect2(top_left + Vector2(tile_size * 0.18, tile_size * 0.18), Vector2(tile_size * 0.1, tile_size * 0.1)), Color("#111519", 0.28))
	else:
		if edge or y <= 1:
			draw_rect(rect, Color("#2a231d"))
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.82), Vector2(tile_size, tile_size * 0.1)), Color("#51351f"))
		else:
			draw_rect(rect, Color("#3b2a1d"))
			var board_height := maxf(1.0, tile_size * 0.08)
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.46), Vector2(tile_size, board_height)), Color("#5a3a20", 0.42))
			if x % 2 == 0:
				draw_rect(Rect2(top_left + Vector2(tile_size * 0.04, 0), Vector2(maxf(1.0, tile_size * 0.02), tile_size)), Color("#24160d", 0.34))


func _draw_tile_noise(top_left: Vector2, tile_size: float, color: Color) -> void:
	for index in range(3):
		var offset := Vector2(tile_size * (0.18 + index * 0.22), tile_size * (0.22 + ((index * 2) % 3) * 0.16))
		draw_rect(Rect2(top_left + offset, Vector2(tile_size * 0.08, tile_size * 0.04)), color)


func _draw_location_objects(origin: Vector2, tile_size: float, visual: Dictionary) -> void:
	if not visual.is_empty():
		if _is_illiterate_station():
			_draw_station_blankening(origin, tile_size)
		for prop in visual.get("props", []):
			_draw_visual_prop(prop, origin, tile_size)
		if session.has_flag(str(session.scene.get("ending_flag", ""))):
			draw_texture_rect(MAGIC_ORB, Rect2(origin + Vector2(12, 4) * tile_size, Vector2(tile_size, tile_size)), false)
		return

	var location: Dictionary = session.current_location()
	var item_ids: Array = location.get("items", {}).keys()
	var slots := [
		Vector2i(3, 3),
		Vector2i(6, 3),
		Vector2i(10, 3),
		Vector2i(4, 6),
		Vector2i(8, 6),
		Vector2i(11, 6),
	]
	var slot_index := 0
	for item_id in item_ids:
		var coord: Vector2i = slots[slot_index % slots.size()]
		_draw_prop(str(item_id), origin + Vector2(coord) * tile_size, tile_size)
		slot_index += 1

	var exits: Array = location.get("exits", {}).keys()
	if exits.size() > 0:
		_draw_prop("door", origin + Vector2(COLUMNS - 2, 4) * tile_size, tile_size)
	if exits.size() > 1:
		_draw_prop("stairs", origin + Vector2(1, 4) * tile_size, tile_size)

	if session.has_flag(str(session.scene.get("ending_flag", ""))):
		draw_texture_rect(MAGIC_ORB, Rect2(origin + Vector2(7, 4) * tile_size, Vector2(tile_size, tile_size)), false)

	var combat: Dictionary = location.get("combat", {})
	if not combat.is_empty() and session.enemy_hp > 0:
		_draw_dungeon_tile(Vector2i(6, 2), origin + Vector2(10, 4) * tile_size, tile_size)
		draw_texture_rect(FIREBALL, Rect2(origin + Vector2(9, 4) * tile_size, Vector2(tile_size, tile_size)), false)


func _draw_actors(origin: Vector2, tile_size: float, _visual: Dictionary) -> void:
	var bob := 0.0
	if player_moving and fmod(Time.get_ticks_msec() / 120.0, 2.0) >= 1.0:
		bob = -2.0
	var player_top_left := origin + player_tile * tile_size + Vector2(0, bob)
	_draw_character(_player_frame(), player_top_left, tile_size)
	_draw_facing_marker(player_top_left, tile_size)
	if session.scene_index >= 2:
		_draw_character(Vector2i(3, 0), origin + Vector2(6, 5) * tile_size, tile_size)
	if session.scene_index >= 4:
		_draw_character(Vector2i(5, 1), origin + Vector2(8, 5) * tile_size, tile_size)


func _draw_prop(item_id: String, top_left: Vector2, tile_size: float) -> void:
	match item_id:
		"window":
			_draw_dungeon_tile(Vector2i(12, 12), top_left, tile_size)
		"poster", "letter", "note":
			draw_texture_rect(PAPER_ICON, Rect2(top_left + Vector2(tile_size * 0.15, tile_size * 0.1), Vector2(tile_size * 0.7, tile_size * 0.8)), false)
		"pen":
			_draw_dungeon_tile(Vector2i(34, 28), top_left, tile_size)
		"vending":
			_draw_vending_machine(top_left, tile_size)
		"phone":
			_draw_phone_device(top_left, tile_size)
		"tv":
			_draw_tv_device(top_left, tile_size)
		"mailbox":
			_draw_mailbox(top_left, tile_size)
		"door_open":
			_draw_open_door(top_left, tile_size)
		"lock", "door":
			_draw_dungeon_tile(Vector2i(28, 11), top_left, tile_size)
		"stairs":
			_draw_dungeon_tile(Vector2i(7, 14), top_left, tile_size)
		"dinner":
			_draw_dungeon_tile(Vector2i(13, 12), top_left, tile_size)
		"photo", "glasses":
			_draw_dungeon_tile(Vector2i(49, 12), top_left, tile_size)
		_:
			_draw_dungeon_tile(Vector2i(18, 15), top_left, tile_size)


func _draw_blocked_feedback(origin: Vector2, tile_size: float) -> void:
	if not show_blocked_feedback:
		return
	if blocked_tile.x < 0 or blocked_tile.y < 0 or blocked_tile.x >= COLUMNS or blocked_tile.y >= ROWS:
		return
	var rect := Rect2(origin + Vector2(blocked_tile) * tile_size, Vector2(tile_size, tile_size))
	draw_rect(rect, Color("#d45c55", 0.36))
	draw_rect(rect, Color("#f1ead4", 0.5), false, 2.0)


func _draw_visual_prop(prop: Dictionary, origin: Vector2, tile_size: float) -> void:
	var kind := str(prop.get("kind", "decor"))
	var position := origin + Vector2(float(prop.get("x", 0)), float(prop.get("y", 0))) * tile_size
	var width := int(prop.get("w", 1))
	var height := int(prop.get("h", 1))
	var item_id := str(prop.get("item", ""))
	match kind:
		"building":
			if _uses_modern_scene_props():
				_draw_apartment_block(position, tile_size, width, height)
			else:
				_draw_block(Vector2i(4, 13), position, tile_size, width, height)
				_draw_dungeon_tile(Vector2i(12, 12), position + Vector2(tile_size, tile_size), tile_size)
		"tent":
			_draw_block(Vector2i(18, 15), position, tile_size, width, height)
		"tree":
			_draw_block(Vector2i(13, 15), position, tile_size, width, height)
		"campfire":
			draw_texture_rect(FIREBALL, Rect2(position, Vector2(tile_size, tile_size)), false)
		"city_fire":
			_draw_city_fire(position, tile_size)
		"sign":
			_draw_text_surface(position, tile_size, false)
		"notice":
			_draw_text_surface(position, tile_size, true)
		"pen":
			_draw_pen_threat(position, tile_size)
		"phone":
			_draw_phone_device(position, tile_size, session.has_flag("checked_phone_no_service"))
		"sofa", "bed":
			if _uses_modern_scene_props() and kind == "sofa":
				_draw_sofa(position, tile_size, width)
			elif _uses_modern_scene_props():
				_draw_bed(position, tile_size, width)
			else:
				_draw_block(Vector2i(6, 14), position, tile_size, width, height)
		"table", "desk":
			if _uses_modern_scene_props():
				_draw_table(position, tile_size, width, kind == "desk")
			else:
				_draw_block(Vector2i(13, 12), position, tile_size, width, height)
		"bookcase":
			if _uses_modern_scene_props():
				_draw_bookcase(position, tile_size, height)
			else:
				_draw_block(Vector2i(24, 11), position, tile_size, 1, height)
		"cabinet":
			_draw_dungeon_tile(Vector2i(24, 11), position, tile_size)
		"well":
			_draw_dungeon_tile(Vector2i(11, 14), position, tile_size)
		"node":
			_draw_dungeon_tile(Vector2i(2, 16), position, tile_size)
			draw_texture_rect(MAGIC_ORB, Rect2(position, Vector2(tile_size, tile_size)), false)
		"portal":
			if session.has_flag(str(session.scene.get("ending_flag", ""))):
				draw_texture_rect(MAGIC_ORB, Rect2(position, Vector2(tile_size, tile_size)), false)
			else:
				_draw_dungeon_tile(Vector2i(2, 16), position, tile_size)
		"lamp":
			if _uses_modern_scene_props():
				_draw_voice_lamp(position, tile_size)
			else:
				_draw_dungeon_tile(Vector2i(32, 12), position, tile_size)
		"soldier":
			_draw_soldier_threat(position, tile_size)
		"xiaoyan":
			_draw_xiaoyan_state(position, tile_size)
		"xiali":
			_draw_xiali_judgement(position, tile_size)
		"enemy":
			_draw_nameless_enemy(position, tile_size)
		"wensu", "villager", "officer", "student":
			_draw_actor(kind, position, tile_size)
		"gate":
			_draw_gate_rune(position, tile_size)
		"rune":
			if item_id == "strokes" or prop.has("action"):
				_draw_name_rune(position, tile_size, item_id == "strokes")
			else:
				_draw_dungeon_tile(Vector2i(2, 16), position, tile_size)
		"record":
			draw_texture_rect(PAPER_ICON, Rect2(position + Vector2(tile_size * 0.15, tile_size * 0.1), Vector2(tile_size * 0.7, tile_size * 0.8)), false)
		"window_dark":
			_draw_dark_window(position, tile_size)
		"shadow":
			draw_rect(Rect2(position, Vector2(tile_size, tile_size)), Color("#000000", 0.45))
		"exit":
			_draw_apartment_exit(position, tile_size)
		_:
			if _uses_modern_scene_props():
				_draw_modern_prop(kind, position, tile_size)
			else:
				_draw_prop(kind, position, tile_size)


func _draw_modern_prop(kind: String, top_left: Vector2, tile_size: float) -> void:
	match kind:
		"stairs":
			_draw_stairs(top_left, tile_size)
		"dinner":
			_draw_cold_dinner(top_left, tile_size)
		"photo":
			_draw_photo_frame(top_left, tile_size)
		"glasses":
			_draw_glasses(top_left, tile_size)
		"window":
			_draw_dark_window(top_left, tile_size)
		"poster", "letter", "note":
			_draw_paper_note(top_left, tile_size, kind)
		_:
			var marker := Rect2(top_left + Vector2(tile_size * 0.25, tile_size * 0.25), Vector2(tile_size * 0.5, tile_size * 0.5))
			draw_rect(marker, Color("#2b1d10"))
			draw_rect(marker, GameThemeScript.COLORS.border, false, maxf(1.0, tile_size * 0.03))


func _draw_apartment_block(top_left: Vector2, tile_size: float, width: int, height: int) -> void:
	var rect := Rect2(top_left, Vector2(tile_size * max(1, width), tile_size * max(1, height)))
	draw_rect(rect, Color("#262523"))
	draw_rect(rect, Color("#3f2a18"), false, maxf(2.0, tile_size * 0.035))
	for row in range(max(1, height)):
		for column in range(max(1, width)):
			if row == 0 and column == 0:
				continue
			var window := Rect2(
				top_left + Vector2(tile_size * (column + 0.22), tile_size * (row + 0.22)),
				Vector2(tile_size * 0.36, tile_size * 0.22)
			)
			draw_rect(window, Color("#0b0d10"))
			draw_rect(window, Color("#6d695f", 0.45), false, maxf(1.0, tile_size * 0.018))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.35, tile_size * (height - 0.95)), Vector2(tile_size * 0.42, tile_size * 0.72)), Color("#101010"))


func _draw_apartment_exit(top_left: Vector2, tile_size: float) -> void:
	var frame := Rect2(top_left + Vector2(tile_size * 0.2, tile_size * 0.08), Vector2(tile_size * 0.6, tile_size * 0.84))
	draw_rect(frame, Color("#2e2f31"))
	draw_rect(frame, Color("#8f7040"), false, maxf(1.0, tile_size * 0.035))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.32, tile_size * 0.18), Vector2(tile_size * 0.36, tile_size * 0.5)), Color("#08090a"))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.38, tile_size * 0.72), Vector2(tile_size * 0.24, tile_size * 0.08)), Color("#3f2a18"))


func _draw_dark_window(top_left: Vector2, tile_size: float) -> void:
	var frame := Rect2(top_left + Vector2(tile_size * 0.18, tile_size * 0.12), Vector2(tile_size * 0.64, tile_size * 0.62))
	draw_rect(frame, Color("#1d2023"))
	draw_rect(frame, Color("#8f7040"), false, maxf(1.0, tile_size * 0.035))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.26, tile_size * 0.2), Vector2(tile_size * 0.48, tile_size * 0.46)), Color("#050608"))
	draw_line(top_left + Vector2(tile_size * 0.5, tile_size * 0.2), top_left + Vector2(tile_size * 0.5, tile_size * 0.66), Color("#2a2f34"), maxf(1.0, tile_size * 0.018))
	draw_line(top_left + Vector2(tile_size * 0.26, tile_size * 0.43), top_left + Vector2(tile_size * 0.74, tile_size * 0.43), Color("#2a2f34"), maxf(1.0, tile_size * 0.018))


func _draw_voice_lamp(top_left: Vector2, tile_size: float) -> void:
	draw_line(top_left + Vector2(tile_size * 0.5, 0), top_left + Vector2(tile_size * 0.5, tile_size * 0.18), Color("#3f2a18"), maxf(1.0, tile_size * 0.025))
	draw_circle(top_left + Vector2(tile_size * 0.5, tile_size * 0.32), tile_size * 0.18, Color("#2d2a25"))
	draw_circle(top_left + Vector2(tile_size * 0.5, tile_size * 0.32), tile_size * 0.1, Color("#5d5548", 0.5))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.34, tile_size * 0.54), Vector2(tile_size * 0.32, tile_size * 0.06)), Color("#050608", 0.55))


func _draw_sofa(top_left: Vector2, tile_size: float, width: int) -> void:
	var sofa_width: float = tile_size * float(max(1, width))
	var body := Rect2(top_left + Vector2(tile_size * 0.04, tile_size * 0.28), Vector2(sofa_width - tile_size * 0.08, tile_size * 0.42))
	draw_rect(body, Color("#293647"))
	draw_rect(body, Color("#8f7040"), false, maxf(1.0, tile_size * 0.025))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.08, tile_size * 0.18), Vector2(sofa_width - tile_size * 0.16, tile_size * 0.18)), Color("#34465a"))
	for column in range(max(1, width)):
		draw_rect(Rect2(top_left + Vector2(tile_size * (column + 0.12), tile_size * 0.42), Vector2(tile_size * 0.76, tile_size * 0.22)), Color("#203040", 0.52), false, maxf(1.0, tile_size * 0.018))


func _draw_bed(top_left: Vector2, tile_size: float, width: int) -> void:
	var bed_width: float = tile_size * float(max(1, width))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.04, tile_size * 0.24), Vector2(bed_width - tile_size * 0.08, tile_size * 0.48)), Color("#2f3d4a"))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.12, tile_size * 0.3), Vector2(tile_size * 0.48, tile_size * 0.28)), Color("#d6d0bf"))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.62, tile_size * 0.32), Vector2(bed_width - tile_size * 0.78, tile_size * 0.3)), Color("#6b2630"))


func _draw_table(top_left: Vector2, tile_size: float, width: int, desk: bool) -> void:
	var table_width: float = tile_size * float(max(1, width))
	var color := Color("#4a2e1b") if desk else Color("#5a3921")
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.04, tile_size * 0.28), Vector2(table_width - tile_size * 0.08, tile_size * 0.34)), color)
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.04, tile_size * 0.28), Vector2(table_width - tile_size * 0.08, tile_size * 0.34)), Color("#8f7040"), false, maxf(1.0, tile_size * 0.025))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.14, tile_size * 0.62), Vector2(tile_size * 0.08, tile_size * 0.22)), Color("#2b1d10"))
	draw_rect(Rect2(top_left + Vector2(table_width - tile_size * 0.22, tile_size * 0.62), Vector2(tile_size * 0.08, tile_size * 0.22)), Color("#2b1d10"))


func _draw_bookcase(top_left: Vector2, tile_size: float, height: int) -> void:
	var rect := Rect2(top_left + Vector2(tile_size * 0.16, tile_size * 0.04), Vector2(tile_size * 0.68, tile_size * max(1, height) - tile_size * 0.08))
	draw_rect(rect, Color("#3f2a18"))
	draw_rect(rect, Color("#8f7040"), false, maxf(1.0, tile_size * 0.025))
	for row in range(max(1, height) * 2):
		var y := top_left.y + tile_size * (0.18 + row * 0.42)
		draw_rect(Rect2(Vector2(top_left.x + tile_size * 0.22, y), Vector2(tile_size * 0.56, tile_size * 0.06)), Color("#17110d"))
		draw_rect(Rect2(Vector2(top_left.x + tile_size * 0.26, y + tile_size * 0.08), Vector2(tile_size * 0.12, tile_size * 0.16)), Color("#b7a780"))
		draw_rect(Rect2(Vector2(top_left.x + tile_size * 0.44, y + tile_size * 0.08), Vector2(tile_size * 0.12, tile_size * 0.16)), Color("#293647"))


func _draw_stairs(top_left: Vector2, tile_size: float) -> void:
	for step in range(4):
		var y := tile_size * (0.18 + step * 0.16)
		draw_rect(Rect2(top_left + Vector2(tile_size * 0.18, y), Vector2(tile_size * 0.64, tile_size * 0.08)), Color("#45484c"))
		draw_rect(Rect2(top_left + Vector2(tile_size * 0.18, y), Vector2(tile_size * 0.64, tile_size * 0.08)), Color("#8f7040"), false, maxf(1.0, tile_size * 0.018))


func _draw_cold_dinner(top_left: Vector2, tile_size: float) -> void:
	draw_circle(top_left + Vector2(tile_size * 0.48, tile_size * 0.48), tile_size * 0.18, Color("#d6d0bf"))
	draw_circle(top_left + Vector2(tile_size * 0.48, tile_size * 0.48), tile_size * 0.1, Color("#6b5d4a"))
	draw_line(top_left + Vector2(tile_size * 0.66, tile_size * 0.28), top_left + Vector2(tile_size * 0.78, tile_size * 0.68), Color("#1a120c"), maxf(1.0, tile_size * 0.025))
	draw_line(top_left + Vector2(tile_size * 0.72, tile_size * 0.28), top_left + Vector2(tile_size * 0.84, tile_size * 0.68), Color("#1a120c"), maxf(1.0, tile_size * 0.025))


func _draw_photo_frame(top_left: Vector2, tile_size: float) -> void:
	var frame := Rect2(top_left + Vector2(tile_size * 0.18, tile_size * 0.14), Vector2(tile_size * 0.64, tile_size * 0.48))
	draw_rect(frame, Color("#1d2023"))
	draw_rect(frame, Color("#8f7040"), false, maxf(1.0, tile_size * 0.035))
	for index in range(3):
		draw_circle(top_left + Vector2(tile_size * (0.34 + index * 0.12), tile_size * 0.34), tile_size * 0.045, Color("#b7a780"))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.34, tile_size * 0.62), Vector2(tile_size * 0.32, tile_size * 0.08)), Color("#3f2a18"))


func _draw_glasses(top_left: Vector2, tile_size: float) -> void:
	var left := top_left + Vector2(tile_size * 0.34, tile_size * 0.46)
	var right := top_left + Vector2(tile_size * 0.58, tile_size * 0.46)
	draw_circle(left, tile_size * 0.1, Color("#101820"))
	draw_circle(right, tile_size * 0.1, Color("#101820"))
	draw_circle(left, tile_size * 0.1, GameThemeScript.COLORS.paper, false, maxf(1.0, tile_size * 0.025))
	draw_circle(right, tile_size * 0.1, GameThemeScript.COLORS.paper, false, maxf(1.0, tile_size * 0.025))
	draw_line(left + Vector2(tile_size * 0.1, 0), right - Vector2(tile_size * 0.1, 0), GameThemeScript.COLORS.paper, maxf(1.0, tile_size * 0.018))


func _draw_paper_note(top_left: Vector2, tile_size: float, kind: String) -> void:
	var page := Rect2(top_left + Vector2(tile_size * 0.22, tile_size * 0.12), Vector2(tile_size * 0.56, tile_size * 0.72))
	draw_rect(page, Color("#d8ceb0"))
	draw_rect(page, Color("#8f7040"), false, maxf(1.0, tile_size * 0.025))
	for row in range(3):
		draw_rect(Rect2(top_left + Vector2(tile_size * 0.3, tile_size * (0.28 + row * 0.13)), Vector2(tile_size * 0.38, tile_size * 0.035)), Color("#17110d", 0.7))
	if kind == "letter":
		draw_line(top_left + Vector2(tile_size * 0.28, tile_size * 0.18), top_left + Vector2(tile_size * 0.5, tile_size * 0.38), Color("#17110d", 0.52), maxf(1.0, tile_size * 0.018))
		draw_line(top_left + Vector2(tile_size * 0.72, tile_size * 0.18), top_left + Vector2(tile_size * 0.5, tile_size * 0.38), Color("#17110d", 0.52), maxf(1.0, tile_size * 0.018))


func _draw_city_fire(top_left: Vector2, tile_size: float) -> void:
	var wall := Rect2(
		top_left + Vector2(tile_size * 0.04, tile_size * 0.28),
		Vector2(tile_size * 0.92, tile_size * 0.36)
	)
	draw_rect(wall, Color("#15110e"))
	draw_rect(wall, Color("#6c4a2a"), false, maxf(1.0, tile_size * 0.035))
	for column in range(3):
		var tower := Rect2(
			top_left + Vector2(tile_size * (0.12 + column * 0.28), tile_size * 0.16),
			Vector2(tile_size * 0.14, tile_size * 0.28)
		)
		draw_rect(tower, Color("#1d1611"))
		draw_rect(tower, Color("#8f7040"), false, maxf(1.0, tile_size * 0.025))
	_draw_flame(top_left + Vector2(tile_size * 0.23, tile_size * 0.28), tile_size * 0.22)
	_draw_flame(top_left + Vector2(tile_size * 0.52, tile_size * 0.22), tile_size * 0.28)
	_draw_flame(top_left + Vector2(tile_size * 0.76, tile_size * 0.32), tile_size * 0.2)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.08, tile_size * 0.68), Vector2(tile_size * 0.84, tile_size * 0.08)),
		Color("#000000", 0.42)
	)


func _draw_flame(center: Vector2, size: float) -> void:
	var outer := PackedVector2Array([
		center + Vector2(0, -size),
		center + Vector2(size * 0.52, size * 0.55),
		center + Vector2(-size * 0.52, size * 0.55),
	])
	var inner := PackedVector2Array([
		center + Vector2(0, -size * 0.45),
		center + Vector2(size * 0.25, size * 0.35),
		center + Vector2(-size * 0.25, size * 0.35),
	])
	draw_colored_polygon(outer, Color("#d45c55"))
	draw_colored_polygon(inner, Color("#f0d18a"))


func _draw_text_surface(top_left: Vector2, tile_size: float, live_ink: bool) -> void:
	var body := Rect2(
		top_left + Vector2(tile_size * 0.1, tile_size * 0.18),
		Vector2(tile_size * 0.8, tile_size * 0.5)
	)
	var bg := Color("#2b1d10") if live_ink else Color("#3f2a18")
	draw_rect(body, bg)
	draw_rect(body, GameThemeScript.COLORS.border_light, false, maxf(1.0, tile_size * 0.035))
	var ink_offset := 0.0
	if live_ink:
		ink_offset = sin(Time.get_ticks_msec() / 180.0) * tile_size * 0.035
	for index in range(3):
		var block := Rect2(
			top_left + Vector2(tile_size * (0.2 + index * 0.2), tile_size * 0.36 + ink_offset),
			Vector2(tile_size * 0.11, tile_size * 0.11)
		)
		draw_rect(block, Color("#0b0907"))
		draw_rect(block, GameThemeScript.COLORS.cyan if live_ink else GameThemeScript.COLORS.paper, false, maxf(1.0, tile_size * 0.018))
	if live_ink:
		for index in range(2):
			draw_line(
				top_left + Vector2(tile_size * (0.3 + index * 0.18), tile_size * 0.64),
				top_left + Vector2(tile_size * (0.28 + index * 0.22), tile_size * 0.78),
				Color("#050608"),
				maxf(1.0, tile_size * 0.035)
			)


func _draw_pen_threat(top_left: Vector2, tile_size: float) -> void:
	var start := top_left + Vector2(tile_size * 0.22, tile_size * 0.64)
	var end := top_left + Vector2(tile_size * 0.78, tile_size * 0.28)
	draw_line(start, end, Color("#050608"), maxf(3.0, tile_size * 0.08))
	draw_line(start, end, GameThemeScript.COLORS.border_light, maxf(1.0, tile_size * 0.022))
	var nib := PackedVector2Array([
		end,
		end + Vector2(-tile_size * 0.06, tile_size * 0.16),
		end + Vector2(tile_size * 0.12, tile_size * 0.06),
	])
	draw_colored_polygon(nib, GameThemeScript.COLORS.gold)
	draw_circle(start, tile_size * 0.15, Color("#000000", 0.24))


func _draw_soldier_threat(top_left: Vector2, tile_size: float) -> void:
	_draw_character(Vector2i(5, 1), top_left, tile_size)
	var blade_start := top_left + Vector2(tile_size * 0.62, tile_size * 0.42)
	var blade_end := top_left + Vector2(tile_size * 0.94, tile_size * 0.2)
	draw_line(blade_start, blade_end, GameThemeScript.COLORS.paper, maxf(2.0, tile_size * 0.045))
	for index in range(2):
		draw_rect(
			Rect2(blade_start + Vector2(tile_size * (0.08 + index * 0.08), -tile_size * (0.04 + index * 0.03)), Vector2(tile_size * 0.045, tile_size * 0.045)),
			GameThemeScript.COLORS.gold
		)


func _draw_xiaoyan_state(top_left: Vector2, tile_size: float) -> void:
	_draw_character(Vector2i(0, 0), top_left + Vector2(tile_size * 0.05, tile_size * 0.04), tile_size * 0.92)
	if session.location_id == "camp":
		draw_line(
			top_left + Vector2(tile_size * 0.55, tile_size * 0.42),
			top_left + Vector2(tile_size * 0.88, tile_size * 0.28),
			GameThemeScript.COLORS.paper,
			maxf(1.0, tile_size * 0.03)
		)
	if session.location_id == "station" and session.has_flag("saw_xiaoyan_name_fading"):
		for index in range(2):
			draw_rect(
				Rect2(top_left + Vector2(tile_size * (0.24 + index * 0.18), tile_size * 0.02), Vector2(tile_size * 0.12, tile_size * 0.1)),
				Color("#050608")
			)
			draw_rect(
				Rect2(top_left + Vector2(tile_size * (0.24 + index * 0.18), tile_size * 0.02), Vector2(tile_size * 0.12, tile_size * 0.1)),
				GameThemeScript.COLORS.paper,
				false,
				1.0
			)


func _draw_xiali_judgement(top_left: Vector2, tile_size: float) -> void:
	_draw_character(Vector2i(3, 0), top_left, tile_size)
	draw_line(
		top_left + Vector2(tile_size * 0.22, tile_size * 0.2),
		top_left + Vector2(tile_size * 0.82, tile_size * 0.72),
		Color("#050608", 0.72),
		maxf(2.0, tile_size * 0.055)
	)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.16, tile_size * 0.82), Vector2(tile_size * 0.68, tile_size * 0.06)),
		Color("#000000", 0.34)
	)


func _draw_gate_rune(top_left: Vector2, tile_size: float) -> void:
	var pillar_color := Color("#2a2722")
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.12, tile_size * 0.2), Vector2(tile_size * 0.18, tile_size * 0.68)), pillar_color)
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.7, tile_size * 0.2), Vector2(tile_size * 0.18, tile_size * 0.68)), pillar_color)
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.18, tile_size * 0.14), Vector2(tile_size * 0.64, tile_size * 0.18)), pillar_color)
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.34, tile_size * 0.32), Vector2(tile_size * 0.32, tile_size * 0.42)), Color("#050608", 0.52))
	draw_line(
		top_left + Vector2(tile_size * 0.36, tile_size * 0.34),
		top_left + Vector2(tile_size * 0.52, tile_size * 0.48),
		GameThemeScript.COLORS.cyan,
		maxf(1.0, tile_size * 0.035)
	)
	draw_line(
		top_left + Vector2(tile_size * 0.52, tile_size * 0.48),
		top_left + Vector2(tile_size * 0.64, tile_size * 0.38),
		Color(GameThemeScript.COLORS.cyan.r, GameThemeScript.COLORS.cyan.g, GameThemeScript.COLORS.cyan.b, 0.32),
		maxf(1.0, tile_size * 0.035)
	)


func _draw_name_rune(top_left: Vector2, tile_size: float, teaching: bool) -> void:
	var slab := Rect2(top_left + Vector2(tile_size * 0.18, tile_size * 0.18), Vector2(tile_size * 0.64, tile_size * 0.64))
	draw_rect(slab, Color("#17110d"))
	draw_rect(slab, GameThemeScript.COLORS.border_light if teaching else GameThemeScript.COLORS.border, false, maxf(1.0, tile_size * 0.035))
	var ink := GameThemeScript.COLORS.gold if session.has_flag("learned_name_strokes") else GameThemeScript.COLORS.paper
	draw_line(top_left + Vector2(tile_size * 0.35, tile_size * 0.34), top_left + Vector2(tile_size * 0.65, tile_size * 0.34), ink, maxf(2.0, tile_size * 0.045))
	draw_line(top_left + Vector2(tile_size * 0.48, tile_size * 0.32), top_left + Vector2(tile_size * 0.34, tile_size * 0.58), ink, maxf(2.0, tile_size * 0.045))
	draw_line(top_left + Vector2(tile_size * 0.42, tile_size * 0.58), top_left + Vector2(tile_size * 0.68, tile_size * 0.58), ink, maxf(2.0, tile_size * 0.045))
	if session.has_flag("name_broke_once") and not session.has_flag("named_beast"):
		draw_line(top_left + Vector2(tile_size * 0.28, tile_size * 0.26), top_left + Vector2(tile_size * 0.72, tile_size * 0.74), GameThemeScript.COLORS.danger, maxf(2.0, tile_size * 0.045))


func _draw_nameless_enemy(top_left: Vector2, tile_size: float) -> void:
	if session.has_flag("defeated_nameless"):
		for index in range(3):
			draw_circle(top_left + Vector2(tile_size * (0.3 + index * 0.16), tile_size * 0.5), tile_size * 0.04, Color("#050608", 0.28))
		return
	var named: bool = session.has_flag("named_beast")
	var alpha: float = 0.86 if named else 0.72
	var trim := maxf(1.0, tile_size * 0.035)
	var body := Rect2(top_left + Vector2(tile_size * 0.2, tile_size * 0.22), Vector2(tile_size * 0.6, tile_size * 0.58))
	draw_rect(body, Color("#050608", alpha))
	draw_circle(top_left + Vector2(tile_size * 0.5, tile_size * 0.2), tile_size * 0.2, Color("#050608", alpha))
	if named:
		draw_rect(body, GameThemeScript.COLORS.gold, false, trim)
	else:
		draw_rect(body, Color(GameThemeScript.COLORS.paper.r, GameThemeScript.COLORS.paper.g, GameThemeScript.COLORS.paper.b, 0.55), false, trim)
		draw_line(top_left + Vector2(tile_size * 0.22, tile_size * 0.36), top_left + Vector2(tile_size * 0.08, tile_size * 0.62), Color("#050608", 0.82), trim)
		draw_line(top_left + Vector2(tile_size * 0.78, tile_size * 0.36), top_left + Vector2(tile_size * 0.92, tile_size * 0.62), Color("#050608", 0.82), trim)
		for index in range(3):
			draw_rect(
				Rect2(top_left + Vector2(tile_size * (0.31 + index * 0.14), tile_size * 0.07), Vector2(tile_size * 0.09, tile_size * 0.09)),
				GameThemeScript.COLORS.paper
			)
	if session.has_flag("name_broke_once") and not named:
		draw_line(top_left + Vector2(tile_size * 0.2, tile_size * 0.18), top_left + Vector2(tile_size * 0.8, tile_size * 0.82), GameThemeScript.COLORS.danger, maxf(2.0, tile_size * 0.04))


func _draw_station_blankening(origin: Vector2, tile_size: float) -> void:
	draw_rect(Rect2(origin + Vector2(tile_size, tile_size), Vector2(tile_size * 13, tile_size * 1.2)), Color("#050608", 0.32))
	for index in range(5):
		var x := tile_size * (2.2 + index * 1.1)
		var top_left := origin + Vector2(x, tile_size * 1.38)
		draw_rect(Rect2(top_left, Vector2(tile_size * 0.42, tile_size * 0.08)), GameThemeScript.COLORS.paper if index < 3 else Color("#050608"))
		draw_rect(Rect2(top_left + Vector2(tile_size * 0.14, tile_size * 0.12), Vector2(tile_size * 0.18, tile_size * 0.08)), GameThemeScript.COLORS.paper if index < 2 else Color("#050608", 0.5))
	draw_rect(Rect2(origin + Vector2(tile_size * 10.4, tile_size * 1.4), Vector2(tile_size * 2.2, tile_size * 4.8)), Color("#000000", 0.24))


func _draw_vending_machine(top_left: Vector2, tile_size: float) -> void:
	var body := Rect2(
		top_left + Vector2(tile_size * 0.18, tile_size * 0.05),
		Vector2(tile_size * 0.64, tile_size * 0.9)
	)
	var trim := maxf(1.0, tile_size * 0.04)
	draw_rect(body, Color("#8b241d"))
	draw_rect(body, Color("#f0d18a"), false, trim)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.28, tile_size * 0.16), Vector2(tile_size * 0.3, tile_size * 0.28)),
		Color("#101820")
	)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.32, tile_size * 0.2), Vector2(tile_size * 0.22, tile_size * 0.08)),
		Color("#b9d1c4")
	)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.62, tile_size * 0.18), Vector2(tile_size * 0.1, tile_size * 0.34)),
		Color("#2b1d10")
	)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.3, tile_size * 0.62), Vector2(tile_size * 0.38, tile_size * 0.12)),
		Color("#120e0a")
	)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.24, tile_size * 0.86), Vector2(tile_size * 0.52, tile_size * 0.08)),
		Color("#3f2a18")
	)


func _draw_phone_device(top_left: Vector2, tile_size: float, corrupted: bool = false) -> void:
	var body := Rect2(
		top_left + Vector2(tile_size * 0.28, tile_size * 0.08),
		Vector2(tile_size * 0.44, tile_size * 0.78)
	)
	draw_rect(body, Color("#101820"))
	draw_rect(body, Color("#8f7040"), false, maxf(1.0, tile_size * 0.035))
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.34, tile_size * 0.17), Vector2(tile_size * 0.32, tile_size * 0.42)),
		Color("#060708")
	)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.4, tile_size * 0.23), Vector2(tile_size * 0.2, tile_size * 0.08)),
		Color("#b9d1c4")
	)
	if corrupted:
		draw_line(
			top_left + Vector2(tile_size * 0.36, tile_size * 0.2),
			top_left + Vector2(tile_size * 0.63, tile_size * 0.55),
			Color("#000000"),
			maxf(2.0, tile_size * 0.055)
		)
		for index in range(2):
			draw_rect(
				Rect2(top_left + Vector2(tile_size * (0.39 + index * 0.12), tile_size * 0.4), Vector2(tile_size * 0.07, tile_size * 0.06)),
				GameThemeScript.COLORS.paper
			)
	draw_circle(top_left + Vector2(tile_size * 0.5, tile_size * 0.72), tile_size * 0.045, Color("#f0d18a"))


func _draw_tv_device(top_left: Vector2, tile_size: float) -> void:
	var frame := Rect2(
		top_left + Vector2(tile_size * 0.12, tile_size * 0.2),
		Vector2(tile_size * 0.76, tile_size * 0.48)
	)
	draw_rect(frame, Color("#2a2a2a"))
	draw_rect(frame, Color("#8f7040"), false, maxf(1.0, tile_size * 0.035))
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.2, tile_size * 0.28), Vector2(tile_size * 0.6, tile_size * 0.32)),
		Color("#050608")
	)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.42, tile_size * 0.68), Vector2(tile_size * 0.16, tile_size * 0.14)),
		Color("#3f2a18")
	)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.28, tile_size * 0.8), Vector2(tile_size * 0.44, tile_size * 0.08)),
		Color("#3f2a18")
	)


func _draw_mailbox(top_left: Vector2, tile_size: float) -> void:
	var box_rect := Rect2(
		top_left + Vector2(tile_size * 0.16, tile_size * 0.28),
		Vector2(tile_size * 0.68, tile_size * 0.42)
	)
	draw_rect(box_rect, Color("#273747"))
	draw_rect(box_rect, Color("#f0d18a"), false, maxf(1.0, tile_size * 0.035))
	for row in range(2):
		for column in range(3):
			draw_rect(
				Rect2(
					top_left + Vector2(tile_size * (0.22 + column * 0.18), tile_size * (0.34 + row * 0.16)),
					Vector2(tile_size * 0.12, tile_size * 0.08)
				),
				Color("#0d0b08")
			)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.42, tile_size * 0.7), Vector2(tile_size * 0.16, tile_size * 0.18)),
		Color("#3f2a18")
	)


func _draw_open_door(top_left: Vector2, tile_size: float) -> void:
	var frame := Rect2(
		top_left + Vector2(tile_size * 0.2, tile_size * 0.08),
		Vector2(tile_size * 0.6, tile_size * 0.84)
	)
	draw_rect(frame, Color("#4b2c17"), false, maxf(2.0, tile_size * 0.055))
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.3, tile_size * 0.18), Vector2(tile_size * 0.4, tile_size * 0.68)),
		Color("#050608")
	)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.36, tile_size * 0.18), Vector2(tile_size * 0.18, tile_size * 0.68)),
		Color("#2b1d10")
	)
	draw_circle(top_left + Vector2(tile_size * 0.58, tile_size * 0.5), tile_size * 0.035, Color("#f0d18a"))


func _draw_block(tile: Vector2i, top_left: Vector2, tile_size: float, width: int, height: int) -> void:
	for y in range(max(1, height)):
		for x in range(max(1, width)):
			_draw_dungeon_tile(tile, top_left + Vector2(x, y) * tile_size, tile_size)


func _draw_actor(kind: String, top_left: Vector2, tile_size: float) -> void:
	match kind:
		"xiali":
			_draw_character(Vector2i(3, 0), top_left, tile_size)
		"guardian":
			_draw_character(Vector2i(5, 1), top_left, tile_size)
		_:
			_draw_character(Vector2i(0, 0), top_left, tile_size)


func _draw_dungeon_tile(tile: Vector2i, top_left: Vector2, tile_size: float) -> void:
	draw_texture_rect_region(
		DUNGEON_CRAWL,
		Rect2(top_left, Vector2(tile_size, tile_size)),
		Rect2(Vector2(tile) * ATLAS_TILE, Vector2(ATLAS_TILE, ATLAS_TILE))
	)


func _draw_character(tile: Vector2i, top_left: Vector2, tile_size: float) -> void:
	var sprite_size := tile_size * 0.74
	var sprite_top_left := top_left + Vector2((tile_size - sprite_size) * 0.5, tile_size - sprite_size - tile_size * 0.08)
	draw_rect(
		Rect2(
			top_left + Vector2(tile_size * 0.24, tile_size * 0.82),
			Vector2(tile_size * 0.52, tile_size * 0.1)
		),
		Color("#000000", 0.32)
	)
	draw_texture_rect_region(
		RPG_CHARACTERS,
		Rect2(sprite_top_left, Vector2(sprite_size, sprite_size)),
		Rect2(Vector2(tile) * CHAR_TILE, Vector2(CHAR_TILE, CHAR_TILE))
	)


func _player_frame() -> Vector2i:
	var column := 1
	if player_moving:
		var cycle := [0, 1, 2, 1]
		column = cycle[int(Time.get_ticks_msec() / 120) % cycle.size()]

	var row := 0
	if player_facing == Vector2i(0, -1):
		row = 2
	elif player_facing == Vector2i(-1, 0) or player_facing == Vector2i(1, 0):
		row = 1
	else:
		row = 0
	return PLAYER_FRAME_ORIGIN + Vector2i(column, row)


func _draw_facing_marker(top_left: Vector2, tile_size: float) -> void:
	var center := top_left + Vector2(tile_size * 0.5, tile_size * 0.86)
	var radius := tile_size * 0.11
	var facing := Vector2(player_facing)
	if player_facing == Vector2i.ZERO:
		facing = Vector2.DOWN
	var tip := center + facing * tile_size * 0.22
	var points: PackedVector2Array
	if player_facing == Vector2i(0, -1):
		points = [tip, tip + Vector2(-radius, radius * 1.2), tip + Vector2(radius, radius * 1.2)]
	elif player_facing == Vector2i(0, 1):
		points = [tip, tip + Vector2(-radius, -radius * 1.2), tip + Vector2(radius, -radius * 1.2)]
	elif player_facing == Vector2i(-1, 0):
		points = [tip, tip + Vector2(radius * 1.2, -radius), tip + Vector2(radius * 1.2, radius)]
	else:
		points = [tip, tip + Vector2(-radius * 1.2, -radius), tip + Vector2(-radius * 1.2, radius)]
	draw_colored_polygon(points, Color("#f0d18a", 0.84))


func _palette_for_scene(terrain: String = "") -> Dictionary:
	if terrain == "street":
		return {
			"floor": Vector2i(1, 15),
			"wall": Vector2i(4, 13),
			"path": Vector2i(9, 14),
			"room_shadow": Vector2i(6, 14),
			"accent": Vector2i(18, 15),
		}
	if terrain in ["interior", "room"] or _is_modern_home():
		return {
			"floor": Vector2i(1, 15),
			"wall": Vector2i(4, 13),
			"path": Vector2i(9, 14),
			"room_shadow": Vector2i(6, 14),
			"accent": Vector2i(18, 15),
		}
	if _is_moqi_location():
		return {
			"floor": Vector2i(0, 14),
			"wall": Vector2i(6, 13),
			"path": Vector2i(9, 14),
			"room_shadow": Vector2i(4, 14),
			"accent": Vector2i(2, 16),
		}
	return {
		"floor": Vector2i(6, 14),
		"wall": Vector2i(4, 13),
		"path": Vector2i(8, 14),
		"room_shadow": Vector2i(5, 14),
		"accent": Vector2i(16, 15),
	}


func _is_road_location() -> bool:
	return session.location_id in ["street", "market", "ruins", "road", "mud_road"]


func _is_modern_home() -> bool:
	return session.location_id in ["street", "building", "home", "living_room", "study", "bedroom"]


func _is_moqi_location() -> bool:
	return session.scene_index in [2, 3, 5, 6] or session.location_id.contains("moqi") or session.location_id.contains("academy")


func _is_illiterate_station() -> bool:
	return session.scene_id == "01-illiterate" and session.location_id == "station"


func _uses_modern_scene_tiles(terrain: String) -> bool:
	return session != null and session.scene_id in ["00-prologue-lights-out", "07-lights-on-again"] and terrain in ["street", "interior", "room"]


func _uses_modern_scene_props() -> bool:
	return session != null and session.scene_id in ["00-prologue-lights-out", "07-lights-on-again"]


func _current_visual() -> Dictionary:
	if visual_repository == null:
		return {}
	return visual_repository.location_visual(session.scene_id, session.location_id)
