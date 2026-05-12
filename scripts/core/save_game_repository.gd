class_name SaveGameRepository
extends RefCounted

const SAVE_PATH := "user://dream_coastline_save.json"


func save(session, player_controller) -> bool:
	var payload := {
		"version": 1,
		"session": session.to_save_data(),
		"player": player_controller.to_save_data(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(payload))
	return true


func load_into(session, player_controller) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	session.load_save_data(parsed.get("session", {}))
	player_controller.load_save_data(parsed.get("player", {}))
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
