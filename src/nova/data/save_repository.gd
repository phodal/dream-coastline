extends RefCounted

const DEFAULT_SAVE_PATH := "user://nova_save.json"

var _save_path := DEFAULT_SAVE_PATH


func configure(path: String) -> void:
	if not path.is_empty():
		_save_path = path


func has_save() -> bool:
	return FileAccess.file_exists(_save_path)


func save_game(scene_id: String, location_id: String, flags: Dictionary, story_progress: Dictionary = {}) -> bool:
	if scene_id.is_empty() or location_id.is_empty():
		return false
	var flag_names := flags.keys()
	flag_names.sort()
	var payload := {
		"version": 2,
		"architecture": "nova",
		"scene_id": scene_id,
		"location_id": location_id,
		"flags": flag_names,
		"story_progress": story_progress.duplicate(true),
		"saved_at": Time.get_datetime_string_from_system(true),
	}
	var absolute_dir := ProjectSettings.globalize_path(_save_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	var temp_path := "%s.tmp" % _save_path
	var backup_path := "%s.bak" % _save_path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	var temp_payload := _read_valid_payload(temp_path)
	if temp_payload.is_empty():
		_remove_if_exists(temp_path)
		return false
	var absolute_save := ProjectSettings.globalize_path(_save_path)
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	_remove_if_exists(backup_path)
	if FileAccess.file_exists(_save_path):
		if DirAccess.copy_absolute(absolute_save, absolute_backup) != OK:
			_remove_if_exists(temp_path)
			return false
		if DirAccess.remove_absolute(absolute_save) != OK:
			_remove_if_exists(temp_path)
			return false
	if DirAccess.rename_absolute(absolute_temp, absolute_save) != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.copy_absolute(absolute_backup, absolute_save)
		_remove_if_exists(temp_path)
		return false
	return true


func load_game() -> Dictionary:
	var parsed := _read_valid_payload(_save_path)
	if not parsed.is_empty():
		return parsed
	return _read_valid_payload("%s.bak" % _save_path)


func clear() -> void:
	for path in [_save_path, "%s.tmp" % _save_path, "%s.bak" % _save_path]:
		_remove_if_exists(path)


func _read_valid_payload(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {}
	var payload: Dictionary = parsed
	if str(payload.get("architecture", "")) != "nova":
		return {}
	if int(payload.get("version", 0)) < 1:
		return {}
	if str(payload.get("scene_id", "")).is_empty() or str(payload.get("location_id", "")).is_empty():
		return {}
	if not (payload.get("flags", []) is Array):
		return {}
	return payload


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
