class_name RpgMoqiAcademySmoke
extends RefCounted

var session
var controller
var failures: Array[String] = []


func _init(game_session, player_controller) -> void:
	session = game_session
	controller = player_controller


func run() -> bool:
	failures.clear()
	session.load_scene(2)
	controller.reset_for_location()

	_expect_location("academy")
	_move(Vector2i(1, 0), 1)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("闻素")
	controller.interact()
	_expect_flag("met_wensu")

	_move(Vector2i(-1, 0), 5)
	_move(Vector2i(0, -1), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("名")
	controller.interact()
	_expect_flag("learned_name")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("门")
	controller.interact()
	_expect_flag("learned_door")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("火")
	controller.interact()
	_expect_flag("learned_fire")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("止")
	controller.interact()
	_expect_flag("learned_stop")

	_move(Vector2i(0, 1), 1)
	_move(Vector2i(1, 0), 7)
	_expect_prompt("边境村落")
	controller.interact()
	_expect_location("village")

	_move(Vector2i(-1, 0), 4)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("裂开的水井")
	controller.interact()
	_expect_flag("checked_broken_well")
	session.apply_action({"verb": "engage", "arg": "contract_patrol"})
	_expect_flag("cleared_contract_patrol")

	_move(Vector2i(1, 0), 5)
	_face(Vector2i(1, 0))
	_expect_prompt("村民")
	controller.interact()

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：止")
	controller.interact()
	_expect_flag("stabilized_well_crack")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：火")
	controller.interact()
	_expect_flag("started_ink_engine")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：名")
	controller.interact()
	_expect_flag("repaired_well")

	_move(Vector2i(0, 1), 3)
	_move(Vector2i(1, 0), 6)
	_move(Vector2i(0, -1), 2)
	_expect_prompt("地下藏书室")
	controller.interact()
	_expect_location("archive")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("三层文字")
	controller.interact()
	_move(Vector2i(1, 0), 4)
	_face(Vector2i(0, -1))
	_expect_prompt("封存柜")
	controller.interact()
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：门")
	controller.interact()
	_expect_flag("got_basic_dictionary")

	_move(Vector2i(1, 0), 4)
	_expect_prompt("第一个国书节点")
	controller.interact()
	_expect_location("node")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("契约封锁")
	controller.interact()
	_expect_flag("checked_contract_lock")

	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("写：名")
	controller.interact()
	_expect_flag("named_contract_officer")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：门")
	controller.interact()
	_expect_flag("found_contract_gap")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：止")
	controller.interact()
	_expect_flag("paused_contract")

	_move(Vector2i(1, 0), 2)
	_face(Vector2i(1, 0))
	_expect_prompt("攻击执契官")
	controller.interact()
	controller.interact()
	controller.interact()
	_expect_flag("defeated_contract_officer")

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(-1, 0), 4)
	_face(Vector2i(0, -1))
	_expect_prompt("命名节点")
	controller.interact()
	_expect_flag("named_first_node")

	_move(Vector2i(1, 0), 2)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("写：止")
	controller.interact()
	_expect_flag("stabilized_first_node")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：火")
	controller.interact()
	_expect_flag("repaired_first_node")

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(1, 0), 3)
	_move(Vector2i(0, -1), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("父母影像")
	controller.interact()
	_expect_flag("viewed_parent_record")

	var ok := failures.is_empty()
	print("rpg-moqi-academy-keyboard-smoke status=%s location=%s tile=%s time=%s" % [
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
