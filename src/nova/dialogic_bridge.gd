extends Node

signal finished(payload: Dictionary)

const DialogicTimelineScript := preload("res://addons/dialogic/Resources/timeline.gd")

var _active_payload: Dictionary = {}
var _dialogic_node: Node = null


func is_dialogic_installed() -> bool:
	return FileAccess.file_exists("res://addons/dialogic/plugin.cfg") and FileAccess.file_exists("res://addons/dialogic/Core/DialogicGameHandler.gd")


func can_play_runtime() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	_dialogic_node = get_node_or_null("/root/Dialogic")
	return _dialogic_node != null and _dialogic_node.has_method("start")


func play_payload(payload: Dictionary, backdrop_path: String) -> bool:
	if not can_play_runtime():
		return false
	var timeline = build_timeline(payload, backdrop_path)
	if timeline == null:
		return false
	_active_payload = payload.duplicate(true)
	if not _dialogic_node.timeline_ended.is_connected(_on_dialogic_timeline_ended):
		_dialogic_node.timeline_ended.connect(_on_dialogic_timeline_ended)
	_dialogic_node.start(timeline)
	return true


func build_timeline(payload: Dictionary, backdrop_path: String):
	if not is_dialogic_installed():
		return null
	var timeline = DialogicTimelineScript.new()
	timeline.from_text(build_timeline_text(payload, backdrop_path))
	return timeline


func build_timeline_text(payload: Dictionary, backdrop_path: String) -> String:
	var lines: Array[String] = []
	if not backdrop_path.is_empty():
		lines.append("[background arg=\"%s\"]" % _escape_shortcode_value(backdrop_path))
	var dialogic_speaker := ""
	for character in _dialogic_characters(payload):
		var character_id := str(character.get("dialogic_id", "")).strip_edges()
		var portrait := str(character.get("portrait", "")).strip_edges()
		if portrait.is_empty():
			portrait = "phone"
		lines.append("join %s (%s) left" % [_escape_identifier(character_id), _escape_identifier(portrait)])
		if dialogic_speaker.is_empty():
			dialogic_speaker = character_id
	var speaker := dialogic_speaker
	if speaker.is_empty():
		speaker = str(payload.get("speaker", "旁白")).strip_edges()
	if speaker.is_empty():
		speaker = "旁白"
	var text := str(payload.get("text", "")).replace("\n", "\\\n")
	lines.append("%s: %s" % [_escape_speaker(speaker), text])
	for character in _dialogic_characters(payload):
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
	finished.emit(payload)


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
