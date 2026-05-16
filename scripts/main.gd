extends Node2D

const AudioDirectorScript := preload("res://scripts/core/audio_director.gd")
const RpgFirstActSmokeScript := preload("res://scripts/core/rpg_first_act_smoke.gd")
const RpgIlliterateSmokeScript := preload("res://scripts/core/rpg_illiterate_smoke.gd")
const RpgMoqiAcademySmokeScript := preload("res://scripts/core/rpg_moqi_academy_smoke.gd")
const RpgDeadKingdomSmokeScript := preload("res://scripts/core/rpg_dead_kingdom_smoke.gd")
const RpgContinuationInstituteSmokeScript := preload("res://scripts/core/rpg_continuation_institute_smoke.gd")
const RpgCenturyContinuationSmokeScript := preload("res://scripts/core/rpg_century_continuation_smoke.gd")
const RpgReturnStarPlanSmokeScript := preload("res://scripts/core/rpg_return_star_plan_smoke.gd")
const RpgLightsOnAgainSmokeScript := preload("res://scripts/core/rpg_lights_on_again_smoke.gd")
const SaveLoadSmokeScript := preload("res://scripts/core/save_load_smoke.gd")
const AnimationClipRepositorySmokeScript := preload("res://scripts/core/animation_clip_repository_smoke.gd")
const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const GameHudScript := preload("res://scripts/ui/game_hud.gd")

var database
var visual_repository
var save_repository
var settings_repository
var session
var player_controller
var audio_director
var hud
var game_started := false
var pending_title_quit := false
var pending_return_to_title := false


func _ready() -> void:
	database = RustSceneDatabase.new()
	database.load_all()
	visual_repository = RustSceneVisualRepository.new()
	visual_repository.load_for_scene_ids(database.scene_ids())
	save_repository = RustSaveGameRepository.new()
	settings_repository = RustSettingsRepository.new()
	settings_repository.load()
	settings_repository.apply()
	session = RustGameSession.new()
	session.set_database(database)
	player_controller = RustRpgPlayerController.new()
	player_controller.set_session(session)
	player_controller.set_visual_repository(visual_repository)
	audio_director = AudioDirectorScript.new()
	audio_director.enabled = not _is_smoke_run(OS.get_cmdline_user_args())
	add_child(audio_director)
	if OS.get_cmdline_user_args().has("--smoke-audio-director"):
		var ok: bool = audio_director.verify_streams()
		print("audio-director-smoke status=%s streams=%s" % ["PASS" if ok else "FAIL", audio_director.streams.size()])
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-export-config"):
		var ok: bool = _run_export_config_smoke()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-release-libraries"):
		var ok: bool = _run_release_libraries_smoke()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-input-map"):
		var ok: bool = _run_input_map_smoke()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-animation-clips"):
		var ok: bool = AnimationClipRepositorySmokeScript.new().run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-visual-asset-scenes"):
		var ok: bool = _run_visual_asset_scene_smoke()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-autoplay"):
		var ok: bool = session.run_smoke_verification()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-first-act"):
		var ok: bool = RpgFirstActSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-illiterate"):
		var ok: bool = RpgIlliterateSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-moqi-academy"):
		var ok: bool = RpgMoqiAcademySmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-dead-kingdom"):
		var ok: bool = RpgDeadKingdomSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-continuation-institute"):
		var ok: bool = RpgContinuationInstituteSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-century-continuation"):
		var ok: bool = RpgCenturyContinuationSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-return-star-plan"):
		var ok: bool = RpgReturnStarPlanSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-rpg-lights-on-again"):
		var ok: bool = RpgLightsOnAgainSmokeScript.new(session, player_controller).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-save-load"):
		var ok: bool = SaveLoadSmokeScript.new(session, player_controller, save_repository).run()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-menu-flow"):
		_build_ui()
		_load_scene(0)
		var ok := _run_menu_smoke()
		get_tree().quit(0 if ok else 1)
		return
	if OS.get_cmdline_user_args().has("--smoke-render-frame"):
		_build_ui()
		_start_new_game()
		call_deferred("_finish_render_smoke")
		return
	if OS.get_cmdline_user_args().has("--capture-scene-screenshots"):
		_build_ui()
		game_started = true
		hud.hide_title()
		call_deferred("_capture_scene_screenshots")
		return

	_build_ui()
	_load_scene(0)


func _process(delta: float) -> void:
	if player_controller != null and player_controller.update(delta):
		_refresh_ui()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), GameThemeScript.COLORS.background)


func _build_ui() -> void:
	hud = GameHudScript.new()
	hud.configure(visual_repository, save_repository.has_save())
	hud.resume_requested.connect(_resume_game)
	hud.save_requested.connect(_save_game)
	hud.load_requested.connect(_load_game)
	hud.return_to_title_requested.connect(_request_return_to_title)
	hud.new_game_requested.connect(_start_new_game)
	hud.continue_requested.connect(_continue_from_title)
	hud.settings_requested.connect(_open_settings)
	hud.title_quit_requested.connect(_request_title_quit)
	hud.settings_back_requested.connect(_close_settings)
	hud.fullscreen_changed.connect(_set_fullscreen)
	hud.master_volume_changed.connect(_set_master_volume)
	add_child(hud)


func _load_scene(index: int) -> void:
	session.load_scene(index)
	player_controller.reset_for_location()
	_refresh_ui()


func _refresh_ui() -> void:
	if hud == null:
		return

	hud.refresh(session, player_controller)
	queue_redraw()


func _focus_visible_menu() -> void:
	if hud != null:
		hud.focus_visible_menu()


func _unhandled_input(event: InputEvent) -> void:
	if hud != null and hud.is_settings_visible():
		if _is_action_pressed(event, ["ui_cancel", "pause"]):
			_close_settings()
		return
	if hud != null and hud.is_title_visible():
		return
	if _is_action_pressed(event, ["ui_cancel", "pause"]):
		_toggle_pause()
		return
	if hud != null and hud.is_pause_visible():
		return
	if event.is_action_pressed("move_up"):
		_try_move(Vector2i(0, -1))
	elif event.is_action_pressed("move_down"):
		_try_move(Vector2i(0, 1))
	elif event.is_action_pressed("move_left"):
		_try_move(Vector2i(-1, 0))
	elif event.is_action_pressed("move_right"):
		_try_move(Vector2i(1, 0))
	elif _is_action_pressed(event, ["ui_accept", "interact"]):
		_interact()


func _try_move(direction: Vector2i) -> void:
	var was_moving: bool = player_controller.is_moving
	var moved: bool = player_controller.try_move(direction)
	if audio_director != null:
		if moved:
			audio_director.play_step()
		elif not was_moving and player_controller.has_blocked_feedback():
			audio_director.play_blocked()
	_refresh_ui()


func _interact() -> void:
	var before_location: String = session.location_id
	var before_log_count: int = session.event_log.size()
	var before_complete: bool = session.has_flag(str(session.scene.get("ending_flag", "")))
	player_controller.interact()
	if audio_director != null:
		if session.location_id != before_location:
			audio_director.play_transition()
		elif not before_complete and session.has_flag(str(session.scene.get("ending_flag", ""))):
			audio_director.play_success()
		elif session.event_log.size() > before_log_count:
			audio_director.play_interact()
	_refresh_ui()


func _toggle_pause() -> void:
	if hud == null or not game_started:
		return
	pending_return_to_title = false
	hud.toggle_pause("ESC 返回游戏")
	if audio_director != null:
		audio_director.play_ui()


func _resume_game() -> void:
	hud.hide_pause()
	pending_return_to_title = false
	if audio_director != null:
		audio_director.play_ui()


func _save_game() -> void:
	var ok: bool = save_repository.save(session, player_controller)
	hud.set_pause_status("已保存" if ok else "保存失败")
	if audio_director != null:
		if ok:
			audio_director.play_success()
		else:
			audio_director.play_blocked()


func _load_game() -> void:
	var ok: bool = save_repository.load_into(session, player_controller)
	if ok:
		game_started = true
		hud.hide_pause()
		_refresh_ui()
		if audio_director != null:
			audio_director.play_transition()
	else:
		hud.set_pause_status("没有可读取的存档")
		if audio_director != null:
			audio_director.play_blocked()


func _start_new_game() -> void:
	game_started = true
	pending_title_quit = false
	pending_return_to_title = false
	hud.hide_title()
	_load_scene(0)
	if audio_director != null:
		audio_director.play_transition()


func _continue_from_title() -> void:
	var ok: bool = save_repository.load_into(session, player_controller)
	if ok:
		game_started = true
		pending_title_quit = false
		pending_return_to_title = false
		hud.hide_title()
		_refresh_ui()
		if audio_director != null:
			audio_director.play_transition()
	else:
		hud.set_title_status("没有可读取的存档")
		if audio_director != null:
			audio_director.play_blocked()


func _open_settings() -> void:
	pending_title_quit = false
	pending_return_to_title = false
	hud.show_settings(settings_repository.fullscreen_enabled(), settings_repository.master_volume_value())
	if audio_director != null:
		audio_director.play_ui()


func _close_settings() -> void:
	hud.hide_settings(not game_started)
	if audio_director != null:
		audio_director.play_ui()


func _set_fullscreen(enabled: bool) -> void:
	settings_repository.set_fullscreen_enabled(enabled)
	settings_repository.apply()
	settings_repository.save()
	if audio_director != null:
		audio_director.play_ui()


func _set_master_volume(value: float) -> void:
	settings_repository.set_master_volume_value(clampf(value, 0.0, 1.0))
	settings_repository.apply()
	settings_repository.save()
	if audio_director != null:
		audio_director.play_ui()


func _request_title_quit() -> void:
	if not pending_title_quit:
		pending_title_quit = true
		hud.set_title_status("再次选择退出以关闭游戏")
		if audio_director != null:
			audio_director.play_blocked()
		return
	get_tree().quit()


func _request_return_to_title() -> void:
	if not pending_return_to_title:
		pending_return_to_title = true
		hud.set_pause_status("再次选择返回标题，未保存进度会丢失")
		if audio_director != null:
			audio_director.play_blocked()
		return
	_return_to_title()


func _return_to_title() -> void:
	game_started = false
	pending_return_to_title = false
	pending_title_quit = false
	hud.show_title(save_repository.has_save(), "")
	_load_scene(0)
	if audio_director != null:
		audio_director.play_transition()


func _run_menu_smoke() -> bool:
	var failures: Array[String] = []
	_focus_visible_menu()
	if not hud.is_title_visible():
		failures.append("title screen should be visible at boot")
	if not hud.has_menu_focus():
		failures.append("title screen should have keyboard focus")
	if game_started:
		failures.append("game should not be marked started at boot")

	_start_new_game()
	if hud.is_title_visible():
		failures.append("title screen should hide after new game")
	if not game_started:
		failures.append("new game should mark game started")

	_toggle_pause()
	if not hud.is_pause_visible():
		failures.append("pause should open after ESC")
	if not hud.has_menu_focus():
		failures.append("pause menu should have keyboard focus")
	_resume_game()
	if hud.is_pause_visible():
		failures.append("pause should close on resume")

	_open_settings()
	if not hud.is_settings_visible():
		failures.append("settings should open")
	if not hud.has_menu_focus():
		failures.append("settings should have keyboard focus")
	_close_settings()
	if hud.is_settings_visible():
		failures.append("settings should close")
	if hud.is_title_visible():
		failures.append("title should not return when settings closes during game")
	hud.set_settings_master_volume(0.55)
	_set_master_volume(0.55)
	if not is_equal_approx(settings_repository.master_volume_value(), 0.55):
		failures.append("settings should update master volume")

	_toggle_pause()
	_request_return_to_title()
	if hud.is_title_visible():
		failures.append("return-to-title should require confirmation")
	_request_return_to_title()
	if not hud.is_title_visible():
		failures.append("return-to-title should show title after confirmation")
	if game_started:
		failures.append("return-to-title should clear game started")

	_request_title_quit()
	if not hud.is_title_visible():
		failures.append("title quit should require confirmation")

	var ok := failures.is_empty()
	print("menu-flow-smoke status=%s title=%s pause=%s settings=%s" % [
		"PASS" if ok else "FAIL",
		hud.is_title_visible(),
		hud.is_pause_visible(),
		hud.is_settings_visible(),
	])
	for failure in failures:
		print("failure=", failure)
	return ok


func _finish_render_smoke() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var image: Image = get_viewport().get_texture().get_image()
	var ok: bool = _verify_render_image(image)
	get_tree().quit(0 if ok else 1)


func _capture_scene_screenshots() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := _global_capture_path(_arg_value(args, "--capture-output", "user://scene-screenshots"))
	var scene_filter := _arg_value(args, "--capture-scene", "all")
	var scope := _arg_value(args, "--capture-scope", "locations")
	var warmup_frames := maxi(1, int(_arg_value(args, "--capture-warmup-frames", "3")))
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK:
		print("scene-screenshot-capture status=FAIL reason=mkdir path=%s error=%s" % [output_dir, mkdir_error])
		get_tree().quit(1)
		return

	var screenshots: Array[Dictionary] = []
	var failures: Array[String] = []
	for scene_index in range(database.count()):
		var scene_id := str(database.scene_id_at(scene_index))
		if scene_filter != "all" and scene_filter != scene_id:
			continue
		var story_scene: Dictionary = database.scene_at(scene_index)
		var location_ids := _capture_location_ids(story_scene, scope)
		for location_index in range(location_ids.size()):
			var location_id := str(location_ids[location_index])
			var entry := await _capture_location_screenshot(
				scene_index,
				scene_id,
				story_scene,
				location_id,
				location_index,
				output_dir,
				warmup_frames
			)
			if bool(entry.get("ok", false)):
				screenshots.append(entry)
			else:
				failures.append(str(entry.get("failure", "unknown")))

	var manifest := {
		"version": 1,
		"generated_by": "--capture-scene-screenshots",
		"scope": scope,
		"scene_filter": scene_filter,
		"viewport": {
			"width": int(get_viewport_rect().size.x),
			"height": int(get_viewport_rect().size.y),
		},
		"screenshot_count": screenshots.size(),
		"procedural_fallback_count": _capture_asset_status_count(screenshots, "procedural_fallback"),
		"framework_placeholder_count": _capture_asset_status_count(screenshots, "framework_placeholder"),
		"asset_backed_count": _capture_asset_status_count(screenshots, "asset_backed"),
		"screenshots": screenshots,
		"failures": failures,
	}
	var manifest_path := output_dir.path_join("manifest.json")
	var manifest_file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if manifest_file == null:
		print("scene-screenshot-capture status=FAIL reason=manifest path=%s" % manifest_path)
		get_tree().quit(1)
		return
	manifest_file.store_string(JSON.stringify(manifest, "\t"))
	manifest_file.close()

	var ok := failures.is_empty() and not screenshots.is_empty()
	print("scene-screenshot-capture status=%s output=%s screenshots=%s failures=%s" % [
		"PASS" if ok else "FAIL",
		output_dir,
		screenshots.size(),
		failures.size(),
	])
	get_tree().quit(0 if ok else 1)


func _capture_location_screenshot(
	scene_index: int,
	scene_id: String,
	story_scene: Dictionary,
	location_id: String,
	location_index: int,
	output_dir: String,
	warmup_frames: int
) -> Dictionary:
	var locations: Dictionary = story_scene.get("locations", {})
	var location: Dictionary = locations.get(location_id, {})
	if location.is_empty():
		return {"ok": false, "failure": "missing location %s/%s" % [scene_id, location_id]}

	_prepare_capture_state(scene_index, story_scene, location_id, location)
	for _frame in range(warmup_frames):
		await get_tree().process_frame

	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		return {"ok": false, "failure": "empty image %s/%s" % [scene_id, location_id]}

	var filename := "%02d-%s__%02d-%s.png" % [
		scene_index,
		_safe_filename(scene_id),
		location_index,
		_safe_filename(location_id),
	]
	var path := output_dir.path_join(filename)
	var save_error := image.save_png(path)
	if save_error != OK:
		return {"ok": false, "failure": "save failed %s error=%s" % [path, save_error]}

	var visual: Dictionary = visual_repository.location_visual(scene_id, location_id)
	return {
		"ok": true,
		"scene_index": scene_index,
		"scene_id": scene_id,
		"scene_title": str(story_scene.get("title", "")),
		"location_id": location_id,
		"location_name": str(location.get("name", location_id)),
		"terrain": str(visual.get("terrain", "")),
		"visual_family": str(visual.get("visual_family", "")),
		"asset_scene": str(visual.get("asset_scene", "")),
		"asset_status": str(visual.get("asset_status", "")),
		"tileset_id": str(visual.get("tileset_id", "")),
		"props": _capture_prop_summary(visual),
		"path": path,
		"file": filename,
	}


func _prepare_capture_state(scene_index: int, story_scene: Dictionary, location_id: String, location: Dictionary) -> void:
	var event_log: Array[String] = ["开始：%s" % str(story_scene.get("title", ""))]
	if location_id != str(story_scene.get("start", "")):
		event_log.append("前往：%s" % str(location.get("name", location_id)))

	var flags: Array[String] = []
	for flag in story_scene.get("initial_flags", []):
		flags.append(str(flag))

	var combat: Dictionary = location.get("combat", {})
	var state := {
		"scene_index": scene_index,
		"location_id": location_id,
		"flags": flags,
		"metrics": story_scene.get("metrics", {}).duplicate(true),
		"elapsed_seconds": 0,
		"enemy_hp": int(combat.get("enemy_hp", 0)) if not combat.is_empty() else 0,
		"player_hp": 5,
		"name_attempts": 0,
		"attacks_since_name": 0,
		"event_log": event_log,
	}
	session.load_save_data(state)
	player_controller.reset_for_location()
	_refresh_ui()


func _capture_location_ids(story_scene: Dictionary, scope: String) -> Array[String]:
	var start_location := str(story_scene.get("start", ""))
	if scope == "starts":
		return [start_location]

	var locations: Dictionary = story_scene.get("locations", {})
	var location_ids: Array[String] = []
	for location_id in locations.keys():
		location_ids.append(str(location_id))
	location_ids.sort()
	if start_location in location_ids:
		location_ids.erase(start_location)
		location_ids.push_front(start_location)
	return location_ids


func _capture_prop_summary(visual: Dictionary) -> Array[Dictionary]:
	var summary: Array[Dictionary] = []
	for prop in visual.get("props", []):
		if typeof(prop) != TYPE_DICTIONARY:
			continue
		summary.append({
			"kind": str(prop.get("kind", "")),
			"item": str(prop.get("item", "")),
			"exit": str(prop.get("exit", "")),
			"action": str(prop.get("action", "")),
			"x": int(prop.get("x", 0)),
			"y": int(prop.get("y", 0)),
		})
	return summary


func _capture_asset_status_count(screenshots: Array[Dictionary], status: String) -> int:
	var count := 0
	for shot in screenshots:
		if str(shot.get("asset_status", "")) == status:
			count += 1
	return count


func _run_visual_asset_scene_smoke() -> bool:
	var failures: Array[String] = []
	var checked := 0
	var asset_backed := 0
	var placeholders := 0
	for scene_index in range(database.count()):
		var scene_id := str(database.scene_id_at(scene_index))
		var story_scene: Dictionary = database.scene_at(scene_index)
		var locations: Dictionary = story_scene.get("locations", {})
		for location_id_variant in locations.keys():
			var location_id := str(location_id_variant)
			var visual: Dictionary = visual_repository.location_visual(scene_id, location_id)
			checked += 1
			var asset_scene := str(visual.get("asset_scene", ""))
			var asset_status := str(visual.get("asset_status", ""))
			if asset_scene.is_empty():
				failures.append("%s/%s missing asset_scene" % [scene_id, location_id])
				continue
			if asset_status == "procedural_fallback":
				failures.append("%s/%s still marked procedural_fallback" % [scene_id, location_id])
			if _requires_asset_backed_scene(scene_id, location_id) and asset_status != "asset_backed":
				failures.append("%s/%s should be asset_backed, got %s" % [scene_id, location_id, asset_status])
			if asset_status == "asset_backed":
				asset_backed += 1
			elif asset_status == "framework_placeholder":
				placeholders += 1
			if not ResourceLoader.exists(asset_scene):
				failures.append("%s/%s missing PackedScene %s" % [scene_id, location_id, asset_scene])
				continue
			var packed_resource: Resource = load(asset_scene)
			if not (packed_resource is PackedScene):
				failures.append("%s/%s is not a PackedScene: %s" % [scene_id, location_id, asset_scene])
				continue
			var packed_scene := packed_resource as PackedScene
			var instance := packed_scene.instantiate()
			if not (instance is Node):
				failures.append("%s/%s scene root is not a Node" % [scene_id, location_id])
				continue
			var root := instance as Node
			for layer_name in ["ground", "walls", "decor", "props_shadow", "lighting"]:
				var layer := root.get_node_or_null(layer_name)
				if not (layer is TileMapLayer):
					failures.append("%s/%s missing TileMapLayer %s" % [scene_id, location_id, layer_name])
					continue
				if (layer as TileMapLayer).tile_set == null:
					failures.append("%s/%s TileMapLayer %s has no TileSet" % [scene_id, location_id, layer_name])
			root.queue_free()
	var ok := failures.is_empty() and checked > 0
	print("visual-asset-scenes-smoke status=%s checked=%s asset_backed=%s placeholders=%s failures=%s" % [
		"PASS" if ok else "FAIL",
		checked,
		asset_backed,
		placeholders,
		failures.size(),
	])
	for failure in failures:
		print("failure=", failure)
	return ok


func _requires_asset_backed_scene(scene_id: String, location_id: String) -> bool:
	if scene_id == "00-prologue-lights-out":
		return true
	if scene_id == "07-lights-on-again" and location_id in ["home", "school", "street", "store"]:
		return true
	return false


func _global_capture_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path


func _arg_value(args: Array, key: String, default_value: String) -> String:
	for index in range(args.size()):
		var arg := str(args[index])
		if arg == key and index + 1 < args.size():
			return str(args[index + 1])
		if arg.begins_with(key + "="):
			return arg.substr(key.length() + 1)
	return default_value


func _safe_filename(value: String) -> String:
	var safe := value.strip_edges().to_lower()
	for character in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|", " "]:
		safe = safe.replace(character, "_")
	return safe


func _verify_render_image(image: Image) -> bool:
	if image == null:
		print("render-frame-smoke status=FAIL reason=no-image")
		return false

	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		print("render-frame-smoke status=FAIL reason=empty-image size=%sx%s" % [width, height])
		return false

	var step_x: int = int(ceil(float(width) / 48.0))
	var step_y: int = int(ceil(float(height) / 36.0))
	if step_x < 1:
		step_x = 1
	if step_y < 1:
		step_y = 1

	var sampled_count := 0
	var non_dark_count := 0
	var color_keys := {}
	for y in range(0, height, step_y):
		for x in range(0, width, step_x):
			var color: Color = image.get_pixel(x, y)
			sampled_count += 1
			if color.r > 0.08 or color.g > 0.08 or color.b > 0.08:
				non_dark_count += 1
			var key := "%02x%02x%02x" % [
				int(color.r * 255.0) / 32,
				int(color.g * 255.0) / 32,
				int(color.b * 255.0) / 32,
			]
			color_keys[key] = true

	var distinct_count: int = color_keys.size()
	var ok := sampled_count > 0 and non_dark_count >= 16 and distinct_count >= 6
	print("render-frame-smoke status=%s size=%sx%s sampled=%s non_dark=%s distinct=%s" % [
		"PASS" if ok else "FAIL",
		width,
		height,
		sampled_count,
		non_dark_count,
		distinct_count,
	])
	return ok


func _is_smoke_run(args: Array) -> bool:
	for arg in args:
		if str(arg).begins_with("--smoke-"):
			return true
	return false


func _is_action_pressed(event: InputEvent, actions: Array[String]) -> bool:
	for action in actions:
		if event.is_action_pressed(action):
			return true
	return false


func _run_input_map_smoke() -> bool:
	var required := {
		"move_left": true,
		"move_right": true,
		"move_up": true,
		"move_down": true,
		"interact": false,
		"pause": false,
	}
	var missing: Array[String] = []
	for action in required.keys():
		if not InputMap.has_action(action):
			missing.append("%s missing" % action)
			continue
		var has_joypad := false
		var has_motion := false
		for input_event in InputMap.action_get_events(action):
			if input_event is InputEventJoypadButton:
				has_joypad = true
			elif input_event is InputEventJoypadMotion:
				has_motion = true
		if not has_joypad:
			missing.append("%s has no joypad button" % action)
		if required[action] and not has_motion:
			missing.append("%s has no joypad axis" % action)

	var ok := missing.is_empty()
	print("input-map-smoke status=%s actions=%s" % ["PASS" if ok else "FAIL", required.size()])
	for failure in missing:
		print("failure=", failure)
	return ok


func _run_export_config_smoke() -> bool:
	var config := ConfigFile.new()
	var error := config.load("res://export_presets.cfg")
	if error != OK:
		print("export-config-smoke status=FAIL reason=missing-export-presets error=%s" % error)
		return false

	var expected := ["macOS", "Windows Desktop", "Linux/X11"]
	var found: Array[String] = []
	for section in config.get_sections():
		if not str(section).begins_with("preset.") or str(section).ends_with(".options"):
			continue
		var preset_name := str(config.get_value(section, "name", ""))
		if expected.has(preset_name):
			found.append(preset_name)

	var missing: Array[String] = []
	for preset_name in expected:
		if not found.has(preset_name):
			missing.append(preset_name)

	var templates_path := _export_templates_path()
	var templates_installed := DirAccess.dir_exists_absolute(templates_path)
	var branding_missing := _release_branding_missing()
	var ok := missing.is_empty() and branding_missing.is_empty()
	print("export-config-smoke status=%s presets=%s/%s templates=%s branding=%s path=%s" % [
		"PASS" if ok else "FAIL",
		found.size(),
		expected.size(),
		"installed" if templates_installed else "missing",
		"ok" if branding_missing.is_empty() else "missing",
		templates_path,
	])
	if not missing.is_empty():
		print("missing=", missing)
	for failure in branding_missing:
		print("failure=", failure)
	return ok


func _run_release_libraries_smoke() -> bool:
	var expected := {
		"macos": "res://target/release/libdream_coastline.dylib",
		"windows": "res://target/release/dream_coastline.dll",
		"linux": "res://target/release/libdream_coastline.so",
	}
	var missing: Array[String] = []
	for platform in expected.keys():
		var path := str(expected[platform])
		if not FileAccess.file_exists(path):
			missing.append("%s library missing at %s" % [platform, path])

	var ok := missing.is_empty()
	print("release-libraries-smoke status=%s libraries=%s/%s" % [
		"PASS" if ok else "FAIL",
		expected.size() - missing.size(),
		expected.size(),
	])
	for failure in missing:
		print("failure=", failure)
	return ok


func _release_branding_missing() -> Array[String]:
	var missing: Array[String] = []
	var icon_path := str(ProjectSettings.get_setting("application/config/icon", ""))
	var splash_path := str(ProjectSettings.get_setting("application/boot_splash/image", ""))
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	var description := str(ProjectSettings.get_setting("application/config/description", ""))
	if icon_path.is_empty() or not FileAccess.file_exists(icon_path):
		missing.append("application icon missing")
	if splash_path.is_empty() or not FileAccess.file_exists(splash_path):
		missing.append("boot splash image missing")
	if version.is_empty():
		missing.append("application version missing")
	if description.is_empty():
		missing.append("application description missing")
	return missing


func _export_templates_path() -> String:
	var version := Engine.get_version_info()
	var template_version := "%s.%s.%s.%s" % [
		version.get("major", 0),
		version.get("minor", 0),
		version.get("patch", 0),
		version.get("status", "stable"),
	]
	return "%s/Library/Application Support/Godot/export_templates/%s" % [
		OS.get_environment("HOME"),
		template_version,
	]
