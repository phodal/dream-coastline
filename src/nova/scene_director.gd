extends Node

signal project_loaded
signal location_presented(scene_id: String, location_id: String, location: Dictionary, visual: Dictionary)
signal cutscene_started(payload: Dictionary)
signal cutscene_finished(payload: Dictionary)
signal runtime_error(message: String)

const StoryRepository := preload("res://src/nova/data/story_repository.gd")
const VisualRepository := preload("res://src/nova/data/visual_repository.gd")
const DialogicBridge := preload("res://src/nova/dialogic_bridge.gd")
const MoqiText := preload("res://src/nova/ui/moqi_text.gd")
const CHARACTER_APPEARANCES := {
	"jizi_xuan": {"name": "纪子轩", "path": "res://assets/characters/main/jizi_xuan/portrait_xianjian_phone.png", "dialogic_id": "jizi_xuan", "portrait": "phone"},
	"jizixuan": {"name": "纪子轩", "path": "res://assets/characters/main/jizi_xuan/portrait_xianjian_phone.png", "dialogic_id": "jizi_xuan", "portrait": "phone"},
	"xiali": {"name": "夏离", "path": "res://assets/characters/main/xiali/model_sheet.png", "dialogic_id": "xiali", "portrait": "default"},
	"wensu": {"name": "闻素", "path": "res://assets/characters/main/wensu/model_sheet.png", "dialogic_id": "wensu", "portrait": "default"},
	"atang": {"name": "阿棠", "path": "res://assets/characters/main/atang/model_sheet.png", "dialogic_id": "atang", "portrait": "default"},
	"xiaoyan": {"name": "小砚", "path": "", "dialogic_id": "xiaoyan", "portrait": "default"},
}

var story_repository = StoryRepository.new()
var visual_repository = VisualRepository.new()
var _combat_attack_attempts: Dictionary = {}


func boot() -> bool:
	var ok: bool = story_repository.load_all()
	if not ok:
		runtime_error.emit("No story scenes loaded.")
		return false
	visual_repository.load_for_scene_ids(story_repository.scene_ids())
	for scene_id in story_repository.scene_ids():
		var scene := story_repository.get_scene(scene_id)
		QuestState.ensure_quest(scene_id, str(scene.get("title", scene_id)))
	var first_scene := story_repository.first_scene_id()
	GameState.start_scene(first_scene, story_repository.get_start_location(first_scene))
	_apply_initial_flags(first_scene)
	QuestState.set_status(first_scene, QuestState.ACTIVE)
	GameMode.set_mode(GameMode.EXPLORATION)
	project_loaded.emit()
	present_current_location()
	return true


func present_current_location() -> void:
	var scene_id := GameState.current_scene_id
	var location_id := GameState.current_location_id
	var location := story_repository.get_location(scene_id, location_id)
	var visual := visual_repository.get_location_visual(scene_id, location_id)
	location_presented.emit(scene_id, location_id, location, visual)


func move_to(location_id: String) -> bool:
	var exits := story_repository.get_exits(GameState.current_scene_id, GameState.current_location_id)
	if not exits.has(location_id):
		runtime_error.emit("Unknown exit: %s" % location_id)
		return false
	GameState.move_to(location_id)
	present_current_location()
	return true


func inspect_item(item_id: String) -> bool:
	var items := story_repository.get_items(GameState.current_scene_id, GameState.current_location_id)
	if not items.has(item_id):
		runtime_error.emit("Unknown item: %s" % item_id)
		return false
	var item: Dictionary = items[item_id]
	var requires: Array = item.get("requires", [])
	if not StoryFlags.has_all(requires):
		var missing := _first_missing(requires)
		start_cutscene({
			"speaker": _speaker_for_item(item_id, item),
			"title": str(item.get("name", item_id)),
			"text": "现在还不能确认它。还缺少线索：%s。" % missing,
			"flags": [],
			"mode": GameMode.DIALOGUE,
			"characters": _characters_for_item(item_id, item),
		})
		return false
	start_cutscene({
		"speaker": _speaker_for_item(item_id, item),
		"title": str(item.get("name", item_id)),
		"text": str(item.get("text", "")),
		"dialogue": item.get("dialogue", []),
		"flags": item.get("flags", []),
		"time_seconds": item.get("time_seconds", 0),
		"mode": GameMode.VN_CUTSCENE,
		"characters": _characters_for_item(item_id, item),
		"timeline_path": DialogicBridge.resolve_timeline_path(
			GameState.current_scene_id,
			GameState.current_location_id,
			item_id,
		),
	})
	return true


func choose_location_choice(choice_id: String) -> bool:
	var choices := story_repository.get_location_choices(GameState.current_scene_id, GameState.current_location_id)
	if not choices.has(choice_id):
		runtime_error.emit("Unknown choice: %s" % choice_id)
		return false
	var choice: Dictionary = choices[choice_id]
	var resolved_flag := story_repository.get_branch_resolved_flag(GameState.current_scene_id)
	if not resolved_flag.is_empty() and StoryFlags.has_flag(resolved_flag):
		start_cutscene({
			"speaker": "旁白",
			"title": str(choice.get("name", choice_id)),
			"text": "这条路线已经确定，不能再改写。",
			"flags": [],
			"mode": GameMode.DIALOGUE,
			"characters": _characters_for_item(choice_id, choice),
		})
		return false
	var requires: Array = choice.get("requires", [])
	if not StoryFlags.has_all(requires):
		var missing := _first_missing(requires)
		start_cutscene({
			"speaker": "旁白",
			"title": str(choice.get("name", choice_id)),
			"text": "现在还不能选择这条路线。还缺少线索：%s。" % missing,
			"flags": [],
			"mode": GameMode.DIALOGUE,
			"characters": _characters_for_item(choice_id, choice),
		})
		return false
	start_cutscene({
		"speaker": _speaker_for_item(choice_id, choice),
		"title": str(choice.get("name", choice_id)),
		"text": str(choice.get("text", "")),
		"dialogue": choice.get("dialogue", []),
		"flags": choice.get("flags", []),
		"time_seconds": choice.get("time_seconds", 0),
		"mode": GameMode.VN_CUTSCENE,
		"characters": _characters_for_item(choice_id, choice),
		"timeline_path": DialogicBridge.resolve_choice_timeline_path(
			GameState.current_scene_id,
			GameState.current_location_id,
			choice_id,
		),
	})
	return true


func perform_story_action(action_type: String, action_id: String) -> bool:
	match action_type:
		"glyph":
			return _perform_record_action("glyph", action_id, story_repository.get_glyph_actions(GameState.current_scene_id, GameState.current_location_id), "写")
		"build":
			return _perform_record_action("build", action_id, story_repository.get_build_actions(GameState.current_scene_id, GameState.current_location_id), "建设")
		"encounter":
			return _perform_record_action("encounter", action_id, story_repository.get_encounters(GameState.current_scene_id, GameState.current_location_id), "遭遇")
		"combo":
			return _perform_record_action("combo", action_id, story_repository.get_combos(GameState.current_scene_id, GameState.current_location_id), "组合")
		"combat_identify":
			return _perform_combat_identify()
		"combat_spell":
			return _perform_combat_spell(action_id)
		"combat_resolve":
			return _perform_combat_resolve()
		_:
			runtime_error.emit("Unknown story action: %s/%s" % [action_type, action_id])
			return false


func start_cutscene(payload: Dictionary) -> void:
	GameMode.set_mode(str(payload.get("mode", GameMode.VN_CUTSCENE)))
	cutscene_started.emit(payload)


func finish_cutscene(payload: Dictionary) -> void:
	for flag in payload.get("flags", []):
		StoryFlags.set_flag(str(flag), true)
	_update_scene_completion()
	GameMode.set_mode(GameMode.EXPLORATION)
	cutscene_finished.emit(payload)
	present_current_location()


func build_location_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var scene_id := GameState.current_scene_id
	var location_id := GameState.current_location_id
	var items := story_repository.get_items(scene_id, location_id)
	for item_id in items.keys():
		var item: Dictionary = items[item_id]
		choices.append({
			"type": "inspect",
			"id": item_id,
			"label": "调查 %s" % str(item.get("name", item_id)),
			"enabled": StoryFlags.has_all(item.get("requires", [])),
			"done": StoryFlags.has_all(item.get("flags", [])),
		})
	var location_choices := story_repository.get_location_choices(scene_id, location_id)
	var resolved_flag := story_repository.get_branch_resolved_flag(scene_id)
	var branch_resolved := not resolved_flag.is_empty() and StoryFlags.has_flag(resolved_flag)
	for choice_id in location_choices.keys():
		var choice: Dictionary = location_choices[choice_id]
		var flags: Array = choice.get("flags", [])
		var choice_done := StoryFlags.has_any(flags)
		choices.append({
			"type": "choice",
			"id": choice_id,
			"label": "选择 %s" % str(choice.get("name", choice_id)),
			"enabled": StoryFlags.has_all(choice.get("requires", [])) and not branch_resolved,
			"done": choice_done,
		})
	_append_record_action_choices(choices, "glyph", "写", story_repository.get_glyph_actions(scene_id, location_id))
	_append_record_action_choices(choices, "build", "建设", story_repository.get_build_actions(scene_id, location_id))
	_append_record_action_choices(choices, "encounter", "遭遇", story_repository.get_encounters(scene_id, location_id))
	_append_record_action_choices(choices, "combo", "组合", story_repository.get_combos(scene_id, location_id))
	_append_combat_choices(choices, story_repository.get_combat(scene_id, location_id))
	var exits := story_repository.get_exits(scene_id, location_id)
	for exit_id in exits.keys():
		choices.append({
			"type": "move",
			"id": exit_id,
			"label": "前往 %s" % str(exits[exit_id]),
			"enabled": true,
			"done": false,
		})
	return choices


func _append_record_action_choices(result: Array[Dictionary], action_type: String, verb_label: String, records: Dictionary) -> void:
	for action_id in records.keys():
		var record: Dictionary = records[action_id]
		var flags: Array = record.get("flags", [])
		var choice := {
			"type": "story_action",
			"action_type": action_type,
			"id": str(action_id),
			"label": "%s %s" % [verb_label, str(record.get("name", action_id))],
			"enabled": StoryFlags.has_all(record.get("requires", [])),
			"done": StoryFlags.has_any(flags),
		}
		if action_type == "glyph":
			var glyph_id := str(action_id)
			var glyph_label := str(record.get("name", MoqiText.display_name(glyph_id)))
			choice["label"] = "%s %s" % [verb_label, glyph_label]
			choice["moqi_prefix"] = verb_label
			choice["moqi_glyph"] = MoqiText.glyph(glyph_id)
			choice["moqi_label"] = glyph_label
		result.append(choice)


func _append_combat_choices(result: Array[Dictionary], combat: Dictionary) -> void:
	if combat.is_empty():
		return
	var lock_flag := str(combat.get("lock_flag", ""))
	var win_flag := str(combat.get("win_flag", ""))
	var learn_flag := str(combat.get("learn_flag", ""))
	var identify_choice := {
		"type": "story_action",
		"action_type": "combat_identify",
		"id": "identify",
		"label": "识名 %s" % str(combat.get("hidden_name", "敌人")),
		"enabled": (learn_flag.is_empty() or StoryFlags.has_flag(learn_flag)) and (win_flag.is_empty() or not StoryFlags.has_flag(win_flag)),
		"done": StoryFlags.has_flag(lock_flag),
		"moqi_prefix": "识名",
		"moqi_glyph": MoqiText.glyph("name"),
		"moqi_label": str(combat.get("hidden_name", "敌人")),
	}
	result.append(identify_choice)
	var spells: Dictionary = combat.get("spells", {})
	for spell_id in spells.keys():
		var spell: Dictionary = spells[spell_id]
		var flags: Array = spell.get("flags", [])
		var glyph_id := str(spell_id)
		var spell_label := str(spell.get("name", MoqiText.display_name(glyph_id)))
		var spell_choice := {
			"type": "story_action",
			"action_type": "combat_spell",
			"id": glyph_id,
			"label": "破解 %s" % spell_label,
			"enabled": StoryFlags.has_flag(lock_flag) and StoryFlags.has_all(spell.get("requires", [])),
			"done": StoryFlags.has_any(flags),
		}
		var spell_glyph := MoqiText.glyph(glyph_id)
		if not spell_glyph.is_empty():
			spell_choice["moqi_prefix"] = "破解"
			spell_choice["moqi_glyph"] = spell_glyph
			spell_choice["moqi_label"] = spell_label
		result.append(spell_choice)
	result.append({
		"type": "story_action",
		"action_type": "combat_resolve",
		"id": "resolve",
		"label": "终局 %s" % str(combat.get("revealed_name", combat.get("hidden_name", "敌人"))),
		"enabled": StoryFlags.has_flag(lock_flag) and StoryFlags.has_all(_as_array(combat.get("required_attack_flags", []))),
		"done": StoryFlags.has_flag(win_flag),
	})


func _perform_record_action(action_type: String, action_id: String, records: Dictionary, verb_label: String) -> bool:
	if not records.has(action_id):
		runtime_error.emit("Unknown %s action: %s" % [action_type, action_id])
		return false
	var record: Dictionary = records[action_id]
	return _start_record_payload(record, {
		"action_type": action_type,
		"action_id": action_id,
		"title": "%s %s" % [verb_label, str(record.get("name", action_id))],
		"timeline_path": DialogicBridge.resolve_action_timeline_path(
			GameState.current_scene_id,
			GameState.current_location_id,
			action_type,
			action_id,
		),
	})


func _perform_combat_identify() -> bool:
	var combat := story_repository.get_combat(GameState.current_scene_id, GameState.current_location_id)
	if combat.is_empty():
		runtime_error.emit("No combat in current location.")
		return false
	var learn_flag := str(combat.get("learn_flag", ""))
	if not learn_flag.is_empty() and not StoryFlags.has_flag(learn_flag):
		start_cutscene(_blocked_payload("识名", "你还没有理解“名”的笔画。"))
		return false
	var flags: Array = []
	var lock_flag := str(combat.get("lock_flag", ""))
	if not lock_flag.is_empty():
		flags.append(lock_flag)
	flags.append_array(combat.get("success_flags", []))
	return _start_synthetic_payload({
		"title": "识名 %s" % str(combat.get("hidden_name", "敌人")),
		"text": "“名”字亮起。目标显形：%s。" % str(combat.get("revealed_name", "敌人")),
		"flags": flags,
		"timeline_path": DialogicBridge.resolve_action_timeline_path(GameState.current_scene_id, GameState.current_location_id, "combat", "identify"),
	})


func _perform_combat_spell(spell_id: String) -> bool:
	var combat := story_repository.get_combat(GameState.current_scene_id, GameState.current_location_id)
	var spells: Dictionary = combat.get("spells", {})
	if not spells.has(spell_id):
		runtime_error.emit("Unknown combat spell: %s" % spell_id)
		return false
	var lock_flag := str(combat.get("lock_flag", ""))
	if not StoryFlags.has_flag(lock_flag):
		start_cutscene(_blocked_payload("破解", "目标还没有被识名，规则无法落点。"))
		return false
	var spell: Dictionary = spells[spell_id]
	return _start_record_payload(spell, {
		"action_type": "combat_spell",
		"action_id": spell_id,
		"title": "破解 %s" % str(spell.get("name", spell_id)),
		"timeline_path": DialogicBridge.resolve_action_timeline_path(GameState.current_scene_id, GameState.current_location_id, "combat_spell", spell_id),
	})


func _perform_combat_resolve() -> bool:
	var combat := story_repository.get_combat(GameState.current_scene_id, GameState.current_location_id)
	if combat.is_empty():
		runtime_error.emit("No combat in current location.")
		return false
	var lock_flag := str(combat.get("lock_flag", ""))
	if not StoryFlags.has_flag(lock_flag):
		start_cutscene(_blocked_payload("终局", "目标还没有被识名。"))
		return false
	var required: Array = _as_array(combat.get("required_attack_flags", []))
	if not StoryFlags.has_all(required):
		start_cutscene(_blocked_payload("终局", "战场规则还没破解：%s。" % _first_missing(required)))
		return false
	var attempt_key := "%s/%s" % [GameState.current_scene_id, GameState.current_location_id]
	var attempts := _combat_attempt_count(attempt_key, combat) + 1
	_combat_attack_attempts[attempt_key] = attempts
	var enemy_hp: int = max(1, int(combat.get("enemy_hp", combat.get("success_attempt", 1))))
	if attempts < enemy_hp:
		var failure_flags: Array = _as_array(combat.get("failure_flags", []))
		var flags: Array = []
		if not failure_flags.is_empty():
			flags.append(str(failure_flags[(attempts - 1) % failure_flags.size()]))
		return _start_synthetic_payload({
			"title": "终局 %s" % str(combat.get("revealed_name", "敌人")),
			"text": "%s 没有被击退。名字的笔画再次松开。" % str(combat.get("revealed_name", "敌人")),
			"flags": flags,
			"timeline_path": DialogicBridge.resolve_action_timeline_path(GameState.current_scene_id, GameState.current_location_id, "combat", "resolve"),
		})
	var flags: Array = []
	var win_flag := str(combat.get("win_flag", ""))
	if not win_flag.is_empty():
		flags.append(win_flag)
	flags.append_array(combat.get("reward_flags", []))
	return _start_synthetic_payload({
		"title": "终局 %s" % str(combat.get("revealed_name", "敌人")),
		"text": "%s 被击退。" % str(combat.get("revealed_name", "敌人")),
		"flags": flags,
		"timeline_path": DialogicBridge.resolve_action_timeline_path(GameState.current_scene_id, GameState.current_location_id, "combat", "resolve"),
	})


func _combat_attempt_count(attempt_key: String, combat: Dictionary) -> int:
	var stored := int(_combat_attack_attempts.get(attempt_key, 0))
	var failure_count := 0
	for flag in _as_array(combat.get("failure_flags", [])):
		if StoryFlags.has_flag(str(flag)):
			failure_count += 1
	return maxi(stored, failure_count)


func _start_record_payload(record: Dictionary, meta: Dictionary) -> bool:
	var requires: Array = record.get("requires", [])
	if not StoryFlags.has_all(requires):
		start_cutscene(_blocked_payload(str(meta.get("title", "行动")), "前置条件不足：%s。" % _first_missing(requires)))
		return false
	return _start_synthetic_payload({
		"title": str(meta.get("title", record.get("name", meta.get("action_id", "行动")))),
		"text": str(record.get("text", record.get("success_text", ""))),
		"dialogue": record.get("dialogue", []),
		"flags": record.get("flags", []),
		"time_seconds": record.get("time_seconds", 0),
		"mode": GameMode.VN_CUTSCENE,
		"characters": _characters_for_item(str(meta.get("action_id", "")), record),
		"timeline_path": str(meta.get("timeline_path", "")),
	})


func _start_synthetic_payload(payload: Dictionary) -> bool:
	if not payload.has("speaker"):
		payload["speaker"] = "旁白"
	if not payload.has("mode"):
		payload["mode"] = GameMode.VN_CUTSCENE
	if not payload.has("characters"):
		payload["characters"] = []
	start_cutscene(payload)
	return true


func _blocked_payload(title: String, text: String) -> Dictionary:
	return {
		"speaker": "旁白",
		"title": title,
		"text": text,
		"flags": [],
		"mode": GameMode.DIALOGUE,
		"characters": [],
	}


func _update_scene_completion() -> void:
	var scene_id := GameState.current_scene_id
	var ending_flag := story_repository.get_ending_flag(scene_id)
	if not ending_flag.is_empty() and not StoryFlags.has_flag(ending_flag):
		return
	var required_flags := story_repository.get_required_flags(scene_id)
	if required_flags.is_empty() or StoryFlags.has_all(required_flags):
		QuestState.set_status(scene_id, QuestState.COMPLETE)
		_advance_to_next_scene(scene_id)


func _advance_to_next_scene(completed_scene_id: String) -> void:
	var next_scene := story_repository.next_scene_id(completed_scene_id)
	if next_scene.is_empty():
		return
	var next_location := story_repository.get_start_location(next_scene)
	if next_location.is_empty():
		runtime_error.emit("Next scene has no start location: %s" % next_scene)
		return
	GameState.start_scene(next_scene, next_location)
	_apply_initial_flags(next_scene)
	QuestState.set_status(next_scene, QuestState.ACTIVE)


func _apply_initial_flags(scene_id: String) -> void:
	for flag in story_repository.get_initial_flags(scene_id):
		StoryFlags.set_flag(str(flag), true)


func _first_missing(flags: Array) -> String:
	for flag in flags:
		if not StoryFlags.has_flag(str(flag)):
			return str(flag)
	return "unknown"


func _as_array(value) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	return []


func _speaker_for_item(item_id: String, item: Dictionary) -> String:
	var characters := _characters_for_item(item_id, item)
	if not characters.is_empty():
		return str(characters[0].get("name", item.get("name", item_id)))
	return "旁白"


func _characters_for_item(item_id: String, item: Dictionary) -> Array[Dictionary]:
	var ids: Array[String] = []
	if CHARACTER_APPEARANCES.has(item_id):
		ids.append(item_id)
	if item.has("character_id"):
		var character_id := str(item.get("character_id", ""))
		if not character_id.is_empty() and not ids.has(character_id):
			ids.append(character_id)
	if item.has("characters"):
		for raw_id in item.get("characters", []):
			var character_id := str(raw_id)
			if not character_id.is_empty() and not ids.has(character_id):
				ids.append(character_id)

	var result: Array[Dictionary] = []
	for character_id in ids:
		if not CHARACTER_APPEARANCES.has(character_id):
			continue
		var appearance: Dictionary = CHARACTER_APPEARANCES[character_id]
		result.append({
			"id": character_id,
			"name": str(appearance.get("name", character_id)),
			"path": str(appearance.get("path", "")),
			"dialogic_id": str(appearance.get("dialogic_id", "")),
			"portrait": str(appearance.get("portrait", "")),
		})
	return result
