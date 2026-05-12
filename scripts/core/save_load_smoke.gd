class_name SaveLoadSmoke
extends RefCounted

var session
var player_controller
var save_repository
var failures: Array[String] = []


func _init(game_session, controller, repository) -> void:
	session = game_session
	player_controller = controller
	save_repository = repository


func run() -> bool:
	failures.clear()
	session.load_scene(0)
	player_controller.reset_for_location()
	_move(Vector2i(1, 0), 6)
	_move(Vector2i(0, -1), 2)
	player_controller.interact()

	if session.location_id != "building":
		failures.append("setup expected building, got %s" % session.location_id)
	if not save_repository.save(session, player_controller):
		failures.append("save returned false")

	session.load_scene(1)
	player_controller.reset_for_location()
	if session.location_id == "building":
		failures.append("mutation did not change location before load")

	if not save_repository.load_into(session, player_controller):
		failures.append("load returned false")

	if session.location_id != "building":
		failures.append("loaded location expected building, got %s" % session.location_id)
	if player_controller.tile != Vector2i(7, 6):
		failures.append("loaded player tile expected (7, 6), got %s" % player_controller.tile)
	if session.elapsed_seconds != 20:
		failures.append("loaded elapsed expected 20, got %s" % session.elapsed_seconds)

	var ok := failures.is_empty()
	print("save-load-smoke status=%s location=%s tile=%s time=%s" % [
		"PASS" if ok else "FAIL",
		session.location_id,
		player_controller.tile,
		session.format_time(),
	])
	for failure in failures:
		print("failure=", failure)
	return ok


func _move(direction: Vector2i, count: int) -> void:
	for _step in range(count):
		player_controller.try_move(direction)
		player_controller.complete_movement()
