class_name VisualAssetRegistry
extends RefCounted

const CHARACTER_PATH := "res://data/visual_assets/characters.json"

var characters := {}


func load_all() -> bool:
	characters.clear()
	return _load_characters()


func character_clip(actor_id: String, fallback_clip: String) -> String:
	var character = characters.get(actor_id, {})
	if typeof(character) != TYPE_DICTIONARY:
		return fallback_clip

	var clip := str(character.get("clip", ""))
	if clip.is_empty():
		clip = str(character.get("animation_clip", ""))
	return fallback_clip if clip.is_empty() else clip


func has_character(actor_id: String) -> bool:
	return characters.has(actor_id)


func _load_characters() -> bool:
	if not FileAccess.file_exists(CHARACTER_PATH):
		push_warning("Visual character asset registry does not exist: %s" % CHARACTER_PATH)
		return false

	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CHARACTER_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Could not parse visual character assets: %s" % CHARACTER_PATH)
		return false

	characters = parsed
	return true
