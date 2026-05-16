class_name RpgLightsOnAgainSmoke
extends RefCounted

var session
var controller
var failures: Array[String] = []


func _init(game_session, player_controller) -> void:
	session = game_session
	controller = player_controller


func run() -> bool:
	failures.clear()
	session.load_scene(7)
	controller.reset_for_location()

	_expect_location("home")
	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("半静默的家")
	controller.interact()
	_expect_flag("confirmed_home_silenced")
	_move(Vector2i(1, 0), 4)
	_face(Vector2i(0, -1))
	_expect_prompt("手机联系人")
	controller.interact()

	_move(Vector2i(1, 0), 5)
	_expect_prompt("学校")
	controller.interact()
	_expect_location("school")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("无尽走廊")
	controller.interact()
	_expect_flag("confirmed_school_erasure")
	_move(Vector2i(1, 0), 4)
	_face(Vector2i(0, -1))
	_expect_prompt("同学名牌")
	controller.interact()

	_move(Vector2i(1, 0), 5)
	_expect_prompt("城市街道")
	controller.interact()
	_expect_location("street")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("城市电网")
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("点亮城市电网")
	controller.interact()
	_expect_flag("lit_city_grid")
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("节点基座")
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("建设临时国书节点")
	controller.interact()
	_expect_flag("temporary_node_built")

	_move(Vector2i(1, 0), 3)
	_expect_prompt("便利店")
	controller.interact()
	_expect_location("store")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("无脸店员")
	controller.interact()
	_move(Vector2i(0, 1), 2)
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("呼名")
	controller.interact()
	_expect_flag("rescued_clerk_name")

	_move(Vector2i(1, 0), 7)
	_move(Vector2i(0, -1), 2)
	_expect_prompt("城市街道")
	controller.interact()
	_expect_location("street")
	_move(Vector2i(1, 0), 6)
	_expect_prompt("父母实验室")
	controller.interact()
	_expect_location("lab")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("最终字组合")
	controller.interact()
	_expect_flag("learned_continue")
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("现代信标")
	controller.interact()
	_move(Vector2i(1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("稳定现代节点")
	controller.interact()
	_expect_flag("modern_node_stable")
	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, 1), 1)
	_expect_prompt("父母最终记录")
	controller.interact()
	_expect_flag("read_parent_final_record")
	_move(Vector2i(1, 0), 2)
	_expect_prompt("失败的归桥测试")
	controller.interact()
	_expect_flag("survived_failed_bridge_test")
	_move(Vector2i(1, 0), 2)
	_move(Vector2i(0, -1), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("稳定归桥")
	controller.interact()
	_expect_flag("bridge_stable")

	_move(Vector2i(1, 0), 3)
	_expect_prompt("轨道静默层")
	controller.interact()
	_expect_location("orbit")

	_move(Vector2i(-1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("静默协议")
	controller.interact()
	_expect_flag("identified_final_protocol")
	_move(Vector2i(1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("恢复最终 UI")
	controller.interact()
	_expect_flag("restored_final_ui")

	_move(Vector2i(1, 0), 2)
	_move(Vector2i(0, 1), 2)
	_move(Vector2i(-1, 0), 3)
	_face(Vector2i(0, -1))
	_expect_prompt("写：名")
	controller.interact()
	_expect_flag("named_final_protocol")
	_move(Vector2i(1, 0), 1)
	_face(Vector2i(0, -1))
	_expect_prompt("写：止")
	controller.interact()
	_expect_flag("paused_final_deletion")

	_move(Vector2i(1, 0), 3)
	_move(Vector2i(0, -1), 2)
	_face(Vector2i(1, 0))
	_expect_prompt("攻击静默协议")
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
	_expect_flag("defeated_final_protocol")

	_move(Vector2i(0, 1), 2)
	_move(Vector2i(-1, 0), 2)
	_face(Vector2i(0, -1))
	_expect_prompt("写下 Continue")
	controller.interact()
	_expect_flag("rejected_silence_protocol")

	var ok := failures.is_empty()
	print("rpg-lights-on-again-keyboard-smoke status=%s location=%s tile=%s time=%s" % [
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
