class_name SceneDatabase
extends RefCounted

const SCENE_DIR := "res://data/story_scenes"
const SCENE_IDS := [
	"00-prologue-lights-out",
	"01-illiterate",
	"02-moqi-academy",
	"03-dead-kingdom",
	"04-continuation-institute",
	"05-century-continuation",
	"06-return-star-plan",
	"07-lights-on-again",
]

var scenes := {}


func load_all() -> bool:
	scenes.clear()
	var ok := true
	for scene_id in SCENE_IDS:
		var path := "%s/%s.json" % [SCENE_DIR, scene_id]
		var text := FileAccess.get_file_as_string(path)
		var parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("Could not parse scene data: %s" % path)
			ok = false
			continue
		scenes[scene_id] = parsed
	return ok


func count() -> int:
	return SCENE_IDS.size()


func scene_id_at(index: int) -> String:
	return SCENE_IDS[clamp(index, 0, SCENE_IDS.size() - 1)]


func scene_at(index: int) -> Dictionary:
	return scenes.get(scene_id_at(index), {})
