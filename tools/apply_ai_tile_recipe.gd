extends SceneTree

const SCHEMA := "dream-coastline.ai_tile_recipe.v1"
const COLUMNS := 15
const ROWS := 9
const SOURCE_ID := 0
const TILE_REGISTRY_PATH := "res://data/visual_assets/tilesets.json"
const VISUAL_SCENE_DIR := "res://data/visual_scenes"
const VALID_LAYERS := ["ground", "walls", "decor", "props_shadow", "lighting"]

var tile_coords := {}
var changed_operations: Array[String] = []


func _initialize() -> void:
	var recipe_path := _recipe_path_from_args()
	if recipe_path.is_empty():
		_fatal("Usage: Godot --path . --headless --script tools/apply_ai_tile_recipe.gd -- <recipe.json>")

	_load_tile_coords()
	var recipe := _read_json(_project_path(recipe_path))
	_validate_recipe_header(recipe)
	_apply_recipe(recipe)
	print("ai-tile-recipe-apply status=PASS scene=%s location=%s operations=%s" % [
		str(recipe.get("scene_id", "")),
		str(recipe.get("location_id", "")),
		", ".join(changed_operations),
	])
	quit(0)


func _recipe_path_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--"):
			continue
		return str(arg)
	return ""


func _project_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://") or path.begins_with("/"):
		return path
	if path.begins_with("./"):
		return "res://%s" % path.substr(2)
	return "res://%s" % path


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_fatal("JSON file does not exist: %s" % path)
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_fatal("JSON root must be an object: %s" % path)
	return parsed


func _load_tile_coords() -> void:
	var registry := _read_json(TILE_REGISTRY_PATH)
	for raw_tileset in registry.get("tilesets", []):
		if typeof(raw_tileset) != TYPE_DICTIONARY:
			continue
		var tileset: Dictionary = raw_tileset
		if str(tileset.get("id", "")) != "dream_scene_tiles":
			continue
		for raw_tile in tileset.get("tiles", []):
			if typeof(raw_tile) != TYPE_DICTIONARY:
				continue
			var tile: Dictionary = raw_tile
			var tile_id := str(tile.get("id", ""))
			var coord: Dictionary = tile.get("coord", {})
			if tile_id.is_empty() or typeof(coord) != TYPE_DICTIONARY:
				continue
			tile_coords[tile_id] = Vector2i(int(coord.get("x", -1)), int(coord.get("y", -1)))
	if tile_coords.is_empty():
		_fatal("No dream_scene_tiles entries found in %s" % TILE_REGISTRY_PATH)


func _validate_recipe_header(recipe: Dictionary) -> void:
	if str(recipe.get("schema", "")) != SCHEMA:
		_fatal("Unsupported recipe schema: %s" % str(recipe.get("schema", "")))
	if str(recipe.get("scene_id", "")).is_empty():
		_fatal("Recipe missing scene_id")
	if str(recipe.get("location_id", "")).is_empty():
		_fatal("Recipe missing location_id")
	if typeof(recipe.get("operations", [])) != TYPE_ARRAY:
		_fatal("Recipe operations must be an array")
	if typeof(recipe.get("screenshot_states", [])) != TYPE_ARRAY or recipe.get("screenshot_states", []).is_empty():
		_fatal("Recipe must include screenshot_states")


func _apply_recipe(recipe: Dictionary) -> void:
	var scene_id := str(recipe.get("scene_id", ""))
	var location_id := str(recipe.get("location_id", ""))
	var visual_path := "%s/%s.json" % [VISUAL_SCENE_DIR, scene_id]
	var visual_scene := _read_json(visual_path)
	var locations: Dictionary = visual_scene.get("locations", {})
	if not locations.has(location_id):
		_fatal("Visual scene %s has no location %s" % [scene_id, location_id])
	var visual: Dictionary = locations[location_id]
	var scene_path := str(visual.get("asset_scene", ""))
	if scene_path.is_empty():
		_fatal("Visual location has no asset_scene: %s/%s" % [scene_id, location_id])

	var packed_resource: Resource = load(scene_path)
	if not (packed_resource is PackedScene):
		_fatal("asset_scene is not a PackedScene: %s" % scene_path)
	var packed_scene := packed_resource as PackedScene
	var instance := packed_scene.instantiate()
	if not (instance is Node):
		_fatal("asset_scene root is not a Node: %s" % scene_path)
	var root := instance as Node
	_apply_operations(root, recipe)
	_assign_owner(root, root)

	var output := PackedScene.new()
	var pack_error := output.pack(root)
	if pack_error != OK:
		root.free()
		_fatal("Could not pack %s: %s" % [scene_path, pack_error])
	var save_error := ResourceSaver.save(output, scene_path)
	root.free()
	if save_error != OK:
		_fatal("Could not save %s: %s" % [scene_path, save_error])


func _assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		if child is Node:
			(child as Node).owner = owner
			_assign_owner(child as Node, owner)


func _apply_operations(root: Node, recipe: Dictionary) -> void:
	for raw_operation in recipe.get("operations", []):
		if typeof(raw_operation) != TYPE_DICTIONARY:
			_fatal("Recipe operation must be an object")
		var operation: Dictionary = raw_operation
		var op_id := str(operation.get("id", ""))
		var tool := str(operation.get("tool", ""))
		if op_id.is_empty():
			_fatal("Recipe operation missing id")
		match tool:
			"fill":
				_apply_fill(root, operation)
			"paint":
				_apply_paint(root, operation)
			"rect":
				_apply_fill(root, operation)
			"line":
				_apply_line(root, operation)
			"scatter":
				_apply_scatter(root, operation)
			"pattern":
				_apply_pattern(root, operation, recipe)
			"erase":
				_apply_erase(root, operation)
			_:
				_fatal("Unsupported tool %s in %s" % [tool, op_id])
		changed_operations.append(op_id)


func _apply_fill(root: Node, operation: Dictionary) -> void:
	var layer := _operation_layer(root, operation)
	var area := _operation_area(operation, [0, 0, COLUMNS, ROWS])
	var tile := str(operation.get("tile", ""))
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			_set_tile(layer, x, y, tile)


func _apply_paint(root: Node, operation: Dictionary) -> void:
	var layer := _operation_layer(root, operation)
	var tile := str(operation.get("tile", ""))
	if operation.has("points"):
		for raw_point in operation.get("points", []):
			var point := _point(raw_point)
			_set_tile(layer, point.x, point.y, tile)
		return
	var point := _point(operation.get("at", []))
	_set_tile(layer, point.x, point.y, tile)


func _apply_line(root: Node, operation: Dictionary) -> void:
	var layer := _operation_layer(root, operation)
	var from_point := _point(operation.get("from", []))
	var to_point := _point(operation.get("to", []))
	var selection := _operation_selection(operation)
	var dx: int = absi(to_point.x - from_point.x)
	var sx := 1 if from_point.x < to_point.x else -1
	var dy: int = -absi(to_point.y - from_point.y)
	var sy := 1 if from_point.y < to_point.y else -1
	var error := dx + dy
	var point := from_point
	var index := 0
	while true:
		_set_tile(layer, point.x, point.y, selection[index % selection.size()])
		if point == to_point:
			break
		var twice_error := 2 * error
		if twice_error >= dy:
			error += dy
			point.x += sx
		if twice_error <= dx:
			error += dx
			point.y += sy
		index += 1


func _apply_scatter(root: Node, operation: Dictionary) -> void:
	var layer := _operation_layer(root, operation)
	var area := _operation_area(operation, [0, 0, COLUMNS, ROWS])
	var selection := _operation_selection(operation)
	var density := clampf(float(operation.get("density", 0.0)), 0.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(operation.get("seed", 1))
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if rng.randf() <= density:
				var tile := selection[rng.randi_range(0, selection.size() - 1)]
				_set_tile(layer, x, y, tile)


func _apply_pattern(root: Node, operation: Dictionary, recipe: Dictionary) -> void:
	var patterns: Dictionary = recipe.get("patterns", {})
	var pattern_id := str(operation.get("pattern", ""))
	if not patterns.has(pattern_id):
		_fatal("Unknown pattern: %s" % pattern_id)
	var pattern: Dictionary = patterns[pattern_id]
	var origin := _point(operation.get("at", []))
	var layers: Dictionary = pattern.get("layers", {})
	var legend: Dictionary = pattern.get("legend", {})
	for layer_name_variant in layers.keys():
		var layer_name := str(layer_name_variant)
		var layer := _layer(root, layer_name)
		var rows: Array = layers[layer_name_variant]
		for row_index in range(rows.size()):
			var row := str(rows[row_index])
			for column_index in range(row.length()):
				var symbol := row.substr(column_index, 1)
				if symbol == "." or symbol == " ":
					continue
				if not legend.has(symbol):
					_fatal("Pattern %s uses unknown symbol %s" % [pattern_id, symbol])
				var tile := str(legend[symbol])
				_set_tile(layer, origin.x + column_index, origin.y + row_index, tile)


func _apply_erase(root: Node, operation: Dictionary) -> void:
	var layer := _operation_layer(root, operation)
	if operation.has("area"):
		var area := _operation_area(operation, [0, 0, COLUMNS, ROWS])
		for y in range(area.position.y, area.end.y):
			for x in range(area.position.x, area.end.x):
				_erase_tile(layer, x, y)
		return
	if operation.has("points"):
		for raw_point in operation.get("points", []):
			var point := _point(raw_point)
			_erase_tile(layer, point.x, point.y)
		return
	var point := _point(operation.get("at", []))
	_erase_tile(layer, point.x, point.y)


func _operation_layer(root: Node, operation: Dictionary) -> TileMapLayer:
	return _layer(root, str(operation.get("layer", "")))


func _layer(root: Node, layer_name: String) -> TileMapLayer:
	if not VALID_LAYERS.has(layer_name):
		_fatal("Unknown TileMapLayer: %s" % layer_name)
	var node := root.get_node_or_null(layer_name)
	if not (node is TileMapLayer):
		_fatal("Missing TileMapLayer: %s" % layer_name)
	return node as TileMapLayer


func _operation_selection(operation: Dictionary) -> Array[String]:
	var selection: Array[String] = []
	if operation.has("selection"):
		for raw_tile in operation.get("selection", []):
			selection.append(str(raw_tile))
	elif operation.has("tile"):
		selection.append(str(operation.get("tile", "")))
	if selection.is_empty():
		_fatal("Operation must include tile or selection")
	for tile in selection:
		_require_tile(tile)
	return selection


func _operation_area(operation: Dictionary, fallback: Array) -> Rect2i:
	var raw_area: Array = operation.get("area", fallback)
	if raw_area.size() != 4:
		_fatal("Area must be [x, y, width, height]")
	var rect := Rect2i(
		Vector2i(int(raw_area[0]), int(raw_area[1])),
		Vector2i(int(raw_area[2]), int(raw_area[3]))
	)
	_require_rect(rect)
	return rect


func _point(raw_value) -> Vector2i:
	if typeof(raw_value) != TYPE_ARRAY or raw_value.size() != 2:
		_fatal("Point must be [x, y]")
	var point := Vector2i(int(raw_value[0]), int(raw_value[1]))
	_require_point(point)
	return point


func _set_tile(layer: TileMapLayer, x: int, y: int, tile_id: String) -> void:
	_require_point(Vector2i(x, y))
	var coord := _require_tile(tile_id)
	layer.set_cell(Vector2i(x, y), SOURCE_ID, coord)


func _erase_tile(layer: TileMapLayer, x: int, y: int) -> void:
	_require_point(Vector2i(x, y))
	layer.erase_cell(Vector2i(x, y))


func _require_tile(tile_id: String) -> Vector2i:
	if not tile_coords.has(tile_id):
		_fatal("Unknown tile ID: %s" % tile_id)
	return tile_coords[tile_id]


func _require_point(point: Vector2i) -> void:
	if point.x < 0 or point.y < 0 or point.x >= COLUMNS or point.y >= ROWS:
		_fatal("Tile point out of bounds: %s" % str(point))


func _require_rect(rect: Rect2i) -> void:
	if rect.position.x < 0 or rect.position.y < 0 or rect.size.x <= 0 or rect.size.y <= 0:
		_fatal("Tile rect out of bounds: %s" % str(rect))
	if rect.end.x > COLUMNS or rect.end.y > ROWS:
		_fatal("Tile rect out of bounds: %s" % str(rect))


func _fatal(message: String) -> void:
	push_error(message)
	print("ai-tile-recipe-apply status=FAIL reason=%s" % message)
	quit(1)
