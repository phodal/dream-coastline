class_name RpgDeadKingdomSmoke
extends RefCounted

var session
var controller
var failures: Array[String] = []


func _init(game_session, player_controller) -> void:
	session = game_session
	controller = player_controller


func run() -> bool:
	failures.clear()
	session.load_scene(3)
	controller.reset_for_location()

	_expect_location("outer_city")
	_move(Vector2i(1, 0), 2)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("死城秩序")
	controller.interact()
	_expect_flag("saw_dead_city_order")

	_move(Vector2i(-1, 0), 5)
	_move(Vector2i(0, -1), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("罪人告示")
	controller.interact()

	_move(Vector2i(0, 1), 3)
	_move(Vector2i(1, 0), 9)
	_move(Vector2i(0, -1), 2)
	_expect_prompt("贵族藏书楼")
	controller.interact()
	_expect_location("library")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("改革文献")
	controller.interact()
	_expect_flag("found_reform_records")
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("禁令抄本")
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("选择公开藏书")
	controller.interact()
	_expect_flag("chose_public_books")

	_move(Vector2i(1, 0), 4)
	_expect_prompt("墨律司总部")
	controller.interact()
	_expect_location("hq")

	_move(Vector2i(-1, 0), 2)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("封锁日志")
	controller.interact()
	_expect_flag("found_lockdown_logs")
	_move(Vector2i(1, 0), 4)
	_face(Vector2i(0, -1))
	_expect_prompt("缺页名册")
	controller.interact()

	_move(Vector2i(0, 1), 1)
	_move(Vector2i(1, 0), 4)
	_move(Vector2i(0, -1), 1)
	_expect_prompt("残破宫城")
	controller.interact()
	_expect_location("palace")

	_move(Vector2i(-1, 0), 2)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("陷落路线")
	controller.interact()
	_expect_flag("restored_fall_route")
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(1, 0))
	_expect_prompt("夏离")
	controller.interact()

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(1, 0), 5)
	_move(Vector2i(0, -1), 2)
	_expect_prompt("主国书殿")
	controller.interact()
	_expect_location("hall")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("王权质问")
	controller.interact()
	_expect_flag("heard_royal_question")

	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("写：名")
	controller.interact()
	_expect_flag("named_royal_shadow")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：门")
	controller.interact()
	_expect_flag("broken_royal_rule")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：止")
	controller.interact()
	_expect_flag("paused_royal_lock")

	_move(Vector2i(1, 0), 2)
	_face(Vector2i(1, 0))
	_expect_prompt("攻击国书残影")
	controller.interact()
	controller.interact()
	controller.interact()
	controller.interact()
	_expect_flag("defeated_royal_shadow")

	_move(Vector2i(-1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("写：门")
	controller.interact()
	_expect_flag("opened_main_core")

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(1, 0), 5)
	_move(Vector2i(0, -1), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("父母完整计划")
	controller.interact()
	_expect_flag("read_parent_full_plan")

	var ok := failures.is_empty()
	print("rpg-dead-kingdom-keyboard-smoke status=%s location=%s tile=%s time=%s" % [
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
