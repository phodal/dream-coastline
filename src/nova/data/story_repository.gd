extends RefCounted

const STORY_DIR := "res://data/story_scenes"

var _scenes: Dictionary = {}
var _scene_ids: Array[String] = []


func load_all() -> bool:
	_scenes.clear()
	_scene_ids.clear()
	var dir := DirAccess.open(STORY_DIR)
	if dir == null:
		push_error("StoryRepository cannot open %s" % STORY_DIR)
		return false
	var files := dir.get_files()
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".json"):
			continue
		var path := "%s/%s" % [STORY_DIR, file_name]
		var parsed := _read_json(path)
		if parsed.is_empty():
			continue
		var scene_id := str(parsed.get("id", file_name.trim_suffix(".json")))
		_scenes[scene_id] = parsed
		_scene_ids.append(scene_id)
	return not _scene_ids.is_empty()


func scene_ids() -> Array[String]:
	return _scene_ids.duplicate()


func first_scene_id() -> String:
	if _scene_ids.is_empty():
		return ""
	return _scene_ids[0]


func get_scene(scene_id: String) -> Dictionary:
	return _scenes.get(scene_id, {})


func get_start_location(scene_id: String) -> String:
	var scene := get_scene(scene_id)
	return str(scene.get("start", ""))


func get_location(scene_id: String, location_id: String) -> Dictionary:
	var scene := get_scene(scene_id)
	var locations: Dictionary = scene.get("locations", {})
	return locations.get(location_id, {})


func get_items(scene_id: String, location_id: String) -> Dictionary:
	var location := get_location(scene_id, location_id)
	return location.get("items", {})


func get_exits(scene_id: String, location_id: String) -> Dictionary:
	var location := get_location(scene_id, location_id)
	return location.get("exits", {})


func get_required_flags(scene_id: String) -> Array:
	return get_scene(scene_id).get("required_flags", [])


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("StoryRepository cannot read %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("StoryRepository invalid JSON dictionary at %s" % path)
		return {}
	return parsed
