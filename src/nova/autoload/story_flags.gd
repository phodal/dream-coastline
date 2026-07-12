extends Node

signal flag_changed(flag: String, value: bool)

var _flags: Dictionary = {}


func set_flag(flag: String, value := true) -> void:
	if flag.is_empty():
		return
	if _flags.get(flag, false) == value:
		return
	if value:
		_flags[flag] = true
	else:
		_flags.erase(flag)
	flag_changed.emit(flag, value)


func has_flag(flag: String) -> bool:
	return bool(_flags.get(flag, false))


func has_all(flags: Array) -> bool:
	for flag in flags:
		if not has_flag(str(flag)):
			return false
	return true


func has_any(flags: Array) -> bool:
	for flag in flags:
		if has_flag(str(flag)):
			return true
	return false


func export_flags() -> Dictionary:
	return _flags.duplicate(true)


func import_flags(flags) -> void:
	reset()
	if typeof(flags) == TYPE_DICTIONARY:
		for flag in flags.keys():
			if bool(flags[flag]):
				set_flag(str(flag), true)
	elif typeof(flags) == TYPE_ARRAY:
		for flag in flags:
			set_flag(str(flag), true)


func reset() -> void:
	_flags.clear()
