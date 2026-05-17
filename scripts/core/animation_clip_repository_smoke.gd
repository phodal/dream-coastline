class_name AnimationClipRepositorySmoke
extends RefCounted

const AnimationClipRepositoryScript := preload("res://scripts/core/animation_clip_repository.gd")
const VisualAssetRegistryScript := preload("res://scripts/core/visual_asset_registry.gd")

var failures: Array[String] = []


func run() -> bool:
	failures.clear()
	var assets = VisualAssetRegistryScript.new()
	if not assets.load_all():
		failures.append("visual asset registry did not load")

	var clips = AnimationClipRepositoryScript.new()
	if not clips.load_all():
		failures.append("animation clips did not load")

	for actor_id in assets.characters.keys():
		var clip_id: String = assets.character_clip(actor_id, "player_default")
		for failure in clips.validate_required_player_states(clip_id):
			failures.append("%s: %s" % [actor_id, failure])
		_validate_creature_config(actor_id, assets.characters[actor_id])

	var ok := failures.is_empty()
	print("animation-clip-smoke status=%s actors=%s" % ["PASS" if ok else "FAIL", assets.characters.size()])
	for failure in failures:
		print("failure=", failure)
	return ok


func _validate_creature_config(actor_id: String, character: Dictionary) -> void:
	if str(character.get("type", "")) != "creature":
		return

	var config_path := str(character.get("config", ""))
	if config_path.is_empty():
		failures.append("%s: missing creature config path" % actor_id)
		return
	if not FileAccess.file_exists(config_path):
		failures.append("%s: creature config does not exist: %s" % [actor_id, config_path])
		return

	var parsed = JSON.parse_string(FileAccess.get_file_as_string(config_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("%s: creature config is not a dictionary: %s" % [actor_id, config_path])
		return

	var config: Dictionary = parsed
	for key in ["id", "name", "big_image", "walk_spritesheet", "animation_clip", "description", "skills", "personality"]:
		if not config.has(key):
			failures.append("%s: creature config missing %s" % [actor_id, key])
	var big_image := str(config.get("big_image", ""))
	if not big_image.is_empty() and not FileAccess.file_exists(big_image):
		failures.append("%s: creature big_image does not exist: %s" % [actor_id, big_image])
	var walk_spritesheet := str(config.get("walk_spritesheet", ""))
	if not walk_spritesheet.is_empty() and not FileAccess.file_exists(walk_spritesheet):
		failures.append("%s: creature walk_spritesheet does not exist: %s" % [actor_id, walk_spritesheet])
