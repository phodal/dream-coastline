extends Node

signal location_changed(scene_id: String, location_id: String)
signal scene_changed(scene_id: String)

var current_scene_id := ""
var current_location_id := ""
var visited_locations: Dictionary = {}


func start_scene(scene_id: String, location_id: String) -> void:
	current_scene_id = scene_id
	current_location_id = location_id
	visited_locations = {}
	_mark_visited(scene_id, location_id)
	scene_changed.emit(scene_id)
	location_changed.emit(scene_id, location_id)


func move_to(location_id: String) -> void:
	if location_id.is_empty() or location_id == current_location_id:
		return
	current_location_id = location_id
	_mark_visited(current_scene_id, current_location_id)
	location_changed.emit(current_scene_id, current_location_id)


func _mark_visited(scene_id: String, location_id: String) -> void:
	if scene_id.is_empty() or location_id.is_empty():
		return
	if not visited_locations.has(scene_id):
		visited_locations[scene_id] = {}
	visited_locations[scene_id][location_id] = true
