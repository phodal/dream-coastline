class_name SettingsRepository
extends RefCounted

const SETTINGS_PATH := "user://dream_coastline_settings.json"
const DEFAULT_KEY_BINDINGS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_up": KEY_W,
	"move_down": KEY_S,
	"interact": KEY_SPACE,
	"pause": KEY_ESCAPE,
}
const SECONDARY_KEY_BINDINGS := {
	"move_left": KEY_LEFT,
	"move_right": KEY_RIGHT,
	"move_up": KEY_UP,
	"move_down": KEY_DOWN,
	"interact": KEY_ENTER,
}

var fullscreen := false
var master_volume := 0.8
var _visual_style := "classic_dark"
var text_scale := 1.0
var high_contrast := false
var dialogue_speed := 1.0
var screen_reader := false
var key_bindings: Dictionary = DEFAULT_KEY_BINDINGS.duplicate(true)
var _settings_path := SETTINGS_PATH


func configure(path: String) -> void:
	if not path.is_empty():
		_settings_path = path


func load() -> void:
	if not FileAccess.file_exists(_settings_path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(_settings_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	fullscreen = bool(parsed.get("fullscreen", false))
	master_volume = clampf(float(parsed.get("master_volume", 0.8)), 0.0, 1.0)
	_visual_style = _normalize_visual_style(str(parsed.get("visual_style", "classic_dark")))
	text_scale = clampf(float(parsed.get("text_scale", 1.0)), 1.0, 1.5)
	high_contrast = bool(parsed.get("high_contrast", false))
	dialogue_speed = clampf(float(parsed.get("dialogue_speed", 1.0)), 0.0, 2.0)
	screen_reader = bool(parsed.get("screen_reader", false))
	var loaded_bindings = parsed.get("key_bindings", {})
	if loaded_bindings is Dictionary:
		for action in DEFAULT_KEY_BINDINGS.keys():
			var keycode := int(loaded_bindings.get(action, DEFAULT_KEY_BINDINGS[action]))
			key_bindings[action] = keycode if keycode > 0 else DEFAULT_KEY_BINDINGS[action]


func save() -> void:
	var file := FileAccess.open(_settings_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open settings file: %s" % _settings_path)
		return
	file.store_string(JSON.stringify({
		"fullscreen": fullscreen,
		"master_volume": master_volume,
		"visual_style": _visual_style,
		"text_scale": text_scale,
		"high_contrast": high_contrast,
		"dialogue_speed": dialogue_speed,
		"screen_reader": screen_reader,
		"key_bindings": key_bindings.duplicate(true),
	}))
	file.close()


func clear() -> void:
	if FileAccess.file_exists(_settings_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_settings_path))


func apply() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, master_volume <= 0.001)
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.001)))
	_apply_key_bindings()
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		var dialogic := tree.root.get_node_or_null("Dialogic")
		if dialogic != null and dialogic.get("Settings") != null:
			dialogic.Settings.text_speed = dialogue_speed


func set_key_binding(action: String, keycode: int) -> bool:
	if not DEFAULT_KEY_BINDINGS.has(action) or keycode <= 0:
		return false
	for other_action in key_bindings.keys():
		if str(other_action) != action and int(key_bindings[other_action]) == keycode:
			return false
	key_bindings[action] = keycode
	_apply_key_binding(action)
	return true


func reset_key_bindings() -> void:
	key_bindings = DEFAULT_KEY_BINDINGS.duplicate(true)
	_apply_key_bindings()


func key_label(action: String) -> String:
	return OS.get_keycode_string(int(key_bindings.get(action, DEFAULT_KEY_BINDINGS.get(action, 0))))


func _apply_key_bindings() -> void:
	for action in DEFAULT_KEY_BINDINGS.keys():
		_apply_key_binding(str(action))


func _apply_key_binding(action: String) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var primary := InputEventKey.new()
	primary.keycode = int(key_bindings.get(action, DEFAULT_KEY_BINDINGS[action]))
	InputMap.action_add_event(action, primary)
	if SECONDARY_KEY_BINDINGS.has(action):
		var secondary := InputEventKey.new()
		secondary.keycode = int(SECONDARY_KEY_BINDINGS[action])
		InputMap.action_add_event(action, secondary)


func visual_style() -> String:
	return _visual_style


func set_visual_style(value: String) -> void:
	_visual_style = _normalize_visual_style(value)


func _normalize_visual_style(value: String) -> String:
	if value == "classic_dark":
		return "classic_dark"
	if value == "sunlit_mmo":
		return "sunlit_mmo"
	return "classic_dark"
