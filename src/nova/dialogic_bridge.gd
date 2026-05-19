extends Node

signal finished(payload: Dictionary)

const DialogicTimelineScript := preload("res://addons/dialogic/Resources/timeline.gd")
## Base directory for authored .dtl timeline files.
const TIMELINE_DIR := "res://dialogic/timelines"

var _active_payload: Dictionary = {}
var _dialogic_node: Node = null
## Optional reference to DialogicVariableBridge for flag sync.
var variable_bridge: Node = null


func is_dialogic_installed() -> bool:
	return FileAccess.file_exists("res://addons/dialogic/plugin.cfg") and FileAccess.file_exists("res://addons/dialogic/Core/DialogicGameHandler.gd")


func can_play_runtime() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	_dialogic_node = get_node_or_null("/root/Dialogic")
	return _dialogic_node != null and _dialogic_node.has_method("start")


## Returns the res:// path of the authored .dtl file for this item, or "" if none exists.
## Path convention: dialogic/timelines/{scene_id}/{location_id}_{item_id}.dtl
static func resolve_timeline_path(scene_id: String, location_id: String, item_id: String) -> String:
	if scene_id.is_empty() or location_id.is_empty() or item_id.is_empty():
		return ""
	var path := "%s/%s/%s_%s.dtl" % [TIMELINE_DIR, scene_id, location_id, item_id]
	if ResourceLoader.exists(path) or FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		return path
	return ""


func play_payload(payload: Dictionary, backdrop_path: String) -> bool:
	if not can_play_runtime():
		return false
	_active_payload = payload.duplicate(true)
	if variable_bridge != null:
		variable_bridge.sync_flags_to_dialogic()
	if not _dialogic_node.timeline_ended.is_connected(_on_dialogic_timeline_ended):
		_dialogic_node.timeline_ended.connect(_on_dialogic_timeline_ended)
	# Apply Dream Coastline style when Styles subsystem is available.
	if _dialogic_node.has_method("get_subsystem"):
		var styles = _dialogic_node.get_subsystem("Styles")
		if styles != null and styles.has_method("change_style"):
			styles.change_style("Dream Coastline")
	# Prefer authored .dtl file when available.
	var timeline_path: String = str(payload.get("timeline_path", ""))
	if not timeline_path.is_empty() and (ResourceLoader.exists(timeline_path) or FileAccess.file_exists(ProjectSettings.globalize_path(timeline_path))):
		_dialogic_node.start(timeline_path)
		return true
	# Fall back to building from JSON payload.
	var timeline = build_timeline(payload, backdrop_path)
	if timeline == null:
		return false
	_dialogic_node.start(timeline)
	return true


func build_timeline(payload: Dictionary, backdrop_path: String):
	if not is_dialogic_installed():
		return null
	var timeline = DialogicTimelineScript.new()
	timeline.from_text(build_timeline_text(payload, backdrop_path))
	return timeline


## Build Dialogic timeline text from a story payload.
##
## Supports two dialogue formats:
##   1. Legacy single-text: payload["text"] = "single narration block"
##   2. Multi-line dialogue: payload["dialogue"] = [
##        {"speaker": "jizi_xuan", "text": "..."},
##        {"speaker": "旁白", "text": "...", "flags": ["flag_to_set"]},
##      ]
##
## Flags set via payload["flags"] are emitted as [signal set_flag:name] events
## so the DialogicVariableBridge can pick them up mid-timeline.
func build_timeline_text(payload: Dictionary, backdrop_path: String) -> String:
	var lines: Array[String] = []
	if not backdrop_path.is_empty():
		lines.append("[background arg=\"%s\"]" % _escape_shortcode_value(backdrop_path))

	var payload_characters := _dialogic_characters(payload)

	# Join all characters from payload once (for single-text mode)
	var dialogic_speaker := ""
	for character in payload_characters:
		var character_id := str(character.get("dialogic_id", "")).strip_edges()
		var portrait := str(character.get("portrait", "")).strip_edges()
		if portrait.is_empty():
			portrait = "default"
		lines.append("join %s (%s) left" % [_escape_identifier(character_id), _escape_identifier(portrait)])
		if dialogic_speaker.is_empty():
			dialogic_speaker = character_id

	# Multi-line dialogue array takes priority over single text.
	var dialogue: Array = payload.get("dialogue", [])
	if not dialogue.is_empty():
		for entry in dialogue:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var speaker := _resolve_speaker(str(entry.get("speaker", "旁白")), dialogic_speaker)
			var text := str(entry.get("text", "")).replace("\n", "\\\n")
			lines.append("%s: %s" % [_escape_speaker(speaker), text])
			# Emit flag signals inline for mid-dialogue flag progression
			for flag in entry.get("flags", []):
				lines.append("[signal set_flag:%s]" % str(flag))
	else:
		# Legacy single-text block
		var speaker := dialogic_speaker
		if speaker.is_empty():
			speaker = str(payload.get("speaker", "旁白")).strip_edges()
		if speaker.is_empty():
			speaker = "旁白"
		var text := str(payload.get("text", "")).replace("\n", "\\\n")
		lines.append("%s: %s" % [_escape_speaker(speaker), text])
		# Emit flag signals for all payload-level flags
		for flag in payload.get("flags", []):
			lines.append("[signal set_flag:%s]" % str(flag))

	for character in payload_characters:
		var character_id := str(character.get("dialogic_id", "")).strip_edges()
		lines.append("leave %s" % _escape_identifier(character_id))
	lines.append("[end_timeline]")
	return "\n".join(lines)


func smoke(payload: Dictionary, backdrop_path: String) -> bool:
	var timeline = build_timeline(payload, backdrop_path)
	return is_dialogic_installed() and timeline != null and timeline.events.size() >= 2


func _on_dialogic_timeline_ended() -> void:
	if _active_payload.is_empty():
		return
	var payload := _active_payload.duplicate(true)
	_active_payload.clear()
	if variable_bridge != null:
		variable_bridge.sync_flags_from_dialogic()
	finished.emit(payload)


## Resolve a speaker name to a Dialogic identifier when possible.
func _resolve_speaker(speaker_raw: String, dialogic_speaker_fallback: String) -> String:
	if speaker_raw.is_empty() or speaker_raw == "旁白":
		return "旁白" if dialogic_speaker_fallback.is_empty() else dialogic_speaker_fallback
	return speaker_raw

func _escape_speaker(speaker: String) -> String:
	if speaker.find(" ") != -1:
		return "\"%s\"" % speaker.replace("\"", "\\\"")
	return speaker.replace(":", "\\:")


func _escape_identifier(value: String) -> String:
	return value.replace(":", "\\:").replace(" ", "_")


func _escape_shortcode_value(value: String) -> String:
	return value.replace("\\", "\\\\").replace("\"", "\\\"")


func _dialogic_characters(payload: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_character in payload.get("characters", []):
		if typeof(raw_character) != TYPE_DICTIONARY:
			continue
		var character: Dictionary = raw_character
		var character_id := str(character.get("dialogic_id", "")).strip_edges()
		if character_id.is_empty():
			continue
		result.append(character)
	return result
