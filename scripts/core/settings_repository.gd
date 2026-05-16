class_name SettingsRepository
extends RefCounted

const SETTINGS_PATH := "user://dream_coastline_settings.json"

var fullscreen := false
var master_volume := 0.8
var _visual_style := "sunlit_mmo"


func load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	fullscreen = bool(parsed.get("fullscreen", false))
	master_volume = clampf(float(parsed.get("master_volume", 0.8)), 0.0, 1.0)
	_visual_style = _normalize_visual_style(str(parsed.get("visual_style", "sunlit_mmo")))


func save() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open settings file: %s" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify({
		"fullscreen": fullscreen,
		"master_volume": master_volume,
		"visual_style": _visual_style,
	}))


func apply() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, master_volume <= 0.001)
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.001)))


func visual_style() -> String:
	return _visual_style


func set_visual_style(value: String) -> void:
	_visual_style = _normalize_visual_style(value)


func _normalize_visual_style(value: String) -> String:
	if value == "classic_dark":
		return "classic_dark"
	return "sunlit_mmo"
