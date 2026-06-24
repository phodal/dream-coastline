## DialogicVariableBridge
## Keeps StoryFlags and Dialogic.VAR in sync so that Dialogic timelines can
## read and set story-progression flags via {flags.flag_name} syntax.
##
## Usage from a Dialogic timeline:
##   Set variable: flags.noticed_dark_window = true
##   Read variable: {flags.noticed_dark_window}
##   Signal-based flag set: [signal set_flag:noticed_dark_window]
extends Node

const FLAGS_NAMESPACE := "flags"

var _dialogic: Node = null
var _connected := false


func _ready() -> void:
	StoryFlags.flag_changed.connect(_on_story_flag_changed)


func connect_dialogic() -> bool:
	_dialogic = get_node_or_null("/root/Dialogic")
	if _dialogic == null:
		return false
	if not _connected:
		_dialogic.signal_event.connect(_on_dialogic_signal_event)
		_connected = true
	return true


## Push all current StoryFlags into Dialogic.VAR under the "flags" namespace.
## Call this before starting a Dialogic timeline so conditions can read flags.
func sync_flags_to_dialogic() -> void:
	if not connect_dialogic():
		return
	_ensure_dialogic_flags_namespace()
	for flag_name in StoryFlags.export_flags().keys():
		_dialogic.current_state_info["variables"][FLAGS_NAMESPACE][flag_name] = true


## Pull any flag variables that were set inside a Dialogic timeline back into StoryFlags.
## Call this after a timeline ends to capture flags set via variable events.
func sync_flags_from_dialogic() -> void:
	if _dialogic == null:
		return
	_ensure_dialogic_flags_namespace()
	var state: Dictionary = _dialogic.current_state_info.get("variables", {})
	var flags_dict: Dictionary = state.get(FLAGS_NAMESPACE, {})
	for flag_name in flags_dict.keys():
		if bool(flags_dict[flag_name]) and not StoryFlags.has_flag(flag_name):
			StoryFlags.set_flag(flag_name, true)


func _on_story_flag_changed(flag: String, value: bool) -> void:
	if _dialogic == null:
		return
	_ensure_dialogic_flags_namespace()
	_dialogic.current_state_info["variables"][FLAGS_NAMESPACE][flag] = value


## Handle [signal set_flag:flag_name] events emitted from Dialogic timelines.
func _on_dialogic_signal_event(argument: Variant) -> void:
	var text := str(argument).strip_edges()
	if text.begins_with("set_flag:"):
		var flag_name := text.trim_prefix("set_flag:").strip_edges()
		if not flag_name.is_empty():
			StoryFlags.set_flag(flag_name, true)
	elif text.begins_with("clear_flag:"):
		var flag_name := text.trim_prefix("clear_flag:").strip_edges()
		if not flag_name.is_empty():
			StoryFlags.set_flag(flag_name, false)


func _ensure_dialogic_flags_namespace() -> void:
	if _dialogic == null:
		return
	if not _dialogic.current_state_info.has("variables"):
		_dialogic.current_state_info["variables"] = {}
	if not _dialogic.current_state_info["variables"].has(FLAGS_NAMESPACE):
		_dialogic.current_state_info["variables"][FLAGS_NAMESPACE] = {}


func shutdown() -> void:
	if StoryFlags.flag_changed.is_connected(_on_story_flag_changed):
		StoryFlags.flag_changed.disconnect(_on_story_flag_changed)
	if _dialogic != null and _connected and _dialogic.signal_event.is_connected(_on_dialogic_signal_event):
		_dialogic.signal_event.disconnect(_on_dialogic_signal_event)
	_dialogic = null
	_connected = false
