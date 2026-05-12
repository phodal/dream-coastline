class_name SceneVisualRepository
extends RefCounted

const VISUAL_DIR := "res://data/visual_scenes"

var scenes := {}


func load_for_scene_ids(scene_ids: Array) -> void:
	scenes.clear()
	for scene_id in scene_ids:
		var path := "%s/%s.json" % [VISUAL_DIR, scene_id]
		if not FileAccess.file_exists(path):
			continue
		var text := FileAccess.get_file_as_string(path)
		var parsed = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY:
			scenes[str(scene_id)] = parsed
		else:
			push_warning("Could not parse visual scene data: %s" % path)


func location_visual(scene_id: String, location_id: String) -> Dictionary:
	var visual_scene: Dictionary = scenes.get(scene_id, {})
	return visual_scene.get("locations", {}).get(location_id, {})
