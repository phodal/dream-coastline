extends Node

signal project_loaded
signal location_presented(scene_id: String, location_id: String, location: Dictionary, visual: Dictionary)
signal cutscene_started(payload: Dictionary)
signal cutscene_finished(payload: Dictionary)
signal runtime_error(message: String)

const StoryRepository := preload("res://src/nova/data/story_repository.gd")
const VisualRepository := preload("res://src/nova/data/visual_repository.gd")
const DialogicBridge := preload("res://src/nova/dialogic_bridge.gd")
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


func _update_scene_completion() -> void:
	var scene_id := GameState.current_scene_id
	var required_flags := story_repository.get_required_flags(scene_id)
	if not required_flags.is_empty() and StoryFlags.has_all(required_flags):
		QuestState.set_status(scene_id, QuestState.COMPLETE)


func _first_missing(flags: Array) -> String:
	for flag in flags:
		if not StoryFlags.has_flag(str(flag)):
			return str(flag)
	return "unknown"


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
