class_name AnimationClipRepository
extends RefCounted

const CLIP_DIR := "res://data/animation_clips"
const DEFAULT_CLIP_ID := "player_default"
const DEFAULT_TILE_SIZE := 16.0
const DEFAULT_RENDER_SIZE := 0.74
const DEFAULT_FPS := 4.0

var clips := {}
var textures := {}


func load_all() -> bool:
	clips.clear()
	textures.clear()
	var ok := true
	var dir := DirAccess.open(CLIP_DIR)
	if dir == null:
		push_error("Could not open animation clip directory: %s" % CLIP_DIR)
		return false

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var clip_id := file_name.substr(0, file_name.length() - 5)
			ok = load_clip(clip_id) and ok
		file_name = dir.get_next()
	dir.list_dir_end()
	return ok


func load_clip(clip_id: String) -> bool:
	var path := "%s/%s.json" % [CLIP_DIR, clip_id]
	if not FileAccess.file_exists(path):
		push_warning("Animation clip file does not exist: %s" % path)
		return false

	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Could not parse animation clip data: %s" % path)
		return false

	var clip: Dictionary = parsed
	var resolved_id := str(clip.get("id", clip_id))
	clips[resolved_id] = clip
	return true


func has_clip(clip_id: String) -> bool:
	return clips.has(clip_id)


func resolve_frame(clip_id: String, moving: bool, facing: Vector2i, elapsed: float) -> Dictionary:
	var clip: Dictionary = clips.get(clip_id, {})
	if clip.is_empty():
		clip = clips.get(DEFAULT_CLIP_ID, {})
	if clip.is_empty():
		return {}

	var animation_name := animation_name_for_state(moving, facing)
	var animation := _animation_data(clip, animation_name)
	if animation.is_empty():
		animation_name = animation_name_for_state(false, facing)
		animation = _animation_data(clip, animation_name)
	if animation.is_empty():
		animation_name = "idle_down"
		animation = _animation_data(clip, animation_name)
	if animation.is_empty():
		return {}

	var frames: Array = animation.get("frames", [])
	if frames.is_empty():
		return {}

	var frame_index := _frame_index(animation, frames.size(), elapsed)
	var frame: Dictionary = frames[frame_index]
	var atlas_path := str(clip.get("atlas", ""))
	var texture = _texture_for(atlas_path)
	if texture == null:
		return {}

	var tile_size := float(clip.get("tile_size", DEFAULT_TILE_SIZE))
	var frame_size := _frame_size_vector(clip, tile_size)
	return {
		"texture": texture,
		"source": Rect2(
			Vector2(float(frame.get("x", 0)) * frame_size.x, float(frame.get("y", 0)) * frame_size.y),
			frame_size
		),
		"tile_size": tile_size,
		"frame_size": frame_size,
		"render_size": float(clip.get("render_size", DEFAULT_RENDER_SIZE)),
		"anchor": _anchor_vector(clip, frame_size),
		"shadow": bool(clip.get("shadow", true)),
		"clip_id": str(clip.get("id", clip_id)),
		"animation": animation_name,
	}


func animation_name_for_state(moving: bool, facing: Vector2i) -> String:
	var prefix := "walk" if moving else "idle"
	return "%s_%s" % [prefix, direction_name(facing)]


func direction_name(facing: Vector2i) -> String:
	if facing == Vector2i(0, -1):
		return "up"
	if facing == Vector2i(-1, 0):
		return "left"
	if facing == Vector2i(1, 0):
		return "right"
	return "down"


func validate_required_player_states(clip_id: String = DEFAULT_CLIP_ID) -> Array[String]:
	var failures: Array[String] = []
	var clip: Dictionary = clips.get(clip_id, {})
	if clip.is_empty():
		failures.append("missing clip %s" % clip_id)
		return failures
	var atlas_path := str(clip.get("atlas", ""))
	if atlas_path.is_empty():
		failures.append("missing atlas for clip %s" % clip_id)
	var texture = _texture_for(atlas_path)
	if texture == null:
		failures.append("missing or unloadable atlas for clip %s: %s" % [clip_id, atlas_path])
	var tile_size := float(clip.get("tile_size", DEFAULT_TILE_SIZE))
	var frame_size := _frame_size_vector(clip, tile_size)
	if tile_size <= 0.0:
		failures.append("invalid tile_size for clip %s" % clip_id)
	if frame_size.x <= 0.0 or frame_size.y <= 0.0:
		failures.append("invalid frame_size for clip %s" % clip_id)
	for moving in [false, true]:
		for facing in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var animation_name := animation_name_for_state(moving, facing)
			var animation := _animation_data(clip, animation_name)
			if animation.is_empty():
				failures.append("missing animation %s" % animation_name)
				continue
			if float(animation.get("fps", DEFAULT_FPS)) <= 0.0:
				failures.append("invalid fps for %s" % animation_name)
			var frames: Array = animation.get("frames", [])
			if frames.is_empty():
				failures.append("missing frame for %s" % animation_name)
				continue
			if texture != null and tile_size > 0.0 and frame_size.x > 0.0 and frame_size.y > 0.0:
				_validate_frame_bounds(animation_name, frames, tile_size, frame_size, texture, failures)
	return failures


func _animation_data(clip: Dictionary, animation_name: String) -> Dictionary:
	var animations: Dictionary = clip.get("animations", {})
	var animation = animations.get(animation_name, {})
	if typeof(animation) == TYPE_DICTIONARY:
		return animation
	return {}


func _frame_index(animation: Dictionary, frame_count: int, elapsed: float) -> int:
	if frame_count <= 1:
		return 0
	var fps := maxf(0.01, float(animation.get("fps", DEFAULT_FPS)))
	var index := int(floor(elapsed * fps))
	if bool(animation.get("loop", true)):
		return index % frame_count
	return mini(index, frame_count - 1)


func _texture_for(atlas_path: String):
	if atlas_path.is_empty():
		return null
	if textures.has(atlas_path):
		return textures[atlas_path]
	var texture = null
	if ResourceLoader.exists(atlas_path):
		texture = load(atlas_path)
	else:
		texture = _load_source_image_texture(atlas_path)
	if texture == null:
		push_warning("Could not load animation atlas: %s" % atlas_path)
		textures[atlas_path] = null
		return null
	textures[atlas_path] = texture
	return texture


func _load_source_image_texture(atlas_path: String):
	if not FileAccess.file_exists(atlas_path):
		return null
	var image := Image.new()
	var error := image.load(atlas_path)
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)


func _validate_frame_bounds(
	animation_name: String,
	frames: Array,
	tile_size: float,
	frame_size: Vector2,
	texture,
	failures: Array[String]
) -> void:
	var texture_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	for index in range(frames.size()):
		var frame = frames[index]
		if typeof(frame) != TYPE_DICTIONARY:
			failures.append("invalid frame for %s[%s]" % [animation_name, index])
			continue
		var x := float(frame.get("x", -1))
		var y := float(frame.get("y", -1))
		var top_left := Vector2(x * frame_size.x, y * frame_size.y)
		var bottom_right := top_left + frame_size
		if x < 0.0 or y < 0.0:
			failures.append("negative frame coordinate for %s[%s]" % [animation_name, index])
		elif bottom_right.x > texture_size.x or bottom_right.y > texture_size.y:
			failures.append("frame out of atlas bounds for %s[%s]" % [animation_name, index])


func _frame_size_vector(clip: Dictionary, tile_size: float) -> Vector2:
	var frame_size = clip.get("frame_size", {})
	if typeof(frame_size) == TYPE_DICTIONARY:
		return Vector2(float(frame_size.get("x", tile_size)), float(frame_size.get("y", tile_size)))
	return Vector2(tile_size, tile_size)


func _anchor_vector(clip: Dictionary, frame_size: Vector2) -> Vector2:
	var anchor: Dictionary = clip.get("anchor", {})
	return Vector2(float(anchor.get("x", frame_size.x * 0.5)), float(anchor.get("y", frame_size.y)))
