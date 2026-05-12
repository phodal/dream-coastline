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
const COLUMNS := 15
const ROWS := 9

var session


func _ready() -> void:
	custom_minimum_size = Vector2(560, 420)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func refresh(game_session) -> void:
	session = game_session
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

	_draw_map(origin, tile_size)
	_draw_location_objects(origin, tile_size)
	_draw_actors(origin, tile_size)
	_draw_letterbox(canvas_size)


func _draw_map(origin: Vector2, tile_size: float) -> void:
	var palette := _palette_for_scene()
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


func _draw_location_objects(origin: Vector2, tile_size: float) -> void:
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


func _draw_actors(origin: Vector2, tile_size: float) -> void:
	_draw_character(Vector2i(0, 0), origin + Vector2(7, 6) * tile_size, tile_size)
	if session.scene_index >= 2:
		_draw_character(Vector2i(3, 0), origin + Vector2(6, 5) * tile_size, tile_size)
	if session.scene_index >= 4:
		_draw_character(Vector2i(5, 1), origin + Vector2(8, 5) * tile_size, tile_size)


func _draw_letterbox(canvas_size: Vector2) -> void:
	var location: Dictionary = session.current_location()
	draw_rect(Rect2(Vector2.ZERO, Vector2(canvas_size.x, 34)), Color("#000000", 0.58))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(12, 23),
		str(location.get("name", session.location_id)),
		HORIZONTAL_ALIGNMENT_LEFT,
		canvas_size.x - 24,
		18,
		GameThemeScript.COLORS.gold
	)


func _draw_prop(item_id: String, top_left: Vector2, tile_size: float) -> void:
	match item_id:
		"window":
			_draw_dungeon_tile(Vector2i(12, 12), top_left, tile_size)
		"poster", "letter", "note":
			draw_texture_rect(PAPER_ICON, Rect2(top_left + Vector2(tile_size * 0.15, tile_size * 0.1), Vector2(tile_size * 0.7, tile_size * 0.8)), false)
		"pen":
			_draw_dungeon_tile(Vector2i(34, 28), top_left, tile_size)
		"vending", "phone", "tv":
			_draw_dungeon_tile(Vector2i(24, 11), top_left, tile_size)
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


func _draw_dungeon_tile(tile: Vector2i, top_left: Vector2, tile_size: float) -> void:
	draw_texture_rect_region(
		DUNGEON_CRAWL,
		Rect2(top_left, Vector2(tile_size, tile_size)),
		Rect2(Vector2(tile) * ATLAS_TILE, Vector2(ATLAS_TILE, ATLAS_TILE))
	)


func _draw_character(tile: Vector2i, top_left: Vector2, tile_size: float) -> void:
	draw_texture_rect_region(
		RPG_CHARACTERS,
		Rect2(top_left + Vector2(tile_size * 0.1, 0), Vector2(tile_size * 0.8, tile_size)),
		Rect2(Vector2(tile) * CHAR_TILE, Vector2(CHAR_TILE, CHAR_TILE))
	)


func _palette_for_scene() -> Dictionary:
	if _is_modern_home():
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
	return session.location_id in ["street", "market", "ruins", "road"]


func _is_modern_home() -> bool:
	return session.location_id in ["street", "building", "home", "living_room", "study", "bedroom"]


func _is_moqi_location() -> bool:
	return session.scene_index in [2, 3, 5, 6] or session.location_id.contains("moqi") or session.location_id.contains("academy")
