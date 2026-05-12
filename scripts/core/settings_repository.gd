class_name SettingsRepository
extends RefCounted

const SETTINGS_PATH := "user://dream_coastline_settings.json"

var fullscreen := false


func load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	fullscreen = bool(parsed.get("fullscreen", false))


func save() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open settings file: %s" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify({"fullscreen": fullscreen}))


func apply() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
