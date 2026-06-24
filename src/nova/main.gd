extends Control

const SceneDirectorScript := preload("res://src/nova/scene_director.gd")
const ExplorationViewScript := preload("res://src/nova/world/exploration_view.gd")
const VNLayerScript := preload("res://src/nova/ui/vn_layer.gd")
const DialogicBridgeScript := preload("res://src/nova/dialogic_bridge.gd")
const DialogicVariableBridgeScript := preload("res://src/nova/dialogic_variable_bridge.gd")
const StartupSplashScript := preload("res://src/nova/ui/startup_splash.gd")
const PauseOverlayScript := preload("res://src/nova/ui/pause_overlay.gd")
const SaveRepositoryScript := preload("res://src/nova/data/save_repository.gd")
const AudioDirectorScript := preload("res://scripts/core/audio_director.gd")
const JOYPAD_BUTTON_A := 0
const JOYPAD_BUTTON_B := 1
const JOYPAD_BUTTON_X := 2
const JOYPAD_BUTTON_DPAD_DOWN := 12

var director
var exploration_view
var vn_layer
var dialogic_bridge
var dialogic_variable_bridge
var startup_splash
var pause_overlay
var save_repository
var audio_director
var _dialogic_runtime_finished := false
var _dialogic_runtime_payload: Dictionary = {}
var _dialogic_runtime_started_with_dialogic := false
var _manual_route_attack_attempts: Dictionary = {}
var _latest_cutscene_payload: Dictionary = {}
var _suppress_runtime_dialogic := false
var _quit_requested := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	director = SceneDirectorScript.new()
	director.name = "SceneDirector"
	add_child(director)

	save_repository = SaveRepositoryScript.new()
	save_repository.configure(_nova_save_path())

	audio_director = AudioDirectorScript.new()
	audio_director.name = "AudioDirector"
	audio_director.enabled = not _is_automation_run()
	add_child(audio_director)

	exploration_view = ExplorationViewScript.new()
	exploration_view.name = "ExplorationView"
	exploration_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exploration_view.inspect_requested.connect(_inspect_item)
	exploration_view.move_requested.connect(_move_to)
	exploration_view.choice_requested.connect(_choose_location_choice)
	exploration_view.story_action_requested.connect(_perform_story_action)
	add_child(exploration_view)

	vn_layer = VNLayerScript.new()
	vn_layer.name = "VNLayer"
	vn_layer.accepted.connect(_finish_cutscene)
	add_child(vn_layer)

	dialogic_bridge = DialogicBridgeScript.new()
	dialogic_bridge.name = "DialogicBridge"
	dialogic_bridge.finished.connect(_finish_cutscene)
	add_child(dialogic_bridge)

	dialogic_variable_bridge = DialogicVariableBridgeScript.new()
	dialogic_variable_bridge.name = "DialogicVariableBridge"
	add_child(dialogic_variable_bridge)
	dialogic_bridge.variable_bridge = dialogic_variable_bridge

	pause_overlay = PauseOverlayScript.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.resume_requested.connect(_resume_from_pause)
	pause_overlay.save_requested.connect(_save_from_pause)
	pause_overlay.title_requested.connect(_return_to_title_from_pause)
	pause_overlay.quit_requested.connect(_quit_from_pause)
	add_child(pause_overlay)

	if not _is_automation_run():
		startup_splash = StartupSplashScript.new()
		startup_splash.name = "StartupSplash"
		startup_splash.configure_continue(save_repository.has_save())
		startup_splash.dismissed.connect(_on_splash_dismissed)
		startup_splash.continue_requested.connect(_on_splash_continue_requested)
		add_child(startup_splash)

	director.location_presented.connect(_present_location)
	director.cutscene_started.connect(_show_cutscene)
	director.runtime_error.connect(_runtime_error)

	if not director.boot():
		get_tree().quit(1)
		return
	if OS.get_cmdline_user_args().has("--smoke-nova-runtime"):
		call_deferred("_run_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-progression"):
		call_deferred("_run_progression_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-choices"):
		call_deferred("_run_choice_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-all-scenes"):
		call_deferred("_run_all_scenes_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-manual-route"):
		call_deferred("_run_manual_route_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-ui-manual-route"):
		call_deferred("_run_ui_manual_route_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-mouse-route"):
		call_deferred("_run_mouse_route_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-keyboard-route"):
		call_deferred("_run_keyboard_route_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-gamepad-route"):
		call_deferred("_run_gamepad_route_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-save-continue"):
		call_deferred("_run_save_continue_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-gamepad-continue"):
		call_deferred("_run_gamepad_continue_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-pause-flow"):
		call_deferred("_run_pause_flow_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-gamepad-pause-flow"):
		call_deferred("_run_gamepad_pause_flow_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-player-quit"):
		call_deferred("_run_player_quit_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-assets"):
		call_deferred("_run_asset_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-story-audio-targets"):
		call_deferred("_run_story_audio_targets_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-dialogic-bridge"):
		call_deferred("_run_dialogic_bridge_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-nova-keyboard-dialogic"):
		call_deferred("_run_keyboard_dialogic_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-export-config"):
		call_deferred("_run_export_config_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-release-libraries"):
		call_deferred("_run_release_libraries_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-dialogic-runtime"):
		call_deferred("_run_dialogic_runtime_smoke")
	elif OS.get_cmdline_user_args().has("--capture-scene-screenshots"):
		call_deferred("_capture_scene_screenshots")
	elif OS.get_cmdline_user_args().has("--capture-nova-screenshot"):
		call_deferred("_capture_screenshot")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_player_quit(0)


func _unhandled_input(event: InputEvent) -> void:
	if startup_splash != null and startup_splash.visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if pause_overlay != null and pause_overlay.visible:
			_resume_from_pause()
		elif GameMode.current_mode == GameMode.EXPLORATION:
			_open_pause()
		get_viewport().set_input_as_handled()


func _present_location(scene_id: String, location_id: String, location: Dictionary, visual: Dictionary) -> void:
	exploration_view.present(scene_id, location_id, location, visual, director.build_location_choices())
	if audio_director != null:
		audio_director.sync_story_context(scene_id, location_id)


func _inspect_item(item_id: String) -> void:
	if audio_director != null:
		audio_director.play_interact()
	director.inspect_item(item_id)


func _move_to(location_id: String) -> void:
	if director.move_to(location_id):
		if audio_director != null:
			audio_director.play_step()
		_save_current_state()


func _choose_location_choice(choice_id: String) -> void:
	if audio_director != null:
		audio_director.play_ui()
	director.choose_location_choice(choice_id)


func _perform_story_action(action_type: String, action_id: String) -> void:
	if audio_director != null:
		audio_director.play_ui()
	director.perform_story_action(action_type, action_id)


func _show_cutscene(payload: Dictionary) -> void:
	_latest_cutscene_payload = payload.duplicate(true)
	var backdrop_path: String = director.visual_repository.get_backdrop_path(GameState.current_scene_id, GameState.current_location_id)
	if audio_director != null:
		audio_director.play_story_voice_for_text(GameState.current_scene_id, str(payload.get("text", "")))
	if not _suppress_runtime_dialogic and dialogic_bridge.play_payload(payload, backdrop_path):
		return
	else:
		vn_layer.show_payload(payload, backdrop_path)


func _finish_cutscene(payload: Dictionary) -> void:
	director.finish_cutscene(payload)
	_save_current_state()


func _runtime_error(message: String) -> void:
	push_warning(message)


func _on_splash_dismissed() -> void:
	if audio_director != null:
		audio_director.play_ui()
	_save_current_state()


func _on_splash_continue_requested() -> void:
	if audio_director != null:
		audio_director.play_ui()
	if not _restore_saved_game():
		_save_current_state()


func _open_pause() -> void:
	if pause_overlay == null:
		return
	GameMode.set_mode(GameMode.MENU)
	pause_overlay.set_status("")
	pause_overlay.open()
	if audio_director != null:
		audio_director.play_ui()


func _resume_from_pause() -> void:
	if pause_overlay != null:
		pause_overlay.close()
	GameMode.set_mode(GameMode.EXPLORATION)
	if audio_director != null:
		audio_director.play_ui()


func _save_from_pause() -> void:
	_save_current_state()
	if pause_overlay != null:
		pause_overlay.set_status("已保存")
	if audio_director != null:
		audio_director.play_ui()


func _return_to_title_from_pause() -> void:
	_save_current_state()
	if pause_overlay != null:
		pause_overlay.close()
	_reset_to_first_scene()
	GameMode.set_mode(GameMode.MENU)
	if not _is_automation_run():
		_show_startup_splash()
	if audio_director != null:
		audio_director.play_ui()


func _quit_from_pause() -> void:
	_request_player_quit(0)


func _request_player_quit(exit_code: int = 0) -> void:
	if _quit_requested:
		return
	_quit_requested = true
	_save_current_state()
	call_deferred("_quit_after_runtime_shutdown", exit_code)


func _quit_after_runtime_shutdown(exit_code: int = 0) -> void:
	await _shutdown_runtime()
	get_tree().quit(exit_code)


func _shutdown_runtime() -> void:
	if dialogic_bridge != null and dialogic_bridge.has_method("shutdown"):
		dialogic_bridge.shutdown()
	if dialogic_variable_bridge != null and dialogic_variable_bridge.has_method("shutdown"):
		dialogic_variable_bridge.shutdown()
	var dialogic := get_node_or_null("/root/Dialogic")
	if dialogic != null:
		if dialogic.has_method("clear"):
			await dialogic.clear()
		var parent := dialogic.get_parent()
		if parent != null:
			parent.remove_child(dialogic)
		dialogic.free()
	await get_tree().process_frame


func _show_startup_splash() -> void:
	if startup_splash != null:
		startup_splash.queue_free()
	startup_splash = StartupSplashScript.new()
	startup_splash.name = "StartupSplash"
	startup_splash.configure_continue(save_repository != null and save_repository.has_save())
	startup_splash.dismissed.connect(_on_splash_dismissed)
	startup_splash.continue_requested.connect(_on_splash_continue_requested)
	add_child(startup_splash)


func _reset_to_first_scene() -> void:
	StoryFlags.reset()
	var first_scene: String = director.story_repository.first_scene_id()
	GameState.start_scene(first_scene, director.story_repository.get_start_location(first_scene))
	for flag in director.story_repository.get_initial_flags(first_scene):
		StoryFlags.set_flag(str(flag), true)
	_restore_quest_status(first_scene)
	director.present_current_location()


func _save_current_state() -> void:
	if save_repository == null or not _can_write_save():
		return
	save_repository.save_game(
		GameState.current_scene_id,
		GameState.current_location_id,
		StoryFlags.export_flags(),
	)


func _restore_saved_game() -> bool:
	if save_repository == null or not save_repository.has_save():
		return false
	var saved: Dictionary = save_repository.load_game()
	var scene_id := str(saved.get("scene_id", ""))
	var location_id := str(saved.get("location_id", ""))
	if scene_id.is_empty() or location_id.is_empty():
		return false
	if director.story_repository.get_location(scene_id, location_id).is_empty():
		return false
	StoryFlags.import_flags(saved.get("flags", []))
	GameState.start_scene(scene_id, location_id)
	_restore_quest_status(scene_id)
	director.present_current_location()
	return true


func _restore_quest_status(active_scene_id: String) -> void:
	QuestState.reset()
	var scene_ids: Array = director.story_repository.scene_ids()
	var active_index := scene_ids.find(active_scene_id)
	for index in range(scene_ids.size()):
		var scene_id := str(scene_ids[index])
		var scene: Dictionary = director.story_repository.get_scene(scene_id)
		QuestState.ensure_quest(scene_id, str(scene.get("title", scene_id)))
		if active_index != -1 and index < active_index:
			QuestState.set_status(scene_id, QuestState.COMPLETE)
		elif scene_id == active_scene_id:
			QuestState.set_status(scene_id, QuestState.ACTIVE)


func _can_write_save() -> bool:
	var args := OS.get_cmdline_user_args()
	return (
		args.has("--smoke-nova-save-continue")
		or args.has("--smoke-nova-gamepad-continue")
		or args.has("--smoke-nova-pause-flow")
		or args.has("--smoke-nova-gamepad-pause-flow")
		or not _is_automation_run()
	)


func _nova_save_path() -> String:
	var args := OS.get_cmdline_user_args()
	if args.has("--smoke-nova-save-continue"):
		return "user://nova_save_smoke.json"
	if args.has("--smoke-nova-gamepad-continue"):
		return "user://nova_gamepad_continue_smoke.json"
	if args.has("--smoke-nova-pause-flow"):
		return "user://nova_pause_smoke.json"
	if args.has("--smoke-nova-gamepad-pause-flow"):
		return "user://nova_gamepad_pause_smoke.json"
	return _arg_value(args, "--nova-save-path", SaveRepositoryScript.DEFAULT_SAVE_PATH)


func _run_smoke() -> void:
	var scene_id := GameState.current_scene_id
	var location_id := GameState.current_location_id
	var location: Dictionary = director.story_repository.get_location(scene_id, location_id)
	var items: Dictionary = director.story_repository.get_items(scene_id, location_id)
	var exits: Dictionary = director.story_repository.get_exits(scene_id, location_id)
	var ok: bool = not scene_id.is_empty() and not location_id.is_empty() and not location.is_empty()
	ok = ok and director.story_repository.scene_ids().size() >= 8
	ok = ok and not items.is_empty()
	ok = ok and not exits.is_empty()
	var first_item := ""
	for item_id in items.keys():
		first_item = str(item_id)
		break
	if ok and not first_item.is_empty():
		ok = director.inspect_item(first_item)
		_finish_cutscene({
			"flags": items[first_item].get("flags", []),
		})
		var flags: Array = items[first_item].get("flags", [])
		if not flags.is_empty():
			ok = ok and StoryFlags.has_flag(str(flags[0]))
	print("nova-runtime-smoke status=%s scene=%s location=%s item=%s" % ["PASS" if ok else "FAIL", scene_id, location_id, first_item])
	get_tree().quit(0 if ok else 1)


func _run_progression_smoke() -> void:
	var ok := true
	ok = ok and _smoke_inspect("window")
	ok = ok and _smoke_move("building")
	ok = ok and _smoke_move("home")
	ok = ok and _smoke_inspect("lock")
	ok = ok and _smoke_move("living_room")
	ok = ok and _smoke_inspect("dinner")
	ok = ok and _smoke_inspect("photo")
	ok = ok and _smoke_move("study")
	ok = ok and _smoke_inspect("glasses")
	ok = ok and _smoke_inspect("note")
	ok = ok and _smoke_inspect("phone")
	ok = ok and _smoke_move("living_room")
	ok = ok and _smoke_move("bedroom")
	ok = ok and _smoke_inspect("letter")
	ok = ok and _smoke_inspect("pen")

	var required_flags: Array = director.story_repository.get_required_flags(GameState.current_scene_id)
	ok = ok and StoryFlags.has_flag("entered_moqi")
	ok = ok and GameState.current_scene_id == "01-illiterate"
	ok = ok and GameState.current_location_id == director.story_repository.get_start_location("01-illiterate")
	print("nova-progression-smoke status=%s scene=%s location=%s flags=%s" % [
		"PASS" if ok else "FAIL",
		GameState.current_scene_id,
		GameState.current_location_id,
		StoryFlags.export_flags().keys().size(),
	])
	get_tree().quit(0 if ok else 1)


func _run_choice_smoke() -> void:
	StoryFlags.reset()
	GameState.start_scene("03-dead-kingdom", "library")
	for flag in director.story_repository.get_initial_flags("03-dead-kingdom"):
		StoryFlags.set_flag(str(flag), true)
	StoryFlags.set_flag("found_reform_records", true)
	director.present_current_location()
	var choices: Array[Dictionary] = director.build_location_choices()
	var has_public_choice: bool = choices.any(func(choice: Dictionary) -> bool:
		return str(choice.get("type", "")) == "choice" and str(choice.get("id", "")) == "public" and bool(choice.get("enabled", false))
	)
	var ok: bool = has_public_choice and director.choose_location_choice("public")
	_finish_cutscene({
		"flags": ["chose_public_books", "resolved_book_route"],
	})
	var after_choices: Array[Dictionary] = director.build_location_choices()
	var disabled_after_resolve: bool = after_choices.any(func(choice: Dictionary) -> bool:
		return str(choice.get("type", "")) == "choice" and str(choice.get("id", "")) == "royal" and not bool(choice.get("enabled", true))
	)
	ok = ok and StoryFlags.has_flag("chose_public_books")
	ok = ok and StoryFlags.has_flag("resolved_book_route")
	ok = ok and disabled_after_resolve
	ok = ok and DialogicBridgeScript.resolve_choice_timeline_path("03-dead-kingdom", "library", "public").ends_with("library_choice_public.dtl")
	print("nova-choice-smoke status=%s scene=%s location=%s resolved=%s" % [
		"PASS" if ok else "FAIL",
		GameState.current_scene_id,
		GameState.current_location_id,
		str(StoryFlags.has_flag("resolved_book_route")),
	])
	get_tree().quit(0 if ok else 1)


func _run_save_continue_smoke() -> void:
	if save_repository != null:
		save_repository.clear()
	StoryFlags.reset()
	var first_scene: String = director.story_repository.first_scene_id()
	GameState.start_scene(first_scene, director.story_repository.get_start_location(first_scene))
	for flag in director.story_repository.get_initial_flags(first_scene):
		StoryFlags.set_flag(str(flag), true)
	_restore_quest_status(first_scene)
	director.present_current_location()

	var ok := _smoke_inspect("window")
	ok = ok and director.move_to("building")
	if ok:
		_save_current_state()
	ok = ok and save_repository != null and save_repository.has_save()
	var saved: Dictionary = save_repository.load_game() if save_repository != null else {}
	ok = ok and str(saved.get("scene_id", "")) == "00-prologue-lights-out"
	ok = ok and str(saved.get("location_id", "")) == "building"

	StoryFlags.reset()
	GameState.start_scene("03-dead-kingdom", "library")
	_restore_quest_status("03-dead-kingdom")
	director.present_current_location()
	ok = ok and _restore_saved_game()
	ok = ok and GameState.current_scene_id == "00-prologue-lights-out"
	ok = ok and GameState.current_location_id == "building"
	ok = ok and StoryFlags.has_flag("noticed_dark_window")
	if save_repository != null:
		save_repository.clear()
	print("nova-save-continue-smoke status=%s scene=%s location=%s flag=%s" % [
		"PASS" if ok else "FAIL",
		GameState.current_scene_id,
		GameState.current_location_id,
		str(StoryFlags.has_flag("noticed_dark_window")),
	])
	get_tree().quit(0 if ok else 1)


func _run_gamepad_continue_smoke() -> void:
	if save_repository != null:
		save_repository.clear()
	StoryFlags.reset()
	var first_scene: String = director.story_repository.first_scene_id()
	GameState.start_scene(first_scene, director.story_repository.get_start_location(first_scene))
	for flag in director.story_repository.get_initial_flags(first_scene):
		StoryFlags.set_flag(str(flag), true)
	_restore_quest_status(first_scene)
	director.present_current_location()

	var ok := _smoke_inspect("window")
	ok = ok and director.move_to("building")
	if ok:
		_save_current_state()
	var saved: Dictionary = save_repository.load_game() if save_repository != null else {}
	ok = ok and str(saved.get("scene_id", "")) == "00-prologue-lights-out"
	ok = ok and str(saved.get("location_id", "")) == "building"

	GameState.start_scene("03-dead-kingdom", "library")
	_restore_quest_status("03-dead-kingdom")
	director.present_current_location()
	if startup_splash != null:
		startup_splash.queue_free()
	startup_splash = StartupSplashScript.new()
	startup_splash.name = "StartupSplash"
	startup_splash.continue_requested.connect(_on_splash_continue_requested)
	add_child(startup_splash)
	await get_tree().process_frame
	startup_splash.configure_continue(true)
	startup_splash._timer = 2.0
	var continue_event := _joypad_button_event(JOYPAD_BUTTON_X)
	var event_matches: bool = startup_splash._is_continue_event(continue_event)
	if not event_matches:
		push_warning("Nova gamepad continue smoke event did not match continue_game")
	var handled: bool = event_matches and startup_splash.handle_startup_input(continue_event)
	if not handled:
		push_warning("Nova gamepad continue smoke did not handle startup input")

	ok = ok and handled
	ok = ok and GameState.current_scene_id == "00-prologue-lights-out"
	ok = ok and GameState.current_location_id == "building"
	ok = ok and StoryFlags.has_flag("noticed_dark_window")
	if save_repository != null:
		save_repository.clear()
	print("nova-gamepad-continue-smoke status=%s scene=%s location=%s flag=%s" % [
		"PASS" if ok else "FAIL",
		GameState.current_scene_id,
		GameState.current_location_id,
		str(StoryFlags.has_flag("noticed_dark_window")),
	])
	get_tree().quit(0 if ok else 1)


func _run_pause_flow_smoke() -> void:
	if save_repository != null:
		save_repository.clear()
	_reset_to_first_scene()
	GameMode.set_mode(GameMode.EXPLORATION)

	_open_pause()
	var ok: bool = pause_overlay != null and pause_overlay.visible and GameMode.current_mode == GameMode.MENU
	_save_from_pause()
	ok = ok and save_repository != null and save_repository.has_save()
	var saved: Dictionary = save_repository.load_game() if save_repository != null else {}
	ok = ok and str(saved.get("scene_id", "")) == "00-prologue-lights-out"
	ok = ok and str(saved.get("location_id", "")) == "street"

	_resume_from_pause()
	ok = ok and pause_overlay != null and not pause_overlay.visible and GameMode.current_mode == GameMode.EXPLORATION

	_open_pause()
	_return_to_title_from_pause()
	ok = ok and pause_overlay != null and not pause_overlay.visible
	ok = ok and GameMode.current_mode == GameMode.MENU
	ok = ok and GameState.current_scene_id == director.story_repository.first_scene_id()
	ok = ok and GameState.current_location_id == director.story_repository.get_start_location(GameState.current_scene_id)
	if save_repository != null:
		save_repository.clear()
	print("nova-pause-flow-smoke status=%s scene=%s location=%s mode=%s" % [
		"PASS" if ok else "FAIL",
		GameState.current_scene_id,
		GameState.current_location_id,
		GameMode.current_mode,
	])
	get_tree().quit(0 if ok else 1)


func _run_gamepad_pause_flow_smoke() -> void:
	if save_repository != null:
		save_repository.clear()
	_reset_to_first_scene()
	GameMode.set_mode(GameMode.EXPLORATION)

	_unhandled_input(_joypad_button_event(JOYPAD_BUTTON_B))
	var ok: bool = pause_overlay != null and pause_overlay.visible and GameMode.current_mode == GameMode.MENU
	if ok:
		pause_overlay._input(_joypad_button_event(JOYPAD_BUTTON_DPAD_DOWN))
		pause_overlay._input(_joypad_button_event(JOYPAD_BUTTON_A))
	ok = ok and pause_overlay != null and pause_overlay.visible
	ok = ok and save_repository != null and save_repository.has_save()
	var saved: Dictionary = save_repository.load_game() if save_repository != null else {}
	ok = ok and str(saved.get("scene_id", "")) == "00-prologue-lights-out"
	ok = ok and str(saved.get("location_id", "")) == "street"

	if ok:
		pause_overlay._input(_joypad_button_event(JOYPAD_BUTTON_B))
	ok = ok and pause_overlay != null and not pause_overlay.visible and GameMode.current_mode == GameMode.EXPLORATION

	if ok:
		_unhandled_input(_joypad_button_event(JOYPAD_BUTTON_B))
		pause_overlay._input(_joypad_button_event(JOYPAD_BUTTON_DPAD_DOWN))
		pause_overlay._input(_joypad_button_event(JOYPAD_BUTTON_DPAD_DOWN))
		pause_overlay._input(_joypad_button_event(JOYPAD_BUTTON_A))
	ok = ok and pause_overlay != null and not pause_overlay.visible
	ok = ok and GameMode.current_mode == GameMode.MENU
	ok = ok and GameState.current_scene_id == director.story_repository.first_scene_id()
	ok = ok and GameState.current_location_id == director.story_repository.get_start_location(GameState.current_scene_id)
	if save_repository != null:
		save_repository.clear()
	print("nova-gamepad-pause-flow-smoke status=%s saved=%s scene=%s location=%s mode=%s" % [
		"PASS" if ok else "FAIL",
		str(not saved.is_empty()),
		GameState.current_scene_id,
		GameState.current_location_id,
		GameMode.current_mode,
	])
	get_tree().quit(0 if ok else 1)


func _run_player_quit_smoke() -> void:
	if save_repository != null:
		save_repository.clear()
	_reset_to_first_scene()
	GameMode.set_mode(GameMode.EXPLORATION)
	_open_pause()
	var ok: bool = pause_overlay != null and pause_overlay.visible and GameMode.current_mode == GameMode.MENU
	print("nova-player-quit-smoke status=%s scene=%s location=%s mode=%s" % [
		"PASS" if ok else "FAIL",
		GameState.current_scene_id,
		GameState.current_location_id,
		GameMode.current_mode,
	])
	_request_player_quit(0 if ok else 1)


func _smoke_move(location_id: String) -> bool:
	return director.move_to(location_id)


func _smoke_inspect(item_id: String) -> bool:
	var scene_id := GameState.current_scene_id
	var location_id := GameState.current_location_id
	var items: Dictionary = director.story_repository.get_items(scene_id, location_id)
	if not items.has(item_id):
		push_warning("Progression smoke missing item %s at %s/%s" % [item_id, scene_id, location_id])
		return false
	var ok: bool = director.inspect_item(item_id)
	if not ok:
		return false
	var item: Dictionary = items[item_id]
	_finish_cutscene({
		"flags": item.get("flags", []),
	})
	return true


func _run_all_scenes_smoke() -> void:
	StoryFlags.reset()
	var first_scene: String = director.story_repository.first_scene_id()
	GameState.start_scene(first_scene, director.story_repository.get_start_location(first_scene))
	for flag in director.story_repository.get_initial_flags(first_scene):
		StoryFlags.set_flag(str(flag), true)
	director.present_current_location()

	var ok := true
	var completed: Array[String] = []
	var scene_guard := 0
	while ok and scene_guard < 16:
		scene_guard += 1
		var scene_id: String = GameState.current_scene_id
		if scene_id.is_empty():
			ok = false
			break
		if not _smoke_complete_current_scene(scene_id):
			ok = false
			break
		completed.append(scene_id)
		if director.story_repository.next_scene_id(scene_id).is_empty():
			break

	ok = ok and completed.size() == director.story_repository.scene_ids().size()
	ok = ok and GameState.current_scene_id == director.story_repository.scene_ids().back()
	ok = ok and StoryFlags.has_all(director.story_repository.get_required_flags(GameState.current_scene_id))
	print("nova-all-scenes-smoke status=%s scenes=%s flags=%s current=%s/%s" % [
		"PASS" if ok else "FAIL",
		completed.size(),
		StoryFlags.export_flags().keys().size(),
		GameState.current_scene_id,
		GameState.current_location_id,
	])
	get_tree().quit(0 if ok else 1)


func _run_manual_route_smoke() -> void:
	StoryFlags.reset()
	_manual_route_attack_attempts.clear()
	var scene_ids: Array[String] = director.story_repository.scene_ids()
	var first_scene: String = director.story_repository.first_scene_id()
	GameState.start_scene(first_scene, director.story_repository.get_start_location(first_scene))
	for flag in director.story_repository.get_initial_flags(first_scene):
		StoryFlags.set_flag(str(flag), true)
	director.present_current_location()

	var ok := true
	var command_count := 0
	var completed: Array[String] = []
	for scene_id in scene_ids:
		if not ok:
			break
		if GameState.current_scene_id != scene_id:
			push_warning("Nova manual-route smoke expected scene %s but got %s" % [scene_id, GameState.current_scene_id])
			ok = false
			break
		var scene: Dictionary = director.story_repository.get_scene(scene_id)
		var commands: Array = scene.get("walkthrough", [])
		for raw_command in commands:
			var command := str(raw_command)
			command_count += 1
			if not _manual_route_command(scene_id, command):
				push_warning("Nova manual-route smoke failed command %s at %s/%s" % [
					command,
					GameState.current_scene_id,
					GameState.current_location_id,
				])
				ok = false
				break
		if ok and not StoryFlags.has_all(director.story_repository.get_required_flags(scene_id)):
			push_warning("Nova manual-route smoke missing required flag %s for %s" % [
				_smoke_first_missing(director.story_repository.get_required_flags(scene_id)),
				scene_id,
			])
			ok = false
		if ok:
			completed.append(scene_id)

	ok = ok and completed.size() == scene_ids.size()
	print("nova-manual-route-smoke status=%s scenes=%s commands=%s flags=%s current=%s/%s" % [
		"PASS" if ok else "FAIL",
		completed.size(),
		command_count,
		StoryFlags.export_flags().keys().size(),
		GameState.current_scene_id,
		GameState.current_location_id,
	])
	get_tree().quit(0 if ok else 1)


func _run_ui_manual_route_smoke() -> void:
	StoryFlags.reset()
	_manual_route_attack_attempts.clear()
	_latest_cutscene_payload = {}
	var scene_ids: Array[String] = director.story_repository.scene_ids()
	var first_scene: String = director.story_repository.first_scene_id()
	GameState.start_scene(first_scene, director.story_repository.get_start_location(first_scene))
	for flag in director.story_repository.get_initial_flags(first_scene):
		StoryFlags.set_flag(str(flag), true)
	_restore_quest_status(first_scene)
	director.present_current_location()

	var ok := true
	var command_count := 0
	var completed: Array[String] = []
	for scene_id in scene_ids:
		if not ok:
			break
		if GameState.current_scene_id != scene_id:
			push_warning("Nova UI route smoke expected scene %s but got %s" % [scene_id, GameState.current_scene_id])
			ok = false
			break
		var scene: Dictionary = director.story_repository.get_scene(scene_id)
		var commands: Array = scene.get("walkthrough", [])
		for raw_command in commands:
			var command := str(raw_command)
			command_count += 1
			if not _ui_route_command(command):
				push_warning("Nova UI route smoke failed command %s at %s/%s choices=%s" % [
					command,
					GameState.current_scene_id,
					GameState.current_location_id,
					", ".join(exploration_view.current_choice_labels()),
				])
				ok = false
				break
		if ok and not StoryFlags.has_all(director.story_repository.get_required_flags(scene_id)):
			push_warning("Nova UI route smoke missing required flag %s for %s" % [
				_smoke_first_missing(director.story_repository.get_required_flags(scene_id)),
				scene_id,
			])
			ok = false
		if ok:
			completed.append(scene_id)

	ok = ok and completed.size() == scene_ids.size()
	print("nova-ui-manual-route-smoke status=%s scenes=%s commands=%s flags=%s current=%s/%s" % [
		"PASS" if ok else "FAIL",
		completed.size(),
		command_count,
		StoryFlags.export_flags().keys().size(),
		GameState.current_scene_id,
		GameState.current_location_id,
	])
	get_tree().quit(0 if ok else 1)


func _run_keyboard_route_smoke() -> void:
	StoryFlags.reset()
	_manual_route_attack_attempts.clear()
	_latest_cutscene_payload = {}
	var scene_ids: Array[String] = director.story_repository.scene_ids()
	var first_scene: String = director.story_repository.first_scene_id()
	GameState.start_scene(first_scene, director.story_repository.get_start_location(first_scene))
	for flag in director.story_repository.get_initial_flags(first_scene):
		StoryFlags.set_flag(str(flag), true)
	_restore_quest_status(first_scene)
	director.present_current_location()

	var ok := true
	var command_count := 0
	var completed: Array[String] = []
	for scene_id in scene_ids:
		if not ok:
			break
		if GameState.current_scene_id != scene_id:
			push_warning("Nova keyboard route smoke expected scene %s but got %s" % [scene_id, GameState.current_scene_id])
			ok = false
			break
		var scene: Dictionary = director.story_repository.get_scene(scene_id)
		var commands: Array = scene.get("walkthrough", [])
		for raw_command in commands:
			var command := str(raw_command)
			command_count += 1
			if not _keyboard_route_command(command):
				push_warning("Nova keyboard route smoke failed command %s at %s/%s selected=%s choices=%s" % [
					command,
					GameState.current_scene_id,
					GameState.current_location_id,
					exploration_view.selected_choice_index(),
					", ".join(exploration_view.current_choice_labels()),
				])
				ok = false
				break
		if ok and not StoryFlags.has_all(director.story_repository.get_required_flags(scene_id)):
			push_warning("Nova keyboard route smoke missing required flag %s for %s" % [
				_smoke_first_missing(director.story_repository.get_required_flags(scene_id)),
				scene_id,
			])
			ok = false
		if ok:
			completed.append(scene_id)

	ok = ok and completed.size() == scene_ids.size()
	print("nova-keyboard-route-smoke status=%s scenes=%s commands=%s flags=%s current=%s/%s" % [
		"PASS" if ok else "FAIL",
		completed.size(),
		command_count,
		StoryFlags.export_flags().keys().size(),
		GameState.current_scene_id,
		GameState.current_location_id,
	])
	get_tree().quit(0 if ok else 1)


func _run_mouse_route_smoke() -> void:
	StoryFlags.reset()
	_manual_route_attack_attempts.clear()
	_latest_cutscene_payload = {}
	var scene_ids: Array[String] = director.story_repository.scene_ids()
	var first_scene: String = director.story_repository.first_scene_id()
	GameState.start_scene(first_scene, director.story_repository.get_start_location(first_scene))
	for flag in director.story_repository.get_initial_flags(first_scene):
		StoryFlags.set_flag(str(flag), true)
	_restore_quest_status(first_scene)
	director.present_current_location()

	var ok := true
	var command_count := 0
	var completed: Array[String] = []
	for scene_id in scene_ids:
		if not ok:
			break
		if GameState.current_scene_id != scene_id:
			push_warning("Nova mouse route smoke expected scene %s but got %s" % [scene_id, GameState.current_scene_id])
			ok = false
			break
		var scene: Dictionary = director.story_repository.get_scene(scene_id)
		var commands: Array = scene.get("walkthrough", [])
		for raw_command in commands:
			var command := str(raw_command)
			command_count += 1
			if not _mouse_route_command(command):
				push_warning("Nova mouse route smoke failed command %s at %s/%s selected=%s choices=%s" % [
					command,
					GameState.current_scene_id,
					GameState.current_location_id,
					exploration_view.selected_choice_index(),
					", ".join(exploration_view.current_choice_labels()),
				])
				ok = false
				break
		if ok and not StoryFlags.has_all(director.story_repository.get_required_flags(scene_id)):
			push_warning("Nova mouse route smoke missing required flag %s for %s" % [
				_smoke_first_missing(director.story_repository.get_required_flags(scene_id)),
				scene_id,
			])
			ok = false
		if ok:
			completed.append(scene_id)

	ok = ok and completed.size() == scene_ids.size()
	print("nova-mouse-route-smoke status=%s scenes=%s commands=%s flags=%s current=%s/%s" % [
		"PASS" if ok else "FAIL",
		completed.size(),
		command_count,
		StoryFlags.export_flags().keys().size(),
		GameState.current_scene_id,
		GameState.current_location_id,
	])
	get_tree().quit(0 if ok else 1)


func _mouse_route_command(command: String) -> bool:
	var expected := _ui_route_expected_choice(command)
	if expected.is_empty():
		push_warning("Nova mouse route smoke cannot map command: %s" % command)
		return false
	var choice_type := str(expected.get("type", ""))
	var choice_id := str(expected.get("id", ""))
	var action_type := str(expected.get("action_type", ""))
	if not exploration_view.has_enabled_choice(choice_type, choice_id, action_type):
		return false
	var target_index: int = exploration_view.choice_index_for(choice_type, choice_id, action_type)
	if target_index < 0:
		return false
	_latest_cutscene_payload = {}
	if not exploration_view.click_choice(choice_type, choice_id, action_type):
		return false
	return _finish_ui_route_payload_if_needed()


func _keyboard_route_command(command: String) -> bool:
	var expected := _ui_route_expected_choice(command)
	if expected.is_empty():
		push_warning("Nova keyboard route smoke cannot map command: %s" % command)
		return false
	var choice_type := str(expected.get("type", ""))
	var choice_id := str(expected.get("id", ""))
	var action_type := str(expected.get("action_type", ""))
	if not exploration_view.has_enabled_choice(choice_type, choice_id, action_type):
		return false
	var target_index: int = exploration_view.choice_index_for(choice_type, choice_id, action_type)
	if target_index < 0:
		return false
	var guard: int = exploration_view.current_choice_labels().size() + 2
	while exploration_view.selected_choice_index() != target_index and guard > 0:
		exploration_view._input(_action_event("ui_down"))
		guard -= 1
	if exploration_view.selected_choice_index() != target_index:
		return false
	_latest_cutscene_payload = {}
	exploration_view._input(_action_event("ui_accept"))
	return _advance_keyboard_route_payload()


func _advance_keyboard_route_payload() -> bool:
	var guard := 64
	while GameMode.current_mode != GameMode.EXPLORATION and guard > 0:
		if vn_layer.visible:
			vn_layer._input(_action_event("ui_accept"))
		elif not _latest_cutscene_payload.is_empty():
			_finish_cutscene(_latest_cutscene_payload)
			_latest_cutscene_payload = {}
		else:
			return false
		guard -= 1
	return GameMode.current_mode == GameMode.EXPLORATION


func _run_gamepad_route_smoke() -> void:
	StoryFlags.reset()
	_manual_route_attack_attempts.clear()
	_latest_cutscene_payload = {}
	var scene_ids: Array[String] = director.story_repository.scene_ids()
	var first_scene: String = director.story_repository.first_scene_id()
	GameState.start_scene(first_scene, director.story_repository.get_start_location(first_scene))
	for flag in director.story_repository.get_initial_flags(first_scene):
		StoryFlags.set_flag(str(flag), true)
	_restore_quest_status(first_scene)
	director.present_current_location()

	var ok := true
	var command_count := 0
	var completed: Array[String] = []
	for scene_id in scene_ids:
		if not ok:
			break
		if GameState.current_scene_id != scene_id:
			push_warning("Nova gamepad route smoke expected scene %s but got %s" % [scene_id, GameState.current_scene_id])
			ok = false
			break
		var scene: Dictionary = director.story_repository.get_scene(scene_id)
		var commands: Array = scene.get("walkthrough", [])
		for raw_command in commands:
			var command := str(raw_command)
			command_count += 1
			if not _gamepad_route_command(command):
				push_warning("Nova gamepad route smoke failed command %s at %s/%s selected=%s choices=%s" % [
					command,
					GameState.current_scene_id,
					GameState.current_location_id,
					exploration_view.selected_choice_index(),
					", ".join(exploration_view.current_choice_labels()),
				])
				ok = false
				break
		if ok and not StoryFlags.has_all(director.story_repository.get_required_flags(scene_id)):
			push_warning("Nova gamepad route smoke missing required flag %s for %s" % [
				_smoke_first_missing(director.story_repository.get_required_flags(scene_id)),
				scene_id,
			])
			ok = false
		if ok:
			completed.append(scene_id)

	ok = ok and completed.size() == scene_ids.size()
	print("nova-gamepad-route-smoke status=%s scenes=%s commands=%s flags=%s current=%s/%s" % [
		"PASS" if ok else "FAIL",
		completed.size(),
		command_count,
		StoryFlags.export_flags().keys().size(),
		GameState.current_scene_id,
		GameState.current_location_id,
	])
	get_tree().quit(0 if ok else 1)


func _gamepad_route_command(command: String) -> bool:
	var expected := _ui_route_expected_choice(command)
	if expected.is_empty():
		push_warning("Nova gamepad route smoke cannot map command: %s" % command)
		return false
	var choice_type := str(expected.get("type", ""))
	var choice_id := str(expected.get("id", ""))
	var action_type := str(expected.get("action_type", ""))
	if not exploration_view.has_enabled_choice(choice_type, choice_id, action_type):
		return false
	var target_index: int = exploration_view.choice_index_for(choice_type, choice_id, action_type)
	if target_index < 0:
		return false
	var guard: int = exploration_view.current_choice_labels().size() + 2
	while exploration_view.selected_choice_index() != target_index and guard > 0:
		exploration_view._input(_joypad_button_event(JOYPAD_BUTTON_DPAD_DOWN))
		guard -= 1
	if exploration_view.selected_choice_index() != target_index:
		return false
	_latest_cutscene_payload = {}
	exploration_view._input(_joypad_button_event(JOYPAD_BUTTON_A))
	return _advance_gamepad_route_payload()


func _advance_gamepad_route_payload() -> bool:
	var guard := 64
	while GameMode.current_mode != GameMode.EXPLORATION and guard > 0:
		if vn_layer.visible:
			vn_layer._input(_joypad_button_event(JOYPAD_BUTTON_A))
		elif not _latest_cutscene_payload.is_empty():
			_finish_cutscene(_latest_cutscene_payload)
			_latest_cutscene_payload = {}
		else:
			return false
		guard -= 1
	return GameMode.current_mode == GameMode.EXPLORATION


func _action_event(action_name: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	return event


func _joypad_button_event(button_index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = true
	event.pressure = 1.0
	return event


func _raw_key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event


func _ui_route_command(command: String) -> bool:
	var expected := _ui_route_expected_choice(command)
	if expected.is_empty():
		push_warning("Nova UI route smoke cannot map command: %s" % command)
		return false
	var choice_type := str(expected.get("type", ""))
	var choice_id := str(expected.get("id", ""))
	var action_type := str(expected.get("action_type", ""))
	if not exploration_view.has_enabled_choice(choice_type, choice_id, action_type):
		return false
	_latest_cutscene_payload = {}
	if not exploration_view.press_choice(choice_type, choice_id, action_type):
		return false
	return _finish_ui_route_payload_if_needed()


func _ui_route_expected_choice(command: String) -> Dictionary:
	var parts := command.split(" ", false, 1)
	if parts.size() == 0:
		return {}
	var verb := str(parts[0])
	var target := str(parts[1]) if parts.size() > 1 else ""
	match verb:
		"go":
			return {"type": "move", "id": target}
		"inspect":
			return {"type": "inspect", "id": target}
		"choose":
			return {"type": "choice", "id": target}
		"build":
			return {"type": "story_action", "action_type": "build", "id": target}
		"engage":
			return {"type": "story_action", "action_type": "encounter", "id": target}
		"combine":
			return {"type": "story_action", "action_type": "combo", "id": target}
		"write":
			return _ui_route_write_choice(target)
		"cast":
			return _ui_route_cast_choice(target)
		"attack":
			return {"type": "story_action", "action_type": "combat_resolve", "id": "resolve"}
		_:
			return {}


func _ui_route_write_choice(glyph_id: String) -> Dictionary:
	var glyphs: Dictionary = director.story_repository.get_glyph_actions(GameState.current_scene_id, GameState.current_location_id)
	if glyphs.has(glyph_id):
		var glyph: Dictionary = glyphs[glyph_id]
		if StoryFlags.has_all(glyph.get("requires", [])):
			return {"type": "story_action", "action_type": "glyph", "id": glyph_id}
	var combat: Dictionary = director.story_repository.get_combat(GameState.current_scene_id, GameState.current_location_id)
	if glyph_id == "name" and not combat.is_empty():
		return {"type": "story_action", "action_type": "combat_identify", "id": "identify"}
	return {}


func _ui_route_cast_choice(glyph_id: String) -> Dictionary:
	var combat: Dictionary = director.story_repository.get_combat(GameState.current_scene_id, GameState.current_location_id)
	var win_flag := str(combat.get("win_flag", ""))
	var spells: Dictionary = combat.get("spells", {})
	if spells.has(glyph_id) and (win_flag.is_empty() or not StoryFlags.has_flag(win_flag)):
		return {"type": "story_action", "action_type": "combat_spell", "id": glyph_id}
	var glyphs: Dictionary = director.story_repository.get_glyph_actions(GameState.current_scene_id, GameState.current_location_id)
	if glyphs.has(glyph_id):
		return {"type": "story_action", "action_type": "glyph", "id": glyph_id}
	return {}


func _finish_ui_route_payload_if_needed() -> bool:
	if GameMode.current_mode == GameMode.EXPLORATION:
		return true
	if _latest_cutscene_payload.is_empty():
		return false
	if vn_layer.visible:
		vn_layer._accept()
	else:
		_finish_cutscene(_latest_cutscene_payload)
	_latest_cutscene_payload = {}
	return GameMode.current_mode == GameMode.EXPLORATION


func _manual_route_command(scene_id: String, command: String) -> bool:
	var parts := command.split(" ", false, 1)
	if parts.size() == 0:
		return true
	var verb := str(parts[0])
	var target := str(parts[1]) if parts.size() > 1 else ""
	match verb:
		"go":
			return director.move_to(target)
		"inspect":
			return _manual_route_inspect(target)
		"choose":
			return _manual_route_choice(target)
		"write":
			return _manual_route_write(target)
		"cast":
			return _manual_route_cast(target)
		"build":
			return _manual_route_record_action("build", target)
		"engage":
			return _manual_route_record_action("encounter", target)
		"combine":
			return _manual_route_record_action("combo", target)
		"attack":
			return _manual_route_attack()
		_:
			push_warning("Nova manual-route smoke unknown verb %s in %s" % [verb, command])
			return false


func _manual_route_inspect(item_id: String) -> bool:
	var scene_id := GameState.current_scene_id
	var location_id := GameState.current_location_id
	var items: Dictionary = director.story_repository.get_items(scene_id, location_id)
	if not items.has(item_id):
		push_warning("Nova manual-route smoke missing item %s at %s/%s" % [item_id, scene_id, location_id])
		return false
	if not director.inspect_item(item_id):
		return false
	var item: Dictionary = items[item_id]
	_finish_cutscene({"flags": item.get("flags", [])})
	return true


func _manual_route_choice(choice_id: String) -> bool:
	var scene_id := GameState.current_scene_id
	var location_id := GameState.current_location_id
	var choices: Dictionary = director.story_repository.get_location_choices(scene_id, location_id)
	if not choices.has(choice_id):
		push_warning("Nova manual-route smoke missing choice %s at %s/%s" % [choice_id, scene_id, location_id])
		return false
	if not director.choose_location_choice(choice_id):
		return false
	var choice: Dictionary = choices[choice_id]
	_finish_cutscene({"flags": choice.get("flags", [])})
	return true


func _manual_route_write(glyph_id: String) -> bool:
	var glyphs: Dictionary = director.story_repository.get_glyph_actions(GameState.current_scene_id, GameState.current_location_id)
	if glyphs.has(glyph_id):
		var glyph: Dictionary = glyphs[glyph_id]
		if StoryFlags.has_all(glyph.get("requires", [])):
			return _manual_route_record_action("glyph", glyph_id)
	var combat: Dictionary = director.story_repository.get_combat(GameState.current_scene_id, GameState.current_location_id)
	if glyph_id == "name" and not combat.is_empty():
		return _manual_route_combat_identify(combat)
	push_warning("Nova manual-route smoke cannot write %s at %s/%s" % [glyph_id, GameState.current_scene_id, GameState.current_location_id])
	return false


func _manual_route_cast(glyph_id: String) -> bool:
	var combat: Dictionary = director.story_repository.get_combat(GameState.current_scene_id, GameState.current_location_id)
	var win_flag := str(combat.get("win_flag", ""))
	var spells: Dictionary = combat.get("spells", {})
	if spells.has(glyph_id) and (win_flag.is_empty() or not StoryFlags.has_flag(win_flag)):
		if not director.perform_story_action("combat_spell", glyph_id):
			return false
		var spell: Dictionary = spells[glyph_id]
		_finish_cutscene({"flags": spell.get("flags", [])})
		return true
	var glyphs: Dictionary = director.story_repository.get_glyph_actions(GameState.current_scene_id, GameState.current_location_id)
	if glyphs.has(glyph_id):
		return _manual_route_record_action("glyph", glyph_id)
	push_warning("Nova manual-route smoke cannot cast %s at %s/%s" % [glyph_id, GameState.current_scene_id, GameState.current_location_id])
	return false


func _manual_route_record_action(action_type: String, action_id: String) -> bool:
	var records: Dictionary = {}
	match action_type:
		"glyph":
			records = director.story_repository.get_glyph_actions(GameState.current_scene_id, GameState.current_location_id)
		"build":
			records = director.story_repository.get_build_actions(GameState.current_scene_id, GameState.current_location_id)
		"encounter":
			records = director.story_repository.get_encounters(GameState.current_scene_id, GameState.current_location_id)
		"combo":
			records = director.story_repository.get_combos(GameState.current_scene_id, GameState.current_location_id)
		_:
			return false
	if not records.has(action_id):
		push_warning("Nova manual-route smoke missing %s action %s at %s/%s" % [
			action_type,
			action_id,
			GameState.current_scene_id,
			GameState.current_location_id,
		])
		return false
	var record: Dictionary = records[action_id]
	var requires: Array = _smoke_array(record.get("requires", []))
	if not StoryFlags.has_all(requires):
		push_warning("Nova manual-route smoke blocked %s action %s at %s/%s missing %s" % [
			action_type,
			action_id,
			GameState.current_scene_id,
			GameState.current_location_id,
			_smoke_first_missing(requires),
		])
		return false
	if not director.perform_story_action(action_type, action_id):
		return false
	_finish_cutscene({"flags": record.get("flags", [])})
	return true


func _manual_route_combat_identify(combat: Dictionary) -> bool:
	var flags: Array = []
	var lock_flag := str(combat.get("lock_flag", ""))
	if not lock_flag.is_empty():
		flags.append(lock_flag)
	flags.append_array(_smoke_array(combat.get("success_flags", [])))
	if not director.perform_story_action("combat_identify", "identify"):
		return false
	_finish_cutscene({"flags": flags})
	return true


func _manual_route_attack() -> bool:
	var combat: Dictionary = director.story_repository.get_combat(GameState.current_scene_id, GameState.current_location_id)
	if combat.is_empty():
		push_warning("Nova manual-route smoke attack without combat at %s/%s" % [
			GameState.current_scene_id,
			GameState.current_location_id,
		])
		return false
	var win_flag := str(combat.get("win_flag", ""))
	if not win_flag.is_empty() and StoryFlags.has_flag(win_flag):
		return true
	var lock_flag := str(combat.get("lock_flag", ""))
	if not lock_flag.is_empty() and not StoryFlags.has_flag(lock_flag):
		_finish_cutscene({"flags": _smoke_array(combat.get("failure_flags", []))})
		return true
	var required: Array = _smoke_array(combat.get("required_attack_flags", []))
	if not StoryFlags.has_all(required):
		_finish_cutscene({"flags": []})
		return true
	var key := "%s/%s" % [GameState.current_scene_id, GameState.current_location_id]
	var attempts := int(_manual_route_attack_attempts.get(key, 0)) + 1
	_manual_route_attack_attempts[key] = attempts
	var enemy_hp: int = max(1, int(combat.get("enemy_hp", combat.get("success_attempt", 1))))
	var flags: Array = []
	if attempts >= enemy_hp:
		if not win_flag.is_empty():
			flags.append(win_flag)
		flags.append_array(_smoke_array(combat.get("reward_flags", [])))
		if not director.perform_story_action("combat_resolve", "resolve"):
			return false
	else:
		var failure_flags: Array = _smoke_array(combat.get("failure_flags", []))
		if not failure_flags.is_empty():
			flags.append(str(failure_flags[(attempts - 1) % failure_flags.size()]))
	_finish_cutscene({"flags": flags})
	return true


func _smoke_complete_current_scene(scene_id: String) -> bool:
	var loops := 0
	while GameState.current_scene_id == scene_id and loops < 128:
		loops += 1
		var before_flags := StoryFlags.export_flags().keys().size()
		var scene: Dictionary = director.story_repository.get_scene(scene_id)
		var locations: Dictionary = scene.get("locations", {})
		for raw_location_id in locations.keys():
			if GameState.current_scene_id != scene_id:
				return true
			var location_id := str(raw_location_id)
			if not _smoke_move_to_location(scene_id, location_id):
				return false
			if not _smoke_apply_location_actions(scene_id, location_id):
				return false
		if GameState.current_scene_id != scene_id:
			return true
		var required_flags: Array = director.story_repository.get_required_flags(scene_id)
		if required_flags.is_empty() or StoryFlags.has_all(required_flags):
			return true
		var after_flags := StoryFlags.export_flags().keys().size()
		if after_flags <= before_flags:
			push_warning("Nova all-scenes smoke stalled at %s/%s; missing %s" % [
				scene_id,
				GameState.current_location_id,
				_smoke_first_missing(required_flags),
			])
			return false
	push_warning("Nova all-scenes smoke exceeded loop guard at %s" % scene_id)
	return false


func _smoke_apply_location_actions(scene_id: String, location_id: String) -> bool:
	var items: Dictionary = director.story_repository.get_items(scene_id, location_id)
	for raw_item_id in items.keys():
		var item_id := str(raw_item_id)
		var item: Dictionary = items[item_id]
		if not _smoke_record_pending(item):
			continue
		if not StoryFlags.has_all(_smoke_array(item.get("requires", []))):
			continue
		if not director.inspect_item(item_id):
			return false
		_finish_cutscene({"flags": _smoke_array(item.get("flags", []))})

	var choices: Dictionary = director.story_repository.get_location_choices(scene_id, location_id)
	var resolved_flag: String = director.story_repository.get_branch_resolved_flag(scene_id)
	var branch_resolved: bool = not resolved_flag.is_empty() and StoryFlags.has_flag(resolved_flag)
	for raw_choice_id in choices.keys():
		if branch_resolved:
			break
		var choice_id := str(raw_choice_id)
		var choice: Dictionary = choices[choice_id]
		if not _smoke_record_pending(choice):
			continue
		if not StoryFlags.has_all(_smoke_array(choice.get("requires", []))):
			continue
		if not director.choose_location_choice(choice_id):
			return false
		_finish_cutscene({"flags": _smoke_array(choice.get("flags", []))})
		branch_resolved = not resolved_flag.is_empty() and StoryFlags.has_flag(resolved_flag)

	if not _smoke_apply_record_actions("glyph", director.story_repository.get_glyph_actions(scene_id, location_id)):
		return false
	if not _smoke_apply_record_actions("build", director.story_repository.get_build_actions(scene_id, location_id)):
		return false
	if not _smoke_apply_record_actions("encounter", director.story_repository.get_encounters(scene_id, location_id)):
		return false
	if not _smoke_apply_record_actions("combo", director.story_repository.get_combos(scene_id, location_id)):
		return false
	return _smoke_apply_combat_actions(director.story_repository.get_combat(scene_id, location_id))


func _smoke_apply_record_actions(action_type: String, records: Dictionary) -> bool:
	for raw_action_id in records.keys():
		var action_id := str(raw_action_id)
		var record: Dictionary = records[action_id]
		if not _smoke_record_pending(record):
			continue
		if not StoryFlags.has_all(_smoke_array(record.get("requires", []))):
			continue
		if not director.perform_story_action(action_type, action_id):
			return false
		_finish_cutscene({"flags": _smoke_array(record.get("flags", []))})
	return true


func _smoke_apply_combat_actions(combat: Dictionary) -> bool:
	if combat.is_empty():
		return true
	var lock_flag := str(combat.get("lock_flag", ""))
	var learn_flag := str(combat.get("learn_flag", ""))
	if not lock_flag.is_empty() and not StoryFlags.has_flag(lock_flag):
		if learn_flag.is_empty() or StoryFlags.has_flag(learn_flag):
			var identify_flags: Array = []
			identify_flags.append(lock_flag)
			identify_flags.append_array(_smoke_array(combat.get("success_flags", [])))
			if not director.perform_story_action("combat_identify", "identify"):
				return false
			_finish_cutscene({"flags": identify_flags})
	var spells: Dictionary = combat.get("spells", {})
	for raw_spell_id in spells.keys():
		var spell_id := str(raw_spell_id)
		var spell: Dictionary = spells[spell_id]
		if not _smoke_record_pending(spell):
			continue
		if not StoryFlags.has_all(_smoke_array(spell.get("requires", []))):
			continue
		if not director.perform_story_action("combat_spell", spell_id):
			return false
		_finish_cutscene({"flags": _smoke_array(spell.get("flags", []))})
	var win_flag := str(combat.get("win_flag", ""))
	if not win_flag.is_empty() and not StoryFlags.has_flag(win_flag):
		if StoryFlags.has_all(_smoke_array(combat.get("required_attack_flags", []))):
			var resolve_flags: Array = []
			resolve_flags.append(win_flag)
			resolve_flags.append_array(_smoke_array(combat.get("reward_flags", [])))
			if not director.perform_story_action("combat_resolve", "resolve"):
				return false
			_finish_cutscene({"flags": resolve_flags})
	return true


func _smoke_move_to_location(scene_id: String, target_location_id: String) -> bool:
	if GameState.current_location_id == target_location_id:
		return true
	var path := _smoke_find_path(scene_id, GameState.current_location_id, target_location_id)
	if path.is_empty():
		push_warning("Nova all-scenes smoke cannot reach %s/%s from %s" % [
			scene_id,
			target_location_id,
			GameState.current_location_id,
		])
		return false
	for location_id in path:
		if not director.move_to(str(location_id)):
			return false
	return true


func _smoke_find_path(scene_id: String, start_location_id: String, target_location_id: String) -> Array[String]:
	var frontier: Array[String] = [start_location_id]
	var previous: Dictionary = {start_location_id: ""}
	var index := 0
	while index < frontier.size():
		var current := frontier[index]
		index += 1
		if current == target_location_id:
			break
		var exits: Dictionary = director.story_repository.get_exits(scene_id, current)
		for raw_next_id in exits.keys():
			var next_id := str(raw_next_id)
			if previous.has(next_id):
				continue
			previous[next_id] = current
			frontier.append(next_id)
	if not previous.has(target_location_id):
		return []
	var path: Array[String] = []
	var cursor := target_location_id
	while cursor != start_location_id:
		path.push_front(cursor)
		cursor = str(previous.get(cursor, ""))
		if cursor.is_empty():
			return []
	return path


func _smoke_record_pending(record: Dictionary) -> bool:
	var flags := _smoke_array(record.get("flags", []))
	return not flags.is_empty() and not StoryFlags.has_any(flags)


func _smoke_array(value) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	return []


func _smoke_first_missing(flags: Array) -> String:
	for flag in flags:
		if not StoryFlags.has_flag(str(flag)):
			return str(flag)
	return "unknown"


func _run_dialogic_bridge_smoke() -> void:
	var backdrop_path: String = director.visual_repository.get_backdrop_path(GameState.current_scene_id, GameState.current_location_id)
	# Smoke single-text payload
	var ok: bool = dialogic_bridge.smoke({
		"speaker": "纪子轩",
		"title": "Dialogic Bridge Smoke",
		"text": "Dialogic timeline bridge is available.",
		"flags": ["dialogic_bridge_smoke"],
		"characters": [{
			"id": "jizi_xuan",
			"name": "纪子轩",
			"path": "res://assets/characters/main/jizi_xuan/portrait_xianjian_phone.png",
			"dialogic_id": "jizi_xuan",
			"portrait": "phone",
		}],
	}, backdrop_path)
	# Smoke multi-line dialogue payload with new characters
	var multi_ok: bool = dialogic_bridge.smoke({
		"title": "Multi-Character Dialogue Smoke",
		"dialogue": [
			{"speaker": "jizi_xuan", "text": "序幕，黑暗中的夜晚。", "flags": ["dialogic_bridge_smoke"]},
			{"speaker": "xiali", "text": "夏离出场了。"},
		],
		"characters": [
			{"id": "jizi_xuan", "name": "纪子轩", "path": "res://assets/characters/main/jizi_xuan/portrait_xianjian_phone.png", "dialogic_id": "jizi_xuan", "portrait": "phone"},
			{"id": "xiali", "name": "夏离", "path": "res://assets/characters/main/xiali/model_sheet.png", "dialogic_id": "xiali", "portrait": "default"},
		],
	}, backdrop_path)
	ok = ok and multi_ok
	# Smoke variable bridge
	var vbridge_ok: bool = dialogic_variable_bridge != null
	ok = ok and vbridge_ok
	print("dialogic-bridge-smoke status=%s installed=%s multi=%s vbridge=%s backdrop=%s" % [
		"PASS" if ok else "FAIL",
		str(dialogic_bridge.is_dialogic_installed()),
		str(multi_ok),
		str(vbridge_ok),
		backdrop_path,
	])
	get_tree().quit(0 if ok else 1)


func _run_dialogic_runtime_smoke() -> void:
	if DisplayServer.get_name() == "headless":
		print("dialogic-runtime-smoke status=SKIP reason=headless")
		get_tree().quit(0)
		return
	StoryFlags.reset()
	GameState.start_scene("00-prologue-lights-out", "street")
	director.present_current_location()
	_dialogic_runtime_finished = false
	_dialogic_runtime_payload = {}
	_dialogic_runtime_started_with_dialogic = false
	if not dialogic_bridge.finished.is_connected(_on_dialogic_runtime_finished):
		dialogic_bridge.finished.connect(_on_dialogic_runtime_finished)
	var ok: bool = director.inspect_item("window")
	var dialogic_node := get_node_or_null("/root/Dialogic")
	ok = ok and dialogic_node != null and dialogic_bridge.can_play_runtime()
	if ok and dialogic_node != null and dialogic_node.has_subsystem("Inputs"):
		dialogic_node.Inputs.auto_skip.time_per_event = 0.01
		dialogic_node.Inputs.auto_skip.disable_on_user_input = false
		dialogic_node.Inputs.auto_skip.enabled = true
	_dialogic_runtime_started_with_dialogic = ok and vn_layer.visible == false
	var timer := Timer.new()
	timer.name = "DialogicRuntimeSmokeTimer"
	timer.one_shot = true
	timer.wait_time = 3.0 if ok else 0.1
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(_finish_dialogic_runtime_smoke.bind(ok))
	add_child(timer)
	timer.start()


func _run_keyboard_dialogic_smoke() -> void:
	if DisplayServer.get_name() == "headless":
		print("nova-keyboard-dialogic-smoke status=SKIP reason=headless")
		get_tree().quit(0)
		return
	StoryFlags.reset()
	var first_scene: String = director.story_repository.first_scene_id()
	GameState.start_scene(first_scene, director.story_repository.get_start_location(first_scene))
	for flag in director.story_repository.get_initial_flags(first_scene):
		StoryFlags.set_flag(str(flag), true)
	_restore_quest_status(first_scene)
	director.present_current_location()

	_dialogic_runtime_finished = false
	_dialogic_runtime_payload = {}
	_dialogic_runtime_started_with_dialogic = false
	_latest_cutscene_payload = {}
	if not dialogic_bridge.finished.is_connected(_on_dialogic_runtime_finished):
		dialogic_bridge.finished.connect(_on_dialogic_runtime_finished)

	var target_index: int = exploration_view.choice_index_for("inspect", "window")
	var menu_ok: bool = target_index >= 0 and exploration_view.has_enabled_choice("inspect", "window")
	var guard: int = exploration_view.current_choice_labels().size() + 2
	while menu_ok and exploration_view.selected_choice_index() != target_index and guard > 0:
		exploration_view._input(_action_event("ui_down"))
		guard -= 1
	menu_ok = menu_ok and exploration_view.selected_choice_index() == target_index
	if menu_ok:
		exploration_view._input(_action_event("ui_accept"))
	_dialogic_runtime_started_with_dialogic = menu_ok and not vn_layer.visible and GameMode.current_mode == GameMode.VN_CUTSCENE

	var dialogic_node := get_node_or_null("/root/Dialogic")
	if _dialogic_runtime_started_with_dialogic and dialogic_node != null and dialogic_node.has_subsystem("Inputs"):
		dialogic_node.Inputs.auto_skip.time_per_event = 0.01
		dialogic_node.Inputs.auto_skip.disable_on_user_input = false
		dialogic_node.Inputs.auto_skip.enabled = true
	await get_tree().process_frame
	var deadline_msec: int = Time.get_ticks_msec() + 3500
	while Time.get_ticks_msec() < deadline_msec and not _dialogic_runtime_finished:
		await get_tree().process_frame
	if dialogic_node != null and dialogic_node.has_subsystem("Inputs"):
		dialogic_node.Inputs.auto_skip.enabled = false

	var menu_restored: bool = GameMode.current_mode == GameMode.EXPLORATION and exploration_view.has_enabled_choice("inspect", "poster")
	var ok: bool = menu_ok
	ok = ok and _dialogic_runtime_started_with_dialogic
	ok = ok and _dialogic_runtime_finished
	ok = ok and StoryFlags.has_flag("noticed_dark_window")
	ok = ok and menu_restored
	ok = ok and str(_dialogic_runtime_payload.get("timeline_path", "")).ends_with("street_window.dtl")
	var screenshot_path := ProjectSettings.globalize_path("res://artifacts/nova-keyboard-dialogic-smoke.png")
	if ok:
		DirAccess.make_dir_recursive_absolute(screenshot_path.get_base_dir())
		var image := get_viewport().get_texture().get_image()
		ok = image != null and image.save_png(screenshot_path) == OK
	print("nova-keyboard-dialogic-smoke status=%s started=%s finished=%s flag=%s menu=%s advance=auto_skip screenshot=%s" % [
		"PASS" if ok else "FAIL",
		str(_dialogic_runtime_started_with_dialogic),
		str(_dialogic_runtime_finished),
		str(StoryFlags.has_flag("noticed_dark_window")),
		str(menu_restored),
		screenshot_path,
	])
	get_tree().quit(0 if ok else 1)


func _on_dialogic_runtime_finished(payload: Dictionary) -> void:
	_dialogic_runtime_finished = true
	_dialogic_runtime_payload = payload.duplicate(true)


func _finish_dialogic_runtime_smoke(start_ok: bool) -> void:
	var dialogic_node := get_node_or_null("/root/Dialogic")
	if dialogic_node != null and dialogic_node.has_subsystem("Inputs"):
		dialogic_node.Inputs.auto_skip.enabled = false
	var ok := start_ok
	ok = ok and _dialogic_runtime_finished
	ok = ok and _dialogic_runtime_started_with_dialogic
	ok = ok and StoryFlags.has_flag("noticed_dark_window")
	ok = ok and str(_dialogic_runtime_payload.get("timeline_path", "")).ends_with("street_window.dtl")
	var screenshot_path := ProjectSettings.globalize_path("res://artifacts/dialogic-runtime-smoke.png")
	if ok:
		DirAccess.make_dir_recursive_absolute(screenshot_path.get_base_dir())
		var image := get_viewport().get_texture().get_image()
		ok = image != null and image.save_png(screenshot_path) == OK
	print("dialogic-runtime-smoke status=%s finished=%s flag=%s screenshot=%s" % [
		"PASS" if ok else "FAIL",
		str(_dialogic_runtime_finished),
		str(StoryFlags.has_flag("noticed_dark_window")),
		screenshot_path,
	])
	get_tree().quit(0 if ok else 1)


func _run_asset_smoke() -> void:
	var required_files := [
		"res://assets/branding/dream-coastline-title-loop.png",
		"res://assets/branding/dream-coastline-splash.png",
		"res://assets/branding/dream-coastline-icon.png",
		"res://assets/characters/jizixuan/player_default.png",
		"res://assets/characters/main/jizi_xuan/portrait_xianjian_phone.png",
		"res://assets/characters/main/jizi_xuan/model_sheet.png",
		"res://assets/characters/main/xiali/model_sheet.png",
		"res://assets/characters/main/wensu/model_sheet.png",
		"res://assets/characters/main/atang/model_sheet.png",
	]
	var ok := true
	for path in required_files:
		ok = ok and FileAccess.file_exists(path)
	ok = ok and audio_director != null and audio_director.verify_streams()
	print("nova-assets-smoke status=%s files=%s audio=%s" % [
		"PASS" if ok else "FAIL",
		required_files.size(),
		str(audio_director != null),
	])
	get_tree().quit(0 if ok else 1)


func _run_story_audio_targets_smoke() -> void:
	var ok := true
	var checked := 0
	var missing_count := 0
	if audio_director == null or not audio_director.has_method("missing_story_audio_targets"):
		ok = false
	else:
		for scene_id in director.story_repository.scene_ids():
			checked += 1
			var missing: Array = audio_director.missing_story_audio_targets(str(scene_id))
			missing_count += missing.size()
			if not missing.is_empty():
				ok = false
				for entry in missing.slice(0, 8):
					if not (entry is Dictionary):
						continue
					print("story-audio-targets-missing scene=%s kind=%s id=%s path=%s" % [
						str(scene_id),
						str(entry.get("kind", "")),
						str(entry.get("id", "")),
						str(entry.get("path", "")),
					])
	print("story-audio-targets-smoke status=%s scenes=%d missing=%d" % [
		"PASS" if ok else "FAIL",
		checked,
		missing_count,
	])
	get_tree().quit(0 if ok else 1)


func _run_export_config_smoke() -> void:
	var config := ConfigFile.new()
	var error := config.load("res://export_presets.cfg")
	if error != OK:
		print("export-config-smoke status=FAIL reason=missing-export-presets error=%s" % error)
		get_tree().quit(1)
		return

	var expected := ["macOS", "Windows Desktop", "Linux/X11"]
	var required_excludes := [
		"tools/**",
		"docs/**",
		"five/**",
		"artifacts/**",
		"builds/**",
		"target/**",
		".godot/**",
		".zig-cache/**",
		".DS_Store",
		".env",
		"deepseek.local.cfg",
		"*.log",
		".claude/**",
		".cursor/**",
		".idea/**",
		".tmp/**",
		".venv/**",
		"node_modules/**",
		"addons/dialogic/Editor/**",
		"addons/yarn_spinner/editor/**",
		"addons/yarn_spinner/templates/**",
	]
	var found: Array[String] = []
	var filter_missing: Array[String] = []
	for section in config.get_sections():
		if not str(section).begins_with("preset.") or str(section).ends_with(".options"):
			continue
		var preset_name := str(config.get_value(section, "name", ""))
		if expected.has(preset_name):
			found.append(preset_name)
			var exclude_filter := str(config.get_value(section, "exclude_filter", ""))
			var excludes := exclude_filter.split(",", false)
			for required in required_excludes:
				if not excludes.has(required):
					filter_missing.append("%s missing exclude %s" % [preset_name, required])

	var missing: Array[String] = []
	for preset_name in expected:
		if not found.has(preset_name):
			missing.append(preset_name)

	var templates_path := _export_templates_path()
	var templates_installed := DirAccess.dir_exists_absolute(templates_path)
	var branding_missing := _release_branding_missing()
	var ok := templates_installed and missing.is_empty() and branding_missing.is_empty() and filter_missing.is_empty()
	print("export-config-smoke status=%s presets=%s/%s templates=%s branding=%s excludes=%s path=%s" % [
		"PASS" if ok else "FAIL",
		found.size(),
		expected.size(),
		"installed" if templates_installed else "missing",
		"ok" if branding_missing.is_empty() else "missing",
		"ok" if filter_missing.is_empty() else "missing",
		templates_path,
	])
	if not missing.is_empty():
		print("missing=", missing)
	if not templates_installed:
		print("failure= export templates missing at %s" % templates_path)
	for failure in filter_missing:
		print("failure=", failure)
	for failure in branding_missing:
		print("failure=", failure)
	get_tree().quit(0 if ok else 1)


func _run_release_libraries_smoke() -> void:
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
	get_tree().quit(0 if ok else 1)


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


func _capture_screenshot() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name() == "headless":
		print("nova-screenshot status=SKIP reason=headless-display-has-no-viewport-texture")
		get_tree().quit(0)
		return
	var output_path := ProjectSettings.globalize_path("res://artifacts/nova-runtime-smoke.png")
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var viewport_texture := get_viewport().get_texture()
	var image: Image = null
	if viewport_texture != null:
		image = viewport_texture.get_image()
	if image == null:
		print("nova-screenshot status=SKIP reason=headless-display-has-no-viewport-texture")
		get_tree().quit(0)
		return
	var err := image.save_png(output_path)
	print("nova-screenshot status=%s path=%s" % ["PASS" if err == OK else "FAIL", output_path])
	get_tree().quit(0 if err == OK else 1)


func _capture_scene_screenshots() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := _global_capture_path(_arg_value(args, "--capture-output", "user://scene-screenshots"))
	var scene_filter := _arg_value(args, "--capture-scene", "all")
	var scope := _arg_value(args, "--capture-scope", "locations")
	var warmup_frames := maxi(1, int(_arg_value(args, "--capture-warmup-frames", "3")))
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK:
		print("scene-screenshot-capture status=FAIL architecture=nova reason=mkdir path=%s error=%s" % [output_dir, mkdir_error])
		get_tree().quit(1)
		return

	var screenshots: Array[Dictionary] = []
	var failures: Array[String] = []
	var route_command_count := 0
	if scope == "route" or scope == "route-full":
		var route_result: Dictionary = await _capture_route_screenshots(
			output_dir,
			scene_filter,
			warmup_frames,
			scope == "route-full"
		)
		route_command_count = int(route_result.get("route_command_count", 0))
		for entry in route_result.get("screenshots", []):
			if typeof(entry) == TYPE_DICTIONARY:
				screenshots.append(entry)
		for failure in route_result.get("failures", []):
			failures.append(str(failure))
	else:
		var scene_ids: Array = director.story_repository.scene_ids()
		for scene_index in range(scene_ids.size()):
			var scene_id := str(scene_ids[scene_index])
			if scene_filter != "all" and scene_filter != scene_id:
				continue
			var story_scene: Dictionary = director.story_repository.get_scene(scene_id)
			var location_ids: Array[String] = _capture_location_ids(story_scene, scope)
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
		"version": 3,
		"generated_by": "--capture-scene-screenshots",
		"architecture": "nova",
		"visual_style": _arg_value(args, "--visual-style", "nova"),
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
		"route_command_count": route_command_count,
		"screenshots": screenshots,
		"failures": failures,
	}
	var manifest_path := output_dir.path_join("manifest.json")
	var manifest_file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if manifest_file == null:
		print("scene-screenshot-capture status=FAIL architecture=nova reason=manifest path=%s" % manifest_path)
		get_tree().quit(1)
		return
	manifest_file.store_string(JSON.stringify(manifest, "\t"))
	manifest_file.close()

	var ok := failures.is_empty() and not screenshots.is_empty()
	print("scene-screenshot-capture status=%s architecture=nova output=%s screenshots=%s failures=%s" % [
		"PASS" if ok else "FAIL",
		output_dir,
		screenshots.size(),
		failures.size(),
	])
	get_tree().quit(0 if ok else 1)


func _capture_route_screenshots(output_dir: String, scene_filter: String, warmup_frames: int, full_route: bool) -> Dictionary:
	StoryFlags.reset()
	_manual_route_attack_attempts.clear()
	_latest_cutscene_payload = {}
	_suppress_runtime_dialogic = true
	var scene_ids: Array[String] = director.story_repository.scene_ids()
	var selected_scene_ids: Array[String] = []
	var route_commands_total := 0
	for raw_scene_id in scene_ids:
		var selected_scene_id := str(raw_scene_id)
		if scene_filter != "all" and scene_filter != selected_scene_id:
			continue
		selected_scene_ids.append(selected_scene_id)
		var selected_scene: Dictionary = director.story_repository.get_scene(selected_scene_id)
		route_commands_total += int(selected_scene.get("walkthrough", []).size())
	var first_scene: String = director.story_repository.first_scene_id()
	GameState.start_scene(first_scene, director.story_repository.get_start_location(first_scene))
	for flag in director.story_repository.get_initial_flags(first_scene):
		StoryFlags.set_flag(str(flag), true)
	_restore_quest_status(first_scene)
	director.present_current_location()

	var screenshots: Array[Dictionary] = []
	var failures: Array[String] = []
	var command_count := 0
	var route_index := 0
	var ok := true
	var scope_label := "route-full" if full_route else "route"
	for source_scene_id in selected_scene_ids:
		if GameState.current_scene_id != source_scene_id:
			failures.append("route expected scene %s but got %s" % [source_scene_id, GameState.current_scene_id])
			ok = false
			break
		var story_scene: Dictionary = director.story_repository.get_scene(source_scene_id)
		var commands: Array = story_scene.get("walkthrough", [])
		var checkpoint_indexes: Dictionary = _route_checkpoint_indexes(commands.size())
		for command_index in range(commands.size()):
			if not full_route:
				for checkpoint in checkpoint_indexes.get(command_index, []):
					var entry := await _capture_current_route_screenshot(
						route_index,
						scope_label,
						source_scene_id,
						str(checkpoint),
						command_index,
						commands.size(),
						output_dir,
						warmup_frames
					)
					route_index += 1
					if bool(entry.get("ok", false)):
						screenshots.append(entry)
					else:
						failures.append(str(entry.get("failure", "unknown")))
						ok = false
						break
				if not ok:
					break
			var command := str(commands[command_index])
			command_count += 1
			if not _ui_route_command(command):
				failures.append("route command failed %s at %s/%s choices=%s" % [
					command,
					GameState.current_scene_id,
					GameState.current_location_id,
					", ".join(exploration_view.current_choice_labels()),
				])
				ok = false
				break
			if full_route:
				var entry := await _capture_current_route_screenshot(
					route_index,
					scope_label,
					source_scene_id,
					"command",
					command_count,
					route_commands_total,
					output_dir,
					warmup_frames,
					command,
					command_index + 1,
					commands.size()
				)
				route_index += 1
				if bool(entry.get("ok", false)):
					screenshots.append(entry)
				else:
					failures.append(str(entry.get("failure", "unknown")))
					ok = false
					break
		if not ok:
			break
		if not StoryFlags.has_all(director.story_repository.get_required_flags(source_scene_id)):
			failures.append("route missing required flag %s for %s" % [
				_smoke_first_missing(director.story_repository.get_required_flags(source_scene_id)),
				source_scene_id,
			])
			ok = false
			break
	if ok and not full_route:
		var final_entry := await _capture_current_route_screenshot(
			route_index,
			scope_label,
			"route",
			"final",
			command_count,
			command_count,
			output_dir,
			warmup_frames
		)
		if bool(final_entry.get("ok", false)):
			screenshots.append(final_entry)
		else:
			failures.append(str(final_entry.get("failure", "unknown")))
	_suppress_runtime_dialogic = false
	return {
		"screenshots": screenshots,
		"failures": failures,
		"route_command_count": command_count,
	}


func _capture_current_route_screenshot(
	route_index: int,
	scope_label: String,
	source_scene_id: String,
	checkpoint: String,
	command_index: int,
	commands_total: int,
	output_dir: String,
	warmup_frames: int,
	command: String = "",
	scene_command_index: int = 0,
	scene_commands_total: int = 0
) -> Dictionary:
	for _frame in range(warmup_frames):
		await get_tree().process_frame

	if DisplayServer.get_name() == "headless":
		return {"ok": false, "failure": "headless display has no viewport texture"}

	var scene_id := GameState.current_scene_id
	var location_id := GameState.current_location_id
	var story_scene: Dictionary = director.story_repository.get_scene(scene_id)
	var location: Dictionary = director.story_repository.get_location(scene_id, location_id)
	if location.is_empty():
		return {"ok": false, "failure": "missing route location %s/%s" % [scene_id, location_id]}

	var viewport_texture := get_viewport().get_texture()
	var image: Image = null
	if viewport_texture != null:
		image = viewport_texture.get_image()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		return {"ok": false, "failure": "empty route image %s/%s" % [scene_id, location_id]}

	var filename := "%03d-%s-%s__%s__%03d-%s.png" % [
		route_index,
		_safe_filename(scope_label),
		_safe_filename(source_scene_id),
		_safe_filename(checkpoint),
		command_index,
		_safe_filename(location_id),
	]
	var path := output_dir.path_join(filename)
	var save_error := image.save_png(path)
	if save_error != OK:
		return {"ok": false, "failure": "save failed %s error=%s" % [path, save_error]}

	var visual: Dictionary = director.visual_repository.get_location_visual(scene_id, location_id)
	return {
		"ok": true,
		"scope": scope_label,
		"route_index": route_index,
		"route_source_scene_id": source_scene_id,
		"checkpoint": checkpoint,
		"command": command,
		"command_index": command_index,
		"commands_total": commands_total,
		"scene_command_index": scene_command_index,
		"scene_commands_total": scene_commands_total,
		"choice_labels": exploration_view.current_choice_labels(),
		"scene_id": scene_id,
		"scene_title": str(story_scene.get("title", "")),
		"location_id": location_id,
		"location_name": str(location.get("name", location_id)),
		"terrain": str(visual.get("terrain", "")),
		"visual_family": str(visual.get("visual_family", "")),
		"asset_scene": str(visual.get("asset_scene", "")),
		"asset_status": str(visual.get("asset_status", "")),
		"asset_loaded": _visual_has_backdrop(visual),
		"asset_runtime_path": str(visual.get("illustrated_backdrop", "")),
		"hotspot_markers_visible": exploration_view.hotspot_markers_visible(),
		"debug_flags_visible": exploration_view.debug_flags_visible(),
		"tileset_id": str(visual.get("tileset_id", "")),
		"visual_mood": str(visual.get("visual_mood", "")),
		"visual_style": _arg_value(OS.get_cmdline_user_args(), "--visual-style", "nova"),
		"props": _capture_prop_summary(visual),
		"path": path,
		"file": filename,
	}


func _route_checkpoint_indexes(command_total: int) -> Dictionary:
	var indexes := {}
	var mid_index: int = maxi(0, int(command_total / 2))
	var before_end_index: int = maxi(0, command_total - 1)
	_append_route_checkpoint(indexes, 0, "start")
	_append_route_checkpoint(indexes, mid_index, "mid")
	_append_route_checkpoint(indexes, before_end_index, "before_end")
	return indexes


func _append_route_checkpoint(indexes: Dictionary, command_index: int, checkpoint: String) -> void:
	var checkpoints: Array = indexes.get(command_index, [])
	checkpoints.append(checkpoint)
	indexes[command_index] = checkpoints


func _capture_location_screenshot(
	scene_index: int,
	scene_id: String,
	story_scene: Dictionary,
	location_id: String,
	location_index: int,
	output_dir: String,
	warmup_frames: int
) -> Dictionary:
	var location: Dictionary = director.story_repository.get_location(scene_id, location_id)
	if location.is_empty():
		return {"ok": false, "failure": "missing location %s/%s" % [scene_id, location_id]}

	_prepare_capture_location(scene_id, location_id)
	for _frame in range(warmup_frames):
		await get_tree().process_frame

	if DisplayServer.get_name() == "headless":
		return {"ok": false, "failure": "headless display has no viewport texture"}

	var viewport_texture := get_viewport().get_texture()
	var image: Image = null
	if viewport_texture != null:
		image = viewport_texture.get_image()
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

	var visual: Dictionary = director.visual_repository.get_location_visual(scene_id, location_id)
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
		"asset_loaded": _visual_has_backdrop(visual),
		"asset_runtime_path": str(visual.get("illustrated_backdrop", "")),
		"hotspot_markers_visible": exploration_view.hotspot_markers_visible(),
		"debug_flags_visible": exploration_view.debug_flags_visible(),
		"tileset_id": str(visual.get("tileset_id", "")),
		"visual_mood": str(visual.get("visual_mood", "")),
		"visual_style": _arg_value(OS.get_cmdline_user_args(), "--visual-style", "nova"),
		"props": _capture_prop_summary(visual),
		"path": path,
		"file": filename,
	}


func _prepare_capture_location(scene_id: String, location_id: String) -> void:
	StoryFlags.reset()
	QuestState.reset()
	for quest_scene_id in director.story_repository.scene_ids():
		var scene: Dictionary = director.story_repository.get_scene(str(quest_scene_id))
		QuestState.ensure_quest(str(quest_scene_id), str(scene.get("title", quest_scene_id)))
	QuestState.set_status(scene_id, QuestState.ACTIVE)
	GameState.start_scene(scene_id, location_id)
	for flag in director.story_repository.get_initial_flags(scene_id):
		StoryFlags.set_flag(str(flag), true)
	director.present_current_location()


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


func _visual_has_backdrop(visual: Dictionary) -> bool:
	var path := str(visual.get("illustrated_backdrop", ""))
	return not path.is_empty() and ResourceLoader.exists(path)


func _global_capture_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path


func _arg_value(args: PackedStringArray, key: String, default_value: String) -> String:
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


func _is_automation_run() -> bool:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if str(arg).begins_with("--smoke-") or str(arg).begins_with("--capture-"):
			return true
	return false
