class_name GameSession
extends RefCounted

const EQUIPMENT_CATALOG_PATH := "res://data/equipment_catalog.json"

var database
var scene_index := 0
var scene_id := ""
var scene := {}
var location_id := ""
var flags := {}
var metrics := {}
var carried_flags := {}
var carried_branch_excluded_flags := {}
var carried_metrics_by_scene := {}
var equipment_catalog := {}
var equipment_inventory := {}
var equipped_items := {}
var player_stats := {}
var glyph_mastery := {}
var elapsed_seconds := 0
var enemy_hp := 0
var player_hp := 5
var name_attempts := 0
var attacks_since_name := 0
var event_log: Array[String] = []


func _init(scene_database) -> void:
	database = scene_database


func load_scene(index: int) -> void:
	var next_index := clamp(index, 0, database.count() - 1)
	if next_index == 0:
		_clear_story_carryover()
		_clear_equipment_state()
	scene_index = next_index
	scene_id = database.scene_id_at(scene_index)
	scene = database.scene_at(scene_index)
	location_id = str(scene.get("start", ""))
	flags.clear()
	for flag in scene.get("initial_flags", []):
		flags[str(flag)] = true
	metrics = scene.get("metrics", {}).duplicate(true)
	_apply_carried_story_state()
	player_stats = scene.get("player_stats", {}).duplicate(true)
	glyph_mastery = scene.get("glyph_mastery", {}).duplicate(true)
	_ensure_equipment_catalog()
	_refresh_equipment_state()
	elapsed_seconds = 0
	enemy_hp = 0
	player_hp = 5
	name_attempts = 0
	attacks_since_name = 0
	event_log.clear()
	_enter_combat_if_needed()
	_log("开始：%s" % scene.get("title", ""))


func current_location() -> Dictionary:
	return scene.get("locations", {}).get(location_id, {})


func scene_count() -> int:
	return database.count()


func action_groups() -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var location := current_location()

	var move_actions: Array[Dictionary] = []
	for exit_id in location.get("exits", {}).keys():
		move_actions.append({
			"label": "去：%s" % location["exits"][exit_id],
			"verb": "go",
			"arg": str(exit_id),
		})
	_append_group(groups, "移动", move_actions)

	var inspect_actions: Array[Dictionary] = []
	for item_id in location.get("items", {}).keys():
		var item = location["items"][item_id]
		inspect_actions.append({
			"label": "查：%s" % item.get("name", item_id),
			"verb": "inspect",
			"arg": str(item_id),
		})
	_append_group(groups, "调查", inspect_actions)

	var encounter_actions: Array[Dictionary] = []
	for encounter_id in location.get("encounters", {}).keys():
		var encounter: Dictionary = location["encounters"][encounter_id]
		if _encounter_is_hidden(encounter):
			continue
		encounter_actions.append({
			"label": "迎战：%s" % encounter.get("name", encounter_id),
			"verb": "engage",
			"arg": str(encounter_id),
		})
	_append_group(groups, "遭遇", encounter_actions)

	var cast_actions: Array[Dictionary] = []
	for glyph in _available_casts():
		cast_actions.append({
			"label": "写/施：%s" % glyph,
			"verb": "cast",
			"arg": glyph,
		})
	_append_group(groups, "字根", cast_actions)

	var build_actions: Array[Dictionary] = []
	for project in location.get("build_actions", {}).keys():
		build_actions.append({
			"label": "建：%s" % project,
			"verb": "build",
			"arg": str(project),
		})
	_append_group(groups, "建设", build_actions)

	var choice_actions: Array[Dictionary] = []
	for route in location.get("choices", {}).keys():
		choice_actions.append({
			"label": "选：%s" % route,
			"verb": "choose",
			"arg": str(route),
		})
	_append_group(groups, "选择", choice_actions)

	if location.has("combat"):
		_append_group(groups, "战斗", [
			{"label": "写：名", "verb": "write", "arg": ""},
			{"label": "攻击", "verb": "attack", "arg": ""},
			{"label": "防御", "verb": "guard", "arg": ""},
		])

	var combo_actions: Array[Dictionary] = []
	for combo in location.get("combos", {}).keys():
		combo_actions.append({
			"label": "组合：%s" % combo,
			"verb": "combine",
			"arg": str(combo),
		})
	_append_group(groups, "组合", combo_actions)

	return groups


func apply_action(action: Dictionary) -> void:
	var verb := str(action.get("verb", ""))
	var arg := str(action.get("arg", ""))
	match verb:
		"go":
			_move(arg)
		"inspect":
			_inspect_item(arg)
		"cast":
			_cast_glyph(arg)
		"write":
			_write_name()
		"attack":
			_attack()
		"guard":
			_guard()
		"choose":
			_choose_route(arg)
		"build":
			_build_project(arg)
		"combine":
			_combine_words(arg)
		"engage":
			_engage_encounter(arg)
		_:
			_log("未知行动：%s" % verb)


func status_text() -> String:
	var required: Array = scene.get("required_flags", [])
	var found := 0
	for flag in required:
		if has_flag(str(flag)):
			found += 1
	var text := "目标覆盖 %s/%s" % [found, required.size()]
	if scene.has("min_minutes"):
		text += "  最低时长 %.1f 分钟" % float(scene["min_minutes"])
	var progression := progression_text()
	if progression != "":
		text += "\n%s" % progression
	var combat: Dictionary = current_location().get("combat", {})
	if not combat.is_empty():
		var lock_flag := str(combat.get("lock_flag", ""))
		var enemy_name := str(combat.get("revealed_name", combat.get("hidden_name", "敌人"))) if has_flag(lock_flag) else str(combat.get("hidden_name", "???"))
		text += "\n敌人 %s HP %s/%s  我方 HP %s" % [enemy_name, enemy_hp, combat.get("enemy_hp", 0), player_hp]
	if has_flag(str(scene.get("ending_flag", ""))):
		text += "\n章节完成，可以切到下一幕。"
	return text


func metrics_text() -> String:
	if metrics.is_empty():
		return ""
	var parts: Array[String] = []
	for key in metrics.keys():
		parts.append("%s=%s" % [key, metrics[key]])
	return "指标  " + "  ".join(parts)


func progression_text() -> String:
	var stat_parts: Array[String] = []
	for key in ["ink", "focus", "stability"]:
		if player_stats.has(key):
			var max_key := "max_%s" % key
			var max_value := stat_value(max_key)
			if max_value > 0:
				stat_parts.append("%s=%s/%s" % [key, stat_value(key), max_value])
			else:
				stat_parts.append("%s=%s" % [key, stat_value(key)])

	var mastery_parts: Array[String] = []
	var mastery_keys := glyph_mastery.keys()
	mastery_keys.sort()
	for glyph in mastery_keys:
		mastery_parts.append("%s=%s" % [glyph, glyph_mastery_value(str(glyph))])

	var lines: Array[String] = []
	if not stat_parts.is_empty():
		lines.append("资源  " + "  ".join(stat_parts))
	if not mastery_parts.is_empty():
		lines.append("字根熟练  " + "  ".join(mastery_parts))
	var carriers := equipment_text()
	if carriers != "":
		lines.append(carriers)
	return "\n".join(lines)


func equipment_text() -> String:
	var names := _equipment_names()
	if names.is_empty():
		return ""
	return "载体  " + "  ".join(names)


func has_equipment(item_id: String) -> bool:
	return item_id != "" and equipment_inventory.has(item_id)


func _base_stat_value(key: String) -> int:
	return int(player_stats.get(key, 0))


func _base_glyph_mastery_value(glyph: String) -> int:
	return int(glyph_mastery.get(glyph, 0))


func stat_value(key: String) -> int:
	return _base_stat_value(key) + _equipment_number_effect("stat_modifiers", key)


func glyph_mastery_value(glyph: String) -> int:
	return _base_glyph_mastery_value(glyph) + _equipment_number_effect("glyph_mastery_modifiers", glyph)


func _equipment_names() -> Array[String]:
	var names: Array[String] = []
	var items: Dictionary = equipment_catalog.get("items", {})
	var item_ids := equipped_items.keys()
	item_ids.sort()
	for item_id in item_ids:
		var item: Dictionary = items.get(str(item_id), {})
		var name := str(item.get("name", item_id))
		if not name.is_empty():
			names.append(name)
	return names


func format_time() -> String:
	return "%02d:%02d" % [elapsed_seconds / 60, elapsed_seconds % 60]


func visible_log(max_lines: int) -> String:
	return "\n".join(event_log.slice(max(0, event_log.size() - max_lines), event_log.size()))


func to_save_data() -> Dictionary:
	return {
		"scene_index": scene_index,
		"location_id": location_id,
		"flags": flags.keys(),
		"metrics": metrics,
		"carried_flags": carried_flags.keys(),
		"carried_branch_excluded_flags": carried_branch_excluded_flags.keys(),
		"carried_metrics_by_scene": carried_metrics_by_scene,
		"player_stats": player_stats,
		"glyph_mastery": glyph_mastery,
		"equipment_inventory": equipment_inventory.keys(),
		"equipped_items": equipped_items.keys(),
		"elapsed_seconds": elapsed_seconds,
		"enemy_hp": enemy_hp,
		"player_hp": player_hp,
		"name_attempts": name_attempts,
		"attacks_since_name": attacks_since_name,
		"event_log": event_log,
	}


func load_save_data(data: Dictionary) -> void:
	scene_index = clamp(int(data.get("scene_index", 0)), 0, database.count() - 1)
	scene_id = database.scene_id_at(scene_index)
	scene = database.scene_at(scene_index)
	location_id = str(data.get("location_id", scene.get("start", "")))
	flags.clear()
	for flag in data.get("flags", []):
		flags[str(flag)] = true
	metrics = data.get("metrics", {}).duplicate(true)
	carried_flags.clear()
	for flag in data.get("carried_flags", []):
		carried_flags[str(flag)] = true
	carried_branch_excluded_flags.clear()
	for flag in data.get("carried_branch_excluded_flags", []):
		carried_branch_excluded_flags[str(flag)] = true
	carried_metrics_by_scene = data.get("carried_metrics_by_scene", {}).duplicate(true)
	player_stats = data.get("player_stats", scene.get("player_stats", {})).duplicate(true)
	glyph_mastery = data.get("glyph_mastery", scene.get("glyph_mastery", {})).duplicate(true)
	equipment_inventory.clear()
	for item_id in data.get("equipment_inventory", []):
		equipment_inventory[str(item_id)] = true
	equipped_items.clear()
	for item_id in data.get("equipped_items", []):
		equipped_items[str(item_id)] = true
	_ensure_equipment_catalog()
	_refresh_equipment_state()
	elapsed_seconds = int(data.get("elapsed_seconds", 0))
	enemy_hp = int(data.get("enemy_hp", 0))
	player_hp = int(data.get("player_hp", 5))
	name_attempts = int(data.get("name_attempts", 0))
	attacks_since_name = int(data.get("attacks_since_name", 0))
	event_log.clear()
	for line in data.get("event_log", []):
		event_log.append(str(line))


func run_smoke_verification() -> bool:
	var all_ok := true
	for index in range(database.count()):
		load_scene(index)
		var ok := _verify_current_scene()
		all_ok = all_ok and ok
	return all_ok


func _verify_current_scene() -> bool:
	for command in scene.get("walkthrough", []):
		_apply_text_command(str(command))
		if has_flag(str(scene.get("ending_flag", ""))):
			break

	var missing: Array[String] = []
	for flag in scene.get("required_flags", []):
		if not has_flag(str(flag)):
			missing.append(str(flag))
	var duration_ok := float(elapsed_seconds) / 60.0 >= float(scene.get("min_minutes", 0.0))
	var complete := has_flag(str(scene.get("ending_flag", ""))) and missing.is_empty()
	var ok := duration_ok and complete
	print("%s duration=%.1fmin required=%s/%s status=%s" % [
		scene_id,
		float(elapsed_seconds) / 60.0,
		scene.get("required_flags", []).size() - missing.size(),
		scene.get("required_flags", []).size(),
		"PASS" if ok else "FAIL",
	])
	if not ok:
		print("missing=", missing)
	return ok


func _append_group(groups: Array[Dictionary], title: String, actions: Array[Dictionary]) -> void:
	if actions.is_empty():
		return
	groups.append({"title": title, "actions": actions})


func _move(exit_id: String) -> void:
	var location := current_location()
	if not location.get("exits", {}).has(exit_id):
		_log("这里不能去那里。")
		return
	location_id = exit_id
	elapsed_seconds += 20
	_enter_combat_if_needed()
	_log("前往：%s" % current_location().get("name", exit_id))


func _inspect_item(item_id: String) -> void:
	var item = current_location().get("items", {}).get(item_id)
	if item == null:
		_log("这里没有这个调查对象。")
		return
	if not _requirements_met(item.get("requires", [])):
		_log("前置条件不足。")
		return
	if not _action_costs_met(item):
		_log("资源不足。")
		return
	_apply_action_costs(item)
	elapsed_seconds += int(item.get("time_seconds", 30))
	_add_flags(item.get("flags", []))
	_apply_progression_rewards(item)
	_log(_action_text(item))


func _available_casts() -> Array[String]:
	var casts: Array[String] = []
	var location := current_location()
	for glyph in location.get("glyph_actions", {}).keys():
		casts.append(str(glyph))
	for glyph in location.get("combat", {}).get("spells", {}).keys():
		if not casts.has(str(glyph)):
			casts.append(str(glyph))
	return casts


func _cast_glyph(glyph: String) -> void:
	var combat_active := _combat_active()
	if glyph in ["name", "名"] and combat_active:
		_write_name()
		return

	var location := current_location()
	var action = null
	if combat_active:
		action = location.get("combat", {}).get("spells", {}).get(glyph)
	if action == null:
		action = location.get("glyph_actions", {}).get(glyph)
	if action == null:
		action = location.get("combat", {}).get("spells", {}).get(glyph)
	if action == null:
		_log("这个字根现在派不上用场。")
		return
	if not _requirements_met(action.get("requires", [])):
		_log("术式前置条件不足。")
		return
	if not _mastery_requirements_met(action.get("requires_mastery", {})):
		_log("字根熟练度不足。")
		return
	if not _action_costs_met(action):
		_log("资源不足，术式写不稳。")
		return
	_apply_action_costs(action)
	elapsed_seconds += int(action.get("time_seconds", 45))
	_add_flags(action.get("flags", []))
	_apply_metrics(action.get("metrics", {}))
	_apply_progression_rewards(action)
	_log(_action_text(action))


func _build_project(project: String) -> void:
	var action = current_location().get("build_actions", {}).get(project)
	if action == null:
		_log("这里不能建设这个项目。")
		return
	if not _requirements_met(action.get("requires", [])):
		_log("建设条件不足。")
		return
	if not _mastery_requirements_met(action.get("requires_mastery", {})):
		_log("字根熟练度不足。")
		return
	if not _action_costs_met(action):
		_log("资源不足，建设无法开工。")
		return
	_apply_action_costs(action)
	elapsed_seconds += int(action.get("time_seconds", 60))
	_add_flags(action.get("flags", []))
	_apply_metrics(action.get("metrics", {}))
	_apply_progression_rewards(action)
	_log(_action_text(action))


func _choose_route(route: String) -> void:
	var choice = current_location().get("choices", {}).get(route)
	if choice == null:
		_log("这里没有这个选择。")
		return
	if not _requirements_met(choice.get("requires", [])):
		_log("选择条件不足。")
		return
	if not _mastery_requirements_met(choice.get("requires_mastery", {})):
		_log("字根熟练度不足。")
		return
	if not _action_costs_met(choice):
		_log("资源不足。")
		return
	if _branch_choice_already_resolved(choice):
		_log("这条路线已经定下，不能再改写。")
		return
	_apply_action_costs(choice)
	elapsed_seconds += int(choice.get("time_seconds", 45))
	var choice_flags: Array = choice.get("flags", [])
	_add_flags(choice_flags)
	_record_branch_consequence(choice_flags)
	_apply_progression_rewards(choice)
	_log(_action_text(choice))


func _combine_words(combo: String) -> void:
	var action = current_location().get("combos", {}).get(combo)
	if action == null:
		_log("这里不能组合这组字。")
		return
	if not _requirements_met(action.get("requires", [])):
		_log("字义还不稳定，组合会碎掉。")
		return
	if not _mastery_requirements_met(action.get("requires_mastery", {})):
		_log("字根熟练度不足。")
		return
	if not _action_costs_met(action):
		_log("资源不足，组合会碎掉。")
		return
	_apply_action_costs(action)
	elapsed_seconds += int(action.get("time_seconds", 90))
	_add_flags(action.get("flags", []))
	_apply_progression_rewards(action)
	_log(_action_text(action))


func _engage_encounter(encounter_id: String) -> void:
	var encounter = current_location().get("encounters", {}).get(encounter_id)
	if encounter == null:
		_log("这里没有这个遭遇。")
		return
	if _encounter_is_hidden(encounter):
		_log("这个威胁已经处理过。")
		return
	if not _requirements_met(encounter.get("requires", [])):
		_log("遭遇条件不足。")
		return
	if not _mastery_requirements_met(encounter.get("requires_mastery", {})):
		_log("字根熟练度不足，不能稳定处理这个遭遇。")
		return
	if not _action_costs_met(encounter):
		_log("资源不足，不能迎战。")
		return

	_apply_action_costs(encounter)
	elapsed_seconds += int(encounter.get("time_seconds", 45))
	_add_flags(encounter.get("flags", []))
	_apply_metrics(encounter.get("metrics", {}))
	_apply_progression_rewards(encounter)
	_log(_action_text(encounter))


func _write_name() -> void:
	var combat: Dictionary = current_location().get("combat", {})
	if combat.is_empty():
		_log("现在不需要写“名”。")
		return
	if combat.get("learn_flag", "") != "" and not has_flag(str(combat["learn_flag"])):
		_log("你还没有理解“名”的笔画。")
		return

	elapsed_seconds += int(combat.get("write_seconds", 45))
	name_attempts += 1
	if name_attempts < int(combat.get("success_attempt", 1)):
		player_hp -= 1
		_add_flags(combat.get("failure_flags", []))
		_log("符文碎开。敌人继续逼近，UI 上的名字短暂变成□□。")
	else:
		_add_flags([combat["lock_flag"]])
		_add_flags(combat.get("success_flags", []))
		attacks_since_name = 0
		_log("“名”字亮起。目标显形：%s。" % combat.get("revealed_name", "敌人"))


func _attack() -> void:
	var combat: Dictionary = current_location().get("combat", {})
	if combat.is_empty():
		_log("这里没有敌人。")
		return
	if not has_flag(str(combat.get("lock_flag", ""))):
		elapsed_seconds += 25
		player_hp -= 1
		_log("无法锁定目标，攻击穿过空白。")
		return
	if not _requirements_met(combat.get("required_attack_flags", [])):
		elapsed_seconds += 25
		_log("目标已显形，但战场规则还没破解。")
		return

	elapsed_seconds += int(combat.get("attack_seconds", 35))
	enemy_hp -= 1
	attacks_since_name += 1
	if enemy_hp <= 0:
		_add_flags([combat["win_flag"]])
		_add_flags(combat.get("reward_flags", []))
		_apply_progression_rewards(combat)
		_log("%s 被击退。" % combat.get("revealed_name", "敌人"))
	elif attacks_since_name >= int(combat.get("lose_name_every", 2)):
		flags.erase(str(combat.get("lock_flag", "")))
		attacks_since_name = 0
		_log("%s 开始失名，必须重新写“名”。" % combat.get("revealed_name", "敌人"))
	else:
		_log("攻击命中：%s。" % combat.get("revealed_name", "敌人"))


func _guard() -> void:
	elapsed_seconds += 30
	_log("你稳住阵线，争取到半步距离。")


func _enter_combat_if_needed() -> void:
	var combat: Dictionary = current_location().get("combat", {})
	if combat.is_empty() or enemy_hp > 0 or has_flag(str(combat.get("win_flag", ""))):
		return
	enemy_hp = int(combat.get("enemy_hp", 1))
	player_hp = int(combat.get("player_hp", 5))
	name_attempts = 0
	attacks_since_name = 0


func _combat_active() -> bool:
	var combat: Dictionary = current_location().get("combat", {})
	return not combat.is_empty() and enemy_hp > 0 and not has_flag(str(combat.get("win_flag", "")))


func _encounter_is_hidden(encounter: Dictionary) -> bool:
	var repeatable := bool(encounter.get("repeatable", false))
	var clear_flag := str(encounter.get("clear_flag", ""))
	return not repeatable and has_flag(clear_flag)


func _requirements_met(required: Array) -> bool:
	for flag in required:
		if not has_flag(str(flag)):
			return false
	return true


func _mastery_requirements_met(required: Dictionary) -> bool:
	for glyph in required.keys():
		if glyph_mastery_value(str(glyph)) < int(required[glyph]):
			return false
	return true


func _action_costs_met(action: Dictionary) -> bool:
	for key in action.get("stat_costs", {}).keys():
		var cost := int(action["stat_costs"][key])
		if cost > 0 and stat_value(str(key)) < cost:
			return false
	return true


func _apply_action_costs(action: Dictionary) -> void:
	var deltas := {}
	for key in action.get("stat_costs", {}).keys():
		var cost := int(action["stat_costs"][key])
		if cost > 0:
			deltas[str(key)] = -cost
	_apply_stat_delta(deltas)


func _apply_progression_rewards(action: Dictionary) -> void:
	_apply_stat_delta(action.get("stats", {}))
	_apply_glyph_mastery_delta(action.get("glyph_mastery", {}))


func _add_flags(new_flags: Array) -> void:
	var changed := false
	for flag in new_flags:
		var flag_key := str(flag)
		if flag_key.is_empty():
			continue
		if not flags.has(flag_key):
			changed = true
		flags[flag_key] = true
	if changed:
		_refresh_equipment_state()


func _clear_equipment_state() -> void:
	equipment_inventory.clear()
	equipped_items.clear()


func _ensure_equipment_catalog() -> void:
	if not equipment_catalog.is_empty():
		return
	if not FileAccess.file_exists(EQUIPMENT_CATALOG_PATH):
		push_warning("Equipment catalog does not exist: %s" % EQUIPMENT_CATALOG_PATH)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(EQUIPMENT_CATALOG_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Could not parse equipment catalog: %s" % EQUIPMENT_CATALOG_PATH)
		return
	equipment_catalog = parsed


func _refresh_equipment_state() -> void:
	_ensure_equipment_catalog()
	var items: Dictionary = equipment_catalog.get("items", {})
	if items.is_empty():
		equipped_items.clear()
		return

	var item_ids := items.keys()
	item_ids.sort()
	for item_id in item_ids:
		var item_key := str(item_id)
		if equipment_inventory.has(item_key):
			continue
		var item: Dictionary = items.get(item_key, {})
		if _equipment_source_flags_met(item):
			equipment_inventory[item_key] = true

	var slots: Dictionary = equipment_catalog.get("slots", {})
	var slot_counts := {}
	equipped_items.clear()
	for item_id in item_ids:
		var item_key := str(item_id)
		if not equipment_inventory.has(item_key):
			continue
		var item: Dictionary = items.get(item_key, {})
		var slot_id := str(item.get("slot", ""))
		if slot_id.is_empty():
			continue
		var slot: Dictionary = slots.get(slot_id, {})
		var max_equipped := max(1, int(slot.get("max_equipped", 1)))
		var current_count := int(slot_counts.get(slot_id, 0))
		if current_count >= max_equipped:
			continue
		equipped_items[item_key] = true
		slot_counts[slot_id] = current_count + 1


func _equipment_source_flags_met(item: Dictionary) -> bool:
	var acquisition: Dictionary = item.get("acquisition", {})
	var source_flags: Array = acquisition.get("source_flags", [])
	if source_flags.is_empty():
		return false
	for flag in source_flags:
		if not has_flag(str(flag)):
			return false
	return true


func _equipment_number_effect(bucket: String, key: String) -> int:
	var total := 0
	var items: Dictionary = equipment_catalog.get("items", {})
	for item_id in equipped_items.keys():
		var item: Dictionary = items.get(str(item_id), {})
		var effects: Dictionary = item.get("effects", {})
		var values: Dictionary = effects.get(bucket, {})
		total += int(values.get(key, 0))
	return total


func _apply_metrics(delta: Dictionary) -> void:
	for key in delta.keys():
		var metric_key := str(key)
		metrics[metric_key] = int(metrics.get(metric_key, 0)) + int(delta[key])


func _action_text(action: Dictionary) -> String:
	var route_texts: Dictionary = action.get("route_texts", {})
	for route_flag in route_texts.keys():
		if has_flag(str(route_flag)):
			return str(route_texts[route_flag])
	return str(action.get("text", ""))


func _clear_story_carryover() -> void:
	carried_flags.clear()
	carried_branch_excluded_flags.clear()
	carried_metrics_by_scene.clear()


func _apply_carried_story_state() -> void:
	for flag in carried_branch_excluded_flags.keys():
		flags.erase(str(flag))
	for flag in carried_flags.keys():
		flags[str(flag)] = true
	var metric_delta: Dictionary = carried_metrics_by_scene.get(scene_id, {})
	if not metric_delta.is_empty():
		_apply_metrics(metric_delta)


func _branch_choice_already_resolved(choice: Dictionary) -> bool:
	var resolved_flag := _branch_resolved_flag_for_choice(choice)
	return not resolved_flag.is_empty() and has_flag(resolved_flag)


func _branch_resolved_flag_for_choice(choice: Dictionary) -> String:
	var contract: Dictionary = scene.get("branch_consequences", {})
	var resolved_flag := str(contract.get("resolved_flag", ""))
	if resolved_flag.is_empty():
		return ""
	if _array_has_text(choice.get("flags", []), resolved_flag):
		return resolved_flag
	return ""


func _record_branch_consequence(choice_flags: Array) -> void:
	var contract: Dictionary = scene.get("branch_consequences", {})
	var resolved_flag := str(contract.get("resolved_flag", ""))
	if resolved_flag.is_empty() or not _array_has_text(choice_flags, resolved_flag):
		return
	carried_flags[resolved_flag] = true
	var routes: Dictionary = contract.get("routes", {})
	for route in routes.keys():
		var route_contract: Dictionary = routes[route]
		var route_flag := str(route_contract.get("flag", ""))
		if route_flag.is_empty():
			continue
		carried_branch_excluded_flags[route_flag] = true
		if not _array_has_text(choice_flags, route_flag):
			continue
		carried_flags[route_flag] = true
		var next_scene_metrics: Dictionary = route_contract.get("next_scene_metrics", {})
		for target_scene_id in next_scene_metrics.keys():
			_add_carried_metrics(str(target_scene_id), next_scene_metrics[target_scene_id])


func _add_carried_metrics(target_scene_id: String, delta: Dictionary) -> void:
	var merged: Dictionary = carried_metrics_by_scene.get(target_scene_id, {}).duplicate(true)
	for key in delta.keys():
		var metric_key := str(key)
		merged[metric_key] = int(merged.get(metric_key, 0)) + int(delta[key])
	carried_metrics_by_scene[target_scene_id] = merged


func _array_has_text(values: Array, text: String) -> bool:
	for value in values:
		if str(value) == text:
			return true
	return false


func _apply_stat_delta(delta: Dictionary) -> void:
	for key in delta.keys():
		var stat_key := str(key)
		var new_value := _base_stat_value(stat_key) + int(delta[key])
		if not stat_key.begins_with("max_"):
			var max_value := stat_value("max_%s" % stat_key)
			if max_value > 0:
				new_value = clamp(new_value, 0, max_value)
			else:
				new_value = max(0, new_value)
		player_stats[stat_key] = new_value


func _apply_glyph_mastery_delta(delta: Dictionary) -> void:
	for glyph in delta.keys():
		var glyph_key := str(glyph)
		glyph_mastery[glyph_key] = max(0, _base_glyph_mastery_value(glyph_key) + int(delta[glyph]))


func has_flag(flag: String) -> bool:
	return flag != "" and flags.has(flag)


func _log(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	event_log.append(text)


func _apply_text_command(command: String) -> void:
	var parts := command.split(" ", false)
	if parts.is_empty():
		return
	apply_action({
		"verb": parts[0],
		"arg": parts[1] if parts.size() > 1 else "",
	})
