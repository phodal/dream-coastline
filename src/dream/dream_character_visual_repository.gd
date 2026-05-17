class_name DreamCharacterVisualRepository
extends RefCounted

const MODEL_PATH := "res://data/character_visual_models.json"

var characters: Dictionary = {}


func load_all() -> bool:
	characters.clear()
	var parsed := _load_json_dictionary(MODEL_PATH)
	if parsed.is_empty():
		push_error("Could not load character visual models: %s" % MODEL_PATH)
		return false

	var records: Dictionary = parsed.get("characters", {})
	for character_id in records.keys():
		var record: Variant = records[character_id]
		if typeof(record) == TYPE_DICTIONARY:
			characters[str(character_id)] = record
	return not characters.is_empty()


func character_record(character_id: String) -> Dictionary:
	return characters.get(character_id, {})


func story_review_assets_for(character_refs: Array) -> Array[Dictionary]:
	var assets: Array[Dictionary] = []
	for character_ref in character_refs:
		var ref := _normalize_character_ref(character_ref)
		var character_id := str(ref.get("id", ""))
		if character_id.is_empty():
			continue
		var record := character_record(character_id)
		if record.is_empty():
			continue
		assets.append({
			"id": character_id,
			"display_name": str(record.get("display_name", character_id)),
			"role_slot": str(record.get("role_slot", "")),
			"asset_path": _preferred_story_review_asset(record),
			"costume_state": str(ref.get("costume_state", "")),
			"pose": str(ref.get("pose", "")),
			"position": str(ref.get("position", "")),
		})
	return assets


func _normalize_character_ref(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	if typeof(value) == TYPE_STRING:
		return {"id": str(value)}
	return {}


func _preferred_story_review_asset(record: Dictionary) -> String:
	var targets: Dictionary = record.get("asset_targets", {})
	for key in ["story_review_cutout", "portrait", "model_sheet"]:
		var path := str(targets.get(key, ""))
		if not path.is_empty() and ResourceLoader.exists(path):
			return path
	return ""


func _load_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
