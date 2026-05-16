extends SceneTree

const TILE_SIZE := 32
const COLUMNS := 15
const ROWS := 9
const SOURCE_ID := 0

const VISUAL_DIR := "res://data/visual_scenes"
const SCENE_DIR := "res://scenes/visual_locations"
const TILE_DIR := "res://assets/visual_tiles"
const UI_DIR := "res://assets/ui"
const TILE_SHEET_PATH := "res://assets/visual_tiles/dream_scene_tiles.png"
const TILESET_PATH := "res://assets/visual_tiles/dream_scene_tileset.tres"
const UI_PANEL_PATH := "res://assets/ui/pixel_panel_9patch.png"
const TILE_REGISTRY_PATH := "res://data/visual_assets/tilesets.json"

const BTL_INTERIOR_PATH := "res://assets/external/btl_topdown_interior/housetileset.png"
const KENNEY_CITY_PATH := "res://assets/external/kenney_modern_city/source/Spritesheet/roguelikeCity_transparent.png"
const OGA_CITY_EXTENSION_PATH := "res://assets/external/oga_modern_city_extension/city_extension.png"

var tile_coords := {}


func _initialize() -> void:
	_init_tile_coords()
	_ensure_dirs()
	_write_tilesheet()
	_write_ui_skin()
	_write_tileset()
	_write_tileset_registry()
	_write_visual_location_scenes()
	quit(0)


func _init_tile_coords() -> void:
	var keys := [
		"interior_floor",
		"interior_wall",
		"wood_floor",
		"carpet_floor",
		"street_asphalt",
		"street_sidewalk",
		"street_crosswalk",
		"academy_floor",
		"archive_floor",
		"node_floor",
		"ruin_floor",
		"wilderness_ground",
		"forest_ground",
		"mine_floor",
		"industry_floor",
		"workshop_floor",
		"building_wall",
		"building_window",
		"building_window_dark",
		"building_door",
		"door_open",
		"vending",
		"poster",
		"lamp",
		"mailbox",
		"stairs",
		"sofa",
		"bed",
		"table",
		"desk",
		"bookcase",
		"tv",
		"phone",
		"photo",
		"note",
		"pen",
		"dinner",
		"portal",
		"rune",
		"node",
		"enemy",
		"npc",
		"tree",
		"campfire",
		"gate",
		"record",
		"cabinet",
		"well",
		"tent",
		"shadow",
		"gold_glow",
		"cyan_glow",
		"danger_glow",
		"sunlit_grass",
		"sunlit_path",
		"flower",
		"bright_tree",
	]
	for index in range(keys.size()):
		tile_coords[keys[index]] = Vector2i(index % 16, index / 16)


func _ensure_dirs() -> void:
	for path in [TILE_DIR, UI_DIR, SCENE_DIR]:
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
		if error != OK:
			push_error("Could not create directory %s: %s" % [path, error])
			quit(1)


func _write_tilesheet() -> void:
	var sheet := Image.create_empty(TILE_SIZE * 16, TILE_SIZE * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	var btl := _load_source_image(BTL_INTERIOR_PATH)
	if btl != null:
		_copy_tile(sheet, "interior_floor", btl, Vector2i(2, 0), 32)
		_copy_tile(sheet, "interior_wall", btl, Vector2i(1, 3), 32)
		_copy_tile(sheet, "wood_floor", btl, Vector2i(3, 3), 32)
		_copy_tile(sheet, "carpet_floor", btl, Vector2i(1, 6), 32)
	_paint_ground_tile(sheet, "interior_floor", Color("#201b16"), Color("#332a20"))
	_paint_ground_tile(sheet, "wood_floor", Color("#34251a"), Color("#735331"))
	_paint_ground_tile(sheet, "carpet_floor", Color("#2d2738"), Color("#584a73"))

	var oga := _load_source_image(OGA_CITY_EXTENSION_PATH)
	if oga != null:
		_copy_region(sheet, "building_wall", oga, Rect2i(Vector2i(0, 32), Vector2i(32, 32)), false)
		_copy_region(sheet, "building_window", oga, Rect2i(Vector2i(160, 32), Vector2i(32, 32)), false)
		_copy_region(sheet, "building_window_dark", oga, Rect2i(Vector2i(448, 64), Vector2i(32, 32)), false)

	var kenney := _load_source_image(KENNEY_CITY_PATH)
	if kenney != null:
		_copy_region(sheet, "street_asphalt", kenney, Rect2i(Vector2i(18, 392), Vector2i(16, 16)), true)
		_copy_region(sheet, "street_sidewalk", kenney, Rect2i(Vector2i(1, 392), Vector2i(16, 16)), true)
		_copy_region(sheet, "street_crosswalk", kenney, Rect2i(Vector2i(290, 205), Vector2i(16, 16)), true)

	_paint_ground_tile(sheet, "street_asphalt", Color("#242930"), Color("#3a4148"))
	_paint_ground_tile(sheet, "street_sidewalk", Color("#58666b"), Color("#748489"))
	_paint_crosswalk_tile(sheet, "street_crosswalk")
	_paint_if_empty(sheet, "academy_floor", Color("#d8c786"), Color("#f2dda2"))
	_paint_if_empty(sheet, "sunlit_grass", Color("#7abd55"), Color("#a5df74"))
	_paint_if_empty(sheet, "sunlit_path", Color("#d4bd72"), Color("#f3dda0"))
	_paint_flower(sheet, "flower")
	_paint_bright_tree(sheet, "bright_tree")
	_paint_if_empty(sheet, "archive_floor", Color("#38271d"), Color("#7a5731"))
	_paint_if_empty(sheet, "node_floor", Color("#0a1822"), Color("#2d7f8f"))
	_paint_if_empty(sheet, "ruin_floor", Color("#24252a"), Color("#54545a"))
	_paint_if_empty(sheet, "wilderness_ground", Color("#55432a"), Color("#766039"))
	_paint_if_empty(sheet, "forest_ground", Color("#21351f"), Color("#426b35"))
	_paint_if_empty(sheet, "mine_floor", Color("#242126"), Color("#655b68"))
	_paint_if_empty(sheet, "industry_floor", Color("#2d3335"), Color("#647173"))
	_paint_if_empty(sheet, "workshop_floor", Color("#3d2f28"), Color("#80634a"))
	_paint_if_empty(sheet, "building_wall", Color("#5f7477"), Color("#8ba1a3"))
	_paint_if_empty(sheet, "building_window", Color("#253b43"), Color("#acd2c7"))
	_paint_if_empty(sheet, "building_window_dark", Color("#11191e"), Color("#29353d"))

	_paint_door(sheet, "building_door", false)
	_paint_door(sheet, "door_open", true)
	_paint_machine(sheet, "vending")
	_paint_poster(sheet, "poster")
	_paint_lamp(sheet, "lamp")
	_paint_mailbox(sheet, "mailbox")
	_paint_stairs(sheet, "stairs")
	_paint_sofa(sheet, "sofa")
	_paint_bed(sheet, "bed")
	_paint_table(sheet, "table", false)
	_paint_table(sheet, "desk", true)
	_paint_bookcase(sheet, "bookcase")
	_paint_tv(sheet, "tv")
	_paint_phone(sheet, "phone")
	_paint_small_frame(sheet, "photo", Color("#c89a5a"))
	_paint_small_frame(sheet, "note", Color("#eadcae"))
	_paint_pen(sheet, "pen")
	_paint_dinner(sheet, "dinner")
	_paint_portal(sheet, "portal")
	_paint_rune(sheet, "rune")
	_paint_node(sheet, "node")
	_paint_enemy(sheet, "enemy")
	_paint_npc(sheet, "npc")
	_paint_tree(sheet, "tree")
	_paint_campfire(sheet, "campfire")
	_paint_gate(sheet, "gate")
	_paint_record(sheet, "record")
	_paint_cabinet(sheet, "cabinet")
	_paint_well(sheet, "well")
	_paint_tent(sheet, "tent")
	_paint_shadow(sheet, "shadow")
	_paint_glow(sheet, "gold_glow", Color("#d7b15e", 0.34))
	_paint_glow(sheet, "cyan_glow", Color("#75d9e6", 0.32))
	_paint_glow(sheet, "danger_glow", Color("#d45c55", 0.38))

	var error := sheet.save_png(ProjectSettings.globalize_path(TILE_SHEET_PATH))
	if error != OK:
		push_error("Could not save %s: %s" % [TILE_SHEET_PATH, error])
		quit(1)


func _load_source_image(path: String) -> Image:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		push_warning("Could not load source image %s: %s" % [path, error])
		return null
	return image


func _copy_tile(sheet: Image, tile_key: String, source: Image, source_tile: Vector2i, source_size: int) -> void:
	_copy_region(
		sheet,
		tile_key,
		source,
		Rect2i(source_tile * source_size, Vector2i(source_size, source_size)),
		source_size != TILE_SIZE
	)


func _copy_region(sheet: Image, tile_key: String, source: Image, region: Rect2i, scale_to_32: bool) -> void:
	if region.position.x < 0 or region.position.y < 0:
		return
	if region.end.x > source.get_width() or region.end.y > source.get_height():
		return
	var tile := source.get_region(region)
	tile.convert(Image.FORMAT_RGBA8)
	if scale_to_32:
		tile.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_NEAREST)
	sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(TILE_SIZE, TILE_SIZE)), _tile_pixel(tile_key))


func _paint_if_empty(sheet: Image, tile_key: String, base: Color, accent: Color) -> void:
	var origin := _tile_pixel(tile_key)
	if sheet.get_pixel(origin.x + 8, origin.y + 8).a > 0.01:
		return
	_paint_ground_tile(sheet, tile_key, base, accent)


func _paint_ground_tile(sheet: Image, tile_key: String, base: Color, accent: Color) -> void:
	var origin := _tile_pixel(tile_key)
	_fill_tile(sheet, tile_key, base)
	if tile_key == "wood_floor":
		sheet.fill_rect(Rect2i(origin + Vector2i(4, 16), Vector2i(TILE_SIZE - 8, 1)), Color(accent, 0.06))
	elif tile_key == "street_asphalt":
		for x in [11, 23]:
			sheet.fill_rect(Rect2i(origin + Vector2i(x, 3), Vector2i(1, TILE_SIZE - 6)), Color(accent, 0.04))
		for y in [14, 26]:
			sheet.fill_rect(Rect2i(origin + Vector2i(4, y), Vector2i(TILE_SIZE - 8, 1)), Color("#101820", 0.08))
	elif tile_key == "street_sidewalk":
		for x in [15]:
			sheet.fill_rect(Rect2i(origin + Vector2i(x, 2), Vector2i(1, TILE_SIZE - 4)), Color(accent, 0.06))
		for y in [15]:
			sheet.fill_rect(Rect2i(origin + Vector2i(2, y), Vector2i(TILE_SIZE - 4, 1)), Color(accent, 0.05))
	elif tile_key in ["interior_floor", "carpet_floor", "academy_floor", "archive_floor", "node_floor", "ruin_floor", "wilderness_ground", "forest_ground", "mine_floor", "industry_floor", "workshop_floor", "sunlit_grass", "sunlit_path"]:
		pass
	else:
		for index in [13, 25]:
			sheet.fill_rect(Rect2i(origin + Vector2i(index, 4), Vector2i(1, TILE_SIZE - 8)), Color(accent, 0.035))
			sheet.fill_rect(Rect2i(origin + Vector2i(4, index), Vector2i(TILE_SIZE - 8, 1)), Color(accent, 0.03))
	var speck_count := 10 if tile_key in ["wilderness_ground", "forest_ground", "ruin_floor", "mine_floor", "industry_floor", "workshop_floor", "node_floor"] else 5
	for index in range(speck_count):
		var x := (index * 9 + 5) % (TILE_SIZE - 6) + 3
		var y := (index * 7 + 11) % (TILE_SIZE - 6) + 3
		var alpha := 0.11 if speck_count > 5 else 0.14
		sheet.fill_rect(Rect2i(origin + Vector2i(x, y), Vector2i(1, 1)), Color(accent, alpha))


func _paint_crosswalk_tile(sheet: Image, tile_key: String) -> void:
	_fill_tile(sheet, tile_key, Color("#303842"))
	for index in range(2, TILE_SIZE, 8):
		sheet.fill_rect(Rect2i(_tile_pixel(tile_key) + Vector2i(index, 0), Vector2i(4, TILE_SIZE)), Color("#cbd4c8"))


func _write_ui_skin() -> void:
	var image := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	image.fill_rect(Rect2i(Vector2i(2, 2), Vector2i(20, 20)), Color("#1d2f1c", 0.96))
	image.fill_rect(Rect2i(Vector2i(0, 3), Vector2i(24, 18)), Color("#96b45e", 0.72))
	image.fill_rect(Rect2i(Vector2i(3, 0), Vector2i(18, 24)), Color("#96b45e", 0.72))
	image.fill_rect(Rect2i(Vector2i(3, 3), Vector2i(18, 18)), Color("#20351f", 0.96))
	image.fill_rect(Rect2i(Vector2i(4, 4), Vector2i(16, 2)), Color("#f3dc8a", 0.42))
	image.fill_rect(Rect2i(Vector2i(4, 18), Vector2i(16, 2)), Color("#465b2a", 0.72))
	image.set_pixel(3, 3, Color("#fff4ce", 0.9))
	image.set_pixel(20, 3, Color("#fff4ce", 0.9))
	image.set_pixel(3, 20, Color("#465b2a", 0.9))
	image.set_pixel(20, 20, Color("#465b2a", 0.9))
	var error := image.save_png(ProjectSettings.globalize_path(UI_PANEL_PATH))
	if error != OK:
		push_error("Could not save %s: %s" % [UI_PANEL_PATH, error])
		quit(1)


func _write_tileset() -> void:
	var sheet := Image.new()
	var error := sheet.load(ProjectSettings.globalize_path(TILE_SHEET_PATH))
	if error != OK:
		push_error("Could not reload generated tile sheet: %s" % error)
		quit(1)
	var texture: Texture2D
	if ResourceLoader.exists(TILE_SHEET_PATH):
		var texture_resource: Resource = load(TILE_SHEET_PATH)
		if texture_resource is Texture2D:
			texture = texture_resource as Texture2D
	if texture == null:
		texture = ImageTexture.create_from_image(sheet)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for y in range(sheet.get_height() / TILE_SIZE):
		for x in range(sheet.get_width() / TILE_SIZE):
			source.create_tile(Vector2i(x, y))
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(source, SOURCE_ID)
	error = ResourceSaver.save(tile_set, TILESET_PATH)
	if error != OK:
		push_error("Could not save TileSet %s: %s" % [TILESET_PATH, error])
		quit(1)


func _write_tileset_registry() -> void:
	var registry := {
		"version": 1,
		"tile_size": TILE_SIZE,
		"tilesets": [
			{
				"id": "dream_scene_tiles",
				"display_name": "Dream Coastline normalized scene tiles",
				"license": "CC0-compatible composite",
				"normalized_tilesheet": TILE_SHEET_PATH,
				"godot_tileset": TILESET_PATH,
				"terrain_families": [
					"modern_exterior",
					"modern_interior",
					"wilderness",
					"forest",
					"ruin",
					"academy",
					"archive",
					"node",
					"workshop",
					"mine",
					"industry"
				],
				"sources": [
					{
						"id": "btl_topdown_interior",
						"url": "https://btl-games.itch.io/topdown",
						"license": "CC0",
						"original_path": BTL_INTERIOR_PATH
					},
					{
						"id": "kenney_modern_city",
						"url": "https://opengameart.org/content/roguelike-modern-city-pack",
						"license": "CC0",
						"original_path": KENNEY_CITY_PATH
					},
					{
						"id": "oga_modern_city_extension",
						"url": "https://opengameart.org/content/modern-city-extension",
						"license": "CC0",
						"original_path": OGA_CITY_EXTENSION_PATH
					}
				]
			}
		]
	}
	_write_json(TILE_REGISTRY_PATH, registry)


func _write_visual_location_scenes() -> void:
	var tile_set := load(TILESET_PATH)
	if tile_set == null:
		push_error("Could not load generated tileset %s" % TILESET_PATH)
		quit(1)
	for visual_path in _visual_scene_paths():
		var visual_scene := _read_json(visual_path)
		if visual_scene.is_empty():
			continue
		var scene_id := str(visual_scene.get("id", visual_path.get_file().get_basename()))
		var locations: Dictionary = visual_scene.get("locations", {})
		for location_id in locations.keys():
			var location: Dictionary = locations[location_id]
			var family := _visual_family(str(location.get("terrain", "")), scene_id, str(location_id))
			var scene_path := "%s/%s/%s.tscn" % [SCENE_DIR, scene_id, str(location_id)]
			var mood := _visual_mood_for_location(scene_id, str(location_id), str(location.get("terrain", "")), family)
			location["visual_family"] = family
			location["asset_scene"] = scene_path
			location["asset_status"] = "asset_backed" if _is_primary_asset_location(scene_id, str(location_id), family) else "framework_placeholder"
			location["tileset_id"] = "dream_scene_tiles"
			if mood.is_empty():
				location.erase("visual_mood")
			else:
				location["visual_mood"] = mood
			_write_location_scene(scene_path, scene_id, str(location_id), location, family, tile_set)
		_write_json(visual_path, visual_scene)


func _visual_scene_paths() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(VISUAL_DIR)
	if dir == null:
		return paths
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			paths.append("%s/%s" % [VISUAL_DIR, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths


func _write_location_scene(path: String, scene_id: String, location_id: String, visual: Dictionary, family: String, tile_set: TileSet) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var root := Node2D.new()
	root.name = "AssetLocation"
	root.set_meta("scene_id", scene_id)
	root.set_meta("location_id", location_id)
	root.set_meta("visual_family", family)
	root.set_meta("visual_mood", str(visual.get("visual_mood", "")))

	var ground := _make_layer("ground", tile_set)
	var walls := _make_layer("walls", tile_set)
	var decor := _make_layer("decor", tile_set)
	var props_shadow := _make_layer("props_shadow", tile_set)
	var lighting := _make_layer("lighting", tile_set)
	for layer in [ground, walls, decor, props_shadow, lighting]:
		root.add_child(layer)
		layer.owner = root

	_fill_ground(ground, family, scene_id, location_id)
	_paint_boundaries(walls, family, scene_id, location_id)
	_paint_scene_pattern(ground, decor, lighting, family, scene_id, location_id)
	_paint_props(decor, props_shadow, lighting, visual, family)

	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("Could not pack %s: %s" % [path, pack_error])
		quit(1)
	var save_error := ResourceSaver.save(packed, path)
	if save_error != OK:
		push_error("Could not save %s: %s" % [path, save_error])
		quit(1)
	root.free()


func _make_layer(layer_name: String, tile_set: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return layer


func _fill_ground(layer: TileMapLayer, family: String, scene_id: String, location_id: String) -> void:
	if _is_sunlit_location(scene_id, location_id, family):
		for y in range(ROWS):
			for x in range(COLUMNS):
				_set_tile(layer, x, y, "sunlit_grass")
		for x in range(1, COLUMNS - 1):
			_set_tile(layer, x, 4, "sunlit_path")
		for y in range(1, ROWS - 1):
			_set_tile(layer, 7, y, "sunlit_path")
		for x in range(5, 10):
			for y in range(3, 6):
				if x in [5, 9] or y in [3, 5]:
					_set_tile(layer, x, y, "academy_floor")
		return
	var tile_key := _ground_tile_for_location(family, scene_id, location_id)
	for y in range(ROWS):
		for x in range(COLUMNS):
			_set_tile(layer, x, y, tile_key)
	if family == "modern_exterior":
		for y in range(1, 5):
			for x in range(COLUMNS):
				_set_tile(layer, x, y, "street_sidewalk")
		for y in range(5, ROWS):
			for x in range(COLUMNS):
				_set_tile(layer, x, y, "street_asphalt")
		for x in range(1, COLUMNS, 4):
			_set_tile(layer, x, 6, "street_crosswalk")
	elif family == "node":
		for x in range(1, COLUMNS - 1, 2):
			_set_tile(layer, x, 2, "node_floor")
			_set_tile(layer, x, 6, "node_floor")


func _paint_boundaries(layer: TileMapLayer, family: String, scene_id: String, location_id: String) -> void:
	if _is_sunlit_location(scene_id, location_id, family):
		for x in range(0, COLUMNS, 2):
			_set_tile(layer, x, 0, "bright_tree")
		for y in range(2, ROWS - 1, 2):
			_set_tile(layer, 0, y, "bright_tree")
			_set_tile(layer, COLUMNS - 1, y, "bright_tree")
		for x in [2, 12]:
			_set_tile(layer, x, ROWS - 2, "flower")
		return
	if family in ["modern_interior", "academy", "archive", "workshop", "mine", "industry"]:
		for x in range(COLUMNS):
			_set_tile(layer, x, 0, "interior_wall")
		for y in range(1, ROWS):
			_set_tile(layer, 0, y, "interior_wall")
			_set_tile(layer, COLUMNS - 1, y, "interior_wall")
	elif family == "modern_exterior":
		for x in range(COLUMNS):
			_set_tile(layer, x, 0, "building_wall")
	elif family in ["ruin", "node"]:
		for x in range(COLUMNS):
			_set_tile(layer, x, 0, "ruin_floor" if family == "ruin" else "node")
			_set_tile(layer, x, ROWS - 1, "ruin_floor" if family == "ruin" else "node")
	elif family in ["wilderness", "forest"]:
		for x in range(0, COLUMNS, 2):
			_set_tile(layer, x, 0, "tree" if family == "forest" else "wilderness_ground")


func _paint_scene_pattern(ground: TileMapLayer, decor: TileMapLayer, lighting: TileMapLayer, family: String, scene_id: String, location_id: String) -> void:
	if _is_sunlit_location(scene_id, location_id, family):
		_paint_sunlit_academy_decor(ground, decor, lighting, scene_id, location_id)
		return
	if family == "modern_exterior":
		for y in range(1, 3):
			for x in range(COLUMNS):
				_set_tile(decor, x, y, "building_wall")
		for x in range(1, COLUMNS - 1, 2):
			_set_tile(decor, x, 1, "building_window")
		for x in range(1, COLUMNS - 1, 4):
			_set_tile(decor, x, 4, "lamp")
			_set_tile(lighting, x, 4, "gold_glow")
		for x in range(1, COLUMNS - 1):
			if x % 4 == 2:
				_set_tile(decor, x, 6, "street_crosswalk")
	elif family == "modern_interior":
		_paint_modern_room_ground(ground, scene_id, location_id)
		_paint_modern_room_decor(decor, lighting, scene_id, location_id)
	elif family == "academy":
		_paint_academy_decor(decor, scene_id, location_id)
	elif family == "node":
		for x in range(2, COLUMNS - 2, 3):
			_set_tile(lighting, x, 2, "cyan_glow")
			_set_tile(lighting, x, 6, "cyan_glow")
	elif family == "wilderness":
		_paint_wilderness_decor(ground, decor, lighting, scene_id, location_id)
	elif family == "forest":
		for x in range(2, COLUMNS - 2, 4):
			_set_tile(decor, x, 1, "tree")
	elif scene_id == "00-prologue-lights-out" and location_id == "bedroom":
		_set_tile(lighting, 12, 4, "danger_glow")


func _paint_props(decor: TileMapLayer, props_shadow: TileMapLayer, lighting: TileMapLayer, visual: Dictionary, family: String) -> void:
	for raw_prop in visual.get("props", []):
		if typeof(raw_prop) != TYPE_DICTIONARY:
			continue
		var prop: Dictionary = raw_prop
		var kind := str(prop.get("kind", "decor"))
		if kind == "shadow":
			continue
		var x := int(prop.get("x", 0))
		var y := int(prop.get("y", 0))
		var w: int = maxi(1, int(prop.get("w", 1)))
		var h: int = maxi(1, int(prop.get("h", 1)))
		if bool(prop.get("solid", false)):
			for yy in range(y, y + h):
				for xx in range(x, x + w):
					_set_tile(props_shadow, xx, yy, "shadow")
		if kind == "building":
			_paint_building(decor, x, y, w, h)
			continue
		var target_layer := lighting if _is_detail_prop(kind) else decor
		var tile_key := _tile_for_prop(kind, family)
		if tile_key.is_empty():
			continue
		_set_tile(target_layer, x, y, tile_key)
		if kind in ["lamp", "rune", "node", "portal", "window_dark", "pen"]:
			_set_tile(lighting, x, y, _glow_for_prop(kind))


func _paint_building(layer: TileMapLayer, x: int, y: int, w: int, h: int) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var tile_key := "building_wall"
			if yy > y and yy < y + h - 1 and (xx + yy) % 2 == 0:
				tile_key = "building_window"
			_set_tile(layer, xx, yy, tile_key)
	_set_tile(layer, x + w - 1, y + h - 1, "building_door")


func _set_tile(layer: TileMapLayer, x: int, y: int, tile_key: String) -> void:
	if x < 0 or y < 0 or x >= COLUMNS or y >= ROWS:
		return
	if not tile_coords.has(tile_key):
		return
	layer.set_cell(Vector2i(x, y), SOURCE_ID, tile_coords[tile_key])


func _fill_rect_tiles(layer: TileMapLayer, rect: Rect2i, tile_key: String) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_set_tile(layer, x, y, tile_key)


func _ground_tile_for_family(family: String) -> String:
	match family:
		"modern_exterior":
			return "street_sidewalk"
		"modern_interior":
			return "interior_floor"
		"academy":
			return "academy_floor"
		"archive":
			return "archive_floor"
		"node":
			return "node_floor"
		"workshop":
			return "workshop_floor"
		"mine":
			return "mine_floor"
		"industry":
			return "industry_floor"
		"ruin":
			return "ruin_floor"
		"forest":
			return "forest_ground"
		_:
			return "wilderness_ground"


func _ground_tile_for_location(family: String, scene_id: String, location_id: String) -> String:
	if _is_sunlit_location(scene_id, location_id, family):
		return "sunlit_grass"
	if family == "modern_interior":
		if location_id in ["living_room", "study", "home", "store"]:
			return "wood_floor"
		if location_id == "bedroom":
			return "carpet_floor"
		if location_id == "building":
			return "interior_floor"
		if scene_id == "07-lights-on-again" and location_id == "school":
			return "academy_floor"
	return _ground_tile_for_family(family)


func _paint_modern_room_ground(ground: TileMapLayer, scene_id: String, location_id: String) -> void:
	if location_id in ["living_room", "home"]:
		_fill_rect_tiles(ground, Rect2i(Vector2i(4, 3), Vector2i(6, 3)), "carpet_floor")
		_fill_rect_tiles(ground, Rect2i(Vector2i(6, 4), Vector2i(2, 1)), "wood_floor")
	elif location_id == "bedroom":
		_fill_rect_tiles(ground, Rect2i(Vector2i(2, 3), Vector2i(5, 3)), "wood_floor")
		_fill_rect_tiles(ground, Rect2i(Vector2i(8, 2), Vector2i(3, 3)), "wood_floor")
	elif location_id == "study":
		_fill_rect_tiles(ground, Rect2i(Vector2i(3, 2), Vector2i(5, 3)), "archive_floor")
		_fill_rect_tiles(ground, Rect2i(Vector2i(9, 2), Vector2i(3, 4)), "wood_floor")
	elif location_id == "store":
		_fill_rect_tiles(ground, Rect2i(Vector2i(2, 2), Vector2i(10, 2)), "interior_floor")
		_fill_rect_tiles(ground, Rect2i(Vector2i(2, 5), Vector2i(8, 2)), "wood_floor")
	elif location_id == "building":
		_fill_rect_tiles(ground, Rect2i(Vector2i(6, 1), Vector2i(3, 7)), "street_sidewalk")
	elif scene_id == "00-prologue-lights-out" and location_id == "home":
		_fill_rect_tiles(ground, Rect2i(Vector2i(5, 2), Vector2i(5, 4)), "wood_floor")


func _paint_modern_room_decor(decor: TileMapLayer, lighting: TileMapLayer, scene_id: String, location_id: String) -> void:
	if location_id in ["living_room", "home"]:
		for x in [2, 12]:
			_set_tile(decor, x, 2, "cabinet")
		for x in [3, 11]:
			_set_tile(decor, x, 5, "lamp")
			_set_tile(lighting, x, 5, "gold_glow")
	elif location_id == "bedroom":
		_set_tile(decor, 2, 2, "cabinet")
		_set_tile(decor, 12, 3, "lamp")
		_set_tile(lighting, 12, 3, "gold_glow")
	elif location_id == "study":
		for x in [2, 3, 11, 12]:
			_set_tile(decor, x, 2, "bookcase")
		_set_tile(decor, 8, 4, "lamp")
		_set_tile(lighting, 8, 4, "gold_glow")
	elif location_id == "store":
		for x in range(2, 12):
			_set_tile(decor, x, 2, "cabinet")
		for x in [3, 9]:
			_set_tile(decor, x, 5, "vending")
		_set_tile(decor, 8, 4, "table")
	elif location_id == "building":
		for y in range(2, 7, 2):
			_set_tile(decor, 3, y, "mailbox")
			_set_tile(decor, 11, y, "stairs")
	if scene_id == "07-lights-on-again" and location_id == "home":
		_set_tile(decor, 10, 3, "photo")


func _paint_academy_decor(decor: TileMapLayer, scene_id: String, location_id: String) -> void:
	if scene_id == "07-lights-on-again" and location_id == "school":
		for x in [3, 5, 9, 11]:
			_set_tile(decor, x, 3, "desk")
			_set_tile(decor, x, 5, "desk")
		_set_tile(decor, 7, 2, "note")
	else:
		for x in range(2, COLUMNS - 2, 3):
			_set_tile(decor, x, 2, "bookcase")
			_set_tile(decor, x, 6, "desk")


func _paint_sunlit_academy_decor(_ground: TileMapLayer, decor: TileMapLayer, lighting: TileMapLayer, scene_id: String, location_id: String) -> void:
	for x in [2, 4, 10, 12]:
		_set_tile(decor, x, 2, "flower")
	for x in [3, 11]:
		_set_tile(decor, x, 6, "flower")
	if location_id == "village":
		for x in [3, 11]:
			_set_tile(decor, x, 2, "bright_tree")
		_set_tile(decor, 7, 5, "well")
		_set_tile(lighting, 7, 5, "gold_glow")
		return
	if location_id == "workshop":
		for x in [4, 7, 10]:
			_set_tile(decor, x, 3, "table")
		_set_tile(decor, 12, 5, "cabinet")
		return
	if location_id == "institute":
		for x in [4, 10]:
			_set_tile(decor, x, 3, "bookcase")
		for x in [5, 9]:
			_set_tile(decor, x, 5, "desk")
		_set_tile(decor, 7, 2, "note")
		return
	for x in [4, 6, 8, 10]:
		_set_tile(decor, x, 5, "desk")
	_set_tile(decor, 3, 2, "bookcase")
	_set_tile(decor, 11, 2, "bookcase")
	if scene_id == "02-moqi-academy":
		_set_tile(lighting, 7, 3, "gold_glow")


func _paint_wilderness_decor(ground: TileMapLayer, decor: TileMapLayer, lighting: TileMapLayer, _scene_id: String, location_id: String) -> void:
	for x in range(2, COLUMNS - 2):
		if x % 3 == 0:
			_set_tile(ground, x, 4, "forest_ground")
	for x in [2, 12]:
		_set_tile(decor, x, 1, "tree")
	for x in [4, 10]:
		_set_tile(decor, x, 6, "tent")
	if location_id in ["camp", "station"]:
		_set_tile(decor, 7, 4, "campfire")
		_set_tile(lighting, 7, 4, "gold_glow")
	else:
		_set_tile(decor, 7, 5, "well")


func _visual_family(terrain: String, _scene_id: String, _location_id: String) -> String:
	match terrain:
		"street", "dead_city":
			return "modern_exterior"
		"interior", "room", "store", "institute":
			return "modern_interior"
		"forest":
			return "forest"
		"ruin":
			return "ruin"
		"academy", "village":
			return "academy"
		"archive":
			return "archive"
		"node":
			return "node"
		"workshop":
			return "workshop"
		"mine":
			return "mine"
		"industry":
			return "industry"
		_:
			return "wilderness"


func _visual_mood_for_location(scene_id: String, location_id: String, terrain: String, family: String) -> String:
	if _is_sunlit_location(scene_id, location_id, family):
		return "sunlit"
	if scene_id == "00-prologue-lights-out":
		return "silenced"
	if terrain in ["ruin", "dead_city"] or family in ["ruin", "mine"]:
		return "ruin"
	return ""


func _is_sunlit_location(scene_id: String, location_id: String, _family: String) -> bool:
	if scene_id == "02-moqi-academy" and location_id in ["academy", "village"]:
		return true
	if scene_id == "04-continuation-institute" and location_id in ["institute", "school", "workshop"]:
		return true
	if scene_id == "07-lights-on-again" and location_id == "school":
		return true
	return false


func _is_primary_asset_location(scene_id: String, location_id: String, family: String) -> bool:
	if _is_sunlit_location(scene_id, location_id, family):
		return true
	if scene_id == "00-prologue-lights-out":
		return true
	if scene_id == "07-lights-on-again" and location_id in ["home", "school", "street", "store"]:
		return true
	return family in ["modern_interior", "modern_exterior"] and scene_id == "07-lights-on-again"


func _tile_for_prop(kind: String, family: String) -> String:
	match kind:
		"exit":
			return "building_door" if family == "modern_exterior" else "door_open"
		"window", "window_dark":
			return "building_window_dark"
		"door_open":
			return "door_open"
		"vending":
			return "vending"
		"poster":
			return "poster"
		"lamp":
			return "lamp"
		"mailbox":
			return "mailbox"
		"stairs":
			return "stairs"
		"sofa":
			return "sofa"
		"bed":
			return "bed"
		"table":
			return "table"
		"desk":
			return "desk"
		"bookcase":
			return "bookcase"
		"tv":
			return "tv"
		"phone":
			return "phone"
		"photo":
			return "photo"
		"note", "letter", "notice", "sign":
			return "note"
		"pen":
			return "pen"
		"dinner":
			return "dinner"
		"portal":
			return "portal"
		"rune":
			return "rune"
		"node":
			return "node"
		"enemy", "soldier":
			return "enemy"
		"villager", "student", "officer", "wensu", "xiali", "xiaoyan":
			return "npc"
		"tree":
			return "bright_tree" if family == "academy" else "tree"
		"campfire", "city_fire":
			return "campfire"
		"gate":
			return "gate"
		"record":
			return "record"
		"cabinet":
			return "cabinet"
		"well":
			return "well"
		"tent":
			return "tent"
		"glasses":
			return "photo"
		_:
			return ""


func _is_detail_prop(kind: String) -> bool:
	return kind in ["dinner", "photo", "note", "letter", "pen", "glasses", "record"]


func _glow_for_prop(kind: String) -> String:
	if kind == "pen" or kind == "window_dark":
		return "danger_glow"
	if kind == "node":
		return "cyan_glow"
	return "gold_glow"


func _fill_tile(image: Image, tile_key: String, color: Color) -> void:
	image.fill_rect(Rect2i(_tile_pixel(tile_key), Vector2i(TILE_SIZE, TILE_SIZE)), color)


func _tile_pixel(tile_key: String) -> Vector2i:
	return tile_coords[tile_key] * TILE_SIZE


func _rect(tile_key: String, x: int, y: int, w: int, h: int) -> Rect2i:
	return Rect2i(_tile_pixel(tile_key) + Vector2i(x, y), Vector2i(w, h))


func _paint_door(image: Image, key: String, open: bool) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 8, 5, 16, 24), Color("#4d3422"))
	image.fill_rect(_rect(key, 10, 7, 12, 20), Color("#765235"))
	if open:
		image.fill_rect(_rect(key, 15, 6, 9, 22), Color("#050608", 0.88))
	image.fill_rect(_rect(key, 20, 17, 2, 2), Color("#d7b15e"))


func _paint_machine(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 6, 3, 20, 26), Color("#7d1f2a"))
	image.fill_rect(_rect(key, 9, 6, 14, 7), Color("#b9d1c4"))
	image.fill_rect(_rect(key, 9, 16, 10, 8), Color("#f0d18a"))
	image.fill_rect(_rect(key, 21, 16, 3, 8), Color("#050608"))


func _paint_poster(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 7, 5, 18, 22), Color("#eadcae"))
	image.fill_rect(_rect(key, 9, 8, 14, 3), Color("#d45c55"))
	image.fill_rect(_rect(key, 9, 14, 12, 2), Color("#17110d"))
	image.fill_rect(_rect(key, 9, 19, 10, 2), Color("#17110d"))


func _paint_lamp(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 15, 10, 2, 18), Color("#3f2a18"))
	image.fill_rect(_rect(key, 9, 5, 14, 8), Color("#d7b15e"))
	image.fill_rect(_rect(key, 11, 7, 10, 4), Color("#f0d18a"))


func _paint_mailbox(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 7, 11, 18, 12), Color("#6e7375"))
	image.fill_rect(_rect(key, 9, 13, 14, 2), Color("#b9d1c4"))
	image.fill_rect(_rect(key, 15, 23, 2, 6), Color("#3f2a18"))


func _paint_stairs(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	for step in range(5):
		image.fill_rect(_rect(key, 7 + step * 2, 8 + step * 4, 18 - step * 2, 3), Color("#6b5845"))


func _paint_sofa(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 4, 12, 24, 12), Color("#3d5164"))
	image.fill_rect(_rect(key, 6, 8, 20, 8), Color("#4f6d7f"))
	image.fill_rect(_rect(key, 5, 23, 22, 3), Color("#1b2028"))


func _paint_bed(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 4, 7, 24, 19), Color("#4a3c73"))
	image.fill_rect(_rect(key, 6, 9, 20, 5), Color("#eadcae"))
	image.fill_rect(_rect(key, 6, 15, 20, 9), Color("#6f5bb3"))


func _paint_table(image: Image, key: String, desk: bool) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	var color := Color("#7a5731") if not desk else Color("#5a3f2b")
	image.fill_rect(_rect(key, 5, 10, 22, 12), color)
	image.fill_rect(_rect(key, 7, 22, 3, 6), Color("#3f2a18"))
	image.fill_rect(_rect(key, 22, 22, 3, 6), Color("#3f2a18"))
	if desk:
		image.fill_rect(_rect(key, 10, 13, 12, 2), Color("#eadcae"))


func _paint_bookcase(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 5, 4, 22, 24), Color("#4e3422"))
	for yy in [8, 14, 20]:
		image.fill_rect(_rect(key, 7, yy, 18, 2), Color("#8f7040"))
	for xx in [8, 12, 18, 22]:
		image.fill_rect(_rect(key, xx, 6, 2, 18), Color("#b7a780"))


func _paint_tv(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 5, 7, 22, 15), Color("#111820"))
	image.fill_rect(_rect(key, 8, 10, 16, 9), Color("#203b42"))
	image.fill_rect(_rect(key, 13, 22, 6, 4), Color("#3f2a18"))


func _paint_phone(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 10, 5, 12, 22), Color("#17110d"))
	image.fill_rect(_rect(key, 12, 8, 8, 12), Color("#b9d1c4"))
	image.fill_rect(_rect(key, 15, 23, 2, 2), Color("#eadcae"))


func _paint_small_frame(image: Image, key: String, color: Color) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 9, 8, 14, 16), color)
	image.fill_rect(_rect(key, 11, 10, 10, 12), Color("#050608", 0.16))


func _paint_pen(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 8, 15, 17, 3), Color("#050608"))
	image.fill_rect(_rect(key, 23, 14, 3, 5), Color("#d45c55"))


func _paint_dinner(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 9, 11, 14, 10), Color("#eadcae"))
	image.fill_rect(_rect(key, 12, 14, 8, 4), Color("#765235"))


func _paint_portal(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	for r in range(12, 2, -3):
		image.fill_rect(_rect(key, 16 - r / 2, 16 - r / 2, r, r), Color("#75d9e6", 0.18 + r * 0.02))
	image.fill_rect(_rect(key, 13, 6, 6, 20), Color("#b9d1c4", 0.6))


func _paint_rune(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 8, 8, 16, 16), Color("#050608", 0.72))
	image.fill_rect(_rect(key, 14, 10, 4, 12), Color("#d7b15e"))
	image.fill_rect(_rect(key, 10, 14, 12, 4), Color("#d7b15e"))


func _paint_node(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 6, 6, 20, 20), Color("#102b34"))
	image.fill_rect(_rect(key, 10, 10, 12, 12), Color("#75d9e6", 0.56))
	image.fill_rect(_rect(key, 15, 2, 2, 28), Color("#75d9e6", 0.24))


func _paint_enemy(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 8, 8, 16, 17), Color("#32151a"))
	image.fill_rect(_rect(key, 10, 11, 4, 3), Color("#d45c55"))
	image.fill_rect(_rect(key, 18, 11, 4, 3), Color("#d45c55"))


func _paint_npc(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 13, 6, 6, 6), Color("#eadcae"))
	image.fill_rect(_rect(key, 11, 13, 10, 13), Color("#3d5164"))


func _paint_tree(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 15, 18, 3, 10), Color("#4e3422"))
	image.fill_rect(_rect(key, 8, 7, 17, 14), Color("#244b26"))
	image.fill_rect(_rect(key, 11, 4, 11, 10), Color("#386b35"))


func _paint_flower(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	for pos in [Vector2i(8, 18), Vector2i(15, 13), Vector2i(21, 20)]:
		image.fill_rect(_rect(key, pos.x, pos.y, 1, 5), Color("#4f8d35"))
		image.fill_rect(_rect(key, pos.x - 2, pos.y - 2, 5, 3), Color("#fff4ce"))
		image.fill_rect(_rect(key, pos.x - 1, pos.y - 1, 3, 2), Color("#ef7c91"))
	for pos in [Vector2i(11, 24), Vector2i(18, 24)]:
		image.fill_rect(_rect(key, pos.x, pos.y, 4, 1), Color("#3f7a2f", 0.72))


func _paint_bright_tree(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 15, 17, 3, 11), Color("#7f5b31"))
	image.fill_rect(_rect(key, 8, 9, 17, 13), Color("#60ad3e"))
	image.fill_rect(_rect(key, 11, 5, 11, 11), Color("#8ad461"))
	image.fill_rect(_rect(key, 13, 7, 5, 3), Color("#c9ee82", 0.55))


func _paint_campfire(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 8, 23, 16, 3), Color("#4e3422"))
	image.fill_rect(_rect(key, 13, 12, 6, 11), Color("#d45c55"))
	image.fill_rect(_rect(key, 15, 8, 4, 13), Color("#f0d18a"))


func _paint_gate(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 7, 5, 4, 23), Color("#6b5845"))
	image.fill_rect(_rect(key, 21, 5, 4, 23), Color("#6b5845"))
	image.fill_rect(_rect(key, 7, 7, 18, 4), Color("#8f7040"))


func _paint_record(image: Image, key: String) -> void:
	_paint_small_frame(image, key, Color("#b9d1c4"))
	image.fill_rect(_rect(key, 12, 13, 8, 2), Color("#17110d"))
	image.fill_rect(_rect(key, 12, 17, 6, 2), Color("#17110d"))


func _paint_cabinet(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 6, 5, 20, 23), Color("#5a3f2b"))
	image.fill_rect(_rect(key, 9, 8, 14, 6), Color("#7a5731"))
	image.fill_rect(_rect(key, 9, 17, 14, 6), Color("#7a5731"))


func _paint_well(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 8, 13, 16, 11), Color("#5f6b70"))
	image.fill_rect(_rect(key, 10, 15, 12, 7), Color("#101820"))


func _paint_tent(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 6, 12, 20, 14), Color("#7a5731"))
	image.fill_rect(_rect(key, 12, 12, 8, 14), Color("#3f2a18"))


func _paint_shadow(image: Image, key: String) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 4, 22, 24, 5), Color("#050608", 0.34))


func _paint_glow(image: Image, key: String, color: Color) -> void:
	_fill_tile(image, key, Color(0, 0, 0, 0))
	image.fill_rect(_rect(key, 5, 5, 22, 22), color)
	image.fill_rect(_rect(key, 10, 10, 12, 12), Color(color, min(color.a + 0.18, 0.7)))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	push_warning("Could not parse JSON: %s" % path)
	return {}


func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open JSON for writing: %s" % path)
		quit(1)
	file.store_string(JSON.stringify(value, "\t"))
	file.store_string("\n")
	file.close()
