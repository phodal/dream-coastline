extends RefCounted

const VISUAL_DIR := "res://data/visual_scenes"

var _visual_scenes: Dictionary = {}


func load_for_scene_ids(scene_ids: Array[String]) -> void:
	_visual_scenes.clear()
	for scene_id in scene_ids:
		var path := "%s/%s.json" % [VISUAL_DIR, scene_id]
		var parsed := _read_json(path)
		if not parsed.is_empty():
			_visual_scenes[scene_id] = parsed


func get_location_visual(scene_id: String, location_id: String) -> Dictionary:
	var visual_scene: Dictionary = _visual_scenes.get(scene_id, {})
	var locations: Dictionary = visual_scene.get("locations", {})
	return locations.get(location_id, {})


func get_backdrop_path(scene_id: String, location_id: String) -> String:
	var visual := get_location_visual(scene_id, location_id)
	return str(visual.get("illustrated_backdrop", ""))


func get_props(scene_id: String, location_id: String) -> Array:
	var visual := get_location_visual(scene_id, location_id)
	return visual.get("props", [])


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("VisualRepository invalid JSON dictionary at %s" % path)
		return {}
	return parsed
