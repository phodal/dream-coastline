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


func spawn_for(scene_id: String, location_id: String) -> Vector2i:
	var visual := location_visual(scene_id, location_id)
	var spawn: Dictionary = visual.get("spawn", {})
	return Vector2i(int(spawn.get("x", 7)), int(spawn.get("y", 6)))


func interaction_at(scene_id: String, location_id: String, position: Vector2i) -> Dictionary:
	var visual := location_visual(scene_id, location_id)
	for prop in visual.get("props", []):
		var rect := _prop_rect(prop)
		if rect.has_point(position):
			if prop.has("exit") or prop.has("item"):
				return prop
	return {}


func is_blocked(scene_id: String, location_id: String, position: Vector2i) -> bool:
	if position.x <= 0 or position.y <= 0 or position.x >= 14 or position.y >= 8:
		return true
	var visual := location_visual(scene_id, location_id)
	for prop in visual.get("props", []):
		if not bool(prop.get("solid", false)):
			continue
		if _prop_rect(prop).has_point(position):
			return true
	return false


func _prop_rect(prop: Dictionary) -> Rect2i:
	return Rect2i(
		Vector2i(int(prop.get("x", 0)), int(prop.get("y", 0))),
		Vector2i(max(1, int(prop.get("w", 1))), max(1, int(prop.get("h", 1))))
	)
