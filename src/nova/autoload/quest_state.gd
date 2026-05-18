extends Node

signal quest_changed(quest_id: String, status: String)

const NOT_STARTED := "not_started"
const ACTIVE := "active"
const COMPLETE := "complete"

var _quests: Dictionary = {}


func ensure_quest(quest_id: String, title: String) -> void:
	if quest_id.is_empty() or _quests.has(quest_id):
		return
	_quests[quest_id] = {
		"title": title,
		"status": NOT_STARTED,
	}


func set_status(quest_id: String, status: String) -> void:
	if quest_id.is_empty():
		return
	if not _quests.has(quest_id):
		ensure_quest(quest_id, quest_id)
	if _quests[quest_id].get("status", NOT_STARTED) == status:
		return
	_quests[quest_id]["status"] = status
	quest_changed.emit(quest_id, status)


func get_status(quest_id: String) -> String:
	if not _quests.has(quest_id):
		return NOT_STARTED
	return str(_quests[quest_id].get("status", NOT_STARTED))


func active_summary() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest_id in _quests.keys():
		var quest: Dictionary = _quests[quest_id]
		if quest.get("status", NOT_STARTED) != COMPLETE:
			result.append({
				"id": quest_id,
				"title": quest.get("title", quest_id),
				"status": quest.get("status", NOT_STARTED),
			})
	return result


func reset() -> void:
	_quests.clear()
