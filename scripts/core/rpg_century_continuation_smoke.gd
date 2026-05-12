class_name RpgCenturyContinuationSmoke
extends RefCounted

var session
var controller
var failures: Array[String] = []


func _init(game_session, player_controller) -> void:
	session = game_session
	controller = player_controller


func run() -> bool:
	failures.clear()
	session.load_scene(5)
	controller.reset_for_location()

	_expect_location("industry")
	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("第一批教师")
	controller.interact()
	_expect_flag("first_students_teach")
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("闻素教材")
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("建设文字工业")
	controller.interact()
	_expect_flag("built_text_industry")

	_move(Vector2i(1, 0), 4)
	_expect_prompt("国书网络时代")
	controller.interact()
	_expect_location("network")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("夏离的选择")
	controller.interact()
	_expect_flag("xiali_accepts_cost")
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("绑定夏离")
	controller.interact()
	_expect_flag("bound_xiali_to_statebook")
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("新一代工程师")
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("建设国书网络")
	controller.interact()
	_expect_flag("built_statebook_network")

	_move(Vector2i(1, 0), 3)
	_expect_prompt("星象工程时代")
	controller.interact()
	_expect_location("astral")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("星图")
	controller.interact()
	_expect_flag("mapped_stars_as_text")
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("跨界信标")
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("建设星象塔")
	controller.interact()
	_expect_flag("completed_astral_tower")

	_move(Vector2i(1, 0), 4)
	_expect_prompt("星象塔顶")
	controller.interact()
	_expect_location("star_tower")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("静默信号")
	controller.interact()
	_expect_flag("identified_silent_probe")

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("写：名")
	controller.interact()
	_expect_flag("named_silent_probe")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：止")
	controller.interact()
	_expect_flag("paused_signal_deletion")

	_move(Vector2i(1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(1, 0))
	_expect_prompt("攻击静默探针")
	controller.interact()
	controller.interact()
	_move(Vector2i(0, 1), 2)
	_move(Vector2i(-1, 0), 4)
	_face(Vector2i(0, -1))
	controller.interact()
	_move(Vector2i(1, 0), 4)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(1, 0))
	controller.interact()
	controller.interact()
	_expect_flag("defeated_silent_probe")

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(1, 0), 2)
	_move(Vector2i(0, -1), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("现代城市")
	controller.interact()
	_expect_flag("saw_modern_star_darkening")

	var ok := failures.is_empty()
	print("rpg-century-continuation-keyboard-smoke status=%s location=%s tile=%s time=%s" % [
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
