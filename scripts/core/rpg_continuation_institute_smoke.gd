class_name RpgContinuationInstituteSmoke
extends RefCounted

var session
var controller
var failures: Array[String] = []


func _init(game_session, player_controller) -> void:
	session = game_session
	controller = player_controller


func run() -> bool:
	failures.clear()
	session.load_scene(4)
	controller.reset_for_location()

	_expect_location("institute")
	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("第一批成员")
	controller.interact()
	_expect_flag("met_first_members")
	_move(Vector2i(1, 0), 4)
	_face(Vector2i(0, -1))
	_expect_prompt("续文院章程")
	controller.interact()
	_expect_flag("drafted_open_charter")
	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("建设续文院")
	controller.interact()
	_expect_flag("founded_institute")
	_move(Vector2i(0, 1), 3)
	_move(Vector2i(1, 0), 4)
	_move(Vector2i(0, -1), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("发布标准字典")
	controller.interact()
	_expect_flag("published_standard_dictionary")

	_move(Vector2i(0, 1), 1)
	_move(Vector2i(1, 0), 4)
	_expect_prompt("平民学塾")
	controller.interact()
	_expect_location("school")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("第一堂课")
	controller.interact()
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("错误记录")
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("建设公开学塾")
	controller.interact()
	_expect_flag("opened_first_school")

	_move(Vector2i(1, 0), 4)
	_expect_prompt("工坊区")
	controller.interact()
	_expect_location("workshop")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("阿棠")
	controller.interact()
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("防洪符文事故")
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("建立工坊流程")
	controller.interact()
	_expect_flag("repaired_workshop_flow")

	_move(Vector2i(1, 0), 4)
	_expect_prompt("符文矿场")
	controller.interact()
	_expect_location("mine")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("危险作业")
	controller.interact()
	_expect_flag("checked_mine_hazard")
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("写：止")
	controller.interact()
	_expect_flag("stabilized_mine")
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("建设矿场安全流程")
	controller.interact()
	_expect_flag("solved_mine_safety")

	_move(Vector2i(1, 0), 5)
	_expect_prompt("通信塔遗址")
	controller.interact()
	_expect_location("tower")

	_move(Vector2i(-1, 0), 2)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("通信符阵")
	controller.interact()
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("修复通信塔")
	controller.interact()
	_expect_flag("restored_communication_tower")

	_move(Vector2i(1, 0), 5)
	_expect_prompt("封字塔")
	controller.interact()
	_expect_location("seal_tower")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("学生")
	controller.interact()
	_expect_flag("students_under_attack")
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("公共字典")
	controller.interact()
	_expect_flag("dictionary_under_attack")
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("保护学生和字典")
	controller.interact()
	_expect_flag("protected_dictionary")

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(-1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("写：名")
	controller.interact()
	_expect_flag("named_seal_tower")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：止")
	controller.interact()
	_expect_flag("paused_forgetting")

	_move(Vector2i(1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(1, 0))
	_expect_prompt("攻击封字塔")
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
	_expect_flag("defeated_seal_tower")

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(-1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("建设公共档案塔")
	controller.interact()
	_expect_flag("archive_tower_built")

	var ok := failures.is_empty()
	print("rpg-continuation-institute-keyboard-smoke status=%s location=%s tile=%s time=%s" % [
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
