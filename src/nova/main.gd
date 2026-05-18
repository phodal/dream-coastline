extends Control

const SceneDirectorScript := preload("res://src/nova/scene_director.gd")
const ExplorationViewScript := preload("res://src/nova/world/exploration_view.gd")
const VNLayerScript := preload("res://src/nova/ui/vn_layer.gd")
const DialogicBridgeScript := preload("res://src/nova/dialogic_bridge.gd")

var director
var exploration_view
var vn_layer
var dialogic_bridge


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	director = SceneDirectorScript.new()
	director.name = "SceneDirector"
	add_child(director)

	exploration_view = ExplorationViewScript.new()
	exploration_view.name = "ExplorationView"
	exploration_view.inspect_requested.connect(_inspect_item)
	exploration_view.move_requested.connect(_move_to)
	add_child(exploration_view)

	vn_layer = VNLayerScript.new()
	vn_layer.name = "VNLayer"
	vn_layer.accepted.connect(_finish_cutscene)
	add_child(vn_layer)

	dialogic_bridge = DialogicBridgeScript.new()
	dialogic_bridge.name = "DialogicBridge"
	dialogic_bridge.finished.connect(_finish_cutscene)
	add_child(dialogic_bridge)

	director.location_presented.connect(_present_location)
	director.cutscene_started.connect(_show_cutscene)
	director.runtime_error.connect(_runtime_error)

	if not director.boot():
		get_tree().quit(1)
		return
	if OS.get_cmdline_user_args().has("--smoke-nova-runtime"):
		call_deferred("_run_smoke")
	elif OS.get_cmdline_user_args().has("--smoke-dialogic-bridge"):
		call_deferred("_run_dialogic_bridge_smoke")
	elif OS.get_cmdline_user_args().has("--capture-nova-screenshot"):
		call_deferred("_capture_screenshot")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _present_location(scene_id: String, location_id: String, location: Dictionary, visual: Dictionary) -> void:
	exploration_view.present(scene_id, location_id, location, visual, director.build_location_choices())


func _inspect_item(item_id: String) -> void:
	director.inspect_item(item_id)


func _move_to(location_id: String) -> void:
	director.move_to(location_id)


func _show_cutscene(payload: Dictionary) -> void:
	var backdrop_path: String = director.visual_repository.get_backdrop_path(GameState.current_scene_id, GameState.current_location_id)
	if not dialogic_bridge.play_payload(payload, backdrop_path):
		vn_layer.show_payload(payload, backdrop_path)


func _finish_cutscene(payload: Dictionary) -> void:
	director.finish_cutscene(payload)


func _runtime_error(message: String) -> void:
	push_warning(message)


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


func _run_dialogic_bridge_smoke() -> void:
	var backdrop_path: String = director.visual_repository.get_backdrop_path(GameState.current_scene_id, GameState.current_location_id)
	var ok: bool = dialogic_bridge.smoke({
		"speaker": "旁白",
		"title": "Dialogic Bridge Smoke",
		"text": "Dialogic timeline bridge is available.",
		"flags": ["dialogic_bridge_smoke"],
	}, backdrop_path)
	print("dialogic-bridge-smoke status=%s installed=%s backdrop=%s" % [
		"PASS" if ok else "FAIL",
		str(dialogic_bridge.is_dialogic_installed()),
		backdrop_path,
	])
	get_tree().quit(0 if ok else 1)


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
