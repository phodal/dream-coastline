class_name SpriteSceneCanvas
extends Control

const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const AnimationClipRepositoryScript := preload("res://scripts/core/animation_clip_repository.gd")
const VisualAssetRegistryScript := preload("res://scripts/core/visual_asset_registry.gd")

const DUNGEON_CRAWL_PATH := "res://assets/opengameart/dungeon_crawl/DungeonCrawl_ProjectUtumnoTileset.png"
const RPG_CHARACTERS_PATH := "res://assets/opengameart/rpg_characters/rpg_16x16.png"
const FIREBALL_PATH := "res://assets/opengameart/spells/png/fireball.png"
const MAGIC_ORB_PATH := "res://assets/opengameart/spells/png/magic_orb.png"
const PAPER_ICON_PATH := "res://assets/opengameart/paper_icons/Paper.png"
const PLAYER_DEFAULT_CLIP_ID := "player_default"

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
var animation_time := 0.0
var player_actor_id := "jizixuan"
var visual_assets
var animation_clips
var dungeon_crawl_texture
var rpg_characters_texture
var fireball_texture
var magic_orb_texture
var paper_icon_texture
var asset_viewport: SubViewport
var asset_scene_instance: Node
var asset_scene_path := ""
var asset_scene_warning_keys := {}
var _debug_draw_ticks := 0
var _debug_tile_info_printed := false
var _debug_asset_draw_printed := false


func _ready() -> void:
	visual_assets = VisualAssetRegistryScript.new()
	visual_assets.load_all()
	animation_clips = AnimationClipRepositoryScript.new()
	animation_clips.load_all()
	dungeon_crawl_texture = _load_optional_texture(DUNGEON_CRAWL_PATH)
	rpg_characters_texture = _load_optional_texture(RPG_CHARACTERS_PATH)
	fireball_texture = _load_optional_texture(FIREBALL_PATH)
	magic_orb_texture = _load_optional_texture(MAGIC_ORB_PATH)
	paper_icon_texture = _load_optional_texture(PAPER_ICON_PATH)
	custom_minimum_size = Vector2(560, 420)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_asset_viewport()
	set_process(true)


func _process(delta: float) -> void:
	animation_time += delta
	if session != null:
		queue_redraw()


func _load_optional_texture(path: String):
	if not ResourceLoader.exists(path):
		return null
	var texture = load(path)
	if texture == null:
		push_warning("Optional visual texture is unavailable: %s" % path)
	return texture


func set_visual_repository(repository) -> void:
	visual_repository = repository


func refresh(game_session) -> void:
	session = game_session
	_sync_asset_scene(_current_visual())
	queue_redraw()


func set_player_tile(tile: Vector2) -> void:
	player_tile = tile
	queue_redraw()


func set_player_actor(actor_id: String) -> void:
	player_actor_id = actor_id
	queue_redraw()


func set_player_motion(tile: Vector2, moving: bool, facing: Vector2i, blocked: Vector2i, blocked_feedback: bool) -> void:
	player_tile = tile
	player_moving = moving
	player_facing = facing
	blocked_tile = blocked
	show_blocked_feedback = blocked_feedback
	queue_redraw()


func _draw() -> void:
	if OS.get_environment("DREAM_COASTLINE_LAYOUT_DEBUG") == "1" and _debug_draw_ticks < 5:
		_debug_draw_ticks += 1
		print("layout-debug sprite-draw size=%s anchors=%s offsets=%s session=%s" % [
			str(size),
			[anchor_left, anchor_top, anchor_right, anchor_bottom],
			[offset_left, offset_top, offset_right, offset_bottom],
			str(session != null),
		])
	if session == null:
		return
	var canvas_size := size
	draw_rect(Rect2(Vector2.ZERO, canvas_size), GameThemeScript.COLORS.panel_deep)
	var tile_size: float = floor(min(canvas_size.x / COLUMNS, canvas_size.y / ROWS))
	tile_size = maxf(tile_size, 32.0)
	var map_size := Vector2(tile_size * COLUMNS, tile_size * ROWS)
	var origin := Vector2.ZERO
	if OS.get_environment("DREAM_COASTLINE_LAYOUT_DEBUG") == "1" and not _debug_tile_info_printed:
		print("layout-debug tile-calc canvas=%s tile_size=%s map_size=%s origin=%s" % [
			str(canvas_size),
			str(tile_size),
			str(map_size),
			str(origin),
		])
		_debug_tile_info_printed = true

	var visual := _current_visual()
	var asset_scene_ready := _sync_asset_scene(visual)
	_draw_scene_backdrop(canvas_size, origin, map_size, tile_size, visual)
	if asset_scene_ready:
		_draw_asset_scene_texture(origin, map_size)
		_draw_asset_scene_tone(origin, map_size, tile_size, visual)
		_draw_location_asset_overlays(origin, tile_size, visual)
	else:
		_draw_map(origin, tile_size, visual)
		_draw_scene_dressing(origin, tile_size, visual)
		_draw_location_objects(origin, tile_size, visual)
	_draw_blocked_feedback(origin, tile_size)
	_draw_actors(origin, tile_size, visual)
	_draw_screen_grade(canvas_size, origin, map_size, tile_size, visual)
	if OS.get_environment("DREAM_COASTLINE_ASSET_DEBUG") == "1" and not _debug_asset_draw_printed and asset_viewport != null:
		_debug_asset_draw_printed = true
		var texture := asset_viewport.get_texture()
		var tex_size := Vector2.ZERO
		if texture != null:
			tex_size = texture.get_size()
		print("layout-debug asset-viewport info viewport-size=%s texture-size=%s session_scene=%s asset_ready=%s" % [
			str(asset_viewport.size),
			str(tex_size),
			str(session and session.scene_id if session != null else "none"),
			str(asset_scene_ready),
		])


func _setup_asset_viewport() -> void:
	asset_viewport = SubViewport.new()
	asset_viewport.name = "AssetSceneViewport"
	asset_viewport.size = Vector2i(COLUMNS * int(ATLAS_TILE), ROWS * int(ATLAS_TILE))
	asset_viewport.transparent_bg = true
	asset_viewport.disable_3d = true
	asset_viewport.gui_disable_input = true
	asset_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(asset_viewport)


func _sync_asset_scene(visual: Dictionary) -> bool:
	if asset_viewport == null or visual.is_empty():
		_clear_asset_scene()
		return false
	var status := str(visual.get("asset_status", ""))
	var path := str(visual.get("asset_scene", ""))
	if status == "procedural_fallback" or path.is_empty():
		_clear_asset_scene()
		return false
	if path == asset_scene_path and asset_scene_instance != null:
		return true
	if not ResourceLoader.exists(path):
		_warn_asset_scene_once(path, "missing asset scene")
		_clear_asset_scene()
		return false
	var packed_resource: Resource = load(path)
	if not (packed_resource is PackedScene):
		_warn_asset_scene_once(path, "resource is not a PackedScene")
		_clear_asset_scene()
		return false
	_clear_asset_scene()
	var packed_scene := packed_resource as PackedScene
	var instance := packed_scene.instantiate()
	if not (instance is Node):
		_warn_asset_scene_once(path, "scene root is not a Node")
		return false
	asset_scene_instance = instance
	asset_scene_path = path
	asset_viewport.add_child(asset_scene_instance)
	return true


func _clear_asset_scene() -> void:
	if asset_viewport == null:
		return
	for child in asset_viewport.get_children():
		asset_viewport.remove_child(child)
		child.queue_free()
	asset_scene_instance = null
	asset_scene_path = ""


func _warn_asset_scene_once(path: String, reason: String) -> void:
	var key := "%s:%s" % [path, reason]
	if asset_scene_warning_keys.has(key):
		return
	asset_scene_warning_keys[key] = true
	push_warning("Asset scene fallback: %s (%s)" % [path, reason])


func _draw_asset_scene_texture(origin: Vector2, map_size: Vector2) -> void:
	if asset_viewport == null:
		return
	var texture := asset_viewport.get_texture()
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(origin, map_size), false)


func _draw_asset_scene_tone(origin: Vector2, map_size: Vector2, tile_size: float, visual: Dictionary) -> void:
	var terrain := str(visual.get("terrain", ""))
	var family := str(visual.get("visual_family", ""))
	var mood := _visual_mood(visual)
	var tone := Color("#050608", 0.08)
	if GameThemeScript.visual_style() == GameThemeScript.STYLE_CLASSIC_DARK:
		draw_rect(Rect2(origin, map_size), Color("#050608", 0.18))
		draw_rect(Rect2(origin, map_size), Color("#3f2a18", 0.12))
		var classic_edge := maxf(tile_size * 1.0, 44.0)
		draw_rect(Rect2(origin, Vector2(map_size.x, classic_edge)), Color("#000000", 0.24))
		draw_rect(Rect2(origin + Vector2(0, map_size.y - classic_edge), Vector2(map_size.x, classic_edge)), Color("#000000", 0.18))
		draw_rect(Rect2(origin, Vector2(classic_edge, map_size.y)), Color("#000000", 0.14))
		draw_rect(Rect2(origin + Vector2(map_size.x - classic_edge, 0), Vector2(classic_edge, map_size.y)), Color("#000000", 0.14))
		for prop in visual.get("props", []):
			if typeof(prop) != TYPE_DICTIONARY:
				continue
			if not _prop_visible_for_session(prop):
				continue
			_draw_asset_prop_light(prop, origin, tile_size)
		return
	if _visual_mood(visual) == "sunlit":
		draw_rect(Rect2(origin, map_size), Color("#fff4b8", 0.08))
		draw_rect(Rect2(origin, map_size), Color("#88d86f", 0.045))
		var sun_center := origin + Vector2(map_size.x * 0.18, map_size.y * 0.08)
		draw_circle(sun_center, tile_size * 3.2, Color("#fff4b8", 0.08))
		for index in range(5):
			var start := origin + Vector2(tile_size * (1.2 + index * 2.4), 0)
			var end := start + Vector2(tile_size * 1.4, map_size.y)
			draw_line(start, end, Color("#fff6b8", 0.055), maxf(2.0, tile_size * 0.04))
		return
	if mood == "moqi_shadow":
		tone = Color("#07110c", 0.24)
		draw_rect(Rect2(origin, map_size), Color("#0d2418", 0.18))
		draw_rect(Rect2(origin + Vector2(0, map_size.y * 0.42), Vector2(map_size.x, map_size.y * 0.2)), Color("#050608", 0.08))
	elif mood == "institutional":
		tone = Color("#0b0f10", 0.2)
		draw_rect(Rect2(origin, map_size), Color("#263426", 0.12))
		draw_rect(Rect2(origin + Vector2(0, map_size.y * 0.18), Vector2(map_size.x, tile_size * 0.5)), Color("#050608", 0.1))
	elif mood == "industrial":
		tone = Color("#090807", 0.18)
		draw_rect(Rect2(origin, map_size), Color("#3c2418", 0.12))
	elif mood == "astral":
		tone = Color("#001824", 0.14)
		draw_rect(Rect2(origin, map_size), Color("#00334a", 0.12))
	if session != null and session.scene_id == "00-prologue-lights-out":
		tone = Color("#03060b", 0.18)
	elif family == "node" and mood != "astral":
		tone = Color("#00202a", 0.11)
	elif family in ["wilderness", "forest"]:
		tone = Color("#170f07", 0.12)
	elif family in ["ruin", "mine"]:
		tone = Color("#050608", 0.18)
	elif terrain == "street" or family == "modern_exterior":
		tone = Color("#061016", 0.1)
	draw_rect(Rect2(origin, map_size), tone)
	var edge := maxf(tile_size * 0.9, 40.0)
	draw_rect(Rect2(origin, Vector2(map_size.x, edge)), Color("#000000", 0.18))
	draw_rect(Rect2(origin + Vector2(0, map_size.y - edge), Vector2(map_size.x, edge)), Color("#000000", 0.12))
	draw_rect(Rect2(origin, Vector2(edge, map_size.y)), Color("#000000", 0.1))
	draw_rect(Rect2(origin + Vector2(map_size.x - edge, 0), Vector2(edge, map_size.y)), Color("#000000", 0.1))
	for prop in visual.get("props", []):
		if typeof(prop) != TYPE_DICTIONARY:
			continue
		if not _prop_visible_for_session(prop):
			continue
		_draw_asset_prop_light(prop, origin, tile_size)


func _draw_asset_prop_light(prop: Dictionary, origin: Vector2, tile_size: float) -> void:
	var kind := str(prop.get("kind", ""))
	var light_color := Color(0, 0, 0, 0)
	var radius := tile_size * 0.9
	match kind:
		"lamp":
			light_color = Color("#f0d18a", 0.16)
			radius = tile_size * 1.2
		"window_dark", "pen":
			light_color = Color("#d45c55", 0.12)
			radius = tile_size * 0.9
		"node", "portal":
			light_color = Color("#75d9e6", 0.13)
			radius = tile_size * 1.25
		"rune":
			light_color = Color("#d7b15e", 0.12)
			radius = tile_size * 1.0
		_:
			return
	var center := origin + Vector2(float(prop.get("x", 0)) + 0.5, float(prop.get("y", 0)) + 0.5) * tile_size
	draw_circle(center, radius, Color(light_color.r, light_color.g, light_color.b, light_color.a * 0.45))
	draw_circle(center, radius * 0.45, light_color)


func _draw_location_asset_overlays(origin: Vector2, tile_size: float, visual: Dictionary) -> void:
	for prop in visual.get("props", []):
		if typeof(prop) != TYPE_DICTIONARY:
			continue
		if not _prop_visible_for_session(prop):
			continue
		_draw_asset_overlay_prop(prop, origin, tile_size)
		_draw_visual_prop_focus(prop, origin, tile_size)
	if session.has_flag(str(session.scene.get("ending_flag", ""))):
		_draw_magic_orb(Rect2(origin + Vector2(12, 4) * tile_size, Vector2(tile_size, tile_size)))


func _draw_asset_overlay_prop(prop: Dictionary, origin: Vector2, tile_size: float) -> void:
	if not bool(prop.get("overlay", false)):
		return
	_draw_visual_prop(prop, origin, tile_size)


func _draw_scene_backdrop(canvas_size: Vector2, origin: Vector2, map_size: Vector2, tile_size: float, visual: Dictionary) -> void:
	var terrain := str(visual.get("terrain", ""))
	var base := _ambient_base_color(terrain, visual)
	draw_rect(Rect2(Vector2.ZERO, canvas_size), base)
	_draw_backdrop_texture(canvas_size, tile_size, terrain, visual)
	if _visual_mood(visual) == "sunlit":
		_draw_sunlit_backdrop(origin, map_size, tile_size)
	elif terrain in ["wilderness", "forest"]:
		_draw_wilderness_horizon(origin, map_size, tile_size, terrain)
	elif terrain in ["ruin", "dead_city"]:
		_draw_ruin_haze(origin, map_size, tile_size)
	elif terrain == "node":
		_draw_node_backdrop(origin, map_size, tile_size)
	elif _uses_modern_scene_tiles(terrain):
		_draw_modern_backdrop(origin, map_size, tile_size, terrain)
	var frame_color := Color("#000000", 0.2)
	if _visual_mood(visual) == "sunlit":
		frame_color = Color("#f7e9a7", 0.28)
	draw_rect(Rect2(origin - Vector2(tile_size * 0.16, tile_size * 0.16), map_size + Vector2(tile_size * 0.32, tile_size * 0.32)), frame_color, false, maxf(2.0, tile_size * 0.04))


func _draw_screen_grade(canvas_size: Vector2, origin: Vector2, map_size: Vector2, tile_size: float, visual: Dictionary) -> void:
	var mood := _visual_mood(visual)
	var shade := Color("#000000", 0.22)
	var side_shade := Color("#000000", 0.16)
	var frame_color := Color(GameThemeScript.COLORS.border.r, GameThemeScript.COLORS.border.g, GameThemeScript.COLORS.border.b, 0.22)
	var inner_frame := Color("#f1ead4", 0.035)
	if mood == "sunlit":
		shade = Color("#24451f", 0.045)
		side_shade = Color("#24451f", 0.035)
		frame_color = Color("#f6d978", 0.34)
		inner_frame = Color("#fff7be", 0.12)
	elif mood == "moqi_shadow":
		shade = Color("#07110c", 0.24)
		side_shade = Color("#07110c", 0.18)
		frame_color = Color("#b9d1c4", 0.28)
		inner_frame = Color("#d7b15e", 0.06)
	elif mood == "institutional":
		shade = Color("#10120d", 0.22)
		side_shade = Color("#10120d", 0.16)
		frame_color = Color("#d7b15e", 0.26)
	elif mood == "industrial":
		shade = Color("#120c08", 0.2)
		side_shade = Color("#120c08", 0.18)
		frame_color = Color("#d45c55", 0.22)
	elif mood == "astral":
		shade = Color("#00121d", 0.2)
		side_shade = Color("#00121d", 0.16)
		frame_color = Color("#75d9e6", 0.3)
	elif GameThemeScript.visual_style() == GameThemeScript.STYLE_CLASSIC_DARK:
		shade = Color("#000000", 0.3)
		side_shade = Color("#000000", 0.22)
		frame_color = Color(GameThemeScript.COLORS.border.r, GameThemeScript.COLORS.border.g, GameThemeScript.COLORS.border.b, 0.34)
		inner_frame = Color("#eadcae", 0.035)
	elif mood == "silenced":
		shade = Color("#000000", 0.24)
		side_shade = Color("#000000", 0.18)
	var band := maxf(tile_size * 0.8, 36.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(canvas_size.x, band)), shade)
	draw_rect(Rect2(Vector2(0, canvas_size.y - band), Vector2(canvas_size.x, band)), shade)
	draw_rect(Rect2(Vector2.ZERO, Vector2(band, canvas_size.y)), side_shade)
	draw_rect(Rect2(Vector2(canvas_size.x - band, 0), Vector2(band, canvas_size.y)), side_shade)
	var map_frame := Rect2(origin - Vector2(tile_size * 0.12, tile_size * 0.12), map_size + Vector2(tile_size * 0.24, tile_size * 0.24))
	draw_rect(map_frame, frame_color, false, maxf(1.0, tile_size * 0.018))
	draw_rect(Rect2(origin, map_size), inner_frame, false, maxf(1.0, tile_size * 0.012))


func _draw_backdrop_texture(canvas_size: Vector2, tile_size: float, terrain: String, visual: Dictionary) -> void:
	var speck_color := _ambient_speck_color(terrain, visual)
	for index in range(28):
		var x := fposmod(float(index * 47) + animation_time * 7.0, canvas_size.x)
		var y := fposmod(float(index * 31) + sin(animation_time * 0.6 + index) * 8.0, canvas_size.y)
		var size := maxf(1.0, tile_size * (0.018 + float(index % 3) * 0.006))
		draw_rect(Rect2(Vector2(x, y), Vector2(size, size)), speck_color)


func _draw_sunlit_backdrop(origin: Vector2, map_size: Vector2, tile_size: float) -> void:
	var horizon_y := origin.y + tile_size * 0.45
	draw_rect(Rect2(Vector2(origin.x, horizon_y), Vector2(map_size.x, tile_size * 0.18)), Color("#fff2a7", 0.24))
	for index in range(9):
		var x := origin.x + tile_size * (0.5 + index * 1.7)
		var height := tile_size * (0.2 + float(index % 3) * 0.08)
		draw_circle(Vector2(x, horizon_y - height * 0.35), tile_size * 0.34, Color("#7bcf64", 0.35))
		draw_rect(Rect2(Vector2(x - tile_size * 0.04, horizon_y - height * 0.2), Vector2(tile_size * 0.08, height)), Color("#6d8b3a", 0.22))
	for index in range(6):
		var y := origin.y + tile_size * (1.1 + index * 0.62)
		draw_line(
			Vector2(origin.x + tile_size * 0.8, y),
			Vector2(origin.x + map_size.x - tile_size * 0.8, y + tile_size * 0.28),
			Color("#fff4b8", 0.055),
			maxf(1.0, tile_size * 0.02)
		)


func _draw_wilderness_horizon(origin: Vector2, map_size: Vector2, tile_size: float, terrain: String) -> void:
	var horizon_y := origin.y + tile_size * 0.55
	draw_rect(Rect2(Vector2(origin.x, horizon_y), Vector2(map_size.x, tile_size * 0.12)), Color("#d7b15e", 0.16))
	for index in range(7):
		var x := origin.x + tile_size * (0.8 + index * 2.1)
		var height := tile_size * (0.28 + float(index % 3) * 0.12)
		var color := Color("#10100e", 0.72) if terrain == "wilderness" else Color("#0b130e", 0.78)
		draw_rect(Rect2(Vector2(x, horizon_y - height), Vector2(tile_size * 0.28, height)), color)
		if terrain == "forest":
			draw_circle(Vector2(x + tile_size * 0.14, horizon_y - height), tile_size * 0.24, Color("#102013", 0.62))
	var drift := fposmod(animation_time * tile_size * 0.08, tile_size * 2.0)
	for index in range(5):
		var y := origin.y + tile_size * (1.0 + index * 0.8)
		draw_rect(Rect2(Vector2(origin.x + drift - tile_size * 2.0, y), Vector2(map_size.x + tile_size * 3.0, tile_size * 0.04)), Color("#d8ceb0", 0.045))


func _draw_ruin_haze(origin: Vector2, map_size: Vector2, tile_size: float) -> void:
	for index in range(5):
		var y := origin.y + tile_size * (1.0 + index * 1.2)
		var shift := sin(animation_time * 0.35 + float(index)) * tile_size * 0.18
		draw_rect(Rect2(Vector2(origin.x + shift, y), Vector2(map_size.x - tile_size * 0.5, tile_size * 0.18)), Color("#050608", 0.18))
	for index in range(8):
		var x := origin.x + tile_size * (1.0 + index * 1.55)
		var y := origin.y + tile_size * (1.2 + fposmod(animation_time * 0.18 + index * 0.37, 4.8))
		draw_rect(Rect2(Vector2(x, y), Vector2(tile_size * 0.08, tile_size * 0.025)), GameThemeScript.COLORS.paper)


func _draw_node_backdrop(origin: Vector2, map_size: Vector2, tile_size: float) -> void:
	var pulse := 0.14 + sin(animation_time * 1.4) * 0.05
	draw_rect(Rect2(origin + Vector2(tile_size, tile_size), map_size - Vector2(tile_size * 2.0, tile_size * 2.0)), Color(GameThemeScript.COLORS.cyan.r, GameThemeScript.COLORS.cyan.g, GameThemeScript.COLORS.cyan.b, pulse))
	for index in range(6):
		var x := origin.x + tile_size * (1.0 + index * 2.2)
		draw_line(Vector2(x, origin.y + tile_size * 1.2), Vector2(x + tile_size * 0.8, origin.y + map_size.y - tile_size * 1.2), Color(GameThemeScript.COLORS.cyan.r, GameThemeScript.COLORS.cyan.g, GameThemeScript.COLORS.cyan.b, 0.2), maxf(1.0, tile_size * 0.025))


func _draw_modern_backdrop(origin: Vector2, map_size: Vector2, tile_size: float, terrain: String) -> void:
	var light_alpha := 0.08 + sin(animation_time * 0.75) * 0.025
	for index in range(4):
		var x := origin.x + tile_size * (1.3 + index * 3.2)
		draw_rect(Rect2(Vector2(x, origin.y + tile_size * 0.2), Vector2(tile_size * 0.42, map_size.y - tile_size * 0.6)), Color("#d8ceb0", light_alpha))
	if terrain == "street":
		for index in range(9):
			var x := origin.x + fposmod(index * tile_size * 1.7 + animation_time * tile_size * 0.16, map_size.x)
			draw_line(Vector2(x, origin.y + tile_size * 0.5), Vector2(x - tile_size * 0.12, origin.y + map_size.y - tile_size), Color("#b9d1c4", 0.14), maxf(1.0, tile_size * 0.018))


func _draw_map(origin: Vector2, tile_size: float, visual: Dictionary) -> void:
	var terrain := str(visual.get("terrain", ""))
	if _uses_first_act_scene_tiles(terrain):
		for y in range(ROWS):
			for x in range(COLUMNS):
				_draw_first_act_scene_tile(terrain, x, y, origin + Vector2(x, y) * tile_size, tile_size)
		_draw_terrain_overlay(origin, tile_size, terrain)
		return
	if _uses_modern_scene_tiles(terrain):
		for y in range(ROWS):
			for x in range(COLUMNS):
				_draw_modern_scene_tile(terrain, x, y, origin + Vector2(x, y) * tile_size, tile_size)
		_draw_terrain_overlay(origin, tile_size, terrain)
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
	_draw_terrain_overlay(origin, tile_size, terrain)


func _draw_first_act_scene_tile(terrain: String, x: int, y: int, top_left: Vector2, tile_size: float) -> void:
	var rect := Rect2(top_left, Vector2(tile_size, tile_size))
	var edge := y == 0 or y == ROWS - 1 or x == 0 or x == COLUMNS - 1
	if terrain == "wilderness":
		if edge:
			draw_rect(rect, Color("#17220f"))
			_draw_tile_noise(top_left, tile_size, Color("#526b2b", 0.38))
		elif session.location_id == "camp":
			_draw_camp_ground_tile(x, y, top_left, tile_size)
		elif y in [5, 6]:
			draw_rect(rect, Color("#4b3721"))
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.44), Vector2(tile_size, tile_size * 0.12)), Color("#2d2115", 0.45))
			if (x + y) % 3 == 0:
				draw_rect(Rect2(top_left + Vector2(tile_size * 0.16, tile_size * 0.18), Vector2(tile_size * 0.18, tile_size * 0.08)), Color("#8a7142", 0.34))
		elif y <= 2:
			draw_rect(rect, Color("#1b1b12"))
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.74), Vector2(tile_size, tile_size * 0.12)), Color("#3a2a18", 0.65))
			if (x + y) % 4 == 0:
				draw_rect(Rect2(top_left + Vector2(tile_size * 0.12, tile_size * 0.28), Vector2(tile_size * 0.32, tile_size * 0.12)), Color("#080706", 0.62))
		else:
			draw_rect(rect, Color("#23351a"))
			_draw_tile_noise(top_left, tile_size, Color("#7b8d3a", 0.24))
	elif terrain == "forest":
		if edge:
			draw_rect(rect, Color("#081007"))
			draw_circle(top_left + Vector2(tile_size * 0.52, tile_size * 0.48), tile_size * 0.42, Color("#10240f", 0.82))
		elif y in [4, 5]:
			draw_rect(rect, Color("#342918"))
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.45), Vector2(tile_size, tile_size * 0.1)), Color("#6b5a31", 0.3))
		else:
			draw_rect(rect, Color("#10200f"))
			draw_circle(top_left + Vector2(tile_size * 0.38, tile_size * 0.34), tile_size * 0.28, Color("#1f3a1a", 0.54))
			draw_rect(Rect2(top_left + Vector2(tile_size * 0.44, tile_size * 0.16), Vector2(tile_size * 0.08, tile_size * 0.76)), Color("#14110b", 0.42))
	elif terrain == "ruin":
		var floor_color := Color("#1a1713") if not edge else Color("#0d0c0a")
		draw_rect(rect, floor_color)
		draw_rect(rect, Color("#4b3a24", 0.38), false, maxf(1.0, tile_size * 0.015))
		if (x + y) % 3 == 0:
			draw_line(top_left + Vector2(tile_size * 0.16, tile_size * 0.72), top_left + Vector2(tile_size * 0.68, tile_size * 0.24), Color("#050608", 0.38), maxf(1.0, tile_size * 0.018))
		if y <= 1:
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.68), Vector2(tile_size, tile_size * 0.12)), Color("#050608", 0.44))
	else:
		draw_rect(rect, Color("#15120d"))


func _draw_camp_ground_tile(x: int, y: int, top_left: Vector2, tile_size: float) -> void:
	if y in [4, 5]:
		draw_rect(Rect2(top_left, Vector2(tile_size, tile_size)), Color("#3b2c18"))
		draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.5), Vector2(tile_size, tile_size * 0.08)), Color("#6b5a31", 0.34))
	else:
		draw_rect(Rect2(top_left, Vector2(tile_size, tile_size)), Color("#25351b"))
		if (x + y) % 2 == 0:
			draw_rect(Rect2(top_left + Vector2(tile_size * 0.18, tile_size * 0.2), Vector2(tile_size * 0.16, tile_size * 0.08)), Color("#6e7e36", 0.24))


func _draw_prologue_street_lights(origin: Vector2, tile_size: float) -> void:
	var sign := Rect2(origin + Vector2(tile_size * 1.9, tile_size * 1.28), Vector2(tile_size * 1.28, tile_size * 0.58))
	var glow := 0.74 + sin(animation_time * 2.0) * 0.08
	var buzz := 0.82 + sin(animation_time * 9.0) * 0.18
	draw_rect(sign.grow(tile_size * 0.24), Color("#f0d18a", 0.1 * glow * buzz))
	draw_rect(sign, Color("#1b1208"))
	draw_rect(sign, Color("#f0d18a", 0.82), false, maxf(1.0, tile_size * 0.025))
	var glyph_y := sign.position.y + sign.size.y * 0.34
	for index in range(3):
		var x := sign.position.x + tile_size * (0.22 + index * 0.28)
		var glyph_alpha := glow * (0.58 + buzz * 0.42)
		draw_rect(Rect2(Vector2(x, glyph_y), Vector2(tile_size * 0.16, tile_size * 0.06)), Color("#ffd87a", glyph_alpha))
		draw_rect(Rect2(Vector2(x + tile_size * 0.05, glyph_y + tile_size * 0.12), Vector2(tile_size * 0.11, tile_size * 0.05)), Color("#ffd87a", glyph_alpha * 0.86))
	var lamp_x := origin.x + tile_size * 13.15
	var lamp_center := Vector2(lamp_x + tile_size * 0.03, origin.y + tile_size * 2.72)
	var lamp_pulse := 0.72 + sin(animation_time * 1.7) * 0.12
	draw_rect(Rect2(Vector2(lamp_x, origin.y + tile_size * 2.8), Vector2(tile_size * 0.06, tile_size * 2.0)), Color("#12100c"))
	draw_rect(Rect2(Vector2(lamp_x - tile_size * 0.82, origin.y + tile_size * 4.68), Vector2(tile_size * 1.7, tile_size * 0.22)), Color("#ffd87a", 0.055 * lamp_pulse))
	draw_circle(lamp_center, tile_size * 0.14, Color("#ffd87a", 0.78))
	draw_circle(lamp_center, tile_size * 0.9, Color("#ffd87a", 0.065 * lamp_pulse))
	for index in range(4):
		var dust := fposmod(animation_time * 0.24 + float(index) * 0.31, 1.0)
		draw_rect(
			Rect2(
				Vector2(lamp_x - tile_size * (0.42 - dust * 0.78), origin.y + tile_size * (3.15 + float(index) * 0.28)),
				Vector2(tile_size * 0.045, tile_size * 0.018)
			),
			Color("#f0d18a", 0.18 * lamp_pulse)
		)


func _draw_terrain_overlay(origin: Vector2, tile_size: float, terrain: String) -> void:
	if terrain in ["wilderness", "forest"]:
		var shadow := Color("#050608", 0.12 if terrain == "wilderness" else 0.22)
		for index in range(4):
			var x := origin.x + tile_size * (float(index) * 3.6 + 0.5)
			draw_rect(Rect2(Vector2(x, origin.y + tile_size), Vector2(tile_size * 0.28, tile_size * (ROWS - 2))), shadow)
	elif terrain == "street" and session.scene_id == "00-prologue-lights-out":
		_draw_prologue_street_lights(origin, tile_size)
	elif terrain in ["ruin", "dead_city"]:
		var pulse := 0.1 + sin(animation_time * 0.8) * 0.03
		draw_rect(Rect2(origin + Vector2(tile_size, tile_size), Vector2(tile_size * (COLUMNS - 2), tile_size * (ROWS - 2))), Color("#050608", pulse))
	elif terrain == "node":
		for index in range(5):
			var y := origin.y + tile_size * (2.0 + index)
			draw_line(Vector2(origin.x + tile_size * 1.5, y), Vector2(origin.x + tile_size * 13.5, y), Color(GameThemeScript.COLORS.cyan.r, GameThemeScript.COLORS.cyan.g, GameThemeScript.COLORS.cyan.b, 0.12), maxf(1.0, tile_size * 0.018))


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
		if _is_building_lobby():
			_draw_lobby_tile(x, y, top_left, tile_size)
		elif edge or y <= 1:
			draw_rect(rect, Color("#24201c"))
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.84), Vector2(tile_size, tile_size * 0.08)), Color("#3f2a18"))
		else:
			draw_rect(rect, Color("#20252a"))
			draw_rect(rect, Color("#343a40", 0.16), false, maxf(1.0, tile_size * 0.01))
			if y % 2 == 0:
				draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.08), Vector2(tile_size, tile_size * 0.035)), Color("#2d3338", 0.24))
			if (x + y) % 2 == 0:
				draw_rect(Rect2(top_left + Vector2(tile_size * 0.18, tile_size * 0.18), Vector2(tile_size * 0.08, tile_size * 0.08)), Color("#111519", 0.18))
	else:
		if edge or y <= 1:
			draw_rect(rect, Color("#2a231d"))
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.82), Vector2(tile_size, tile_size * 0.1)), Color("#51351f"))
		else:
			draw_rect(rect, Color("#3b2a1d"))
			var board_height := maxf(1.0, tile_size * 0.08)
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.46), Vector2(tile_size, board_height)), Color("#5a3a20", 0.28))
			if x % 3 == 0:
				draw_rect(Rect2(top_left + Vector2(tile_size * 0.04, 0), Vector2(maxf(1.0, tile_size * 0.012), tile_size)), Color("#24160d", 0.18))


func _draw_lobby_tile(x: int, y: int, top_left: Vector2, tile_size: float) -> void:
	var rect := Rect2(top_left, Vector2(tile_size, tile_size))
	if y <= 1:
		draw_rect(rect, Color("#1a1815"))
		draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.82), Vector2(tile_size, tile_size * 0.08)), Color("#45301d", 0.62))
		if x in [6, 7, 8]:
			draw_rect(Rect2(top_left + Vector2(tile_size * 0.1, tile_size * 0.2), Vector2(tile_size * 0.8, tile_size * 0.1)), Color("#080706"))
	elif y in [2, 3]:
		draw_rect(rect, Color("#24201b"))
		if x in [2, 12]:
			draw_rect(Rect2(top_left + Vector2(tile_size * 0.24, 0), Vector2(tile_size * 0.1, tile_size)), Color("#0b0907", 0.68))
	else:
		draw_rect(rect, Color("#2b2e30"))
		draw_rect(rect, Color("#43484b", 0.42), false, maxf(1.0, tile_size * 0.015))
		if y == 5:
			draw_rect(Rect2(top_left + Vector2(0, tile_size * 0.46), Vector2(tile_size, tile_size * 0.08)), Color("#62676a", 0.28))
		if x in [5, 9]:
			draw_rect(Rect2(top_left + Vector2(tile_size * 0.46, 0), Vector2(tile_size * 0.06, tile_size)), Color("#151719", 0.25))


func _draw_scene_dressing(origin: Vector2, tile_size: float, visual: Dictionary) -> void:
	if session == null or session.scene_id != "00-prologue-lights-out":
		return
	match session.location_id:
		"street":
			_draw_street_dressing(origin, tile_size)
		"building":
			_draw_lobby_dressing(origin, tile_size)
		"home":
			_draw_entry_dressing(origin, tile_size)
		"living_room":
			_draw_living_room_dressing(origin, tile_size)
		"study":
			_draw_study_dressing(origin, tile_size)
		"bedroom":
			_draw_bedroom_dressing(origin, tile_size)


func _draw_street_dressing(origin: Vector2, tile_size: float) -> void:
	for index in range(6):
		var x := origin.x + tile_size * (1.2 + float(index) * 2.2)
		draw_rect(Rect2(Vector2(x, origin.y + tile_size * 5.48), Vector2(tile_size * 0.72, tile_size * 0.055)), Color("#d8ceb0", 0.18))
	draw_rect(Rect2(origin + Vector2(0, tile_size * 3.0), Vector2(tile_size * COLUMNS, tile_size * 0.08)), Color("#5a5146", 0.36))
	draw_rect(Rect2(origin + Vector2(0, tile_size * 6.05), Vector2(tile_size * COLUMNS, tile_size * 0.06)), Color("#0b0d0e", 0.44))
	for index in range(5):
		var paper_pos := origin + Vector2(tile_size * (1.0 + float(index) * 2.6), tile_size * (6.4 + float(index % 2) * 0.32))
		draw_rect(Rect2(paper_pos, Vector2(tile_size * 0.32, tile_size * 0.08)), Color("#d8ceb0", 0.18))
	draw_line(origin + Vector2(tile_size * 9.2, tile_size * 1.15), origin + Vector2(tile_size * 13.7, tile_size * 2.55), Color("#050608", 0.32), maxf(1.0, tile_size * 0.018))


func _draw_lobby_dressing(origin: Vector2, tile_size: float) -> void:
	draw_rect(Rect2(origin + Vector2(tile_size * 0.9, tile_size * 4.82), Vector2(tile_size * 1.1, tile_size * 0.12)), Color("#101214", 0.52))
	draw_rect(Rect2(origin + Vector2(tile_size * 12.9, tile_size * 4.82), Vector2(tile_size * 1.1, tile_size * 0.12)), Color("#101214", 0.52))
	var notice := Rect2(origin + Vector2(tile_size * 3.0, tile_size * 3.15), Vector2(tile_size * 1.05, tile_size * 0.72))
	draw_rect(notice, Color("#2b2117"))
	draw_rect(notice, Color("#8f7040", 0.72), false, maxf(1.0, tile_size * 0.02))
	for row in range(3):
		draw_rect(Rect2(notice.position + Vector2(tile_size * 0.16, tile_size * (0.16 + row * 0.16)), Vector2(tile_size * 0.72, tile_size * 0.035)), Color("#d8ceb0", 0.42))
	var elevator := Rect2(origin + Vector2(tile_size * 6.25, tile_size * 1.1), Vector2(tile_size * 2.5, tile_size * 1.05))
	draw_rect(elevator, Color("#121313", 0.42))
	draw_rect(elevator, Color("#3f2a18", 0.6), false, maxf(1.0, tile_size * 0.025))
	draw_line(elevator.position + Vector2(elevator.size.x * 0.5, 0), elevator.position + Vector2(elevator.size.x * 0.5, elevator.size.y), Color("#050608", 0.58), maxf(1.0, tile_size * 0.018))
	draw_circle(origin + Vector2(tile_size * 7.48, tile_size * 2.3), tile_size * 0.08, Color("#d7b15e", 0.38 + sin(animation_time * 3.0) * 0.1))


func _draw_entry_dressing(origin: Vector2, tile_size: float) -> void:
	var shoe_rack := Rect2(origin + Vector2(tile_size * 2.2, tile_size * 1.2), Vector2(tile_size * 2.1, tile_size * 0.72))
	draw_rect(shoe_rack, Color("#2b1d10", 0.76))
	draw_rect(shoe_rack, Color("#8f7040", 0.45), false, maxf(1.0, tile_size * 0.018))
	for index in range(3):
		draw_rect(Rect2(shoe_rack.position + Vector2(tile_size * (0.25 + index * 0.48), tile_size * 0.38), Vector2(tile_size * 0.28, tile_size * 0.1)), Color("#050608", 0.68))
	var coat_shadow := Rect2(origin + Vector2(tile_size * 10.5, tile_size * 1.0), Vector2(tile_size * 1.4, tile_size * 1.4))
	draw_rect(coat_shadow, Color("#050608", 0.32))
	draw_line(coat_shadow.position + Vector2(tile_size * 0.5, tile_size * 0.2), coat_shadow.position + Vector2(tile_size * 0.25, tile_size * 0.9), Color("#14100c", 0.74), maxf(1.0, tile_size * 0.04))
	draw_line(coat_shadow.position + Vector2(tile_size * 0.5, tile_size * 0.2), coat_shadow.position + Vector2(tile_size * 0.8, tile_size * 0.9), Color("#14100c", 0.74), maxf(1.0, tile_size * 0.04))
	draw_rect(Rect2(origin + Vector2(tile_size * 5.85, tile_size * 3.0), Vector2(tile_size * 1.8, tile_size * 0.12)), Color("#0b0d0e", 0.5))


func _draw_living_room_dressing(origin: Vector2, tile_size: float) -> void:
	var rug := Rect2(origin + Vector2(tile_size * 5.75, tile_size * 3.5), Vector2(tile_size * 3.8, tile_size * 1.55))
	draw_rect(rug, Color("#3b2330", 0.52))
	draw_rect(rug.grow(-tile_size * 0.12), Color("#6b2630", 0.22), false, maxf(1.0, tile_size * 0.02))
	var tv_glow := Rect2(origin + Vector2(tile_size * 10.9, tile_size * 2.65), Vector2(tile_size * 1.35, tile_size * 1.0))
	draw_rect(tv_glow, Color("#050608", 0.32))
	draw_rect(tv_glow.grow(tile_size * 0.18), Color("#b9d1c4", 0.045 + sin(animation_time * 1.4) * 0.015))
	var cabinet := Rect2(origin + Vector2(tile_size * 1.4, tile_size * 2.15), Vector2(tile_size * 2.6, tile_size * 0.55))
	draw_rect(cabinet, Color("#25180f", 0.68))
	for index in range(3):
		draw_rect(Rect2(cabinet.position + Vector2(tile_size * (0.2 + index * 0.72), tile_size * 0.18), Vector2(tile_size * 0.48, tile_size * 0.08)), Color("#8f7040", 0.36))


func _draw_study_dressing(origin: Vector2, tile_size: float) -> void:
	draw_rect(Rect2(origin + Vector2(tile_size * 4.0, tile_size * 2.95), Vector2(tile_size * 2.7, tile_size * 0.38)), Color("#050608", 0.18))
	var lamp_center := origin + Vector2(tile_size * 4.25, tile_size * 2.65)
	draw_circle(lamp_center, tile_size * 0.52, Color("#f0d18a", 0.045 + sin(animation_time * 2.2) * 0.012))
	draw_line(lamp_center, lamp_center + Vector2(tile_size * 0.34, tile_size * 0.34), Color("#2b1d10"), maxf(1.0, tile_size * 0.035))
	draw_rect(Rect2(lamp_center + Vector2(tile_size * 0.24, tile_size * 0.28), Vector2(tile_size * 0.42, tile_size * 0.08)), Color("#d7b15e", 0.36))
	draw_line(origin + Vector2(tile_size * 8.05, tile_size * 5.2), origin + Vector2(tile_size * 7.4, tile_size * 4.2), Color("#050608", 0.46), maxf(1.0, tile_size * 0.018))
	for index in range(4):
		draw_rect(Rect2(origin + Vector2(tile_size * (9.95 + float(index % 2) * 0.35), tile_size * (1.4 + float(index) * 0.62)), Vector2(tile_size * 0.18, tile_size * 0.06)), Color("#d8ceb0", 0.28))


func _draw_bedroom_dressing(origin: Vector2, tile_size: float) -> void:
	var curtain_left := Rect2(origin + Vector2(tile_size * 10.9, tile_size * 0.95), Vector2(tile_size * 0.18, tile_size * 0.9))
	var curtain_right := Rect2(origin + Vector2(tile_size * 11.95, tile_size * 0.95), Vector2(tile_size * 0.18, tile_size * 0.9))
	draw_rect(curtain_left, Color("#293647", 0.62))
	draw_rect(curtain_right, Color("#293647", 0.62))
	for index in range(3):
		var wind := origin + Vector2(tile_size * (10.6 + float(index) * 0.52), tile_size * (1.95 + float(index % 2) * 0.22))
		draw_line(wind, wind + Vector2(tile_size * 0.42, -tile_size * 0.08), Color("#d8ceb0", 0.16), maxf(1.0, tile_size * 0.014))
	var desk_pool := Rect2(origin + Vector2(tile_size * 6.75, tile_size * 2.2), Vector2(tile_size * 2.3, tile_size * 1.2))
	draw_rect(desk_pool, Color("#f0d18a", 0.035 + sin(animation_time * 1.6) * 0.01))
	for index in range(8):
		var speck := origin + Vector2(tile_size * (11.7 + sin(float(index)) * 0.55), tile_size * (4.0 + cos(float(index) * 1.7) * 0.48))
		draw_rect(Rect2(speck, Vector2(tile_size * 0.05, tile_size * 0.05)), Color("#050608", 0.52))


func _draw_tile_noise(top_left: Vector2, tile_size: float, color: Color) -> void:
	for index in range(3):
		var offset := Vector2(tile_size * (0.18 + index * 0.22), tile_size * (0.22 + ((index * 2) % 3) * 0.16))
		draw_rect(Rect2(top_left + offset, Vector2(tile_size * 0.08, tile_size * 0.04)), color)


func _draw_location_objects(origin: Vector2, tile_size: float, visual: Dictionary) -> void:
	if not visual.is_empty():
		if _is_illiterate_station():
			_draw_station_blankening(origin, tile_size)
		for prop in visual.get("props", []):
			if not _prop_visible_for_session(prop):
				continue
			_draw_visual_prop(prop, origin, tile_size)
			_draw_visual_prop_focus(prop, origin, tile_size)
		if session.has_flag(str(session.scene.get("ending_flag", ""))):
			_draw_magic_orb(Rect2(origin + Vector2(12, 4) * tile_size, Vector2(tile_size, tile_size)))
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
		_draw_magic_orb(Rect2(origin + Vector2(7, 4) * tile_size, Vector2(tile_size, tile_size)))

	var combat: Dictionary = location.get("combat", {})
	if not combat.is_empty() and session.enemy_hp > 0:
		_draw_dungeon_tile(Vector2i(6, 2), origin + Vector2(10, 4) * tile_size, tile_size)
		_draw_fireball(Rect2(origin + Vector2(9, 4) * tile_size, Vector2(tile_size, tile_size)))


func _draw_actors(origin: Vector2, tile_size: float, _visual: Dictionary) -> void:
	var bob := 0.0
	if player_moving:
		bob = -tile_size * 0.045 if fmod(animation_time / 0.12, 2.0) >= 1.0 else 0.0
	var player_top_left := origin + player_tile * tile_size + Vector2(0, bob)
	_draw_player_actor(player_top_left, tile_size)
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
			_draw_paper_icon(Rect2(top_left + Vector2(tile_size * 0.15, tile_size * 0.1), Vector2(tile_size * 0.7, tile_size * 0.8)))
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


func _draw_visual_prop_focus(prop: Dictionary, origin: Vector2, tile_size: float) -> void:
	if not (prop.has("item") or prop.has("exit") or prop.has("action")):
		return
	if str(prop.get("kind", "")) == "shadow":
		return
	var prop_tile := Vector2(float(prop.get("x", 0)), float(prop.get("y", 0)))
	var prop_size := Vector2(float(prop.get("w", 1)), float(prop.get("h", 1)))
	var rect := Rect2(origin + prop_tile * tile_size, prop_size * tile_size)
	var center_tile := prop_tile + prop_size * 0.5
	var distance := absf(player_tile.x - center_tile.x) + absf(player_tile.y - center_tile.y)
	var active := _is_active_interaction_prop(prop)
	var nearby := active or distance <= 1.65
	var base_color: Color = GameThemeScript.COLORS.cyan if prop.has("exit") else GameThemeScript.COLORS.gold
	if str(prop.get("kind", "")) == "pen":
		base_color = GameThemeScript.COLORS.danger
	var pulse := 0.5 + sin(animation_time * 3.2 + center_tile.x + center_tile.y) * 0.5
	var alpha := 0.12 + pulse * 0.08
	if nearby:
		alpha = 0.26 + pulse * 0.18
	if active:
		alpha = 0.42 + pulse * 0.22
	var focus_color := Color(base_color.r, base_color.g, base_color.b, alpha)
	var center := rect.get_center()
	var radius := tile_size * (0.58 if active else (0.42 if nearby else 0.28))
	if active:
		var ground := Rect2(
			Vector2(rect.position.x + rect.size.x * 0.16, rect.position.y + rect.size.y - tile_size * 0.14),
			Vector2(rect.size.x * 0.68, tile_size * 0.1)
		)
		draw_rect(ground.grow(tile_size * 0.1), Color(base_color.r, base_color.g, base_color.b, alpha * 0.18))
		draw_rect(ground, Color(base_color.r, base_color.g, base_color.b, alpha * 0.24))
	draw_circle(center, radius, Color(base_color.r, base_color.g, base_color.b, alpha * 0.22))
	draw_circle(center, radius * 0.18, Color(base_color.r, base_color.g, base_color.b, alpha))
	var glint_width := maxf(1.0, tile_size * 0.018)
	for index in range(4):
		var angle := animation_time * 0.8 + float(index) * 1.57
		var inner := center + Vector2(cos(angle), sin(angle)) * radius * 0.62
		var outer := center + Vector2(cos(angle), sin(angle)) * radius
		draw_line(inner, outer, focus_color, glint_width)
	if nearby:
		var marker_center := Vector2(center.x, rect.position.y - tile_size * 0.16)
		var marker := PackedVector2Array([
			marker_center + Vector2(0, -tile_size * 0.12),
			marker_center + Vector2(tile_size * 0.12, 0),
			marker_center + Vector2(0, tile_size * 0.12),
			marker_center + Vector2(-tile_size * 0.12, 0),
		])
		draw_colored_polygon(marker, focus_color)
		draw_colored_polygon(marker, Color("#050608", 0.28))
		if active:
			var small := marker_center + Vector2(0, -tile_size * 0.22)
			var spark := PackedVector2Array([
				small + Vector2(0, -tile_size * 0.08),
				small + Vector2(tile_size * 0.08, 0),
				small + Vector2(0, tile_size * 0.08),
				small + Vector2(-tile_size * 0.08, 0),
			])
			draw_colored_polygon(spark, Color("#f1ead4", alpha * 0.7))


func _is_active_interaction_prop(prop: Dictionary) -> bool:
	if not (prop.has("item") or prop.has("exit") or prop.has("action")):
		return false
	var prop_x := float(prop.get("x", 0))
	var prop_y := float(prop.get("y", 0))
	var prop_w := maxf(1.0, float(prop.get("w", 1)))
	var prop_h := maxf(1.0, float(prop.get("h", 1)))
	var player_cell := Vector2i(roundi(player_tile.x), roundi(player_tile.y))
	var facing_cell := player_cell + player_facing
	return _prop_contains_cell(prop_x, prop_y, prop_w, prop_h, player_cell) or _prop_contains_cell(prop_x, prop_y, prop_w, prop_h, facing_cell)


func _prop_contains_cell(prop_x: float, prop_y: float, prop_w: float, prop_h: float, cell: Vector2i) -> bool:
	return float(cell.x) >= prop_x and float(cell.x) < prop_x + prop_w and float(cell.y) >= prop_y and float(cell.y) < prop_y + prop_h


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
			_draw_campfire(position, tile_size)
		"city_fire":
			_draw_city_fire(position, tile_size)
		"sign":
			_draw_text_surface(position, tile_size, false)
		"notice":
			_draw_text_surface(position, tile_size, true)
		"pen":
			_draw_pen_threat(position, tile_size)
		"vending":
			_draw_vending_machine(position, tile_size)
		"phone":
			_draw_phone_device(position, tile_size, session.has_flag("checked_phone_no_service"))
		"tv":
			_draw_tv_device(position, tile_size)
		"mailbox":
			_draw_mailbox(position, tile_size)
		"door_open":
			_draw_open_door(position, tile_size)
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
			_draw_magic_orb(Rect2(position, Vector2(tile_size, tile_size)))
		"portal":
			if _uses_modern_scene_props():
				_draw_ink_threshold(position, tile_size, session.has_flag(str(session.scene.get("ending_flag", ""))))
			elif session.has_flag(str(session.scene.get("ending_flag", ""))):
				_draw_magic_orb(Rect2(position, Vector2(tile_size, tile_size)))
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
		"xiali_echo":
			_draw_xiali_echo(position, tile_size)
		"private_anchor":
			_draw_private_anchor(position, tile_size)
		"remote_classroom":
			_draw_remote_classroom(position, tile_size)
		"parent_echo":
			_draw_parent_echo(position, tile_size)
		"bridge_static":
			_draw_bridge_static(position, tile_size)
		"route_marker":
			_draw_route_marker(str(prop.get("route", "")), position, tile_size)
		"academy_seal":
			_draw_academy_seal(position, tile_size, width, height)
		"construction_frame":
			_draw_construction_frame(position, tile_size, width, height)
		"order_monument":
			_draw_order_monument(position, tile_size, width, height)
		"factory_stack":
			_draw_factory_stack(position, tile_size, width, height)
		"astral_dial":
			_draw_astral_dial(position, tile_size, width, height)
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
			_draw_paper_icon(Rect2(position + Vector2(tile_size * 0.15, tile_size * 0.1), Vector2(tile_size * 0.7, tile_size * 0.8)))
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
	var floor_count: int = maxi(3, height)
	var column_count: int = maxi(3, width)
	draw_rect(rect, Color("#282923"))
	draw_rect(Rect2(rect.position + Vector2(tile_size * 0.08, 0), Vector2(rect.size.x * 0.22, rect.size.y)), Color("#1a1b17", 0.48))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.72, 0), Vector2(rect.size.x * 0.16, rect.size.y)), Color("#161714", 0.36))
	draw_rect(rect, Color("#5a472c"), false, maxf(2.0, tile_size * 0.035))
	draw_rect(Rect2(top_left + Vector2(-tile_size * 0.05, -tile_size * 0.12), Vector2(rect.size.x + tile_size * 0.1, tile_size * 0.18)), Color("#16120e"))
	draw_rect(Rect2(top_left + Vector2(-tile_size * 0.05, -tile_size * 0.12), Vector2(rect.size.x + tile_size * 0.1, tile_size * 0.18)), Color("#8f7040", 0.52), false, maxf(1.0, tile_size * 0.025))
	for floor in range(floor_count):
		var floor_y := top_left.y + tile_size * (0.28 + floor * 0.82)
		draw_rect(Rect2(Vector2(top_left.x, floor_y + tile_size * 0.52), Vector2(rect.size.x, tile_size * 0.05)), Color("#100f0c", 0.36))
		for column in range(column_count):
			var window_pos := top_left + Vector2(tile_size * (0.18 + column * 0.86), tile_size * (0.22 + floor * 0.82))
			var window_rect := Rect2(window_pos, Vector2(tile_size * 0.46, tile_size * 0.36))
			var home_window := floor == 1 and column == 1
			var lit := (floor + column) % 2 == 0 and not home_window
			var flicker := clampf(
				0.78
					+ sin(animation_time * (1.6 + float(column) * 0.27) + float(floor)) * 0.12
					+ sin(animation_time * 8.0 + float(floor + column) * 1.7) * 0.08,
				0.54,
				1.0
			)
			if lit:
				draw_rect(window_rect.grow(tile_size * 0.14), Color("#f0d18a", 0.16 * flicker))
			draw_rect(window_rect, Color("#07090a"))
			if lit:
				draw_rect(window_rect.grow(-tile_size * 0.05), Color("#ffd87a", 0.95 * flicker))
				draw_rect(Rect2(window_rect.position + Vector2(tile_size * 0.04, tile_size * 0.04), Vector2(window_rect.size.x * 0.34, window_rect.size.y - tile_size * 0.08)), Color("#d45c55", 0.24))
				draw_rect(Rect2(window_rect.position + Vector2(window_rect.size.x * 0.62, tile_size * 0.04), Vector2(window_rect.size.x * 0.16, window_rect.size.y - tile_size * 0.08)), Color("#3f2a18", 0.34))
			else:
				draw_rect(window_rect.grow(-tile_size * 0.05), Color("#050608", 0.86))
			draw_rect(window_rect, Color("#b7a780", 0.62), false, maxf(1.0, tile_size * 0.018))
			draw_line(window_rect.position + Vector2(window_rect.size.x * 0.5, 0), window_rect.position + Vector2(window_rect.size.x * 0.5, window_rect.size.y), Color("#1d2023", 0.7), maxf(1.0, tile_size * 0.012))
			if home_window:
				draw_rect(window_rect.grow(tile_size * 0.05), Color("#050608", 0.42))
				draw_rect(window_rect.grow(tile_size * 0.05), Color(GameThemeScript.COLORS.paper.r, GameThemeScript.COLORS.paper.g, GameThemeScript.COLORS.paper.b, 0.46), false, maxf(1.0, tile_size * 0.02))
	for column in range(column_count - 1):
		var balcony := Rect2(top_left + Vector2(tile_size * (0.72 + column * 0.86), tile_size * 2.6), Vector2(tile_size * 0.5, tile_size * 0.08))
		draw_rect(balcony, Color("#5a472c"))
		draw_rect(balcony, Color("#d8ceb0", 0.34), false, maxf(1.0, tile_size * 0.012))
	var entrance := Rect2(top_left + Vector2(tile_size * 0.36, rect.size.y - tile_size * 0.78), Vector2(tile_size * 0.58, tile_size * 0.68))
	draw_rect(entrance, Color("#050608"))
	draw_rect(entrance, Color("#8f7040"), false, maxf(1.0, tile_size * 0.025))
	draw_rect(Rect2(entrance.position + Vector2(tile_size * 0.12, tile_size * 0.1), Vector2(tile_size * 0.34, tile_size * 0.12)), Color("#d7b15e", 0.26 + sin(animation_time * 1.8) * 0.06))


func _draw_apartment_exit(top_left: Vector2, tile_size: float) -> void:
	var frame := Rect2(top_left + Vector2(tile_size * 0.2, tile_size * 0.08), Vector2(tile_size * 0.6, tile_size * 0.84))
	draw_rect(frame, Color("#2e2f31"))
	draw_rect(frame, Color("#8f7040"), false, maxf(1.0, tile_size * 0.035))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.32, tile_size * 0.18), Vector2(tile_size * 0.36, tile_size * 0.5)), Color("#08090a"))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.38, tile_size * 0.72), Vector2(tile_size * 0.24, tile_size * 0.08)), Color("#3f2a18"))


func _draw_dark_window(top_left: Vector2, tile_size: float) -> void:
	var frame := Rect2(top_left + Vector2(tile_size * 0.08, tile_size * 0.08), Vector2(tile_size * 0.84, tile_size * 0.76))
	draw_rect(frame, Color("#161817"))
	draw_rect(frame, Color("#f1ead4", 0.54), false, maxf(1.0, tile_size * 0.035))
	var glass := Rect2(top_left + Vector2(tile_size * 0.18, tile_size * 0.18), Vector2(tile_size * 0.64, tile_size * 0.52))
	draw_rect(glass, Color("#030405"))
	draw_rect(glass, Color("#050608", 0.82 + sin(animation_time * 1.7) * 0.06))
	draw_line(glass.position + Vector2(glass.size.x * 0.5, 0), glass.position + Vector2(glass.size.x * 0.5, glass.size.y), Color("#2a2f34"), maxf(1.0, tile_size * 0.018))
	draw_line(glass.position + Vector2(0, glass.size.y * 0.5), glass.position + Vector2(glass.size.x, glass.size.y * 0.5), Color("#2a2f34"), maxf(1.0, tile_size * 0.018))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.22, tile_size * 0.76), Vector2(tile_size * 0.56, tile_size * 0.06)), Color("#8f7040", 0.72))


func _draw_voice_lamp(top_left: Vector2, tile_size: float) -> void:
	var center := top_left + Vector2(tile_size * 0.5, tile_size * 0.3)
	var failed_glow := 0.08 + maxf(0.0, sin(animation_time * 5.0)) * 0.08
	var spark := maxf(0.0, sin(animation_time * 11.0))
	draw_line(top_left + Vector2(tile_size * 0.5, 0), center, Color("#3f2a18"), maxf(1.0, tile_size * 0.035))
	draw_circle(center, tile_size * 0.5, Color("#d7b15e", failed_glow))
	draw_circle(center, tile_size * 0.22, Color("#26231d"))
	draw_circle(center, tile_size * 0.12, Color("#050608"))
	draw_circle(center, tile_size * 0.22, Color("#d8ceb0", 0.62), false, maxf(1.0, tile_size * 0.028))
	draw_line(center + Vector2(-tile_size * 0.12, -tile_size * 0.04), center + Vector2(tile_size * 0.1, tile_size * 0.06), Color("#ffd87a", 0.36 * spark), maxf(1.0, tile_size * 0.018))
	draw_line(center + Vector2(tile_size * 0.1, -tile_size * 0.06), center + Vector2(-tile_size * 0.04, tile_size * 0.1), Color("#ffd87a", 0.26 * spark), maxf(1.0, tile_size * 0.018))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.25, tile_size * 0.58), Vector2(tile_size * 0.5, tile_size * 0.08)), Color("#050608", 0.65))
	for index in range(2):
		var mark_x := tile_size * (0.36 + index * 0.18)
		draw_rect(Rect2(top_left + Vector2(mark_x, tile_size * 0.72), Vector2(tile_size * 0.08, tile_size * 0.04)), Color("#f1ead4", 0.42))


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
	var flutter := sin(animation_time * 3.0) * tile_size * 0.025 if kind == "poster" else 0.0
	var page := Rect2(top_left + Vector2(tile_size * 0.22 + flutter, tile_size * 0.12), Vector2(tile_size * 0.56, tile_size * 0.72))
	draw_rect(page, Color("#d8ceb0"))
	draw_rect(page, Color("#8f7040"), false, maxf(1.0, tile_size * 0.025))
	for row in range(3):
		draw_rect(Rect2(top_left + Vector2(tile_size * 0.3 + flutter, tile_size * (0.28 + row * 0.13)), Vector2(tile_size * 0.38, tile_size * 0.035)), Color("#17110d", 0.7))
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
			Vector2(tile_size * 0.14, tile_size * (0.28 + sin(animation_time * 1.5 + column) * 0.025))
		)
		draw_rect(tower, Color("#1d1611"))
		draw_rect(tower, Color("#8f7040"), false, maxf(1.0, tile_size * 0.025))
	_draw_flame(top_left + Vector2(tile_size * 0.23, tile_size * 0.28), tile_size * 0.22, 0.0)
	_draw_flame(top_left + Vector2(tile_size * 0.52, tile_size * 0.22), tile_size * 0.28, 0.7)
	_draw_flame(top_left + Vector2(tile_size * 0.76, tile_size * 0.32), tile_size * 0.2, 1.4)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.08, tile_size * 0.68), Vector2(tile_size * 0.84, tile_size * 0.08)),
		Color("#000000", 0.42)
	)


func _draw_campfire(top_left: Vector2, tile_size: float) -> void:
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.28, tile_size * 0.7), Vector2(tile_size * 0.44, tile_size * 0.08)), Color("#2b1d10"))
	_draw_flame(top_left + Vector2(tile_size * 0.5, tile_size * 0.52), tile_size * 0.28, 2.1)
	draw_circle(top_left + Vector2(tile_size * 0.5, tile_size * 0.58), tile_size * 0.32, Color("#d45c55", 0.12 + sin(animation_time * 2.4) * 0.04))


func _draw_flame(center: Vector2, size: float, phase: float = 0.0) -> void:
	var flicker := 1.0 + sin(animation_time * 6.0 + phase) * 0.12
	var flame_size := size * flicker
	var outer := PackedVector2Array([
		center + Vector2(0, -flame_size),
		center + Vector2(flame_size * 0.52, flame_size * 0.55),
		center + Vector2(-flame_size * 0.52, flame_size * 0.55),
	])
	var inner := PackedVector2Array([
		center + Vector2(0, -flame_size * 0.45),
		center + Vector2(flame_size * 0.25, flame_size * 0.35),
		center + Vector2(-flame_size * 0.25, flame_size * 0.35),
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
		ink_offset = sin(animation_time * 5.5) * tile_size * 0.035
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


func _draw_xiali_echo(top_left: Vector2, tile_size: float) -> void:
	var pulse := 0.6 + sin(animation_time * 2.1) * 0.18
	var centers := [
		top_left + Vector2(tile_size * 0.32, tile_size * 0.36),
		top_left + Vector2(tile_size * 0.68, tile_size * 0.34),
		top_left + Vector2(tile_size * 0.5, tile_size * 0.72),
	]
	for index in range(centers.size()):
		var center: Vector2 = centers[index]
		var alpha := 0.18 + pulse * 0.12 - float(index) * 0.025
		draw_circle(center, tile_size * 0.18, Color("#75d9e6", alpha))
		draw_rect(
			Rect2(center + Vector2(-tile_size * 0.08, tile_size * 0.14), Vector2(tile_size * 0.16, tile_size * 0.22)),
			Color("#d7f7ff", alpha * 0.9)
		)
	for index in range(centers.size()):
		var next_index := (index + 1) % centers.size()
		draw_line(centers[index], centers[next_index], Color("#75d9e6", 0.28), maxf(1.0, tile_size * 0.025))
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.12, tile_size * 0.12), Vector2(tile_size * 0.76, tile_size * 0.76)),
		Color("#75d9e6", 0.22),
		false,
		maxf(1.0, tile_size * 0.025)
	)


func _draw_private_anchor(top_left: Vector2, tile_size: float) -> void:
	var wood := Color("#6b4a2e")
	var light := Color("#d7b15e")
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.22, tile_size * 0.3), Vector2(tile_size * 0.46, tile_size * 0.12)), wood)
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.24, tile_size * 0.42), Vector2(tile_size * 0.42, tile_size * 0.18)), Color("#3b2b20"))
	draw_line(top_left + Vector2(tile_size * 0.28, tile_size * 0.6), top_left + Vector2(tile_size * 0.2, tile_size * 0.86), wood, maxf(2.0, tile_size * 0.04))
	draw_line(top_left + Vector2(tile_size * 0.62, tile_size * 0.6), top_left + Vector2(tile_size * 0.72, tile_size * 0.86), wood, maxf(2.0, tile_size * 0.04))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.54, tile_size * 0.14), Vector2(tile_size * 0.26, tile_size * 0.18)), Color("#f0d18a"))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.54, tile_size * 0.14), Vector2(tile_size * 0.26, tile_size * 0.18)), light, false, maxf(1.0, tile_size * 0.025))
	draw_circle(top_left + Vector2(tile_size * 0.66, tile_size * 0.23), tile_size * 0.025, Color("#3b2b20"))


func _draw_remote_classroom(top_left: Vector2, tile_size: float) -> void:
	var screen := Rect2(top_left + Vector2(tile_size * 0.12, tile_size * 0.18), Vector2(tile_size * 0.76, tile_size * 0.48))
	draw_rect(screen, Color("#102531"))
	draw_rect(screen, Color("#75d9e6", 0.55), false, maxf(1.0, tile_size * 0.025))
	for index in range(3):
		var y := screen.position.y + tile_size * (0.12 + float(index) * 0.12)
		draw_line(screen.position + Vector2(tile_size * 0.12, y - screen.position.y), screen.position + Vector2(screen.size.x - tile_size * 0.12, y - screen.position.y), Color("#d7f7ff", 0.35), maxf(1.0, tile_size * 0.015))
	for index in range(3):
		var x := top_left.x + tile_size * (0.26 + float(index) * 0.22)
		draw_circle(Vector2(x, top_left.y + tile_size * 0.78), tile_size * 0.055, Color("#f0d18a"))
		draw_rect(Rect2(Vector2(x - tile_size * 0.045, top_left.y + tile_size * 0.84), Vector2(tile_size * 0.09, tile_size * 0.08)), Color("#6b4a2e"))


func _draw_parent_echo(top_left: Vector2, tile_size: float) -> void:
	var panel := Rect2(top_left + Vector2(tile_size * 0.12, tile_size * 0.12), Vector2(tile_size * 0.76, tile_size * 0.76))
	draw_rect(panel, Color("#d7f7ff", 0.1))
	draw_rect(panel, Color("#75d9e6", 0.42), false, maxf(1.0, tile_size * 0.025))
	draw_circle(top_left + Vector2(tile_size * 0.36, tile_size * 0.36), tile_size * 0.12, Color("#f1ead4", 0.32))
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.3, tile_size * 0.5), Vector2(tile_size * 0.18, tile_size * 0.26)), Color("#f1ead4", 0.22))
	draw_circle(top_left + Vector2(tile_size * 0.63, tile_size * 0.34), tile_size * 0.055, Color("#f1ead4", 0.35))
	draw_circle(top_left + Vector2(tile_size * 0.74, tile_size * 0.34), tile_size * 0.055, Color("#f1ead4", 0.35))
	draw_line(top_left + Vector2(tile_size * 0.68, tile_size * 0.34), top_left + Vector2(tile_size * 0.69, tile_size * 0.34), Color("#f1ead4", 0.35), maxf(1.0, tile_size * 0.018))
	for index in range(3):
		var y := top_left.y + tile_size * (0.22 + float(index) * 0.2)
		draw_line(top_left + Vector2(tile_size * 0.14, y - top_left.y), top_left + Vector2(tile_size * (0.34 + float(index) * 0.16), y - top_left.y), Color("#050608", 0.36), maxf(1.0, tile_size * 0.02))


func _draw_bridge_static(top_left: Vector2, tile_size: float) -> void:
	var panel := Rect2(top_left + Vector2(tile_size * 0.1, tile_size * 0.16), Vector2(tile_size * 0.8, tile_size * 0.62))
	draw_rect(panel, Color("#f1ead4", 0.78))
	draw_rect(panel, Color("#050608", 0.55), false, maxf(1.0, tile_size * 0.025))
	for index in range(6):
		var x := panel.position.x + tile_size * (0.08 + float(index) * 0.12)
		var alpha := 0.22 + 0.08 * sin(animation_time * 4.0 + float(index))
		draw_line(Vector2(x, panel.position.y), Vector2(x + tile_size * 0.12, panel.end.y), Color("#050608", alpha), maxf(1.0, tile_size * 0.018))
	draw_circle(top_left + Vector2(tile_size * 0.36, tile_size * 0.42), tile_size * 0.11, Color("#75d9e6", 0.28))
	draw_circle(top_left + Vector2(tile_size * 0.64, tile_size * 0.42), tile_size * 0.11, Color("#d45c55", 0.22))


func _draw_route_marker(route: String, top_left: Vector2, tile_size: float) -> void:
	var base := Color("#d7b15e")
	if route == "royal":
		base = Color("#d45c55")
	elif route == "engineer":
		base = Color("#75d9e6")
	elif route == "parent":
		base = Color("#f1ead4")
	var rect := Rect2(top_left + Vector2(tile_size * 0.16, tile_size * 0.16), Vector2(tile_size * 0.68, tile_size * 0.68))
	draw_rect(rect, Color(base.r, base.g, base.b, 0.18))
	draw_rect(rect, Color(base.r, base.g, base.b, 0.65), false, maxf(1.0, tile_size * 0.03))
	match route:
		"royal":
			var crown := PackedVector2Array([
				top_left + Vector2(tile_size * 0.24, tile_size * 0.58),
				top_left + Vector2(tile_size * 0.35, tile_size * 0.36),
				top_left + Vector2(tile_size * 0.5, tile_size * 0.55),
				top_left + Vector2(tile_size * 0.65, tile_size * 0.36),
				top_left + Vector2(tile_size * 0.76, tile_size * 0.58),
			])
			draw_polyline(crown, base, maxf(2.0, tile_size * 0.045))
		"engineer":
			var center := top_left + Vector2(tile_size * 0.5, tile_size * 0.5)
			draw_circle(center, tile_size * 0.16, Color(base.r, base.g, base.b, 0.2))
			draw_circle(center, tile_size * 0.08, Color("#050608", 0.62))
			for index in range(6):
				var angle := float(index) * PI / 3.0
				draw_line(center + Vector2(cos(angle), sin(angle)) * tile_size * 0.16, center + Vector2(cos(angle), sin(angle)) * tile_size * 0.28, base, maxf(1.0, tile_size * 0.025))
		"parent":
			draw_rect(Rect2(top_left + Vector2(tile_size * 0.28, tile_size * 0.28), Vector2(tile_size * 0.44, tile_size * 0.38)), Color("#050608", 0.42))
			draw_circle(top_left + Vector2(tile_size * 0.42, tile_size * 0.45), tile_size * 0.06, base)
			draw_circle(top_left + Vector2(tile_size * 0.58, tile_size * 0.45), tile_size * 0.06, base)
		_:
			draw_line(top_left + Vector2(tile_size * 0.28, tile_size * 0.38), top_left + Vector2(tile_size * 0.5, tile_size * 0.56), base, maxf(2.0, tile_size * 0.04))
			draw_line(top_left + Vector2(tile_size * 0.72, tile_size * 0.38), top_left + Vector2(tile_size * 0.5, tile_size * 0.56), base, maxf(2.0, tile_size * 0.04))
			for index in range(3):
				draw_circle(top_left + Vector2(tile_size * (0.35 + float(index) * 0.15), tile_size * 0.72), tile_size * 0.035, base)


func _draw_academy_seal(top_left: Vector2, tile_size: float, width: int, height: int) -> void:
	var rect := Rect2(top_left, Vector2(tile_size * max(1, width), tile_size * max(1, height)))
	var center := rect.get_center()
	draw_circle(center, minf(rect.size.x, rect.size.y) * 0.42, Color("#0b130e", 0.28))
	draw_circle(center, minf(rect.size.x, rect.size.y) * 0.31, Color("#d7b15e", 0.12))
	draw_circle(center, minf(rect.size.x, rect.size.y) * 0.31, Color("#d7b15e", 0.44), false, maxf(2.0, tile_size * 0.035))
	draw_line(center + Vector2(-rect.size.x * 0.18, 0), center + Vector2(rect.size.x * 0.18, 0), Color("#f1ead4", 0.56), maxf(2.0, tile_size * 0.04))
	draw_line(center + Vector2(0, -rect.size.y * 0.22), center + Vector2(0, rect.size.y * 0.22), Color("#f1ead4", 0.42), maxf(2.0, tile_size * 0.035))
	for index in range(6):
		var angle := float(index) * TAU / 6.0
		draw_line(center + Vector2(cos(angle), sin(angle)) * rect.size.y * 0.16, center + Vector2(cos(angle), sin(angle)) * rect.size.y * 0.28, Color("#b9d1c4", 0.45), maxf(1.0, tile_size * 0.025))


func _draw_construction_frame(top_left: Vector2, tile_size: float, width: int, height: int) -> void:
	var rect := Rect2(top_left, Vector2(tile_size * max(1, width), tile_size * max(1, height)))
	var beam := maxf(2.0, tile_size * 0.06)
	draw_rect(rect, Color("#050608", 0.16))
	draw_rect(rect.grow(-tile_size * 0.12), Color("#d7b15e", 0.22), false, beam)
	for index in range(maxi(2, width + 1)):
		var x := rect.position.x + rect.size.x * float(index) / float(maxi(1, width))
		draw_line(Vector2(x, rect.position.y + tile_size * 0.2), Vector2(x, rect.end.y - tile_size * 0.2), Color("#d7b15e", 0.34), beam)
	for index in range(maxi(2, height + 1)):
		var y := rect.position.y + rect.size.y * float(index) / float(maxi(1, height))
		draw_line(Vector2(rect.position.x + tile_size * 0.2, y), Vector2(rect.end.x - tile_size * 0.2, y), Color("#8f7040", 0.36), beam)
	draw_line(rect.position + Vector2(tile_size * 0.2, rect.size.y - tile_size * 0.2), rect.end - Vector2(tile_size * 0.2, rect.size.y - tile_size * 0.2), Color("#f0d18a", 0.28), beam)


func _draw_order_monument(top_left: Vector2, tile_size: float, width: int, height: int) -> void:
	var rect := Rect2(top_left, Vector2(tile_size * max(1, width), tile_size * max(1, height)))
	var center := rect.get_center()
	draw_rect(Rect2(Vector2(center.x - rect.size.x * 0.23, rect.position.y + rect.size.y * 0.15), Vector2(rect.size.x * 0.46, rect.size.y * 0.7)), Color("#1c2020", 0.72))
	draw_rect(Rect2(Vector2(center.x - rect.size.x * 0.23, rect.position.y + rect.size.y * 0.15), Vector2(rect.size.x * 0.46, rect.size.y * 0.7)), Color("#8f7040", 0.54), false, maxf(2.0, tile_size * 0.04))
	for index in range(4):
		var y := rect.position.y + rect.size.y * (0.28 + float(index) * 0.12)
		draw_line(Vector2(center.x - rect.size.x * 0.14, y), Vector2(center.x + rect.size.x * 0.14, y), Color("#d8ceb0", 0.45), maxf(1.0, tile_size * 0.025))
	draw_circle(center + Vector2(0, rect.size.y * 0.18), tile_size * 0.18, Color("#75d9e6", 0.16))


func _draw_factory_stack(top_left: Vector2, tile_size: float, width: int, height: int) -> void:
	var rect := Rect2(top_left, Vector2(tile_size * max(1, width), tile_size * max(1, height)))
	var stack_rect := Rect2(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.12), Vector2(rect.size.x * 0.18, rect.size.y * 0.78))
	draw_rect(stack_rect, Color("#2c211b", 0.76))
	draw_rect(stack_rect, Color("#d7b15e", 0.42), false, maxf(2.0, tile_size * 0.035))
	for index in range(4):
		var smoke_center := rect.position + Vector2(rect.size.x * (0.38 + float(index) * 0.12), rect.size.y * (0.16 - float(index % 2) * 0.04))
		draw_circle(smoke_center, tile_size * (0.18 + float(index) * 0.02), Color("#b9d1c4", 0.1))
	var conveyor := Rect2(rect.position + Vector2(rect.size.x * 0.28, rect.size.y * 0.66), Vector2(rect.size.x * 0.58, rect.size.y * 0.14))
	draw_rect(conveyor, Color("#050608", 0.34))
	draw_rect(conveyor, Color("#d45c55", 0.3), false, maxf(1.0, tile_size * 0.03))


func _draw_astral_dial(top_left: Vector2, tile_size: float, width: int, height: int) -> void:
	var rect := Rect2(top_left, Vector2(tile_size * max(1, width), tile_size * max(1, height)))
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.36
	draw_circle(center, radius * 1.18, Color("#001824", 0.36))
	draw_circle(center, radius, Color("#75d9e6", 0.12))
	draw_circle(center, radius, Color("#75d9e6", 0.42), false, maxf(2.0, tile_size * 0.035))
	for index in range(8):
		var angle := float(index) * TAU / 8.0 + animation_time * 0.08
		var inner := center + Vector2(cos(angle), sin(angle)) * radius * 0.42
		var outer := center + Vector2(cos(angle), sin(angle)) * radius
		draw_line(inner, outer, Color("#b9d1c4", 0.42), maxf(1.0, tile_size * 0.022))
	draw_line(center, center + Vector2(cos(animation_time * 0.35), sin(animation_time * 0.35)) * radius * 0.82, Color("#f0d18a", 0.56), maxf(2.0, tile_size * 0.035))


func _draw_gate_rune(top_left: Vector2, tile_size: float) -> void:
	var glow := 0.28 + sin(animation_time * 2.0) * 0.08
	var pillar_color := Color("#2a2722")
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.12, tile_size * 0.2), Vector2(tile_size * 0.18, tile_size * 0.68)), pillar_color)
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.7, tile_size * 0.2), Vector2(tile_size * 0.18, tile_size * 0.68)), pillar_color)
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.18, tile_size * 0.14), Vector2(tile_size * 0.64, tile_size * 0.18)), pillar_color)
	draw_rect(Rect2(top_left + Vector2(tile_size * 0.34, tile_size * 0.32), Vector2(tile_size * 0.32, tile_size * 0.42)), Color("#050608", 0.52))
	draw_line(
		top_left + Vector2(tile_size * 0.36, tile_size * 0.34),
		top_left + Vector2(tile_size * 0.52, tile_size * 0.48),
		Color(GameThemeScript.COLORS.cyan.r, GameThemeScript.COLORS.cyan.g, GameThemeScript.COLORS.cyan.b, 0.7 + glow),
		maxf(1.0, tile_size * 0.035)
	)
	draw_line(
		top_left + Vector2(tile_size * 0.52, tile_size * 0.48),
		top_left + Vector2(tile_size * 0.64, tile_size * 0.38),
		Color(GameThemeScript.COLORS.cyan.r, GameThemeScript.COLORS.cyan.g, GameThemeScript.COLORS.cyan.b, glow),
		maxf(1.0, tile_size * 0.035)
	)


func _draw_name_rune(top_left: Vector2, tile_size: float, teaching: bool) -> void:
	var slab := Rect2(top_left + Vector2(tile_size * 0.18, tile_size * 0.18), Vector2(tile_size * 0.64, tile_size * 0.64))
	draw_rect(slab, Color("#17110d"))
	draw_rect(slab, GameThemeScript.COLORS.border_light if teaching else GameThemeScript.COLORS.border, false, maxf(1.0, tile_size * 0.035))
	var learned: bool = session.has_flag("learned_name_strokes")
	var pulse: float = 0.72 + sin(animation_time * 2.2) * 0.18
	var ink: Color = Color(GameThemeScript.COLORS.gold.r, GameThemeScript.COLORS.gold.g, GameThemeScript.COLORS.gold.b, pulse) if learned else GameThemeScript.COLORS.paper
	draw_line(top_left + Vector2(tile_size * 0.35, tile_size * 0.34), top_left + Vector2(tile_size * 0.65, tile_size * 0.34), ink, maxf(2.0, tile_size * 0.045))
	draw_line(top_left + Vector2(tile_size * 0.48, tile_size * 0.32), top_left + Vector2(tile_size * 0.34, tile_size * 0.58), ink, maxf(2.0, tile_size * 0.045))
	draw_line(top_left + Vector2(tile_size * 0.42, tile_size * 0.58), top_left + Vector2(tile_size * 0.68, tile_size * 0.58), ink, maxf(2.0, tile_size * 0.045))
	if session.has_flag("name_broke_once") and not session.has_flag("named_beast"):
		draw_line(top_left + Vector2(tile_size * 0.28, tile_size * 0.26), top_left + Vector2(tile_size * 0.72, tile_size * 0.74), Color(GameThemeScript.COLORS.danger.r, GameThemeScript.COLORS.danger.g, GameThemeScript.COLORS.danger.b, 0.7 + sin(animation_time * 5.0) * 0.2), maxf(2.0, tile_size * 0.045))


func _draw_nameless_enemy(top_left: Vector2, tile_size: float) -> void:
	if session.has_flag("defeated_nameless"):
		for index in range(3):
			draw_circle(top_left + Vector2(tile_size * (0.3 + index * 0.16), tile_size * 0.5), tile_size * 0.04, Color("#050608", 0.28))
		return
	var named: bool = session.has_flag("named_beast")
	var shimmer := sin(animation_time * 2.6) * 0.06
	var alpha: float = 0.86 if named else 0.72 + shimmer
	var trim := maxf(1.0, tile_size * 0.035)
	var body := Rect2(top_left + Vector2(tile_size * (0.2 + shimmer * 0.04), tile_size * 0.22), Vector2(tile_size * 0.6, tile_size * 0.58))
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
		draw_line(top_left + Vector2(tile_size * 0.2, tile_size * 0.18), top_left + Vector2(tile_size * 0.8, tile_size * 0.82), Color(GameThemeScript.COLORS.danger.r, GameThemeScript.COLORS.danger.g, GameThemeScript.COLORS.danger.b, 0.74 + sin(animation_time * 5.5) * 0.2), maxf(2.0, tile_size * 0.04))


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
		Rect2(top_left + Vector2(tile_size * 0.22, tile_size * 0.12), Vector2(tile_size * 0.38, tile_size * 0.42)),
		Color("#b9d1c4", 0.06 + sin(animation_time * 1.3) * 0.025)
	)
	draw_rect(
		Rect2(top_left + Vector2(tile_size * 0.32, tile_size * 0.2), Vector2(tile_size * 0.22, tile_size * 0.08)),
		Color("#b9d1c4", 0.72 + sin(animation_time * 2.2) * 0.12)
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
		var pulse := 0.54 + sin(animation_time * 6.5) * 0.24
		draw_line(
			top_left + Vector2(tile_size * 0.36, tile_size * 0.2),
			top_left + Vector2(tile_size * 0.63, tile_size * 0.55),
			Color("#000000", pulse),
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


func _draw_magic_orb(rect: Rect2) -> void:
	if magic_orb_texture != null:
		draw_texture_rect(magic_orb_texture, rect, false)
		return
	var center := rect.get_center()
	var radius: float = minf(rect.size.x, rect.size.y) * 0.34
	var pulse := 0.72 + sin(animation_time * 2.2) * 0.16
	draw_circle(center, radius * 1.35, Color(GameThemeScript.COLORS.cyan.r, GameThemeScript.COLORS.cyan.g, GameThemeScript.COLORS.cyan.b, 0.14 * pulse))
	draw_circle(center, radius, Color(GameThemeScript.COLORS.cyan.r, GameThemeScript.COLORS.cyan.g, GameThemeScript.COLORS.cyan.b, 0.58 * pulse))
	draw_circle(center, radius * 0.42, Color("#f1ead4", 0.72))


func _draw_ink_threshold(top_left: Vector2, tile_size: float, active: bool) -> void:
	var center := top_left + Vector2(tile_size * 0.5, tile_size * 0.52)
	var pulse := 0.5 + sin(animation_time * 2.4) * 0.5
	draw_circle(center, tile_size * 0.46, Color("#050608", 0.42 + pulse * 0.12))
	draw_circle(center + Vector2(tile_size * 0.14, -tile_size * 0.1), tile_size * 0.26, Color("#050608", 0.6))
	draw_circle(center + Vector2(-tile_size * 0.18, tile_size * 0.04), tile_size * 0.2, Color("#050608", 0.52))
	for index in range(4):
		var angle := animation_time * 0.35 + float(index) * 1.57
		var start := center + Vector2(cos(angle), sin(angle)) * tile_size * 0.12
		var end := center + Vector2(cos(angle + 0.5), sin(angle + 0.5)) * tile_size * (0.36 + pulse * 0.08)
		draw_line(start, end, Color("#0b0d0e", 0.82), maxf(1.0, tile_size * 0.04))
	var paper := Rect2(top_left + Vector2(tile_size * 0.24, tile_size * 0.24), Vector2(tile_size * 0.48, tile_size * 0.32))
	draw_rect(paper, Color("#d8ceb0", 0.16 if not active else 0.28))
	draw_rect(paper, Color("#050608", 0.58), false, maxf(1.0, tile_size * 0.02))
	if active:
		draw_circle(center, tile_size * 0.32, Color(GameThemeScript.COLORS.cyan.r, GameThemeScript.COLORS.cyan.g, GameThemeScript.COLORS.cyan.b, 0.2 + pulse * 0.16))
		draw_circle(center, tile_size * 0.12, Color("#f1ead4", 0.35 + pulse * 0.24))


func _draw_fireball(rect: Rect2) -> void:
	if fireball_texture != null:
		draw_texture_rect(fireball_texture, rect, false)
		return
	_draw_flame(rect.get_center(), min(rect.size.x, rect.size.y) * 0.34, 0.4)


func _draw_paper_icon(rect: Rect2) -> void:
	if paper_icon_texture != null:
		draw_texture_rect(paper_icon_texture, rect, false)
		return
	draw_rect(rect, Color("#d8ceb0"))
	draw_rect(rect, GameThemeScript.COLORS.border_light, false, maxf(1.0, rect.size.x * 0.04))
	for row in range(3):
		draw_rect(
			Rect2(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * (0.25 + row * 0.18)), Vector2(rect.size.x * 0.64, rect.size.y * 0.05)),
			Color("#17110d", 0.62)
		)


func _draw_missing_tile(tile: Vector2i, top_left: Vector2, tile_size: float) -> void:
	var hue := float((abs(tile.x * 17 + tile.y * 31)) % 100) / 100.0
	var base := Color.from_hsv(0.08 + hue * 0.1, 0.35, 0.24)
	draw_rect(Rect2(top_left, Vector2(tile_size, tile_size)), base)
	draw_rect(Rect2(top_left, Vector2(tile_size, tile_size)), Color("#f1ead4", 0.18), false, maxf(1.0, tile_size * 0.02))


func _draw_dungeon_tile(tile: Vector2i, top_left: Vector2, tile_size: float) -> void:
	if dungeon_crawl_texture == null:
		_draw_missing_tile(tile, top_left, tile_size)
		return
	draw_texture_rect_region(
		dungeon_crawl_texture,
		Rect2(top_left, Vector2(tile_size, tile_size)),
		Rect2(Vector2(tile) * ATLAS_TILE, Vector2(ATLAS_TILE, ATLAS_TILE))
	)


func _draw_player_actor(top_left: Vector2, tile_size: float) -> void:
	var clip_id := PLAYER_DEFAULT_CLIP_ID
	if visual_assets != null:
		clip_id = visual_assets.character_clip(player_actor_id, PLAYER_DEFAULT_CLIP_ID)
	var frame := {}
	if animation_clips != null:
		frame = animation_clips.resolve_frame(clip_id, player_moving, player_facing, animation_time)
	if frame.is_empty():
		_draw_character(_fallback_player_frame(), top_left, tile_size)
	else:
		_draw_animation_frame(frame, top_left, tile_size)


func _draw_animation_frame(frame: Dictionary, top_left: Vector2, tile_size: float) -> void:
	if bool(frame.get("shadow", true)):
		_draw_character_shadow(top_left, tile_size)
	_draw_player_focus_ring(top_left, tile_size)
	var render_size := tile_size * maxf(float(frame.get("render_size", 0.74)), 0.9)
	var sprite_top_left := top_left + Vector2((tile_size - render_size) * 0.5, tile_size - render_size - tile_size * 0.08)
	var outline_rect := Rect2(sprite_top_left + Vector2(tile_size * 0.02, tile_size * 0.02), Vector2(render_size, render_size))
	draw_texture_rect_region(
		frame.get("texture"),
		outline_rect,
		frame.get("source"),
		Color("#050608", 0.5)
	)
	draw_texture_rect_region(
		frame.get("texture"),
		Rect2(sprite_top_left, Vector2(render_size, render_size)),
		frame.get("source")
	)


func _draw_character(tile: Vector2i, top_left: Vector2, tile_size: float) -> void:
	var sprite_size := tile_size * 0.9
	var sprite_top_left := top_left + Vector2((tile_size - sprite_size) * 0.5, tile_size - sprite_size - tile_size * 0.08)
	_draw_character_shadow(top_left, tile_size)
	_draw_player_focus_ring(top_left, tile_size)
	if rpg_characters_texture == null:
		_draw_fallback_character(tile, sprite_top_left, sprite_size)
		return
	draw_texture_rect_region(
		rpg_characters_texture,
		Rect2(sprite_top_left + Vector2(tile_size * 0.02, tile_size * 0.02), Vector2(sprite_size, sprite_size)),
		Rect2(Vector2(tile) * CHAR_TILE, Vector2(CHAR_TILE, CHAR_TILE)),
		Color("#050608", 0.5)
	)
	draw_texture_rect_region(
		rpg_characters_texture,
		Rect2(sprite_top_left, Vector2(sprite_size, sprite_size)),
		Rect2(Vector2(tile) * CHAR_TILE, Vector2(CHAR_TILE, CHAR_TILE))
	)


func _draw_character_shadow(top_left: Vector2, tile_size: float) -> void:
	draw_rect(
		Rect2(
			top_left + Vector2(tile_size * 0.24, tile_size * 0.82),
			Vector2(tile_size * 0.52, tile_size * 0.1)
		),
		Color("#000000", 0.32)
	)


func _draw_player_focus_ring(top_left: Vector2, tile_size: float) -> void:
	var center := top_left + Vector2(tile_size * 0.5, tile_size * 0.82)
	draw_circle(center, tile_size * 0.34, Color("#f0d18a", 0.12))
	draw_circle(center, tile_size * 0.2, Color("#050608", 0.22))


func _draw_fallback_character(tile: Vector2i, sprite_top_left: Vector2, sprite_size: float) -> void:
	var body := Rect2(
		sprite_top_left + Vector2(sprite_size * 0.32, sprite_size * 0.34),
		Vector2(sprite_size * 0.36, sprite_size * 0.38)
	)
	var head := sprite_top_left + Vector2(sprite_size * 0.5, sprite_size * 0.24)
	var accent: Color = GameThemeScript.COLORS.gold if tile.x % 2 == 0 else GameThemeScript.COLORS.cyan
	draw_circle(head, sprite_size * 0.16, Color("#d8ceb0"))
	draw_rect(body, Color("#293647"))
	draw_rect(body, accent, false, maxf(1.0, sprite_size * 0.035))
	draw_rect(Rect2(sprite_top_left + Vector2(sprite_size * 0.26, sprite_size * 0.72), Vector2(sprite_size * 0.18, sprite_size * 0.12)), Color("#17110d"))
	draw_rect(Rect2(sprite_top_left + Vector2(sprite_size * 0.56, sprite_size * 0.72), Vector2(sprite_size * 0.18, sprite_size * 0.12)), Color("#17110d"))


func _fallback_player_frame() -> Vector2i:
	var column := 1
	if player_moving:
		var cycle := [0, 1, 2, 1]
		column = cycle[int(animation_time / 0.12) % cycle.size()]

	var row := 0
	if player_facing == Vector2i(0, -1):
		row = 2
	elif player_facing == Vector2i(-1, 0) or player_facing == Vector2i(1, 0):
		row = 1
	else:
		row = 0
	return PLAYER_FRAME_ORIGIN + Vector2i(column, row)


func _ambient_base_color(terrain: String, visual: Dictionary) -> Color:
	if _visual_mood(visual) == "sunlit":
		return Color("#9fd178")
	if _uses_modern_scene_tiles(terrain):
		if terrain == "street":
			return Color("#0b0e10")
		return Color("#100d0b")
	if terrain in ["wilderness", "forest"]:
		return Color("#0e120b")
	if terrain in ["ruin", "dead_city"]:
		return Color("#090807")
	if terrain == "node":
		return Color("#061114")
	if _is_moqi_location():
		return Color("#10110b")
	return GameThemeScript.COLORS.panel_deep


func _ambient_speck_color(terrain: String, visual: Dictionary) -> Color:
	if _visual_mood(visual) == "sunlit":
		return Color("#fff6ba", 0.16)
	if terrain == "node":
		return Color(GameThemeScript.COLORS.cyan.r, GameThemeScript.COLORS.cyan.g, GameThemeScript.COLORS.cyan.b, 0.18)
	if terrain in ["ruin", "dead_city"]:
		return Color("#d8ceb0", 0.1)
	if _uses_modern_scene_tiles(terrain):
		return Color("#b9d1c4", 0.08)
	return Color("#d7b15e", 0.08)


func _visual_mood(visual: Dictionary) -> String:
	var explicit := str(visual.get("visual_mood", ""))
	if not explicit.is_empty():
		return GameThemeScript.effective_visual_mood(explicit)
	if session != null:
		if session.scene_id == "00-prologue-lights-out":
			return GameThemeScript.effective_visual_mood("silenced")
		if session.scene_id in ["02-moqi-academy", "04-continuation-institute"] and str(visual.get("visual_family", "")) == "academy":
			return GameThemeScript.effective_visual_mood("sunlit")
	if str(visual.get("visual_family", "")) in ["ruin", "mine"]:
		return GameThemeScript.effective_visual_mood("ruin")
	return GameThemeScript.effective_visual_mood("neutral")


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


func _is_building_lobby() -> bool:
	return session != null and session.scene_id == "00-prologue-lights-out" and session.location_id == "building"


func _is_moqi_location() -> bool:
	return session.scene_index in [2, 3, 5, 6] or session.location_id.contains("moqi") or session.location_id.contains("academy")


func _is_illiterate_station() -> bool:
	return session.scene_id == "01-illiterate" and session.location_id == "station"


func _uses_modern_scene_tiles(terrain: String) -> bool:
	return session != null and session.scene_id in ["00-prologue-lights-out", "07-lights-on-again"] and terrain in ["street", "interior", "room"]


func _uses_first_act_scene_tiles(terrain: String) -> bool:
	return session != null and session.scene_id == "01-illiterate" and terrain in ["wilderness", "forest", "ruin"]


func _uses_modern_scene_props() -> bool:
	return session != null and session.scene_id in ["00-prologue-lights-out", "07-lights-on-again"]


func _prop_visible_for_session(prop: Dictionary) -> bool:
	if session == null:
		return true
	for flag in prop.get("requires_flags", []):
		if not session.has_flag(str(flag)):
			return false
	for flag in prop.get("hidden_flags", []):
		if session.has_flag(str(flag)):
			return false
	return true


func _current_visual() -> Dictionary:
	if visual_repository == null:
		return {}
	return visual_repository.location_visual(session.scene_id, session.location_id)
