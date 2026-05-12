class_name SettingsRepository
extends RefCounted

const SETTINGS_PATH := "user://dream_coastline_settings.json"

var fullscreen := false
var master_volume := 0.8


func load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	fullscreen = bool(parsed.get("fullscreen", false))
	master_volume = clampf(float(parsed.get("master_volume", 0.8)), 0.0, 1.0)


func save() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open settings file: %s" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify({
		"fullscreen": fullscreen,
		"master_volume": master_volume,
	}))


func apply() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, master_volume <= 0.001)
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.001)))
