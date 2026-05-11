class_name OpeningModel
extends RefCounted

const BEATS_PATH := "res://data/opening_beats.json"

var beats: Array = []
var index := 0
var beat_time := 0.0


func load_beats() -> void:
	var file := FileAccess.open(BEATS_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot load opening beats: %s" % BEATS_PATH)
		beats = []
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Opening beats JSON must be an array")
		beats = []
		return

	beats = parsed
	index = 0
	beat_time = 0.0


func update(delta: float) -> void:
	beat_time += delta
	var seconds := float(current().get("auto_seconds", 0.0))
	if seconds > 0.0 and beat_time >= seconds:
		advance()


func advance() -> void:
	if index < beats.size() - 1:
		index += 1
		beat_time = 0.0


func reset() -> void:
	index = 0
	beat_time = 0.0


func current() -> Dictionary:
	if beats.is_empty():
		return {}
	return beats[index]


func current_id() -> String:
	return str(current().get("id", ""))


func is_at(id: String) -> bool:
	return current_id() == id


func is_or_after(id: String) -> bool:
	var target := _index_of(id)
	return target >= 0 and index >= target


func is_before(id: String) -> bool:
	var target := _index_of(id)
	return target >= 0 and index < target


func is_final() -> bool:
	return index >= beats.size() - 1


func _index_of(id: String) -> int:
	for i in range(beats.size()):
		if str(beats[i].get("id", "")) == id:
			return i
	return -1
