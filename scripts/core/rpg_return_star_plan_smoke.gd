class_name RpgReturnStarPlanSmoke
extends RefCounted

var session
var controller
var failures: Array[String] = []


func _init(game_session, player_controller) -> void:
	session = game_session
	controller = player_controller


func run() -> bool:
	failures.clear()
	session.load_scene(6)
	controller.reset_for_location()

	_expect_location("astral_tower")
	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("现代灾难")
	controller.interact()
	_expect_flag("confirmed_modern_disaster")
	_move(Vector2i(1, 0), 4)
	_face(Vector2i(0, -1))
	_expect_prompt("父母研究摘要")
	controller.interact()

	_move(Vector2i(1, 0), 5)
	_expect_prompt("归星议会")
	controller.interact()
	_expect_location("council")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("支持派")
	controller.interact()
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("反对派")
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("通过归星授权")
	controller.interact()
	_expect_flag("won_return_star_council")

	_move(Vector2i(1, 0), 4)
	_expect_prompt("浮空船坞")
	controller.interact()
	_expect_location("dockyard")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("续页舰蓝图")
	controller.interact()
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("建设续页舰")
	controller.interact()
	_expect_flag("built_return_vessel")

	_move(Vector2i(1, 0), 6)
	_expect_prompt("国书核心")
	controller.interact()
	_expect_location("core")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("夏离稳定国书")
	controller.interact()
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("文明备份链")
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("绑定文明备份")
	controller.interact()
	_expect_flag("bound_civilization_backups")

	_move(Vector2i(1, 0), 4)
	_expect_prompt("归星门")
	controller.interact()
	_expect_location("gate")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("最终校准")
	controller.interact()
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("开启归星门")
	controller.interact()
	_expect_flag("opened_return_gate")

	_move(Vector2i(1, 0), 6)
	_expect_prompt("现代世界裂隙")
	controller.interact()
	_expect_location("rift")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("静默探针")
	controller.interact()
	_expect_flag("identified_invasion_probe")

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("写：名")
	controller.interact()
	_expect_flag("named_invasion_probe")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：止")
	controller.interact()
	_expect_flag("restored_deleted_glyphs")

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
	_move(Vector2i(0, 1), 2)
	_move(Vector2i(-1, 0), 4)
	_face(Vector2i(0, -1))
	controller.interact()
	_move(Vector2i(1, 0), 4)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(1, 0))
	controller.interact()
	_expect_flag("defeated_invasion_probe")

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(1, 0), 2)
	_move(Vector2i(0, -1), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("父母真相")
	controller.interact()
	_expect_flag("received_parent_truth")

	_move(Vector2i(0, 1), 3)
	_move(Vector2i(-1, 0), 4)
	_face(Vector2i(0, -1))
	_expect_prompt("返回现代")
	controller.interact()
	_expect_flag("returned_to_modern_with_moqi")

	var ok := failures.is_empty()
	print("rpg-return-star-plan-keyboard-smoke status=%s location=%s tile=%s time=%s" % [
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
