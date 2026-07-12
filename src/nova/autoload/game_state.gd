extends Node

signal location_changed(scene_id: String, location_id: String)
signal scene_changed(scene_id: String)

var current_scene_id := ""
var current_location_id := ""
var visited_locations: Dictionary = {}
var metrics: Dictionary = {}
var carried_flags: Dictionary = {}
var carried_branch_excluded_flags: Dictionary = {}
var carried_metrics_by_scene: Dictionary = {}
var combat_resources: Dictionary = {}


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


func reset_story_progress() -> void:
	metrics.clear()
	carried_flags.clear()
	carried_branch_excluded_flags.clear()
	carried_metrics_by_scene.clear()
	combat_resources.clear()


func set_scene_metrics(base_metrics: Dictionary) -> void:
	metrics = base_metrics.duplicate(true)


func apply_metrics(delta: Dictionary) -> void:
	for key in delta.keys():
		var metric_key := str(key)
		metrics[metric_key] = int(metrics.get(metric_key, 0)) + int(delta[key])


func add_carried_metrics(scene_id: String, delta: Dictionary) -> void:
	var merged: Dictionary = carried_metrics_by_scene.get(scene_id, {}).duplicate(true)
	for key in delta.keys():
		var metric_key := str(key)
		merged[metric_key] = int(merged.get(metric_key, 0)) + int(delta[key])
	carried_metrics_by_scene[scene_id] = merged


func export_story_progress() -> Dictionary:
	return {
		"metrics": metrics.duplicate(true),
		"carried_flags": carried_flags.duplicate(true),
		"carried_branch_excluded_flags": carried_branch_excluded_flags.duplicate(true),
		"carried_metrics_by_scene": carried_metrics_by_scene.duplicate(true),
		"combat_resources": combat_resources.duplicate(true),
	}


func import_story_progress(data) -> void:
	reset_story_progress()
	if typeof(data) != TYPE_DICTIONARY:
		return
	metrics = _dictionary_value(data, "metrics")
	carried_flags = _dictionary_value(data, "carried_flags")
	carried_branch_excluded_flags = _dictionary_value(data, "carried_branch_excluded_flags")
	carried_metrics_by_scene = _dictionary_value(data, "carried_metrics_by_scene")
	combat_resources = _dictionary_value(data, "combat_resources")


func combat_key(scene_id := current_scene_id, location_id := current_location_id) -> String:
	return "%s/%s" % [scene_id, location_id]


func ensure_combat_resources(combat: Dictionary) -> Dictionary:
	if combat.is_empty():
		return {}
	var key := combat_key()
	if not combat_resources.has(key):
		var player_hp := maxi(1, int(combat.get("player_hp", 5)))
		var enemy_hp := maxi(1, int(combat.get("enemy_hp", 1)))
		combat_resources[key] = {
			"player_hp": player_hp,
			"player_hp_max": player_hp,
			"enemy_hp": enemy_hp,
			"enemy_hp_max": enemy_hp,
			"ink": maxi(2, int(combat.get("player_ink", 3))),
			"ink_max": maxi(2, int(combat.get("player_ink", 3))),
			"supplies": maxi(1, int(combat.get("player_supplies", 2))),
			"name_attempts": 0,
			"attacks_since_name": 0,
		}
	return (combat_resources[key] as Dictionary)


func update_combat_resources(resources: Dictionary) -> void:
	combat_resources[combat_key()] = resources.duplicate(true)


func _mark_visited(scene_id: String, location_id: String) -> void:
	if scene_id.is_empty() or location_id.is_empty():
		return
	if not visited_locations.has(scene_id):
		visited_locations[scene_id] = {}
	visited_locations[scene_id][location_id] = true


func _dictionary_value(data: Dictionary, key: String) -> Dictionary:
	var value = data.get(key, {})
	return value.duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}
