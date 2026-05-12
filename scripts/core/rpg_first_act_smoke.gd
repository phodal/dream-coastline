class_name RpgFirstActSmoke
extends RefCounted

var session
var controller
var failures: Array[String] = []


func _init(game_session, player_controller) -> void:
	session = game_session
	controller = player_controller


func run() -> bool:
	failures.clear()
	session.load_scene(0)
	controller.reset_for_location()

	_expect_location("street")
	_expect_tile(Vector2i(7, 6), "street spawn")
	_move(Vector2i(1, 0), 6)
	_move(Vector2i(0, -1), 2)
	_expect_prompt("居民楼门口")
	controller.interact()
	_expect_location("building")
	_expect_tile(Vector2i(7, 6), "building spawn")

	_move(Vector2i(0, -1), 4)
	_expect_prompt("声控灯")
	controller.interact()
	_expect_flag("checked_voice_lamp")

	_move(Vector2i(1, 0), 6)
	_move(Vector2i(0, 1), 2)
	_expect_prompt("家门口")
	controller.interact()
	_expect_location("home")

	_move(Vector2i(0, -1), 3)
	_move(Vector2i(-1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("门锁")
	controller.interact()
	_expect_flag("checked_unlocked_door")

	_move(Vector2i(1, 0), 7)
	_move(Vector2i(0, 1), 1)
	_expect_prompt("客厅")
	controller.interact()
	_expect_location("living_room")

	_move(Vector2i(1, 0), 1)
	_move(Vector2i(0, -1), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("冷掉的晚饭")
	controller.interact()
	_expect_flag("checked_cold_dinner")

	var ok := failures.is_empty()
	print("rpg-first-act-keyboard-smoke status=%s location=%s tile=%s time=%s" % [
		"PASS" if ok else "FAIL",
		session.location_id,
		controller.tile,
		session.format_time(),
	])
	for failure in failures:
		print("failure=", failure)
	return ok


func _move(direction: Vector2i, count: int) -> void:
	for step in range(count):
		if not controller.try_move(direction):
			failures.append("movement blocked at step %s direction=%s tile=%s" % [step + 1, direction, controller.tile])
			return


func _face(direction: Vector2i) -> void:
	controller.try_move(direction)


func _expect_location(expected: String) -> void:
	if session.location_id != expected:
		failures.append("expected location %s, got %s" % [expected, session.location_id])


func _expect_tile(expected: Vector2i, label: String) -> void:
	if controller.tile != expected:
		failures.append("expected %s tile %s, got %s" % [label, expected, controller.tile])


func _expect_prompt(text: String) -> void:
	var prompt: String = controller.prompt_text()
	if not prompt.contains(text):
		failures.append("expected prompt containing %s, got %s" % [text, prompt])


func _expect_flag(flag: String) -> void:
	if not session.has_flag(flag):
		failures.append("expected flag %s" % flag)
