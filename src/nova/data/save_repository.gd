extends RefCounted

const DEFAULT_SAVE_PATH := "user://nova_save.json"

var _save_path := DEFAULT_SAVE_PATH


func configure(path: String) -> void:
	if not path.is_empty():
		_save_path = path


func has_save() -> bool:
	return FileAccess.file_exists(_save_path)


func save_game(scene_id: String, location_id: String, flags: Dictionary) -> bool:
	if scene_id.is_empty() or location_id.is_empty():
		return false
	var flag_names := flags.keys()
	flag_names.sort()
	var payload := {
		"version": 1,
		"architecture": "nova",
		"scene_id": scene_id,
		"location_id": location_id,
		"flags": flag_names,
		"saved_at": Time.get_datetime_string_from_system(true),
	}
	var absolute_dir := ProjectSettings.globalize_path(_save_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


func load_game() -> Dictionary:
	var file := FileAccess.open(_save_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func clear() -> void:
	if not FileAccess.file_exists(_save_path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path))
