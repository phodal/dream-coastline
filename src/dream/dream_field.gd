extends Node2D
class_name DreamField

const StoryRepositoryScript := preload("res://src/dream/dream_story_repository.gd")
const VisualRepositoryScript := preload("res://src/dream/dream_visual_repository.gd")
const IllustrationRepositoryScript := preload("res://src/dream/dream_illustration_repository.gd")
const IllustratedBackdropScript := preload("res://src/dream/dream_illustrated_backdrop.gd")
const DialogueLayerScript := preload("res://src/dream/dream_dialogue_layer.gd")
const RoomRendererScript := preload("res://src/dream/dream_room_renderer.gd")
const StoryInteractionScript := preload("res://src/dream/dream_story_interaction.gd")
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
var player_gamepiece: Gamepiece
var seen_scene_illustrations: Dictionary = {}


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
	var args := OS.get_cmdline_user_args()

	if _run_headless_smoke_if_requested(args, data_ok, visual_ok, illustration_ok):
		return

	if not data_ok or not visual_ok:
		get_tree().quit(1)
		return

	await _setup_world()
	_load_story_scene(0)
	if _should_show_scene_illustrations(args):
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
	player_gamepiece.animation_scene = DreamPlayerAnimationScene
	room_root.add_child(player_gamepiece)

	var player_changed := Callable(self, "_on_player_gamepiece_changed")
	if not Player.gamepiece_changed.is_connected(player_changed):
		Player.gamepiece_changed.connect(player_changed)
	Player.gamepiece = player_gamepiece

	Camera.gameboard_properties = properties
	Camera.scale = Vector2.ONE
	Camera.make_current()
	_fit_camera_to_board()
	Camera.reset_position()

	dialogue_layer = DialogueLayerScript.new()
	dialogue_layer.name = "DreamDialogueLayer"
	add_child(dialogue_layer)


func _on_player_gamepiece_changed() -> void:
	var new_gamepiece: Gamepiece = Player.gamepiece
	Camera.gamepiece = new_gamepiece

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
	_apply_scene_initial_flags(current_scene)
	current_visual = _current_visual_for_location()
	_reset_player_to_spawn()
	_build_current_room()


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

	if not str(current_visual.get("illustrated_backdrop", "")).is_empty():
		_add_room_caption(str(location.get("name", current_location_id)))
	else:
		_add_room_header(str(current_scene.get("title", scene_id)), str(location.get("name", current_location_id)), str(location.get("description", "")))
	_add_item_interactions(scene_id, location)
	_add_exit_interactions(scene_id, location)
	_add_action_interactions(scene_id, location)


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


func _add_room_caption(location_name: String) -> void:
	var label := Label.new()
	label.name = "LocationCaption"
	label.text = location_name
	label.position = Vector2(12, 10)
	label.size = Vector2(GRID_SIZE.x * CELL_SIZE.x - 24, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#fff8df", 0.88))
	label.add_theme_color_override("font_outline_color", Color("#050608", 0.9))
	label.add_theme_constant_override("outline_size", 2)
	label_root.add_child(label)


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
		await dialogue_layer.show_message(interaction.display_name, "Missing required evidence: %s" % ", ".join(missing))
		return

	var gained := repository.apply_item_flags(item, flags)
	var gained_text := ""
	if not gained.is_empty():
		gained_text = "\n\nFlags: %s" % ", ".join(gained)

	await dialogue_layer.show_message(interaction.display_name, str(item.get("text", "")) + gained_text)

	if repository.is_scene_complete(current_scene, flags):
		await _complete_current_scene()
	else:
		_build_current_room()


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
		await dialogue_layer.show_message(interaction.display_name, str(result.get("error", "Action failed.")))
		return

	var record: Dictionary = interaction.payload.get("record", {})
	var text := str(record.get("text", "Action resolved."))
	await dialogue_layer.show_message(interaction.display_name, text)
	if repository.is_scene_complete(current_scene, flags):
		await _complete_current_scene()
	else:
		_build_current_room()


func _run_exit_interaction(interaction: DreamStoryInteraction) -> void:
	var destination_id := interaction.target_id
	var result := repository.go_to(current_scene, current_location_id, destination_id)
	if not result.get("ok", false):
		await dialogue_layer.show_message(interaction.display_name, "This route is not available.")
		return

	current_location_id = destination_id
	current_visual = _current_visual_for_location()
	_reset_player_to_spawn()
	_build_current_room()
	var location := repository.location_for(current_scene, current_location_id)
	await dialogue_layer.show_message(str(location.get("name", current_location_id)), str(location.get("description", "")))


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
	await _show_scene_illustrations(str(current_scene.get("id", "")))
	await dialogue_layer.show_message(str(current_scene.get("title", "")), str(location.get("description", "")))


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
	var fallback_title := str(current_scene.get("title", scene_id))
	for record in records:
		var title := str(record.get("title", fallback_title))
		var caption := str(record.get("caption", ""))
		var path := str(record.get("path", ""))
		await dialogue_layer.show_illustration(title, caption, path)


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


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _run_headless_smoke_if_requested(args: PackedStringArray, data_ok: bool, visual_ok: bool, illustration_ok: bool) -> bool:
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


func _should_show_scene_illustrations(args: PackedStringArray) -> bool:
	for arg in args:
		if str(arg).begins_with("--smoke-"):
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
	var ok := Player.gamepiece != null and point_count == GRID_SIZE.x * GRID_SIZE.y and interaction_count > 0 and dialogue_layer != null and asset_loaded and disabled_count > 0 and visual_aligned
	print("open-rpg-runtime-smoke status=%s points=%d disabled=%d interactions=%d visual_aligned=%s player=%s asset=%s" % [
		"PASS" if ok else "FAIL",
		point_count,
		disabled_count,
		interaction_count,
		str(visual_aligned),
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
