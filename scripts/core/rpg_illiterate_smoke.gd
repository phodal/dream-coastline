class_name RpgIlliterateSmoke
extends RefCounted

var session
var controller
var failures: Array[String] = []


func _init(game_session, player_controller) -> void:
	session = game_session
	controller = player_controller


func run() -> bool:
	failures.clear()
	session.load_scene(1)
	controller.reset_for_location()

	_expect_location("mud_road")
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("手机")
	controller.interact()
	_expect_flag("checked_phone_no_service")

	_move(Vector2i(1, 0), 1)
	_move(Vector2i(0, -1), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("破损路牌")
	controller.interact()
	_expect_flag("checked_broken_sign")

	_move(Vector2i(-1, 0), 9)
	_face(Vector2i(0, -1))
	_expect_prompt("燃烧的城")
	controller.interact()
	_expect_flag("saw_burning_city")

	_move(Vector2i(1, 0), 4)
	_move(Vector2i(0, 1), 3)
	_expect_prompt("黑色钢笔")
	controller.interact()

	_move(Vector2i(1, 0), 7)
	_move(Vector2i(0, -1), 2)
	_expect_prompt("边境流民营")
	controller.interact()
	_expect_location("camp")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("布告")
	controller.interact()

	_move(Vector2i(1, 0), 4)
	_face(Vector2i(1, 0))
	_expect_prompt("小砚")
	controller.interact()
	_expect_flag("met_xiaoyan")

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(1, 0), 5)
	_move(Vector2i(0, -1), 2)
	_expect_prompt("树林逃跑路线")
	controller.interact()
	_expect_location("chase")

	_move(Vector2i(1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("墨律司士兵")
	controller.interact()
	_expect_flag("saw_molusi")

	_move(Vector2i(-1, 0), 5)
	_face(Vector2i(0, -1))
	_expect_prompt("破损石门")
	controller.interact()

	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("夏离")
	controller.interact()
	_expect_flag("met_xiali")

	_move(Vector2i(1, 0), 5)
	_expect_prompt("废弃驿站")
	controller.interact()
	_expect_location("station")

	_move(Vector2i(-1, 0), 2)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("夏离写下的名")
	controller.interact()
	_expect_flag("learned_name_strokes")

	_move(Vector2i(-1, 0), 1)
	_face(Vector2i(-1, 0))
	_expect_prompt("小砚的名字")
	controller.interact()

	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("写：名")
	controller.interact()
	controller.interact()
	controller.interact()
	_expect_flag("named_beast")

	_move(Vector2i(1, 0), 2)
	_face(Vector2i(1, 0))
	_expect_prompt("攻击无名兽")
	controller.interact()
	controller.interact()
	_move(Vector2i(-1, 0), 2)
	_face(Vector2i(0, -1))
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(1, 0))
	controller.interact()
	controller.interact()
	_expect_flag("defeated_nameless")

	var ok := failures.is_empty()
	print("rpg-illiterate-keyboard-smoke status=%s location=%s tile=%s time=%s" % [
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
		controller.complete_movement()


func _face(direction: Vector2i) -> void:
	controller.try_move(direction)
	controller.complete_movement()


func _expect_location(expected: String) -> void:
	if session.location_id != expected:
		failures.append("expected location %s, got %s" % [expected, session.location_id])


func _expect_prompt(text: String) -> void:
	var prompt: String = controller.prompt_text()
	if not prompt.contains(text):
		failures.append("expected prompt containing %s, got %s" % [text, prompt])


func _expect_flag(flag: String) -> void:
	if not session.has_flag(flag):
		failures.append("expected flag %s" % flag)
