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


func next_scene_id(scene_id: String) -> String:
	var index := _scene_ids.find(scene_id)
	if index == -1 or index + 1 >= _scene_ids.size():
		return ""
	return _scene_ids[index + 1]


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


func get_location_choices(scene_id: String, location_id: String) -> Dictionary:
	var location := get_location(scene_id, location_id)
	return location.get("choices", {})


func get_glyph_actions(scene_id: String, location_id: String) -> Dictionary:
	var location := get_location(scene_id, location_id)
	return location.get("glyph_actions", {})


func get_build_actions(scene_id: String, location_id: String) -> Dictionary:
	var location := get_location(scene_id, location_id)
	return location.get("build_actions", {})


func get_combos(scene_id: String, location_id: String) -> Dictionary:
	var location := get_location(scene_id, location_id)
	return location.get("combos", {})


func get_encounters(scene_id: String, location_id: String) -> Dictionary:
	var location := get_location(scene_id, location_id)
	return location.get("encounters", {})


func get_combat(scene_id: String, location_id: String) -> Dictionary:
	var location := get_location(scene_id, location_id)
	return location.get("combat", {})


func get_initial_flags(scene_id: String) -> Array:
	return get_scene(scene_id).get("initial_flags", [])


func get_ending_flag(scene_id: String) -> String:
	return str(get_scene(scene_id).get("ending_flag", ""))


func get_branch_resolved_flag(scene_id: String) -> String:
	var branch_consequences: Dictionary = get_scene(scene_id).get("branch_consequences", {})
	return str(branch_consequences.get("resolved_flag", ""))


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
