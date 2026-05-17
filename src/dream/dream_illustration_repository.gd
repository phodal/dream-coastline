class_name DreamIllustrationRepository
extends RefCounted

const ILLUSTRATION_PATH := "res://data/chapter_illustrations.json"

var illustrations: Dictionary = {}


func load_all() -> bool:
	illustrations.clear()
	var parsed := _load_json_dictionary(ILLUSTRATION_PATH)
	if parsed.is_empty():
		push_error("Could not load chapter illustrations: %s" % ILLUSTRATION_PATH)
		return false

	var records: Dictionary = parsed.get("illustrations", {})
	for scene_id in records.keys():
		var scene_records: Array = records[scene_id]
		var normalized: Array[Dictionary] = []
		for record in scene_records:
			if typeof(record) == TYPE_DICTIONARY:
				normalized.append(record)
		illustrations[str(scene_id)] = normalized
	return true


func illustrations_for_scene(scene_id: String) -> Array[Dictionary]:
	var records: Array[Dictionary] = illustrations.get(scene_id, [])
	return records.duplicate(true)


func review_illustration_for(scene_id: String, location_id: String, command: String = "") -> Dictionary:
	var records := illustrations_for_scene(scene_id)
	if records.is_empty():
		return {}

	for record in records:
		if _record_matches(record, location_id, command, "commands"):
			return record
	for record in records:
		if _record_matches(record, location_id, "", "locations"):
			return record
	return records[0]


func validate_scene_illustrations(scene_ids: Array[String]) -> Dictionary:
	var failures: Array[String] = []
	var checked := 0
	for scene_id in scene_ids:
		var records := illustrations_for_scene(scene_id)
		if records.is_empty():
			failures.append("%s missing chapter illustration" % scene_id)
			continue

		for record in records:
			var path := str(record.get("path", ""))
			if path.is_empty():
				failures.append("%s/%s missing path" % [scene_id, str(record.get("id", "illustration"))])
				continue
			if not ResourceLoader.exists(path):
				failures.append("%s missing texture %s" % [scene_id, path])
				continue
			var resource := load(path)
			if not (resource is Texture2D):
				failures.append("%s illustration is not Texture2D %s" % [scene_id, path])
				continue
			var texture := resource as Texture2D
			var width := texture.get_width()
			var height := texture.get_height()
			if width <= 0 or height <= 0:
				failures.append("%s illustration has empty size %s" % [scene_id, path])
				continue
			var ratio := float(width) / float(height)
			if absf(ratio - (16.0 / 9.0)) > 0.04:
				failures.append("%s illustration is not widescreen enough %s ratio=%.3f" % [scene_id, path, ratio])
				continue
			var focus_path := str(record.get("focus_path", ""))
			if not focus_path.is_empty():
				if not ResourceLoader.exists(focus_path):
					failures.append("%s missing focus texture %s" % [scene_id, focus_path])
					continue
				var focus_resource := load(focus_path)
				if not (focus_resource is Texture2D):
					failures.append("%s focus illustration is not Texture2D %s" % [scene_id, focus_path])
					continue
			checked += 1

	return {
		"ok": failures.is_empty(),
		"checked": checked,
		"failures": failures,
	}


func _load_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _record_matches(record: Dictionary, location_id: String, command: String, key: String) -> bool:
	var values: Array = record.get(key, [])
	if values.is_empty():
		return false
	if key == "locations":
		for value in values:
			if str(value) == location_id:
				return true
		return false
	for value in values:
		if str(value) == command:
			return true
	return false
