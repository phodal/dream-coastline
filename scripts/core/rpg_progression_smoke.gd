class_name RpgProgressionSmoke
extends RefCounted

var session
var failures: Array[String] = []


func _init(game_session) -> void:
	session = game_session


func run() -> bool:
	failures.clear()
	session.load_scene(2)

	_expect_stat("ink", 4)
	_expect_stat("focus", 3)
	_expect_stat("stability", 2)
	_expect_mastery("stop", 0)

	_act("inspect", "name")
	_act("inspect", "door")
	_act("inspect", "fire")
	_act("inspect", "stop")
	_expect_mastery("name", 1)
	_expect_mastery("door", 1)
	_expect_mastery("fire", 1)
	_expect_mastery("stop", 1)

	_act("go", "village")
	_act("inspect", "well")
	_expect_encounter_action("contract_patrol")
	_act("engage", "contract_patrol")
	_expect_flag("cleared_contract_patrol")
	_expect_stat("ink", 3)
	_expect_stat("focus", 2)
	_expect_stat("stability", 3)
	_expect_mastery("stop", 2)

	_act("engage", "contract_patrol")
	_expect_stat("ink", 3)
	_expect_log_contains("已经处理过")
	_expect_text_contains(session.progression_text(), "stop=2")

	var save_data: Dictionary = session.to_save_data()
	session.load_scene(0)
	session.load_save_data(save_data)
	_expect_flag("cleared_contract_patrol")
	_expect_stat("ink", 3)
	_expect_stat("focus", 2)
	_expect_stat("stability", 3)
	_expect_mastery("stop", 2)

	_run_branch_carryover_case()

	var ok := failures.is_empty()
	print("rpg-progression-smoke status=%s location=%s stats=%s mastery_stop=%s" % [
		"PASS" if ok else "FAIL",
		session.location_id,
		session.progression_text().replace("\n", " | "),
		session.glyph_mastery_value("stop"),
	])
	for failure in failures:
		print("failure=", failure)
	return ok


func _act(verb: String, arg: String) -> void:
	session.apply_action({"verb": verb, "arg": arg})


func _expect_flag(flag: String) -> void:
	if not session.has_flag(flag):
		failures.append("expected flag %s" % flag)


func _expect_no_flag(flag: String) -> void:
	if session.has_flag(flag):
		failures.append("did not expect flag %s" % flag)


func _expect_stat(key: String, expected: int) -> void:
	var actual := int(session.stat_value(key))
	if actual != expected:
		failures.append("expected stat %s=%s, got %s" % [key, expected, actual])


func _expect_metric(key: String, expected: int) -> void:
	var data: Dictionary = session.to_save_data()
	var scene_metrics: Dictionary = data.get("metrics", {})
	var actual := int(scene_metrics.get(key, 0))
	if actual != expected:
		failures.append("expected metric %s=%s, got %s metrics=%s" % [key, expected, actual, scene_metrics])


func _expect_mastery(glyph: String, expected: int) -> void:
	var actual := int(session.glyph_mastery_value(glyph))
	if actual != expected:
		failures.append("expected mastery %s=%s, got %s" % [glyph, expected, actual])


func _expect_log_contains(text: String) -> void:
	if not session.visible_log(3).contains(text):
		failures.append("expected recent log containing %s, got %s" % [text, session.visible_log(3)])


func _expect_text_contains(source: String, text: String) -> void:
	if not source.contains(text):
		failures.append("expected text containing %s, got %s" % [text, source])


func _expect_encounter_action(encounter_id: String) -> void:
	for group in session.action_groups():
		for action in group.get("actions", []):
			if str(action.get("verb", "")) == "engage" and str(action.get("arg", "")) == encounter_id:
				return
	failures.append("expected encounter action %s" % encounter_id)


func _run_branch_carryover_case() -> void:
	session.load_scene(3)
	_act("go", "library")
	_act("inspect", "records")
	_act("choose", "engineers")
	_expect_flag("chose_engineer_books")
	_act("choose", "public")
	_expect_no_flag("chose_public_books")
	_expect_log_contains("路线已经定下")

	var branch_save: Dictionary = session.to_save_data()
	session.load_scene(0)
	session.load_save_data(branch_save)

	session.load_scene(4)
	_expect_flag("chose_engineer_books")
	_expect_no_flag("chose_public_books")
	_expect_metric("engineering", 14)
	_expect_metric("energy", 14)
	_expect_metric("literacy", 9)
	_act("inspect", "members")
	_expect_log_contains("工匠占满前排")

	session.load_scene(6)
	_expect_flag("chose_engineer_books")
	_expect_metric("support", 2)
	_act("go", "council")
	_act("inspect", "supporters")
	_expect_log_contains("工坊代表")
