extends Node2D
class_name DreamField

const StoryRepositoryScript := preload("res://src/dream/dream_story_repository.gd")
const VisualRepositoryScript := preload("res://src/dream/dream_visual_repository.gd")
const IllustrationRepositoryScript := preload("res://src/dream/dream_illustration_repository.gd")
const CharacterVisualRepositoryScript := preload("res://src/dream/dream_character_visual_repository.gd")
const IllustratedBackdropScript := preload("res://src/dream/dream_illustrated_backdrop.gd")
const DialogueLayerScript := preload("res://src/dream/dream_dialogue_layer.gd")
const RoomRendererScript := preload("res://src/dream/dream_room_renderer.gd")
const StoryInteractionScript := preload("res://src/dream/dream_story_interaction.gd")
const StoryReviewOverlayScript := preload("res://src/dream/dream_story_review_overlay.gd")
const GameThemeScript := preload("res://scripts/ui/game_theme.gd")
const AudioDirectorScript := preload("res://scripts/core/audio_director.gd")
const GamepieceScene := preload("res://src/field/gamepieces/gamepiece.tscn")
const PlayerControllerScene := preload("res://src/field/gamepieces/controllers/player_controller.tscn")
const DreamPlayerAnimationScene := preload("res://src/dream/dream_player_animation.tscn")

const GRID_SIZE := Vector2i(16, 9)
const CELL_SIZE := Vector2i(32, 32)
const DEFAULT_PLAYER_CELL := Vector2i(7, 7)
const ITEM_CELLS: Array[Vector2i] = [
	Vector2i(2, 2),
	Vector2i(5, 2),
	Vector2i(8, 2),
	Vector2i(10, 3),
	Vector2i(3, 5),
	Vector2i(9, 5),
	Vector2i(5, 6),
	Vector2i(8, 6),
]
const EXIT_CELLS: Array[Vector2i] = [
	Vector2i(1, 4),
	Vector2i(11, 4),
	Vector2i(6, 1),
	Vector2i(6, 7),
	Vector2i(2, 7),
	Vector2i(10, 7),
]
const ACTION_CELLS: Array[Vector2i] = [
	Vector2i(1, 2),
	Vector2i(11, 2),
	Vector2i(1, 6),
	Vector2i(11, 6),
	Vector2i(4, 1),
	Vector2i(8, 1),
	Vector2i(4, 7),
	Vector2i(8, 7),
]
const REVIEW_DEFAULT_STEP_SECONDS := 2.6
const REVIEW_MIN_STEP_SECONDS := 1.6
const REVIEW_MAX_TEXT_SECONDS := 6.5
const REVIEW_VOICE_WAIT_LIMIT_SECONDS := 10.0
const SCENE_SMOKE_FLAGS := {
	"--smoke-rpg-first-act": 0,
	"--smoke-rpg-illiterate": 1,
	"--smoke-rpg-moqi-academy": 2,
	"--smoke-rpg-dead-kingdom": 3,
	"--smoke-rpg-continuation-institute": 4,
	"--smoke-rpg-century-continuation": 5,
	"--smoke-rpg-return-star-plan": 6,
	"--smoke-rpg-lights-on-again": 7,
}

var repository: DreamStoryRepository
var visual_repository
var illustration_repository
var character_visual_repository
var flags: Dictionary = {}
var combat_state: Dictionary = {}
var current_scene_index := 0
var current_scene: Dictionary = {}
var current_location_id := ""
var current_visual: Dictionary = {}
var room_root: Node2D
var asset_scene_root: Node2D
var illustrated_backdrop
var current_asset_scene_instance: Node
var current_asset_scene_path := ""
var current_backdrop_path := ""
var interaction_root: Node2D
var label_root: Node2D
var renderer: DreamRoomRenderer
var dialogue_layer: DreamDialogueLayer
var runtime_hud_layer: CanvasLayer
var runtime_hud_root: Control
var runtime_top_bar: PanelContainer
var runtime_prompt_bar: PanelContainer
var scene_title_label: Label
var scene_hint_label: Label
var audio_director
var story_review_overlay
var player_gamepiece: Gamepiece
var seen_scene_illustrations: Dictionary = {}
var review_autoplay_running := false
var review_autoplay_paused := false
var review_walkthrough_index := 0
var review_last_command := ""
var review_last_line := ""
var review_prefix_note := ""
var review_step_seconds := 1.0


func _ready() -> void:
	_ensure_open_rpg_input_map()

	repository = StoryRepositoryScript.new()
	var data_ok := repository.load_all()
	visual_repository = VisualRepositoryScript.new()
	var visual_ok := false
	if data_ok:
		visual_ok = visual_repository.load_for_scene_ids(repository.scene_ids())
	illustration_repository = IllustrationRepositoryScript.new()
	var illustration_ok: bool = illustration_repository.load_all()
	character_visual_repository = CharacterVisualRepositoryScript.new()
	character_visual_repository.load_all()
	var args := _runtime_args()
	_apply_visual_style_from_args(args)

	if _run_headless_smoke_if_requested(args, data_ok, visual_ok, illustration_ok):
		return

	if not data_ok or not visual_ok:
		get_tree().quit(1)
		return

	audio_director = AudioDirectorScript.new()
	audio_director.enabled = not _is_smoke_run(args)
	add_child(audio_director)

	await _setup_world()
	_load_story_scene(0)
	if args.has("--capture-scene-screenshots"):
		call_deferred("_capture_scene_screenshots", args)
		return
	if args.has("--record-story-review"):
		call_deferred("_record_story_review", args)
		return
	if args.has("--play-story-review"):
		call_deferred("_play_story_review", args)
		return
	if _should_show_scene_illustrations(args) and not _should_show_story_review(args):
		call_deferred("_show_current_scene_illustrations")

	if args.has("--smoke-open-rpg-runtime"):
		call_deferred("_finish_open_rpg_runtime_smoke")
	elif args.has("--smoke-open-rpg-actions"):
		_load_story_scene(2)
		current_location_id = "node"
		current_visual = _current_visual_for_location()
		_reset_player_to_spawn()
		_build_current_room()
		call_deferred("_finish_open_rpg_action_smoke")
	elif args.has("--smoke-render-frame"):
		call_deferred("_finish_render_smoke")
	elif args.has("--smoke-open-rpg-transition-move"):
		call_deferred("_finish_open_rpg_transition_move_smoke")
	elif args.has("--smoke-story-review-mode"):
		call_deferred("_finish_story_review_mode_smoke")
	elif _should_show_story_review(args):
		call_deferred("_show_story_review_selector")


func run_story_interaction(interaction: DreamStoryInteraction) -> void:
	if interaction.interaction_kind == "exit":
		await _run_exit_interaction(interaction)
		return

	if interaction.interaction_kind == "item":
		await _run_item_interaction(interaction)
		return

	if interaction.interaction_kind == "action":
		await _run_action_interaction(interaction)


func _setup_world() -> void:
	var properties := GameboardProperties.new()
	properties.extents = Rect2i(Vector2i.ZERO, GRID_SIZE)
	properties.cell_size = CELL_SIZE
	Gameboard.properties = properties
	_rebuild_pathfinder()

	room_root = Node2D.new()
	room_root.name = "OpenRPGStoryRoom"
	add_child(room_root)

	renderer = RoomRendererScript.new()
	renderer.name = "RoomRenderer"
	room_root.add_child(renderer)

	asset_scene_root = Node2D.new()
	asset_scene_root.name = "AssetLocationRoot"
	room_root.add_child(asset_scene_root)

	illustrated_backdrop = IllustratedBackdropScript.new()
	illustrated_backdrop.name = "IllustratedBackdrop"
	illustrated_backdrop.z_index = -20
	illustrated_backdrop.visible = false
	asset_scene_root.add_child(illustrated_backdrop)

	interaction_root = Node2D.new()
	interaction_root.name = "Interactions"
	room_root.add_child(interaction_root)

	label_root = Node2D.new()
	label_root.name = "WorldLabels"
	room_root.add_child(label_root)

	player_gamepiece = GamepieceScene.instantiate()
	player_gamepiece.name = "JiziXuan"
	player_gamepiece.position = Gameboard.cell_to_pixel(DEFAULT_PLAYER_CELL)
	player_gamepiece.move_speed = 48.0
	player_gamepiece.animation_scene = DreamPlayerAnimationScene
	room_root.add_child(player_gamepiece)

	var player_changed := Callable(self, "_on_player_gamepiece_changed")
	if not Player.gamepiece_changed.is_connected(player_changed):
		Player.gamepiece_changed.connect(player_changed)
	Player.gamepiece = player_gamepiece
	var moved_callable := Callable(self, "_on_gamepiece_moved")
	if not GamepieceRegistry.gamepiece_moved.is_connected(moved_callable):
		GamepieceRegistry.gamepiece_moved.connect(moved_callable)

	Camera.gameboard_properties = properties
	Camera.scale = Vector2.ONE
	Camera.make_current()
	_fit_camera_to_board()
	_lock_camera_to_board()

	dialogue_layer = DialogueLayerScript.new()
	dialogue_layer.name = "DreamDialogueLayer"
	add_child(dialogue_layer)

	_setup_runtime_hud()
	_setup_story_review_overlay()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_F6 or key_event.physical_keycode == KEY_F6:
			_show_story_review_selector()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_F7 or key_event.physical_keycode == KEY_F7:
			_toggle_story_review_autoplay()
			get_viewport().set_input_as_handled()


func _on_player_gamepiece_changed() -> void:
	var new_gamepiece: Gamepiece = Player.gamepiece
	_lock_camera_to_board()

	for controller in get_tree().get_nodes_in_group(PlayerController.GROUP):
		controller.queue_free()

	if new_gamepiece == null:
		return

	var new_controller := PlayerControllerScene.instantiate()
	new_gamepiece.add_child(new_controller)
	if new_controller is PlayerController:
		new_controller.is_active = true


func _load_story_scene(index: int) -> void:
	current_scene_index = clampi(index, 0, max(repository.scene_count() - 1, 0))
	current_scene = repository.scene_at(current_scene_index)
	current_location_id = str(current_scene.get("start", ""))
	review_walkthrough_index = 0
	review_last_command = ""
	review_last_line = ""
	_apply_scene_initial_flags(current_scene)
	current_visual = _current_visual_for_location()
	_reset_player_to_spawn()
	_build_current_room()
	_sync_story_audio()
	_update_story_review_overlay()


func _build_current_room() -> void:
	_clear_children(interaction_root)
	_clear_children(label_root)

	var scene_id := str(current_scene.get("id", ""))
	var location := repository.location_for(current_scene, current_location_id)
	current_visual = _current_visual_for_location()
	_sync_illustrated_backdrop(current_visual)
	_sync_asset_location(current_visual)
	renderer.visible = current_asset_scene_instance == null
	if renderer.visible:
		renderer.configure(GRID_SIZE, CELL_SIZE, hash(scene_id + current_location_id))

	_rebuild_pathfinder()
	_mark_visual_blockers(current_visual)
	_mark_occupied_cells()

	if str(current_visual.get("illustrated_backdrop", "")).is_empty():
		_add_room_header(str(current_scene.get("title", scene_id)), str(location.get("name", current_location_id)), str(location.get("description", "")))
	_add_item_interactions(scene_id, location)
	_add_exit_interactions(scene_id, location)
	_add_action_interactions(scene_id, location)
	_refresh_runtime_hud(location)
	_sync_story_audio()
	_update_story_review_overlay()


func _add_room_header(scene_title: String, location_name: String, description: String) -> void:
	var label := Label.new()
	label.name = "LocationHeader"
	label.text = "%s\n%s\n%s" % [scene_title, location_name, description]
	label.position = Vector2(12, -84)
	label.size = Vector2(GRID_SIZE.x * CELL_SIZE.x - 24, 76)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.88, 0.9, 0.84))
	label_root.add_child(label)


func _setup_runtime_hud() -> void:
	runtime_hud_layer = CanvasLayer.new()
	runtime_hud_layer.name = "OpenRPGHudLayer"
	runtime_hud_layer.layer = 6
	add_child(runtime_hud_layer)

	runtime_hud_root = Control.new()
	runtime_hud_root.name = "OpenRPGHud"
	runtime_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	runtime_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	runtime_hud_layer.add_child(runtime_hud_root)

	runtime_top_bar = GameThemeScript.make_rpg_panel("TopBar", Color("#152313", 0.82))
	runtime_hud_root.add_child(runtime_top_bar)

	scene_title_label = GameThemeScript.make_label("SceneTitle", 15, GameThemeScript.COLORS.text)
	scene_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_title_label.clip_text = true
	runtime_hud_root.add_child(scene_title_label)

	runtime_prompt_bar = GameThemeScript.make_rpg_panel("PromptBar", Color("#152313", 0.78))
	runtime_hud_root.add_child(runtime_prompt_bar)

	scene_hint_label = GameThemeScript.make_label("Hint", 13, GameThemeScript.COLORS.paper)
	scene_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_hint_label.clip_text = true
	runtime_hud_root.add_child(scene_hint_label)

	_layout_runtime_hud()


func _setup_story_review_overlay() -> void:
	story_review_overlay = StoryReviewOverlayScript.new()
	story_review_overlay.name = "StoryReviewOverlay"
	add_child(story_review_overlay)
	story_review_overlay.configure(repository.scenes)
	story_review_overlay.scene_requested.connect(_on_story_review_scene_requested)
	story_review_overlay.autoplay_requested.connect(_toggle_story_review_autoplay)
	story_review_overlay.pause_requested.connect(_toggle_story_review_pause)
	story_review_overlay.step_requested.connect(_run_story_review_manual_step)
	story_review_overlay.close_requested.connect(_hide_story_review_selector)
	_update_story_review_overlay()


func _refresh_runtime_hud(location: Dictionary) -> void:
	if runtime_hud_root == null:
		return
	scene_title_label.text = "%d/%d  %s    %s" % [
		current_scene_index + 1,
		repository.scene_count(),
		str(current_scene.get("title", current_scene.get("id", ""))),
		_objective_for_current_scene(),
	]
	scene_hint_label.text = "%s · WASD/方向键移动，靠近发光物件后按 Space/Enter 互动" % str(location.get("name", current_location_id))


func _set_runtime_hud_visible(visible: bool) -> void:
	if runtime_hud_root != null:
		runtime_hud_root.visible = visible


func _layout_runtime_hud() -> void:
	if runtime_hud_root == null:
		return
	var view_size := get_viewport_rect().size
	if runtime_top_bar != null:
		runtime_top_bar.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		runtime_top_bar.offset_left = 20.0
		runtime_top_bar.offset_top = 10.0
		runtime_top_bar.offset_right = minf(view_size.x - 20.0, 900.0)
		runtime_top_bar.offset_bottom = 54.0
	if scene_title_label != null:
		scene_title_label.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		scene_title_label.offset_left = 34.0
		scene_title_label.offset_top = 21.0
		scene_title_label.offset_right = minf(view_size.x - 36.0, 874.0)
		scene_title_label.offset_bottom = 46.0
	if runtime_prompt_bar != null:
		runtime_prompt_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE, false)
		runtime_prompt_bar.offset_left = 48.0
		runtime_prompt_bar.offset_top = -76.0
		runtime_prompt_bar.offset_right = -48.0
		runtime_prompt_bar.offset_bottom = -16.0
	if scene_hint_label != null:
		scene_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE, false)
		scene_hint_label.offset_left = 64.0
		scene_hint_label.offset_top = -55.0
		scene_hint_label.offset_right = -64.0
		scene_hint_label.offset_bottom = -30.0


func _objective_for_current_scene() -> String:
	match str(current_scene.get("id", "")):
		"00-prologue-lights-out":
			match current_location_id:
				"street":
					return "目标：回家，确认灯为什么没亮"
				"bedroom":
					return "目标：查看信和黑色钢笔"
				"study":
					return "目标：寻找父母留下的线索"
				_:
					return "目标：确认家里发生了什么"
	return "目标：推进当前场景"


func _show_story_review_selector() -> void:
	if story_review_overlay == null:
		return
	if dialogue_layer != null and dialogue_layer.has_method("set_review_subtitle_mode"):
		dialogue_layer.set_review_subtitle_mode(true)
	FieldEvents.input_paused.emit(true)
	story_review_overlay.show_selector()
	_update_story_review_overlay()


func _hide_story_review_selector() -> void:
	if story_review_overlay == null:
		return
	story_review_overlay.hide_selector()
	if not review_autoplay_running:
		if dialogue_layer != null and dialogue_layer.has_method("set_review_subtitle_mode"):
			dialogue_layer.set_review_subtitle_mode(false)
		FieldEvents.input_paused.emit(false)


func _on_story_review_scene_requested(index: int) -> void:
	review_autoplay_running = false
	review_autoplay_paused = false
	await _prepare_story_review_scene(index)
	_show_story_review_selector()


func _prepare_story_review_scene(index: int) -> void:
	index = clampi(index, 0, max(repository.scene_count() - 1, 0))
	if dialogue_layer != null and dialogue_layer.has_method("set_review_subtitle_mode"):
		dialogue_layer.set_review_subtitle_mode(true)
	flags.clear()
	combat_state.clear()
	seen_scene_illustrations.erase(repository.scene_id_at(index))
	review_prefix_note = _prime_story_review_flags(index)
	_load_story_scene(index)
	var location := repository.location_for(current_scene, current_location_id)
	await _show_story_review_transition_pages(str(current_scene.get("id", "")))
	if dialogue_layer != null:
		await dialogue_layer.show_message_for(
			str(current_scene.get("title", "")),
			str(location.get("description", "")),
			1.1,
			"Auto"
		)
	_update_story_review_overlay()


func _prime_story_review_flags(index: int) -> String:
	if index <= 0:
		return "从序幕开始，无需补齐前序。"

	var failures: Array[String] = []
	var completed: Array[String] = []
	for prior_index in range(index):
		var result := repository.run_walkthrough_at(prior_index, flags)
		if result.get("ok", false):
			completed.append(str(result.get("scene_id", repository.scene_id_at(prior_index))))
		else:
			failures.append_array(result.get("failures", []))

	if failures.is_empty():
		return "已按 canonical walkthrough 补齐前序 %d 幕。" % completed.size()
	return "前序补齐失败：%s。需要过渡页解释断裂。" % "; ".join(failures.slice(0, 3))


func _toggle_story_review_autoplay() -> void:
	if review_autoplay_running:
		review_autoplay_running = false
		review_autoplay_paused = false
		FieldEvents.input_paused.emit(false)
		_update_story_review_overlay()
		return

	_show_story_review_selector()
	review_autoplay_running = true
	review_autoplay_paused = false
	_update_story_review_overlay()
	call_deferred("_run_story_review_autoplay")


func _toggle_story_review_pause() -> void:
	if not review_autoplay_running:
		return
	review_autoplay_paused = not review_autoplay_paused
	_update_story_review_overlay()


func _run_story_review_manual_step() -> void:
	if review_autoplay_running and not review_autoplay_paused:
		return
	await _run_story_review_next_step(false)


func _run_story_review_autoplay() -> void:
	while review_autoplay_running:
		if review_autoplay_paused:
			await get_tree().create_timer(0.15).timeout
			continue
		var advanced := await _run_story_review_next_step(true)
		if not advanced:
			review_autoplay_running = false
			review_autoplay_paused = false
			FieldEvents.input_paused.emit(false)
			break
		await get_tree().create_timer(0.12).timeout
	_update_story_review_overlay()


func _run_story_review_next_step(timed_dialogue: bool, allow_scene_advance: bool = true) -> bool:
	var walkthrough: Array = current_scene.get("walkthrough", [])
	if review_walkthrough_index >= walkthrough.size():
		return await _finish_story_review_scene(timed_dialogue, allow_scene_advance)

	var command := str(walkthrough[review_walkthrough_index])
	review_last_command = command
	review_walkthrough_index += 1
	var result := _apply_story_review_command(command)
	_play_story_event(_story_event_for_command(command))
	review_last_line = str(result.get("line", ""))
	_build_current_room()
	_update_story_review_overlay()
	if dialogue_layer != null:
		var duration := _story_review_line_duration(review_last_line, timed_dialogue)
		var has_voice := _play_story_voice(review_last_line)
		await dialogue_layer.show_message_for(str(result.get("title", command)), review_last_line, duration, "Auto")
		if timed_dialogue and has_voice:
			await _wait_for_story_voice(REVIEW_VOICE_WAIT_LIMIT_SECONDS)
	if repository.is_scene_complete(current_scene, flags):
		return await _finish_story_review_scene(timed_dialogue, allow_scene_advance)
	_update_story_review_overlay()
	return true


func _finish_story_review_scene(timed_dialogue: bool, allow_scene_advance: bool = true) -> bool:
	var scene_title := str(current_scene.get("title", current_scene.get("id", "")))
	if not repository.is_scene_complete(current_scene, flags):
		review_last_line = "当前 walkthrough 已结束，但章节完成 flags 未满足。"
		if dialogue_layer != null:
			await dialogue_layer.show_message_for(scene_title, review_last_line, 1.2, "Auto")
		_update_story_review_overlay()
		return false

	if not allow_scene_advance:
		review_last_line = "本幕已按 canonical walkthrough 播放完毕。"
		if dialogue_layer != null:
			await dialogue_layer.show_message_for(scene_title, review_last_line, 1.0, "Auto")
		_update_story_review_overlay()
		return false

	if current_scene_index >= repository.scene_count() - 1:
		review_last_line = "全部章节已按剧情验收路径播放完毕。"
		if dialogue_layer != null:
			await dialogue_layer.show_message_for(scene_title, review_last_line, 1.4, "Auto")
		_update_story_review_overlay()
		return false

	if timed_dialogue:
		await dialogue_layer.show_message_for(scene_title, "本幕完成，进入下一幕过渡页。", 0.8, "Auto")
	review_prefix_note = ""
	_load_story_scene(current_scene_index + 1)
	seen_scene_illustrations.erase(str(current_scene.get("id", "")))
	await _show_story_review_transition_pages(str(current_scene.get("id", "")))
	var location := repository.location_for(current_scene, current_location_id)
	if dialogue_layer != null:
		await dialogue_layer.show_message_for(str(current_scene.get("title", "")), str(location.get("description", "")), 1.0, "Auto")
	_update_story_review_overlay()
	return true


func _show_story_review_transition_pages(scene_id: String) -> void:
	if dialogue_layer == null or illustration_repository == null:
		return
	var records: Array[Dictionary] = illustration_repository.illustrations_for_scene(scene_id)
	var transition_records: Array[Dictionary] = []
	for record in records:
		if _is_story_review_transition_record(record):
			transition_records.append(record)
	if transition_records.is_empty() and not records.is_empty():
		transition_records.append(records[0])

	if transition_records.is_empty():
		var title := str(current_scene.get("title", scene_id))
		await dialogue_layer.show_message_for(title, "章节过渡页缺失；如果此处读感断裂，可以补一张 Imagen 过渡插图。", 1.0, "Auto")
		return

	_set_runtime_hud_visible(false)
	for record in transition_records:
		await dialogue_layer.show_illustration_for(
			str(record.get("title", current_scene.get("title", scene_id))),
			str(record.get("caption", "")),
			str(record.get("path", "")),
			1.2,
			"Auto"
		)
	_set_runtime_hud_visible(true)


func _is_story_review_transition_record(record: Dictionary) -> bool:
	if bool(record.get("transition", false)):
		return true
	return not record.has("locations") and not record.has("commands")


func _apply_story_review_command(command: String) -> Dictionary:
	var parts := command.split(" ", false, 1)
	if parts.is_empty():
		return {"title": "无效指令", "line": command}
	var verb := parts[0]
	var target := parts[1] if parts.size() > 1 else ""
	match verb:
		"inspect":
			return _apply_story_review_inspect(target)
		"go":
			return _apply_story_review_go(target)
		"cast":
			return _apply_story_review_action("cast", target)
		"build":
			return _apply_story_review_action("build", target)
		"choose":
			return _apply_story_review_action("choose", target)
		"engage":
			return _apply_story_review_action("engage", target)
		"combine":
			return _apply_story_review_action("combine", target)
		"write":
			return _apply_story_review_action("write", target)
		"attack":
			return _apply_story_review_action("attack", target)
	return {"title": command, "line": "未识别的剧情验收指令。"}


func _apply_story_review_inspect(item_id: String) -> Dictionary:
	var location := repository.location_for(current_scene, current_location_id)
	var items: Dictionary = location.get("items", {})
	var item: Dictionary = items.get(item_id, {})
	var result := repository.inspect_item(current_scene, current_location_id, item_id, flags)
	if not result.get("ok", false):
		return {"title": item_id, "line": str(result.get("error", "inspect failed"))}
	return {
		"title": str(item.get("name", item_id)),
		"line": str(result.get("text", item.get("text", ""))),
	}


func _apply_story_review_go(destination_id: String) -> Dictionary:
	var result := repository.go_to(current_scene, current_location_id, destination_id)
	if not result.get("ok", false):
		return {"title": destination_id, "line": str(result.get("error", "missing route"))}
	current_location_id = destination_id
	current_visual = _current_visual_for_location()
	_reset_player_to_spawn()
	_sync_story_audio()
	var location := repository.location_for(current_scene, current_location_id)
	var intro := str(location.get("location_intro", ""))
	var description := str(location.get("description", ""))
	return {
		"title": str(location.get("name", current_location_id)),
		"line": intro if not intro.is_empty() else description,
	}


func _apply_story_review_action(verb: String, arg: String) -> Dictionary:
	var location := repository.location_for(current_scene, current_location_id)
	var record := _story_review_record_for_action(location, verb, arg)
	var result: Dictionary = {}
	match verb:
		"cast":
			result = repository.cast_glyph(current_scene, current_location_id, arg, flags, combat_state)
		"build":
			result = repository.apply_location_record(current_scene, current_location_id, "build_actions", arg, flags)
		"choose":
			result = repository.apply_location_record(current_scene, current_location_id, "choices", arg, flags)
		"engage":
			result = repository.apply_location_record(current_scene, current_location_id, "encounters", arg, flags)
		"combine":
			result = repository.apply_location_record(current_scene, current_location_id, "combos", arg, flags)
		"write":
			result = repository.write_name(current_scene, current_location_id, flags, combat_state)
		"attack":
			result = repository.attack(current_scene, current_location_id, flags, combat_state)
		_:
			result = {"ok": false, "error": "unknown action"}

	if not result.get("ok", false):
		return {"title": _story_review_action_title(verb, arg, record), "line": str(result.get("error", "action failed"))}

	var text := str(record.get("text", ""))
	if text.is_empty():
		text = _story_review_default_action_text(verb, arg)
	return {"title": _story_review_action_title(verb, arg, record), "line": text}


func _story_review_record_for_action(location: Dictionary, verb: String, arg: String) -> Dictionary:
	match verb:
		"cast":
			var glyph_actions: Dictionary = location.get("glyph_actions", {})
			if glyph_actions.has(arg):
				return glyph_actions[arg]
			var combat: Dictionary = location.get("combat", {})
			var spells: Dictionary = combat.get("spells", {})
			if spells.has(arg):
				return spells[arg]
			return combat if arg == "name" or arg == "名" else {}
		"build":
			return _record_from_collection(location, "build_actions", arg)
		"choose":
			return _record_from_collection(location, "choices", arg)
		"engage":
			return _record_from_collection(location, "encounters", arg)
		"combine":
			return _record_from_collection(location, "combos", arg)
		"write", "attack":
			return location.get("combat", {})
	return {}


func _record_from_collection(location: Dictionary, key: String, arg: String) -> Dictionary:
	var collection: Dictionary = location.get(key, {})
	return collection.get(arg, {})


func _story_review_action_title(verb: String, arg: String, record: Dictionary) -> String:
	if record.has("name"):
		return str(record.get("name", arg))
	match verb:
		"cast":
			return "写下「%s」" % arg
		"build":
			return "建设：%s" % arg
		"choose":
			return "选择：%s" % arg
		"engage":
			return "遭遇：%s" % arg
		"combine":
			return "组合：%s" % arg
		"write":
			return "写名"
		"attack":
			return "攻击"
	return "%s %s" % [verb, arg]


func _story_review_default_action_text(verb: String, arg: String) -> String:
	match verb:
		"write":
			return "你尝试写下它真正的名字。"
		"attack":
			return "命名后的攻击让对方的轮廓短暂稳定。"
		"cast":
			return "字根生效，场景状态发生变化。"
		"build":
			return "新的结构被写入这个世界。"
		"choose":
			return "这个选择被记录进后续剧情。"
	return "剧情节点已推进。"


func _update_story_review_overlay() -> void:
	if story_review_overlay == null or repository == null or current_scene.is_empty():
		return
	var location := repository.location_for(current_scene, current_location_id)
	var walkthrough: Array = current_scene.get("walkthrough", [])
	var illustration := _story_review_illustration(str(current_scene.get("id", "")))
	var character_refs: Array = illustration.get("characters", [])
	var character_assets: Array[Dictionary] = []
	if character_visual_repository != null and character_visual_repository.has_method("story_review_assets_for"):
		character_assets = character_visual_repository.story_review_assets_for(character_refs)
	story_review_overlay.update_status({
		"scene_title": "%d/%d  %s" % [current_scene_index + 1, repository.scene_count(), str(current_scene.get("title", ""))],
		"location_name": str(location.get("name", current_location_id)),
		"step_index": review_walkthrough_index,
		"step_count": walkthrough.size(),
		"flags": _story_review_flag_summary(),
		"last_line": review_last_line,
		"running": review_autoplay_running,
		"paused": review_autoplay_paused,
		"prefix_note": review_prefix_note,
		"background_path": str(illustration.get("path", "")),
		"focus_path": str(illustration.get("focus_path", "")),
		"illustration_title": str(illustration.get("title", "")),
		"illustration_caption": str(illustration.get("caption", "")),
		"characters": character_assets,
	})


func _story_review_illustration(scene_id: String) -> Dictionary:
	if illustration_repository == null:
		return {}
	if illustration_repository.has_method("review_illustration_for"):
		return illustration_repository.review_illustration_for(scene_id, current_location_id, review_last_command)
	var records: Array[Dictionary] = illustration_repository.illustrations_for_scene(scene_id)
	return records[0] if not records.is_empty() else {}


func _story_review_flag_summary() -> String:
	var keys := flags.keys()
	keys.sort()
	if keys.is_empty():
		return "none"
	if keys.size() <= 10:
		return ", ".join(keys)
	return "%s ... +%d" % [", ".join(keys.slice(max(0, keys.size() - 10), keys.size())), keys.size() - 10]


func _add_item_interactions(scene_id: String, location: Dictionary) -> void:
	var items: Dictionary = location.get("items", {})
	var keys := items.keys()
	keys.sort()

	for index in range(keys.size()):
		var item_id := str(keys[index])
		var item: Dictionary = items[item_id]
		var visual_prop: Dictionary = visual_repository.item_prop(scene_id, current_location_id, item_id)
		var cell: Vector2i = _interaction_cell_for_prop(visual_prop, ITEM_CELLS[index % ITEM_CELLS.size()])
		var display_name := str(item.get("name", item_id))
		var interaction := _make_story_interaction("item", scene_id, current_location_id, item_id, display_name, item, cell)
		interaction_root.add_child(interaction)
		_add_marker_label(cell, _inspected_prefix(item) + display_name, Color(0.95, 0.86, 0.38))


func _add_exit_interactions(scene_id: String, location: Dictionary) -> void:
	var exits: Dictionary = location.get("exits", {})
	var keys := exits.keys()
	keys.sort()

	for index in range(keys.size()):
		var destination_id := str(keys[index])
		var visual_prop: Dictionary = visual_repository.exit_prop(scene_id, current_location_id, destination_id)
		var cell: Vector2i = _interaction_cell_for_prop(visual_prop, EXIT_CELLS[index % EXIT_CELLS.size()])
		var display_name := str(exits[destination_id])
		var payload := {"destination": destination_id}
		var interaction := _make_story_interaction("exit", scene_id, current_location_id, destination_id, display_name, payload, cell)
		interaction_root.add_child(interaction)
		_add_marker_label(cell, "-> " + display_name, Color(0.5, 0.86, 1.0))


func _add_action_interactions(scene_id: String, location: Dictionary) -> void:
	var action_records: Array[Dictionary] = []
	_append_action_records(action_records, location.get("encounters", {}), "engage", "!", "遭遇")
	_append_action_records(action_records, location.get("glyph_actions", {}), "cast", "字", "字根")
	_append_action_records(action_records, location.get("build_actions", {}), "build", "+", "建设")
	_append_action_records(action_records, location.get("choices", {}), "choose", "?", "选择")
	_append_action_records(action_records, location.get("combos", {}), "combine", "&", "组合")

	var combat: Dictionary = location.get("combat", {})
	if not combat.is_empty():
		var spells: Dictionary = combat.get("spells", {})
		_append_action_records(action_records, spells, "cast", "术", "战术")
		action_records.append({"verb": "write", "arg": "name", "label": "写名", "record": combat})
		action_records.append({"verb": "attack", "arg": "", "label": "攻击", "record": combat})

	for index in range(action_records.size()):
		var record := action_records[index]
		var visual_prop: Dictionary = visual_repository.action_prop(scene_id, current_location_id, str(record.get("verb", "")), str(record.get("arg", "")))
		var cell: Vector2i = _interaction_cell_for_prop(visual_prop, ACTION_CELLS[index % ACTION_CELLS.size()])
		var label := str(visual_prop.get("label", record.get("label", record.get("arg", ""))))
		var interaction := _make_story_interaction("action", scene_id, current_location_id, str(record.get("arg", "")), label, record, cell)
		interaction_root.add_child(interaction)
		_add_marker_label(cell, label, Color(0.72, 1.0, 0.58))


func _append_action_records(target: Array[Dictionary], records: Dictionary, verb: String, prefix: String, title: String) -> void:
	var keys := records.keys()
	keys.sort()
	for key in keys:
		var record: Dictionary = records[key]
		var record_name := str(record.get("name", key))
		target.append({
			"verb": verb,
			"arg": str(key),
			"label": "%s %s" % [prefix, record_name if record_name != str(key) else "%s:%s" % [title, key]],
			"record": record,
		})


func _make_story_interaction(
		kind: String,
		scene_id: String,
		location_id: String,
		target_id: String,
		display_name: String,
		payload: Dictionary,
		cell: Vector2i
) -> DreamStoryInteraction:
	var interaction: DreamStoryInteraction = StoryInteractionScript.new()
	interaction.name = "%s_%s" % [kind.capitalize(), target_id]
	interaction.position = Gameboard.cell_to_pixel(cell)
	interaction.configure(self, kind, scene_id, location_id, target_id, display_name, payload)

	var area := Area2D.new()
	area.name = "InteractionArea2D"
	area.collision_layer = 16
	area.collision_mask = 8
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	area.add_child(shape)
	interaction.add_child(area)

	var button := Button.new()
	button.name = "Button"
	button.offset_left = -14.0
	button.offset_top = -14.0
	button.offset_right = 14.0
	button.offset_bottom = 14.0
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.flat = true
	interaction.add_child(button)

	area.area_entered.connect(Callable(interaction, "_on_area_entered"))
	area.area_exited.connect(Callable(interaction, "_on_area_exited"))
	return interaction


func _add_marker_label(cell: Vector2i, text: String, color: Color) -> void:
	if not str(current_visual.get("illustrated_backdrop", "")).is_empty():
		return
	var label := Label.new()
	label.text = text
	label.position = Gameboard.cell_to_pixel(cell) + Vector2(-42, 12)
	label.size = Vector2(84, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	label_root.add_child(label)


func _run_item_interaction(interaction: DreamStoryInteraction) -> void:
	var item := interaction.payload
	var missing := repository.missing_required_flags(item, flags)
	if not missing.is_empty():
		_play_story_event("blocked")
		await dialogue_layer.show_message(interaction.display_name, "Missing required evidence: %s" % ", ".join(missing))
		return

	_play_story_event("interact")
	var gained := repository.apply_item_flags(item, flags)
	var gained_text := ""
	if not gained.is_empty():
		gained_text = "\n\nFlags: %s" % ", ".join(gained)

	var text := str(item.get("text", ""))
	_play_story_voice(text)
	await dialogue_layer.show_message(interaction.display_name, text + gained_text)

	if repository.is_scene_complete(current_scene, flags):
		await _complete_current_scene()
	else:
		_build_current_room()
		_resume_field_input_after_room_rebuild()


func _run_action_interaction(interaction: DreamStoryInteraction) -> void:
	var verb := str(interaction.payload.get("verb", ""))
	var arg := str(interaction.payload.get("arg", ""))
	var result: Dictionary = {}
	match verb:
		"cast":
			result = repository.cast_glyph(current_scene, current_location_id, arg, flags, combat_state)
		"build":
			result = repository.apply_location_record(current_scene, current_location_id, "build_actions", arg, flags)
		"choose":
			result = repository.apply_location_record(current_scene, current_location_id, "choices", arg, flags)
		"engage":
			result = repository.apply_location_record(current_scene, current_location_id, "encounters", arg, flags)
		"combine":
			result = repository.apply_location_record(current_scene, current_location_id, "combos", arg, flags)
		"write":
			result = repository.write_name(current_scene, current_location_id, flags, combat_state)
		"attack":
			result = repository.attack(current_scene, current_location_id, flags, combat_state)
		_:
			result = {"ok": false, "error": "unknown action"}

	if not result.get("ok", false):
		_play_story_event("blocked")
		await dialogue_layer.show_message(interaction.display_name, str(result.get("error", "Action failed.")))
		return

	_play_story_event(_story_event_for_action(verb, arg))
	var record: Dictionary = interaction.payload.get("record", {})
	var text := str(record.get("text", "Action resolved."))
	_play_story_voice(text)
	await dialogue_layer.show_message(interaction.display_name, text)
	if repository.is_scene_complete(current_scene, flags):
		await _complete_current_scene()
	else:
		_build_current_room()
		_resume_field_input_after_room_rebuild()


func _run_exit_interaction(interaction: DreamStoryInteraction) -> void:
	var destination_id := interaction.target_id
	var result := repository.go_to(current_scene, current_location_id, destination_id)
	if not result.get("ok", false):
		_play_story_event("blocked")
		await dialogue_layer.show_message(interaction.display_name, "This route is not available.")
		return

	current_location_id = destination_id
	current_visual = _current_visual_for_location()
	_reset_player_to_spawn()
	_build_current_room()
	var location := repository.location_for(current_scene, current_location_id)
	_sync_story_audio()
	await dialogue_layer.show_message(str(location.get("name", current_location_id)), str(location.get("description", "")))
	_resume_field_input_after_room_rebuild()


func _complete_current_scene() -> void:
	var scene_title := str(current_scene.get("title", current_scene.get("id", "")))
	if current_scene_index >= repository.scene_count() - 1:
		await dialogue_layer.show_message(scene_title, "All migrated Dream Coastline story scenes are complete.")
		return

	current_scene_index += 1
	current_scene = repository.scene_at(current_scene_index)
	current_location_id = str(current_scene.get("start", ""))
	_apply_scene_initial_flags(current_scene)
	current_visual = _current_visual_for_location()
	_reset_player_to_spawn()
	_build_current_room()
	var location := repository.location_for(current_scene, current_location_id)
	_sync_story_audio()
	await _show_scene_illustrations(str(current_scene.get("id", "")))
	await dialogue_layer.show_message(str(current_scene.get("title", "")), str(location.get("description", "")))
	_resume_field_input_after_room_rebuild()


func _show_current_scene_illustrations() -> void:
	await _show_scene_illustrations(str(current_scene.get("id", "")))


func _show_scene_illustrations(scene_id: String) -> void:
	if dialogue_layer == null or illustration_repository == null:
		return
	if seen_scene_illustrations.has(scene_id):
		return

	var records: Array[Dictionary] = illustration_repository.illustrations_for_scene(scene_id)
	if records.is_empty():
		return

	seen_scene_illustrations[scene_id] = true
	_set_runtime_hud_visible(false)
	var fallback_title := str(current_scene.get("title", scene_id))
	for record in records:
		var title := str(record.get("title", fallback_title))
		var caption := str(record.get("caption", ""))
		var path := str(record.get("path", ""))
		await dialogue_layer.show_illustration(title, caption, path)
	_set_runtime_hud_visible(true)


func _inspected_prefix(item: Dictionary) -> String:
	for flag in repository.flags_for_item(item):
		if not flags.has(flag):
			return ""
	return "* "


func _apply_scene_initial_flags(scene: Dictionary) -> void:
	for flag in scene.get("initial_flags", []):
		flags[str(flag)] = true


func _current_visual_for_location() -> Dictionary:
	if visual_repository == null:
		return {}
	return visual_repository.location_visual(str(current_scene.get("id", "")), current_location_id)


func _sync_asset_location(visual: Dictionary) -> void:
	var path := str(visual.get("asset_scene", ""))
	if path == current_asset_scene_path and current_asset_scene_instance != null:
		_apply_asset_overlay_alpha(visual)
		return

	_clear_asset_location()
	if path.is_empty():
		return
	if not ResourceLoader.exists(path):
		push_warning("Missing Dream visual asset scene: %s" % path)
		return

	var packed_resource: Resource = load(path)
	if not (packed_resource is PackedScene):
		push_warning("Dream visual asset is not a scene: %s" % path)
		return

	var instance := (packed_resource as PackedScene).instantiate()
	if instance == null:
		push_warning("Could not instantiate Dream visual asset scene: %s" % path)
		return

	current_asset_scene_instance = instance
	current_asset_scene_path = path
	asset_scene_root.add_child(current_asset_scene_instance)
	_apply_asset_overlay_alpha(visual)


func _sync_illustrated_backdrop(visual: Dictionary) -> void:
	if illustrated_backdrop == null:
		return
	var path := str(visual.get("illustrated_backdrop", ""))
	if path.is_empty():
		current_backdrop_path = ""
		illustrated_backdrop.visible = false
		illustrated_backdrop.texture = null
		return
	if path == current_backdrop_path and illustrated_backdrop.visible:
		return
	if not ResourceLoader.exists(path):
		push_warning("Missing illustrated backdrop texture: %s" % path)
		current_backdrop_path = ""
		illustrated_backdrop.visible = false
		illustrated_backdrop.texture = null
		return
	var resource := load(path)
	if not (resource is Texture2D):
		push_warning("Illustrated backdrop is not a texture: %s" % path)
		current_backdrop_path = ""
		illustrated_backdrop.visible = false
		illustrated_backdrop.texture = null
		return
	current_backdrop_path = path
	illustrated_backdrop.configure(resource as Texture2D, Vector2(GRID_SIZE * CELL_SIZE))
	illustrated_backdrop.visible = true


func _fit_camera_to_board() -> void:
	if Camera == null:
		return
	var viewport_size := get_viewport_rect().size
	var board_size := Vector2(GRID_SIZE * CELL_SIZE)
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	var zoom := minf(viewport_size.x / board_size.x, viewport_size.y / board_size.y)
	zoom = maxf(1.0, floor(zoom * 100.0) / 100.0)
	Camera.zoom = Vector2(zoom, zoom)


func _lock_camera_to_board() -> void:
	if Camera == null:
		return
	Camera.gamepiece = null
	Camera.position = Vector2(GRID_SIZE * CELL_SIZE) * 0.5
	Camera.reset_smoothing()


func _apply_asset_overlay_alpha(visual: Dictionary) -> void:
	if current_asset_scene_instance == null:
		return
	var alpha := float(visual.get("asset_overlay_alpha", 1.0))
	alpha = clampf(alpha, 0.0, 1.0)
	if current_asset_scene_instance is CanvasItem:
		(current_asset_scene_instance as CanvasItem).modulate = Color(1, 1, 1, alpha)


func _clear_asset_location() -> void:
	current_asset_scene_path = ""
	current_asset_scene_instance = null
	if asset_scene_root == null:
		return
	for child in asset_scene_root.get_children():
		if child == illustrated_backdrop:
			continue
		child.queue_free()


func _reset_player_to_spawn() -> void:
	if player_gamepiece == null:
		return

	var scene_id := str(current_scene.get("id", ""))
	var spawn_cell: Vector2i = visual_repository.spawn_cell(scene_id, current_location_id, DEFAULT_PLAYER_CELL)
	var old_cell := GamepieceRegistry.get_cell(player_gamepiece)
	player_gamepiece.position = Gameboard.cell_to_pixel(spawn_cell)
	player_gamepiece.follower.progress = 0
	player_gamepiece.curve = null
	player_gamepiece.set_process(false)
	if old_cell != Gameboard.INVALID_CELL and old_cell != spawn_cell:
		if GamepieceRegistry.get_gamepiece(spawn_cell) == null:
			GamepieceRegistry.move_gamepiece(player_gamepiece, spawn_cell)


func _rebuild_pathfinder() -> void:
	if Gameboard.pathfinder == null:
		Gameboard.pathfinder = Pathfinder.new()
	else:
		Gameboard.pathfinder.clear()

	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			var cell := Vector2i(x, y)
			Gameboard.pathfinder.add_point(Gameboard.cell_to_index(cell), cell)

	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			var cell := Vector2i(x, y)
			var source_id := Gameboard.cell_to_index(cell)
			for neighbor in [cell + Vector2i.RIGHT, cell + Vector2i.DOWN]:
				if Gameboard.properties.extents.has_point(neighbor):
					Gameboard.pathfinder.connect_points(source_id, Gameboard.cell_to_index(neighbor))


func _mark_visual_blockers(visual: Dictionary) -> void:
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			if x == 0 or y == 0 or x == GRID_SIZE.x - 1 or y == GRID_SIZE.y - 1:
				_disable_path_cell(Vector2i(x, y))

	for prop in visual.get("props", []):
		if typeof(prop) != TYPE_DICTIONARY:
			continue
		if not bool(prop.get("solid", false)):
			continue
		var rect: Rect2i = visual_repository.prop_rect(prop)
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_disable_path_cell(Vector2i(x, y))


func _disable_path_cell(cell: Vector2i) -> void:
	if not Gameboard.properties.extents.has_point(cell):
		return
	var cell_id := Gameboard.cell_to_index(cell)
	if Gameboard.pathfinder.has_point(cell_id):
		Gameboard.pathfinder.set_point_disabled(cell_id, true)


func _disabled_path_point_count() -> int:
	var count := 0
	for cell_id in Gameboard.pathfinder.get_point_ids():
		if Gameboard.pathfinder.is_point_disabled(cell_id):
			count += 1
	return count


func _interaction_cell_for_prop(prop: Dictionary, fallback: Vector2i) -> Vector2i:
	var base_cell: Vector2i = visual_repository.prop_cell(prop, fallback)
	if prop.is_empty() or _path_cell_is_open(base_cell):
		return base_cell

	var best_cell := Gameboard.INVALID_CELL
	var best_distance := 999
	for y in range(max(0, base_cell.y - 4), min(GRID_SIZE.y, base_cell.y + 5)):
		for x in range(max(0, base_cell.x - 4), min(GRID_SIZE.x, base_cell.x + 5)):
			var candidate := Vector2i(x, y)
			if not _path_cell_is_open(candidate):
				continue
			if not _interaction_cell_is_reachable(candidate):
				continue
			var distance := absi(candidate.x - base_cell.x) + absi(candidate.y - base_cell.y)
			if distance < best_distance:
				best_cell = candidate
				best_distance = distance

	if best_cell != Gameboard.INVALID_CELL:
		return best_cell
	return base_cell


func _path_cell_is_open(cell: Vector2i) -> bool:
	if not Gameboard.properties.extents.has_point(cell):
		return false
	var cell_id := Gameboard.cell_to_index(cell)
	return Gameboard.pathfinder.has_point(cell_id) and not Gameboard.pathfinder.is_point_disabled(cell_id)


func _mark_occupied_cells() -> void:
	for cell in GamepieceRegistry.get_occupied_cells():
		var cell_id := Gameboard.cell_to_index(cell)
		if Gameboard.pathfinder.has_point(cell_id):
			Gameboard.pathfinder.set_point_disabled(cell_id, true)


func _resume_field_input_after_room_rebuild() -> void:
	Cutscene._is_cutscene_in_progress = false
	FieldEvents.input_paused.emit(false)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _run_headless_smoke_if_requested(args: PackedStringArray, data_ok: bool, visual_ok: bool, illustration_ok: bool) -> bool:
	if args.has("--smoke-audio-director"):
		var director = AudioDirectorScript.new()
		var ok: bool = director.verify_streams()
		print("audio-director-smoke status=%s streams=%s" % ["PASS" if ok else "FAIL", director.streams.size()])
		director.free()
		get_tree().quit(0 if ok else 1)
		return true

	if args.has("--smoke-input-map"):
		var ok := _run_input_map_smoke()
		get_tree().quit(0 if ok else 1)
		return true

	if args.has("--smoke-animation-clips"):
		var ok := _run_animation_resource_smoke()
		get_tree().quit(0 if ok else 1)
		return true

	if args.has("--smoke-visual-asset-scenes"):
		var ok := _run_visual_asset_scene_smoke(visual_ok)
		get_tree().quit(0 if ok else 1)
		return true

	if args.has("--smoke-open-rpg-visual-scenes"):
		var ok := data_ok and visual_ok and _run_open_rpg_visual_scene_smoke()
		get_tree().quit(0 if ok else 1)
		return true

	if args.has("--smoke-chapter-illustrations"):
		var ok := data_ok and illustration_ok and _run_chapter_illustration_smoke()
		get_tree().quit(0 if ok else 1)
		return true

	if not data_ok:
		return false

	if args.has("--smoke-open-rpg-story") or args.has("--smoke-autoplay") or args.has("--smoke-rpg-progression"):
		var result := repository.run_all_walkthroughs()
		_print_story_smoke(result, "all")
		get_tree().quit(0 if result.get("ok", false) else 1)
		return true

	for flag in SCENE_SMOKE_FLAGS.keys():
		if args.has(flag):
			var result := _run_story_smoke_until(int(SCENE_SMOKE_FLAGS[flag]))
			_print_story_smoke(result, flag)
			get_tree().quit(0 if result.get("ok", false) else 1)
			return true

	return false


func _sync_story_audio() -> void:
	if audio_director == null:
		return
	audio_director.sync_story_context(str(current_scene.get("id", "")), current_location_id)


func _play_story_event(event_name: String) -> void:
	if audio_director == null or event_name.is_empty():
		return
	if audio_director.has_method("play_event"):
		audio_director.play_event(event_name)
		return
	if audio_director.has_method("play_story_event"):
		if bool(audio_director.play_story_event(event_name)):
			return
	match event_name:
		"step":
			if audio_director.has_method("play_step"):
				audio_director.play_step()
		"interact":
			if audio_director.has_method("play_interact"):
				audio_director.play_interact()
		"transition":
			if audio_director.has_method("play_transition"):
				audio_director.play_transition()
		"blocked":
			if audio_director.has_method("play_blocked"):
				audio_director.play_blocked()


func _play_story_voice(text: String) -> bool:
	if audio_director == null:
		return false
	return bool(audio_director.play_story_voice_for_text(str(current_scene.get("id", "")), text))


func _story_event_for_command(command: String) -> String:
	var parts := command.split(" ", false, 1)
	if parts.is_empty():
		return ""
	var arg := parts[1] if parts.size() > 1 else ""
	return _story_event_for_action(parts[0], arg)


func _story_event_for_action(verb: String, arg: String = "") -> String:
	match verb:
		"inspect", "combine", "choose":
			return "interact"
		"build":
			return "build"
		"engage":
			return "engage"
		"cast":
			if arg in ["name", "door", "fire", "stop"]:
				return "cast_%s" % arg
			return "interact"
		"go":
			return ""
		"write":
			return "write"
		"attack":
			return "attack"
	return ""


func _on_gamepiece_moved(gp: Gamepiece, _new_cell: Vector2i, old_cell: Vector2i) -> void:
	if gp != player_gamepiece or old_cell == Gameboard.INVALID_CELL:
		return
	_play_story_event("step")


func _wait_for_story_voice(limit_seconds: float) -> void:
	if audio_director == null or not audio_director.has_method("is_story_voice_playing"):
		return
	var waited := 0.0
	while waited < limit_seconds and bool(audio_director.is_story_voice_playing()):
		await get_tree().create_timer(0.1).timeout
		waited += 0.1


func _story_review_line_duration(line: String, timed_dialogue: bool) -> float:
	if not timed_dialogue:
		return 0.65
	var compact := line.strip_edges()
	if compact.is_empty():
		return review_step_seconds
	var readable_seconds := REVIEW_MIN_STEP_SECONDS + minf(float(compact.length()) * 0.045, REVIEW_MAX_TEXT_SECONDS - REVIEW_MIN_STEP_SECONDS)
	return maxf(review_step_seconds, readable_seconds)


func _is_smoke_run(args: PackedStringArray) -> bool:
	for arg in args:
		if str(arg).begins_with("--smoke-") or str(arg).begins_with("--capture-") or str(arg).begins_with("--record-"):
			return true
	return false


func _should_show_scene_illustrations(args: PackedStringArray) -> bool:
	for arg in args:
		if str(arg).begins_with("--smoke-") or str(arg).begins_with("--capture-") or str(arg).begins_with("--record-") or str(arg).begins_with("--play-"):
			return false
	return true


func _should_show_story_review(args: PackedStringArray) -> bool:
	if args.has("--skip-story-review"):
		return false
	for arg in args:
		if str(arg).begins_with("--smoke-") or str(arg).begins_with("--capture-") or str(arg).begins_with("--record-") or str(arg).begins_with("--play-"):
			return false
	return true


func _run_story_smoke_until(last_index: int) -> Dictionary:
	var smoke_flags: Dictionary = {}
	var failures: Array[String] = []
	var completed: Array[String] = []
	for index in range(last_index + 1):
		var result := repository.run_walkthrough_at(index, smoke_flags)
		if result.get("ok", false):
			completed.append(str(result.get("scene_id", repository.scene_id_at(index))))
		else:
			failures.append_array(result.get("failures", []))

	return {
		"ok": failures.is_empty(),
		"completed": completed,
		"failures": failures,
		"flags": smoke_flags.keys(),
	}


func _print_story_smoke(result: Dictionary, scope: String) -> void:
	var status := "PASS" if result.get("ok", false) else "FAIL"
	print("open-rpg-story-smoke status=%s scope=%s scenes=%d flags=%d" % [
		status,
		scope,
		result.get("completed", []).size(),
		result.get("flags", []).size(),
	])
	for failure in result.get("failures", []):
		push_error(str(failure))


func _run_input_map_smoke() -> bool:
	var required := ["ui_left", "ui_right", "ui_up", "ui_down", "ui_accept", "interact", "back"]
	var missing: Array[String] = []
	for action in required:
		if not InputMap.has_action(action):
			missing.append(action)
	var ok := missing.is_empty()
	print("open-rpg-input-smoke status=%s missing=%s" % ["PASS" if ok else "FAIL", ", ".join(missing)])
	return ok


func _run_animation_resource_smoke() -> bool:
	var required := [
		"res://src/field/gamepieces/gamepiece.tscn",
		"res://src/field/gamepieces/controllers/player_controller.tscn",
		"res://src/dream/dream_player_animation.tscn",
		"res://src/field/gamepieces/animation/gamepiece_animation.tscn",
	]
	var missing: Array[String] = []
	for path in required:
		if not ResourceLoader.exists(path):
			missing.append(path)
	var ok := missing.is_empty()
	print("open-rpg-animation-smoke status=%s missing=%d" % ["PASS" if ok else "FAIL", missing.size()])
	return ok


func _run_visual_asset_scene_smoke(visual_ok: bool) -> bool:
	var dir := DirAccess.open("res://data/visual_scenes")
	if dir == null:
		print("open-rpg-visual-data-smoke status=FAIL files=0")
		return false
	var count := 0
	for file_name in dir.get_files():
		if file_name.ends_with(".json"):
			count += 1
	var ok := visual_ok and count >= repository.scene_count()
	print("open-rpg-visual-data-smoke status=%s files=%d" % ["PASS" if ok else "FAIL", count])
	return ok


func _run_open_rpg_visual_scene_smoke() -> bool:
	var result: Dictionary = visual_repository.validate_asset_scenes(repository.scene_ids())
	var ok := bool(result.get("ok", false))
	print("open-rpg-visual-scene-smoke status=%s assets=%d illustrated=%d failures=%d" % [
		"PASS" if ok else "FAIL",
		int(result.get("checked", 0)),
		int(result.get("illustrated", 0)),
		result.get("failures", []).size(),
	])
	for failure in result.get("failures", []):
		push_error(str(failure))
	return ok


func _run_chapter_illustration_smoke() -> bool:
	var result: Dictionary = illustration_repository.validate_scene_illustrations(repository.scene_ids())
	var ok := bool(result.get("ok", false))
	print("chapter-illustration-smoke status=%s checked=%d failures=%d" % [
		"PASS" if ok else "FAIL",
		int(result.get("checked", 0)),
		result.get("failures", []).size(),
	])
	for failure in result.get("failures", []):
		push_error(str(failure))
	return ok


func _visual_alignment_for_interactions() -> Dictionary:
	var failures: Array[String] = []
	var checked := 0
	if interaction_root == null:
		return {"ok": false, "checked": checked, "failures": ["missing interaction root"]}

	for child in interaction_root.get_children():
		if not (child is DreamStoryInteraction):
			continue
		var interaction := child as DreamStoryInteraction
		var expected := _visual_cell_for_interaction(interaction)
		if expected == Gameboard.INVALID_CELL:
			failures.append("%s missing visual prop for %s/%s/%s" % [
				interaction.name,
				interaction.story_scene_id,
				interaction.location_id,
				interaction.target_id,
			])
			continue
		checked += 1
		var actual := Gameboard.pixel_to_cell(interaction.position)
		if actual != expected:
			failures.append("%s expected %s actual %s" % [interaction.name, str(expected), str(actual)])
		if not _interaction_cell_is_reachable(expected):
			failures.append("%s at %s is not reachable from player spawn" % [interaction.name, str(expected)])

	if checked == 0:
		failures.append("no visual-backed interactions checked")

	return {
		"ok": failures.is_empty(),
		"checked": checked,
		"failures": failures,
	}


func _visual_cell_for_interaction(interaction: DreamStoryInteraction) -> Vector2i:
	var prop: Dictionary = {}
	match interaction.interaction_kind:
		"item":
			prop = visual_repository.item_prop(interaction.story_scene_id, interaction.location_id, interaction.target_id)
		"exit":
			prop = visual_repository.exit_prop(interaction.story_scene_id, interaction.location_id, interaction.target_id)
		"action":
			prop = visual_repository.action_prop(
				interaction.story_scene_id,
				interaction.location_id,
				str(interaction.payload.get("verb", "")),
				str(interaction.payload.get("arg", ""))
			)
	if prop.is_empty():
		return Gameboard.INVALID_CELL
	return _interaction_cell_for_prop(prop, Gameboard.INVALID_CELL)


func _interaction_cell_is_reachable(target_cell: Vector2i) -> bool:
	if player_gamepiece == null:
		return false
	var player_cell := GamepieceRegistry.get_cell(player_gamepiece)
	if player_cell == Gameboard.INVALID_CELL:
		return false
	if target_cell in Gameboard.get_adjacent_cells(player_cell):
		return true
	return not Gameboard.pathfinder.get_path_cells_to_adjacent_cell(player_cell, target_cell).is_empty()


func _finish_open_rpg_runtime_smoke() -> void:
	await get_tree().process_frame
	var interaction_count := interaction_root.get_child_count() if interaction_root != null else 0
	var point_count := Gameboard.pathfinder.get_point_ids().size()
	var asset_loaded := current_asset_scene_instance != null
	var disabled_count := _disabled_path_point_count()
	var visual_alignment := _visual_alignment_for_interactions()
	var visual_aligned := bool(visual_alignment.get("ok", false))
	var camera_locked := Camera != null and Camera.gamepiece == null and Camera.position.is_equal_approx(Vector2(GRID_SIZE * CELL_SIZE) * 0.5)
	var ok := Player.gamepiece != null and point_count == GRID_SIZE.x * GRID_SIZE.y and interaction_count > 0 and dialogue_layer != null and asset_loaded and disabled_count > 0 and visual_aligned and camera_locked
	print("open-rpg-runtime-smoke status=%s points=%d disabled=%d interactions=%d visual_aligned=%s camera_locked=%s player=%s asset=%s" % [
		"PASS" if ok else "FAIL",
		point_count,
		disabled_count,
		interaction_count,
		str(visual_aligned),
		str(camera_locked),
		str(Player.gamepiece != null),
		current_asset_scene_path,
	])
	for failure in visual_alignment.get("failures", []):
		push_error(str(failure))
	get_tree().quit(0 if ok else 1)


func _finish_open_rpg_action_smoke() -> void:
	await get_tree().process_frame
	var action_count := 0
	var verbs: Dictionary = {}
	for child in interaction_root.get_children():
		if child is DreamStoryInteraction and child.interaction_kind == "action":
			action_count += 1
			verbs[str(child.payload.get("verb", ""))] = true
	var required := ["cast", "write", "attack"]
	var missing: Array[String] = []
	for verb in required:
		if not verbs.has(verb):
			missing.append(verb)
	var visual_alignment := _visual_alignment_for_interactions()
	var visual_aligned := bool(visual_alignment.get("ok", false))
	var ok := action_count >= 3 and missing.is_empty() and current_asset_scene_instance != null and visual_aligned
	print("open-rpg-action-smoke status=%s location=%s actions=%d verbs=%s visual_aligned=%s asset=%s" % [
		"PASS" if ok else "FAIL",
		current_location_id,
		action_count,
		", ".join(verbs.keys()),
		str(visual_aligned),
		current_asset_scene_path,
	])
	for failure in visual_alignment.get("failures", []):
		push_error(str(failure))
	get_tree().quit(0 if ok else 1)


func _finish_open_rpg_transition_move_smoke() -> void:
	await get_tree().process_frame
	var failures: Array[String] = []
	var exit_interaction: DreamStoryInteraction = null
	for child in interaction_root.get_children():
		if child is DreamStoryInteraction:
			var interaction := child as DreamStoryInteraction
			if interaction.interaction_kind == "exit" and interaction.target_id == "building":
				exit_interaction = interaction
				break

	if exit_interaction == null:
		failures.append("missing street to building exit interaction")
	else:
		exit_interaction.run()
		await get_tree().process_frame
		if dialogue_layer != null:
			dialogue_layer.advanced.emit()
		await get_tree().process_frame
		await get_tree().process_frame

	var player_cell := GamepieceRegistry.get_cell(player_gamepiece) if player_gamepiece != null else Gameboard.INVALID_CELL
	var right_path := Gameboard.pathfinder.get_path_to_cell(player_cell, player_cell + Vector2i.RIGHT)
	var down_path := Gameboard.pathfinder.get_path_to_cell(player_cell, player_cell + Vector2i.DOWN)
	var controller_active := false
	for controller in get_tree().get_nodes_in_group(PlayerController.GROUP):
		if controller is PlayerController:
			controller_active = controller_active or (controller as PlayerController).is_active

	if current_location_id != "building":
		failures.append("expected building after transition, got %s" % current_location_id)
	if not controller_active:
		failures.append("player controller inactive after transition")
	if player_cell == Gameboard.INVALID_CELL:
		failures.append("player has invalid registry cell after transition")
	if right_path.is_empty() and down_path.is_empty():
		failures.append("player cannot path from building spawn %s" % str(player_cell))

	var ok := failures.is_empty()
	print("open-rpg-transition-move-smoke status=%s location=%s player=%s controller_active=%s right_path=%d down_path=%d" % [
		"PASS" if ok else "FAIL",
		current_location_id,
		str(player_cell),
		str(controller_active),
		right_path.size(),
		down_path.size(),
	])
	for failure in failures:
		push_error(failure)
	get_tree().quit(0 if ok else 1)


func _finish_story_review_mode_smoke() -> void:
	await get_tree().process_frame
	await _prepare_story_review_scene(3)
	var prefix_ok := flags.has("defeated_nameless") and flags.has("viewed_parent_record")
	var step_ok := await _run_story_review_next_step(false)
	var overlay_ok: bool = story_review_overlay != null and story_review_overlay.scene_count() == repository.scene_count()
	var ok: bool = prefix_ok and step_ok and overlay_ok and review_walkthrough_index > 0 and not review_last_line.is_empty()
	print("story-review-mode-smoke status=%s scene=%s step=%d flags=%d prefix_ok=%s overlay=%s" % [
		"PASS" if ok else "FAIL",
		str(current_scene.get("id", "")),
		review_walkthrough_index,
		flags.size(),
		str(prefix_ok),
		str(overlay_ok),
	])
	get_tree().quit(0 if ok else 1)


func _finish_render_smoke() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image: Image = get_viewport().get_texture().get_image()
	var image_ok := _verify_render_image(image)
	var ok := current_asset_scene_instance != null and image_ok
	print("render-smoke status=%s architecture=open-rpg scene=%s location=%s asset=%s" % [
		"PASS" if ok else "FAIL",
		current_scene.get("id", ""),
		current_location_id,
		current_asset_scene_path,
	])
	get_tree().quit(0 if ok else 1)


func _capture_scene_screenshots(args: PackedStringArray) -> void:
	var output_dir := _global_capture_path(_arg_value(args, "--capture-output", "user://scene-screenshots"))
	var scene_filter := _arg_value(args, "--capture-scene", "all")
	var scope := _arg_value(args, "--capture-scope", "locations")
	var warmup_frames := maxi(1, int(_arg_value(args, "--capture-warmup-frames", "3")))
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK:
		print("scene-screenshot-capture status=FAIL architecture=open-rpg reason=mkdir path=%s error=%s" % [output_dir, mkdir_error])
		get_tree().quit(1)
		return

	var screenshots: Array[Dictionary] = []
	var failures: Array[String] = []
	for scene_index in range(repository.scene_count()):
		var scene_id := repository.scene_id_at(scene_index)
		if scene_filter != "all" and scene_filter != scene_id:
			continue
		var story_scene := repository.scene_at(scene_index)
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
		"version": 2,
		"generated_by": "--capture-scene-screenshots",
		"architecture": "open-rpg",
		"visual_style": GameThemeScript.visual_style(),
		"visual_style_label": GameThemeScript.visual_style_label(),
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
		print("scene-screenshot-capture status=FAIL architecture=open-rpg reason=manifest path=%s" % manifest_path)
		get_tree().quit(1)
		return
	manifest_file.store_string(JSON.stringify(manifest, "\t"))
	manifest_file.close()

	var ok := failures.is_empty() and not screenshots.is_empty()
	print("scene-screenshot-capture status=%s architecture=open-rpg output=%s screenshots=%s failures=%s" % [
		"PASS" if ok else "FAIL",
		output_dir,
		screenshots.size(),
		failures.size(),
	])
	get_tree().quit(0 if ok else 1)


func _record_story_review(args: PackedStringArray) -> void:
	var output_dir := _global_capture_path(_arg_value(args, "--record-output", "user://story-review-recording"))
	var scene_id := _arg_value(args, "--record-scene", "01-illiterate")
	var warmup_frames := maxi(1, int(_arg_value(args, "--record-warmup-frames", "2")))
	var scene_index := _scene_index_for_id(scene_id)
	if scene_index < 0:
		print("story-review-record status=FAIL reason=missing-scene scene=%s" % scene_id)
		get_tree().quit(1)
		return
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK:
		print("story-review-record status=FAIL reason=mkdir path=%s error=%s" % [output_dir, mkdir_error])
		get_tree().quit(1)
		return

	story_review_overlay.show_selector()
	await _prepare_story_review_scene(scene_index)
	for _frame in range(warmup_frames):
		await get_tree().process_frame

	var frames: Array[Dictionary] = []
	var failures: Array[String] = []
	var frame_index := 0
	var start_frame := await _capture_story_review_frame(output_dir, frame_index, "start")
	if bool(start_frame.get("ok", false)):
		frames.append(start_frame)
	else:
		failures.append(str(start_frame.get("failure", "start capture failed")))
	frame_index += 1

	var walkthrough: Array = current_scene.get("walkthrough", [])
	while current_scene_index == scene_index and review_walkthrough_index < walkthrough.size():
		var command := str(walkthrough[review_walkthrough_index])
		var advanced := await _run_story_review_next_step(false)
		for _frame in range(warmup_frames):
			await get_tree().process_frame
		var frame := await _capture_story_review_frame(output_dir, frame_index, command)
		if bool(frame.get("ok", false)):
			frames.append(frame)
		else:
			failures.append(str(frame.get("failure", "capture failed")))
		frame_index += 1
		if not advanced:
			break

	var manifest := {
		"version": 1,
		"generated_by": "--record-story-review",
		"scene_id": scene_id,
		"scene_index": scene_index,
		"frame_count": frames.size(),
		"viewport": {
			"width": int(get_viewport_rect().size.x),
			"height": int(get_viewport_rect().size.y),
		},
		"frames": frames,
		"failures": failures,
	}
	var manifest_path := output_dir.path_join("manifest.json")
	var manifest_file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if manifest_file == null:
		print("story-review-record status=FAIL reason=manifest path=%s" % manifest_path)
		get_tree().quit(1)
		return
	manifest_file.store_string(JSON.stringify(manifest, "\t"))
	manifest_file.close()

	var ok := failures.is_empty() and frames.size() >= 2
	print("story-review-record status=%s scene=%s output=%s frames=%d failures=%d" % [
		"PASS" if ok else "FAIL",
		scene_id,
		output_dir,
		frames.size(),
		failures.size(),
	])
	get_tree().quit(0 if ok else 1)


func _play_story_review(args: PackedStringArray) -> void:
	var scene_id := _arg_value(args, "--review-scene", _arg_value(args, "--record-scene", "01-illiterate"))
	var scope := _arg_value(args, "--review-scope", "scene")
	var scene_index := _scene_index_for_id(scene_id)
	if scene_index < 0:
		print("story-review-playback status=FAIL reason=missing-scene scene=%s" % scene_id)
		get_tree().quit(1)
		return

	review_step_seconds = maxf(REVIEW_MIN_STEP_SECONDS, float(_arg_value(args, "--review-step-seconds", str(REVIEW_DEFAULT_STEP_SECONDS))))
	var max_steps := maxi(1, int(_arg_value(args, "--review-max-steps", "320")))
	var allow_scene_advance := scope == "all"
	if story_review_overlay != null and story_review_overlay.has_method("set_cinema_mode"):
		story_review_overlay.set_cinema_mode(true)
	story_review_overlay.show_selector()
	review_autoplay_running = true
	review_autoplay_paused = false
	FieldEvents.input_paused.emit(true)
	await _prepare_story_review_scene(scene_index)

	var steps := 0
	var completed := false
	while steps < max_steps:
		var advanced := await _run_story_review_next_step(true, allow_scene_advance)
		steps += 1
		await get_tree().create_timer(0.05).timeout
		if not advanced:
			completed = true
			break

	review_autoplay_running = false
	review_autoplay_paused = false
	FieldEvents.input_paused.emit(false)
	if dialogue_layer != null and dialogue_layer.has_method("set_review_subtitle_mode"):
		dialogue_layer.set_review_subtitle_mode(false)
	if story_review_overlay != null and story_review_overlay.has_method("set_cinema_mode"):
		story_review_overlay.set_cinema_mode(false)
	_update_story_review_overlay()
	if not completed and steps >= max_steps:
		print("story-review-playback status=FAIL reason=max-steps scene=%s scope=%s steps=%d" % [scene_id, scope, steps])
		get_tree().quit(1)
		return

	await get_tree().create_timer(0.4).timeout
	print("story-review-playback status=PASS scene=%s scope=%s steps=%d final_scene=%s" % [
		scene_id,
		scope,
		steps,
		str(current_scene.get("id", "")),
	])
	get_tree().quit(0)


func _capture_story_review_frame(output_dir: String, frame_index: int, command: String) -> Dictionary:
	await get_tree().process_frame
	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		return {"ok": false, "failure": "empty frame %d" % frame_index}
	var filename := "frame_%04d.png" % frame_index
	var path := output_dir.path_join(filename)
	var save_error := image.save_png(path)
	if save_error != OK:
		return {"ok": false, "failure": "save failed %s error=%s" % [path, save_error]}
	var illustration := _story_review_illustration(str(current_scene.get("id", "")))
	return {
		"ok": true,
		"index": frame_index,
		"command": command,
		"scene_id": str(current_scene.get("id", "")),
		"scene_title": str(current_scene.get("title", "")),
		"location_id": current_location_id,
		"location_name": repository.location_name(current_scene, current_location_id),
		"step_index": review_walkthrough_index,
		"step_count": current_scene.get("walkthrough", []).size(),
		"line": review_last_line,
		"illustration_id": str(illustration.get("id", "")),
		"illustration_title": str(illustration.get("title", "")),
		"illustration_path": str(illustration.get("path", "")),
		"path": path,
		"file": filename,
	}


func _scene_index_for_id(scene_id: String) -> int:
	for index in range(repository.scene_count()):
		if repository.scene_id_at(index) == scene_id:
			return index
	return -1


func _capture_location_screenshot(
	scene_index: int,
	scene_id: String,
	story_scene: Dictionary,
	location_id: String,
	location_index: int,
	output_dir: String,
	warmup_frames: int
) -> Dictionary:
	var location := repository.location_for(story_scene, location_id)
	if location.is_empty():
		return {"ok": false, "failure": "missing location %s/%s" % [scene_id, location_id]}

	_prepare_capture_location(scene_index, location_id)
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
		"asset_loaded": current_asset_scene_instance != null,
		"asset_runtime_path": current_asset_scene_path,
		"tileset_id": str(visual.get("tileset_id", "")),
		"visual_mood": str(visual.get("visual_mood", "")),
		"visual_style": GameThemeScript.visual_style(),
		"props": _capture_prop_summary(visual),
		"path": path,
		"file": filename,
	}


func _prepare_capture_location(scene_index: int, location_id: String) -> void:
	flags.clear()
	combat_state.clear()
	_load_story_scene(scene_index)
	current_location_id = location_id
	current_visual = _current_visual_for_location()
	_reset_player_to_spawn()
	_build_current_room()


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


func _verify_render_image(image: Image) -> bool:
	if image == null:
		print("render-frame-smoke status=FAIL reason=no-image")
		return false

	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		print("render-frame-smoke status=FAIL reason=empty-image size=%sx%s" % [width, height])
		return false

	var step_x: int = max(1, int(ceil(float(width) / 48.0)))
	var step_y: int = max(1, int(ceil(float(height) / 36.0)))
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


func _apply_visual_style_from_args(args: PackedStringArray) -> void:
	GameThemeScript.set_visual_style(_arg_value(args, "--visual-style", GameThemeScript.DEFAULT_STYLE))


func _runtime_args() -> PackedStringArray:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		return args
	return OS.get_cmdline_args()


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


func _ensure_open_rpg_input_map() -> void:
	_add_key_action("ui_left", [KEY_LEFT, KEY_A])
	_add_key_action("ui_right", [KEY_RIGHT, KEY_D])
	_add_key_action("ui_up", [KEY_UP, KEY_W])
	_add_key_action("ui_down", [KEY_DOWN, KEY_S])
	_add_key_action("ui_accept", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	_add_key_action("interact", [KEY_SPACE])
	_add_key_action("back", [KEY_ESCAPE])


func _add_key_action(action: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keycodes:
		var exists := false
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and ((event as InputEventKey).keycode == keycode or (event as InputEventKey).physical_keycode == keycode):
				exists = true
				break
		if not exists:
			var key := InputEventKey.new()
			key.physical_keycode = keycode
			InputMap.action_add_event(action, key)
