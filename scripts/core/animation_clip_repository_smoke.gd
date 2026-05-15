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

	var player_clip: String = assets.character_clip("jizixuan", "player_default")
	for failure in clips.validate_required_player_states(player_clip):
		failures.append(failure)

	var ok := failures.is_empty()
	print("animation-clip-smoke status=%s actor=jizixuan clip=%s" % ["PASS" if ok else "FAIL", player_clip])
	for failure in failures:
		print("failure=", failure)
	return ok
