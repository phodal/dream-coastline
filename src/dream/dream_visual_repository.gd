class_name DreamVisualRepository
extends RefCounted

const VISUAL_DIR := "res://data/visual_scenes"

var scenes: Dictionary = {}


func load_for_scene_ids(scene_ids: Array[String]) -> bool:
	scenes.clear()
	var ok := true
	for scene_id in scene_ids:
		var path := "%s/%s.json" % [VISUAL_DIR, scene_id]
		var parsed := _load_json_dictionary(path)
		if parsed.is_empty():
			push_error("Could not load visual scene data: %s" % path)
			ok = false
			continue
		scenes[str(scene_id)] = parsed
	return ok


func location_visual(scene_id: String, location_id: String) -> Dictionary:
	var visual_scene: Dictionary = scenes.get(scene_id, {})
	var locations: Dictionary = visual_scene.get("locations", {})
	return locations.get(location_id, {})


func spawn_cell(scene_id: String, location_id: String, fallback: Vector2i) -> Vector2i:
	var visual := location_visual(scene_id, location_id)
	var spawn: Dictionary = visual.get("spawn", {})
	if spawn.is_empty():
		return fallback
	return Vector2i(int(spawn.get("x", fallback.x)), int(spawn.get("y", fallback.y)))


func props_for(scene_id: String, location_id: String) -> Array:
	var visual := location_visual(scene_id, location_id)
	var props: Array = visual.get("props", [])
	return props


func prop_rect(prop: Dictionary) -> Rect2i:
	return Rect2i(
		Vector2i(int(prop.get("x", 0)), int(prop.get("y", 0))),
		Vector2i(max(1, int(prop.get("w", 1))), max(1, int(prop.get("h", 1))))
	)


func prop_cell(prop: Dictionary, fallback: Vector2i) -> Vector2i:
	if prop.is_empty():
		return fallback
	return Vector2i(int(prop.get("x", fallback.x)), int(prop.get("y", fallback.y)))


func item_prop(scene_id: String, location_id: String, item_id: String) -> Dictionary:
	for prop in props_for(scene_id, location_id):
		if typeof(prop) == TYPE_DICTIONARY and str(prop.get("item", "")) == item_id:
			return prop
	return {}


func exit_prop(scene_id: String, location_id: String, destination_id: String) -> Dictionary:
	for prop in props_for(scene_id, location_id):
		if typeof(prop) == TYPE_DICTIONARY and str(prop.get("exit", "")) == destination_id:
			return prop
	return {}


func action_prop(scene_id: String, location_id: String, verb: String, arg: String) -> Dictionary:
	for prop in props_for(scene_id, location_id):
		if typeof(prop) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = prop.get("action", {})
		if action.is_empty():
			continue
		if _action_matches(action, verb, arg):
			return prop
	return {}


func validate_asset_scenes(scene_ids: Array[String]) -> Dictionary:
	var checked := 0
	var failures: Array[String] = []
	for scene_id in scene_ids:
		var visual_scene: Dictionary = scenes.get(scene_id, {})
		var locations: Dictionary = visual_scene.get("locations", {})
		for location_id in locations.keys():
			var visual: Dictionary = locations[location_id]
			var path := str(visual.get("asset_scene", ""))
			if path.is_empty():
				failures.append("%s/%s missing asset_scene" % [scene_id, location_id])
				continue
			if not ResourceLoader.exists(path):
				failures.append("%s/%s missing asset scene %s" % [scene_id, location_id, path])
				continue
			var resource := load(path)
			if not (resource is PackedScene):
				failures.append("%s/%s asset scene is not PackedScene %s" % [scene_id, location_id, path])
				continue
			var instance := (resource as PackedScene).instantiate()
			if instance == null:
				failures.append("%s/%s asset scene did not instantiate %s" % [scene_id, location_id, path])
				continue
			instance.free()
			checked += 1
	return {
		"ok": failures.is_empty(),
		"checked": checked,
		"failures": failures,
	}


func _action_matches(action: Dictionary, verb: String, arg: String) -> bool:
	if str(action.get("verb", "")) != verb:
		return false
	var action_arg := str(action.get("arg", ""))
	if action_arg == arg:
		return true
	if verb in ["write", "attack"] and action_arg == "":
		return true
	return false


func _load_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
