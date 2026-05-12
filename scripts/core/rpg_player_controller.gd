class_name RpgPlayerController
extends RefCounted

var session
var visual_repository
var tile := Vector2i(7, 6)
var facing := Vector2i(0, -1)


func _init(game_session, repository) -> void:
	session = game_session
	visual_repository = repository


func reset_for_location() -> void:
	tile = visual_repository.spawn_for(session.scene_id, session.location_id)
	facing = Vector2i(0, -1)


func try_move(direction: Vector2i) -> bool:
	facing = direction
	var target := tile + direction
	if visual_repository.is_blocked(session.scene_id, session.location_id, target):
		return false
	tile = target
	return true


func interact() -> void:
	var interaction := current_interaction()
	if interaction.is_empty():
		session.event_log.append("这里没有可以互动的东西。")
		return

	if interaction.has("exit"):
		session.apply_action({"verb": "go", "arg": str(interaction["exit"])})
		reset_for_location()
	elif interaction.has("item"):
		session.apply_action({"verb": "inspect", "arg": str(interaction["item"])})


func prompt_text() -> String:
	var interaction := current_interaction()
	if interaction.has("exit"):
		var exit_id := str(interaction["exit"])
		var exits: Dictionary = session.current_location().get("exits", {})
		return "Space/Enter 进入：%s" % exits.get(exit_id, exit_id)
	if interaction.has("item"):
		var item_id := str(interaction["item"])
		var items: Dictionary = session.current_location().get("items", {})
		return "Space/Enter 调查：%s" % items.get(item_id, {}).get("name", item_id)
	return "WASD/方向键移动，Space/Enter 互动"


func current_interaction() -> Dictionary:
	var target := tile + facing
	var interaction: Dictionary = visual_repository.interaction_at(session.scene_id, session.location_id, target)
	if interaction.is_empty():
		interaction = visual_repository.interaction_at(session.scene_id, session.location_id, tile)
	return interaction
