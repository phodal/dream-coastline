class_name RpgPlayerController
extends RefCounted

var session
var visual_repository
var move_duration := 0.16
var tile := Vector2i(7, 6)
var previous_tile := Vector2i(7, 6)
var facing := Vector2i(0, -1)
var move_elapsed := 0.0
var is_moving := false
var queued_direction := Vector2i.ZERO
var has_queued_direction := false
var blocked_tile := Vector2i.ZERO
var blocked_feedback_elapsed := 0.0
var blocked_feedback_duration := 0.18


func _init(game_session, repository) -> void:
	session = game_session
	visual_repository = repository


func reset_for_location() -> void:
	tile = visual_repository.spawn_for(session.scene_id, session.location_id)
	previous_tile = tile
	facing = Vector2i(0, -1)
	move_elapsed = 0.0
	is_moving = false
	queued_direction = Vector2i.ZERO
	has_queued_direction = false
	blocked_feedback_elapsed = 0.0


func try_move(direction: Vector2i) -> bool:
	if is_moving:
		queued_direction = direction
		has_queued_direction = true
		return false
	facing = direction
	var target := tile + direction
	if visual_repository.is_blocked(session.scene_id, session.location_id, target):
		blocked_tile = target
		blocked_feedback_elapsed = blocked_feedback_duration
		return false
	previous_tile = tile
	tile = target
	move_elapsed = 0.0
	is_moving = true
	return true


func update(delta: float) -> bool:
	var changed := false
	if blocked_feedback_elapsed > 0.0:
		blocked_feedback_elapsed = maxf(0.0, blocked_feedback_elapsed - delta)
		changed = true
	if not is_moving:
		return changed
	move_elapsed += delta
	if move_elapsed >= move_duration:
		complete_movement()
		if has_queued_direction:
			var next_direction := queued_direction
			has_queued_direction = false
			queued_direction = Vector2i.ZERO
			try_move(next_direction)
	return true


func complete_movement() -> void:
	previous_tile = tile
	move_elapsed = move_duration
	is_moving = false


func visual_tile() -> Vector2:
	if not is_moving:
		return Vector2(tile)
	var t := clampf(move_elapsed / move_duration, 0.0, 1.0)
	return Vector2(previous_tile).lerp(Vector2(tile), t)


func has_blocked_feedback() -> bool:
	return blocked_feedback_elapsed > 0.0


func interact() -> void:
	if is_moving:
		return
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
