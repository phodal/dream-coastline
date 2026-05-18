extends Node

signal mode_changed(mode: String)

const EXPLORATION := "exploration"
const DIALOGUE := "dialogue"
const VN_CUTSCENE := "vn_cutscene"
const MENU := "menu"

var current_mode := MENU


func set_mode(mode: String) -> void:
	if current_mode == mode:
		return
	current_mode = mode
	mode_changed.emit(current_mode)


func is_input_locked() -> bool:
	return current_mode == DIALOGUE or current_mode == VN_CUTSCENE or current_mode == MENU
