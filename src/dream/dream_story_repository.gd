class_name DreamStoryRepository
extends RefCounted

const SCENE_DIR := "res://data/story_scenes"
const SCENE_IDS: Array[String] = [
	"00-prologue-lights-out",
	"01-illiterate",
	"02-moqi-academy",
	"03-dead-kingdom",
	"04-continuation-institute",
	"05-century-continuation",
	"06-return-star-plan",
	"07-lights-on-again",
]

var scenes: Array[Dictionary] = []
var scenes_by_id: Dictionary = {}


func load_all() -> bool:
	scenes.clear()
	scenes_by_id.clear()

	var ok := true
	for scene_id in SCENE_IDS:
		var path := "%s/%s.json" % [SCENE_DIR, scene_id]
		var parsed := _load_json_dictionary(path)
		if parsed.is_empty():
			push_error("Could not load story scene: %s" % path)
			ok = false
			continue

		scenes.append(parsed)
		scenes_by_id[str(parsed.get("id", scene_id))] = parsed

	return ok


func scene_count() -> int:
	return scenes.size()


func scene_at(index: int) -> Dictionary:
	if index < 0 or index >= scenes.size():
		return {}
	return scenes[index]


func scene_id_at(index: int) -> String:
	var scene := scene_at(index)
	return str(scene.get("id", ""))


func location_for(scene: Dictionary, location_id: String) -> Dictionary:
	var locations: Dictionary = scene.get("locations", {})
	return locations.get(location_id, {})


func location_name(scene: Dictionary, location_id: String) -> String:
	var location := location_for(scene, location_id)
	return str(location.get("name", location_id))


func exits_for(scene: Dictionary, location_id: String) -> Dictionary:
	var location := location_for(scene, location_id)
	return location.get("exits", {})


func items_for(scene: Dictionary, location_id: String) -> Dictionary:
	var location := location_for(scene, location_id)
	return location.get("items", {})


func flags_for_item(item: Dictionary) -> Array[String]:
	return _string_array(item.get("flags", []))


func missing_required_flags(record: Dictionary, flags: Dictionary) -> Array[String]:
	var missing: Array[String] = []
	for flag in _string_array(record.get("requires", [])):
		if not flags.has(flag):
			missing.append(flag)
	return missing


func scene_missing_required_flags(scene: Dictionary, flags: Dictionary) -> Array[String]:
	var missing: Array[String] = []
	for flag in _string_array(scene.get("required_flags", [])):
		if not flags.has(flag):
			missing.append(flag)
	return missing


func apply_item_flags(item: Dictionary, flags: Dictionary) -> Array[String]:
	var gained: Array[String] = []
	for flag in flags_for_item(item):
		if not flags.has(flag):
			gained.append(flag)
		flags[flag] = true
	return gained


func is_scene_complete(scene: Dictionary, flags: Dictionary) -> bool:
	var ending_flag := str(scene.get("ending_flag", ""))
	if ending_flag == "" or not flags.has(ending_flag):
		return false
	return scene_missing_required_flags(scene, flags).is_empty()


func run_all_walkthroughs() -> Dictionary:
	if scenes.is_empty():
		load_all()

	var flags: Dictionary = {}
	var failures: Array[String] = []
	var completed: Array[String] = []

	for index in range(scene_count()):
		var result := run_walkthrough_at(index, flags)
		if not result.get("ok", false):
			failures.append_array(result.get("failures", []))
		else:
			completed.append(scene_id_at(index))

	return {
		"ok": failures.is_empty() and completed.size() == scene_count(),
		"completed": completed,
		"failures": failures,
		"flags": flags.keys(),
	}


func run_walkthrough_at(index: int, flags: Dictionary = {}) -> Dictionary:
	var scene := scene_at(index)
	if scene.is_empty():
		return {"ok": false, "failures": ["missing scene at index %d" % index]}

	var failures: Array[String] = []
	var location_id := str(scene.get("start", ""))
	var scene_id := str(scene.get("id", ""))
	for flag in _string_array(scene.get("initial_flags", [])):
		flags[flag] = true
	var combat_state: Dictionary = {}

	for command in scene.get("walkthrough", []):
		var parts := str(command).split(" ", false, 1)
		if parts.is_empty():
			failures.append("%s: invalid walkthrough command '%s'" % [scene_id, command])
			continue

		var verb := parts[0]
		var target := parts[1] if parts.size() > 1 else ""
		match verb:
			"inspect":
				var inspect_result := inspect_item(scene, location_id, target, flags)
				if not inspect_result.get("ok", false):
					failures.append("%s/%s inspect %s: %s" % [
						scene_id,
						location_id,
						target,
						inspect_result.get("error", "failed"),
					])
			"go":
				var go_result := go_to(scene, location_id, target)
				if go_result.get("ok", false):
					location_id = target
				else:
					failures.append("%s/%s go %s: %s" % [
						scene_id,
						location_id,
						target,
						go_result.get("error", "failed"),
					])
			"cast":
				var cast_result := cast_glyph(scene, location_id, target, flags, combat_state)
				if not cast_result.get("ok", false):
					failures.append("%s/%s cast %s: %s" % [scene_id, location_id, target, cast_result.get("error", "failed")])
			"build":
				var build_result := apply_location_record(scene, location_id, "build_actions", target, flags)
				if not build_result.get("ok", false):
					failures.append("%s/%s build %s: %s" % [scene_id, location_id, target, build_result.get("error", "failed")])
			"choose":
				var choice_result := apply_location_record(scene, location_id, "choices", target, flags)
				if not choice_result.get("ok", false):
					failures.append("%s/%s choose %s: %s" % [scene_id, location_id, target, choice_result.get("error", "failed")])
			"engage":
				var engage_result := apply_location_record(scene, location_id, "encounters", target, flags)
				if not engage_result.get("ok", false):
					failures.append("%s/%s engage %s: %s" % [scene_id, location_id, target, engage_result.get("error", "failed")])
			"combine":
				var combo_result := apply_location_record(scene, location_id, "combos", target, flags)
				if not combo_result.get("ok", false):
					failures.append("%s/%s combine %s: %s" % [scene_id, location_id, target, combo_result.get("error", "failed")])
			"write":
				var write_result := write_name(scene, location_id, flags, combat_state)
				if not write_result.get("ok", false):
					failures.append("%s/%s write: %s" % [scene_id, location_id, write_result.get("error", "failed")])
			"attack":
				var attack_result := attack(scene, location_id, flags, combat_state)
				if not attack_result.get("ok", false):
					failures.append("%s/%s attack: %s" % [scene_id, location_id, attack_result.get("error", "failed")])
			_:
				failures.append("%s: unknown walkthrough verb '%s'" % [scene_id, verb])

	if not is_scene_complete(scene, flags):
		var missing := scene_missing_required_flags(scene, flags)
		var ending_flag := str(scene.get("ending_flag", ""))
		if ending_flag != "" and not flags.has(ending_flag):
			missing.append(ending_flag)
		failures.append("%s: missing completion flags %s" % [scene_id, ", ".join(missing)])

	return {
		"ok": failures.is_empty(),
		"scene_id": scene_id,
		"failures": failures,
		"flags": flags.keys(),
	}


func inspect_item(scene: Dictionary, location_id: String, item_id: String, flags: Dictionary) -> Dictionary:
	var location := location_for(scene, location_id)
	if location.is_empty():
		return {"ok": false, "error": "missing location"}

	var items := items_for(scene, location_id)
	if not items.has(item_id):
		return {"ok": false, "error": "missing item"}

	var item: Dictionary = items[item_id]
	var missing := missing_required_flags(item, flags)
	if not missing.is_empty():
		return {"ok": false, "error": "missing required flags %s" % ", ".join(missing)}

	var gained := apply_item_flags(item, flags)
	return {
		"ok": true,
		"text": str(item.get("text", "")),
		"gained": gained,
	}


func go_to(scene: Dictionary, location_id: String, destination_id: String) -> Dictionary:
	var exits := exits_for(scene, location_id)
	if exits.has(destination_id):
		return {"ok": true, "label": str(exits[destination_id])}
	return {"ok": false, "error": "missing exit"}


func apply_location_record(scene: Dictionary, location_id: String, collection_key: String, record_id: String, flags: Dictionary) -> Dictionary:
	var location := location_for(scene, location_id)
	if location.is_empty():
		return {"ok": false, "error": "missing location"}

	var collection: Dictionary = location.get(collection_key, {})
	if not collection.has(record_id):
		return {"ok": false, "error": "missing %s record" % collection_key}

	var record: Dictionary = collection[record_id]
	return apply_progression_record(record, flags)


func cast_glyph(scene: Dictionary, location_id: String, glyph: String, flags: Dictionary, combat_state: Dictionary) -> Dictionary:
	var location := location_for(scene, location_id)
	var combat: Dictionary = location.get("combat", {})
	var combat_active := _combat_active(scene, location_id, flags, combat_state)
	if (glyph == "name" or glyph == "名") and combat_active:
		return write_name(scene, location_id, flags, combat_state)

	var spells: Dictionary = combat.get("spells", {})
	if combat_active and spells.has(glyph):
		return apply_progression_record(spells[glyph], flags)

	var glyph_actions: Dictionary = location.get("glyph_actions", {})
	if glyph_actions.has(glyph):
		return apply_progression_record(glyph_actions[glyph], flags)

	if spells.has(glyph):
		return apply_progression_record(spells[glyph], flags)

	return {"ok": false, "error": "missing glyph action"}


func write_name(scene: Dictionary, location_id: String, flags: Dictionary, combat_state: Dictionary) -> Dictionary:
	var combat := _combat_for(scene, location_id)
	if combat.is_empty():
		return {"ok": false, "error": "no combat"}

	var learn_flag := str(combat.get("learn_flag", ""))
	if learn_flag != "" and not flags.has(learn_flag):
		return {"ok": false, "error": "missing learn flag %s" % learn_flag}

	var state := _combat_state_for(scene, location_id, combat, combat_state)
	state["name_attempts"] = int(state.get("name_attempts", 0)) + 1
	if int(state["name_attempts"]) < int(combat.get("success_attempt", 1)):
		for flag in _string_array(combat.get("failure_flags", [])):
			flags[flag] = true
		return {"ok": true}

	var lock_flag := str(combat.get("lock_flag", ""))
	if lock_flag != "":
		flags[lock_flag] = true
	for flag in _string_array(combat.get("success_flags", [])):
		flags[flag] = true
	state["attacks_since_name"] = 0
	return {"ok": true}


func attack(scene: Dictionary, location_id: String, flags: Dictionary, combat_state: Dictionary) -> Dictionary:
	var combat := _combat_for(scene, location_id)
	if combat.is_empty():
		return {"ok": false, "error": "no combat"}

	var lock_flag := str(combat.get("lock_flag", ""))
	if lock_flag != "" and not flags.has(lock_flag):
		return {"ok": false, "error": "target is not named"}

	var missing_attack_flags: Array[String] = []
	for flag in _string_array(combat.get("required_attack_flags", [])):
		if not flags.has(flag):
			missing_attack_flags.append(flag)
	if not missing_attack_flags.is_empty():
		return {"ok": false, "error": "missing attack flags %s" % ", ".join(missing_attack_flags)}

	var state := _combat_state_for(scene, location_id, combat, combat_state)
	state["enemy_hp"] = int(state.get("enemy_hp", combat.get("enemy_hp", 1))) - 1
	state["attacks_since_name"] = int(state.get("attacks_since_name", 0)) + 1
	if int(state["enemy_hp"]) <= 0:
		var win_flag := str(combat.get("win_flag", ""))
		if win_flag != "":
			flags[win_flag] = true
		for flag in _string_array(combat.get("reward_flags", [])):
			flags[flag] = true
		return {"ok": true}

	var lose_name_every: int = max(1, int(combat.get("lose_name_every", 2)))
	if int(state["attacks_since_name"]) >= lose_name_every and lock_flag != "":
		flags.erase(lock_flag)
		state["attacks_since_name"] = 0

	return {"ok": true}


func apply_progression_record(record: Dictionary, flags: Dictionary) -> Dictionary:
	var missing := missing_required_flags(record, flags)
	if not missing.is_empty():
		return {"ok": false, "error": "missing required flags %s" % ", ".join(missing)}

	apply_item_flags(record, flags)
	var clear_flag := str(record.get("clear_flag", ""))
	if clear_flag != "":
		flags[clear_flag] = true
	return {"ok": true}


func _combat_for(scene: Dictionary, location_id: String) -> Dictionary:
	var location := location_for(scene, location_id)
	return location.get("combat", {})


func _combat_state_for(scene: Dictionary, location_id: String, combat: Dictionary, combat_state: Dictionary) -> Dictionary:
	var key := "%s/%s" % [scene.get("id", ""), location_id]
	if not combat_state.has(key):
		combat_state[key] = {
			"enemy_hp": int(combat.get("enemy_hp", 1)),
			"name_attempts": 0,
			"attacks_since_name": 0,
		}
	return combat_state[key]


func _combat_active(scene: Dictionary, location_id: String, flags: Dictionary, combat_state: Dictionary) -> bool:
	var combat := _combat_for(scene, location_id)
	if combat.is_empty():
		return false
	var win_flag := str(combat.get("win_flag", ""))
	if win_flag != "" and flags.has(win_flag):
		return false
	var state := _combat_state_for(scene, location_id, combat, combat_state)
	return int(state.get("enemy_hp", combat.get("enemy_hp", 1))) > 0


func _load_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	return parsed


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result
