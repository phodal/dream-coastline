extends Node

signal flag_changed(flag: String, value: bool)

var _flags: Dictionary = {}


func set_flag(flag: String, value := true) -> void:
	if flag.is_empty():
		return
	if _flags.get(flag, false) == value:
		return
	_flags[flag] = value
	flag_changed.emit(flag, value)


func has_flag(flag: String) -> bool:
	return bool(_flags.get(flag, false))


func has_all(flags: Array) -> bool:
	for flag in flags:
		if not has_flag(str(flag)):
			return false
	return true


func export_flags() -> Dictionary:
	return _flags.duplicate(true)


func reset() -> void:
	_flags.clear()
