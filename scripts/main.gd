extends Node2D

const BASE_SIZE := Vector2(1280.0, 720.0)
const PIXEL := 4.0
const PLAYER_SPEED := 250.0

const COLORS := {
	"ink": Color("#101018"),
	"wall": Color("#657392"),
	"paper_shadow": Color("#c89f66"),
	"wood": Color("#7a4a32"),
	"wood_dark": Color("#3d2635"),
	"red": Color("#d24a43"),
	"gold": Color("#e5b94e"),
	"white": Color("#f6f0d8"),
}

const RPG_TILESET := preload("res://assets/opengameart/rpg_tileset/open_tileset.png")
const RPG_CHARACTERS := preload("res://assets/opengameart/rpg_characters/rpg_16x16.png")
const PAPER_ICONS := preload("res://assets/opengameart/paper_icons/Paper.png")
const CASTLE_WALLS := preload("res://assets/opengameart/castle_tileset/castle_tileset_part1.png")
const CASTLE_METAL := preload("res://assets/opengameart/castle_tileset/castle_tileset_part2.png")
const CASTLE_PROPS := preload("res://assets/opengameart/castle_tileset/castle_tileset_part3.png")
const SPELL_DARKNESS := preload("res://assets/opengameart/spells/png/darkness_orb.png")
const SPELL_MAGIC_ORB := preload("res://assets/opengameart/spells/png/magic_orb.png")
const SPELL_SPARKS := preload("res://assets/opengameart/spells/png/magic_sparks.png")
const SPELL_FIREBALL := preload("res://assets/opengameart/spells/png/fireball.png")
const DUNGEON_CRAWL := preload("res://assets/opengameart/dungeon_crawl/DungeonCrawl_ProjectUtumnoTileset.png")
const OpeningModelScript := preload("res://scripts/opening_model.gd")

var model: RefCounted = OpeningModelScript.new()
var total_time := 0.0
var smoke_autoplay := false
var smoke_autoplay_elapsed := 0.0
var player_position := Vector2(300.0, 438.0)
var last_mouse_down := false
var last_advance_down := false
var last_reset_down := false
var last_step_keys := {
	KEY_A: false,
	KEY_D: false,
	KEY_W: false,
	KEY_S: false,
	KEY_LEFT: false,
	KEY_RIGHT: false,
	KEY_UP: false,
	KEY_DOWN: false,
}

var title_label: Label
var narration_label: Label
var hint_label: Label
var letter_label: Label
var mode_label: Label
var next_button: Button
var reset_button: Button


func _ready() -> void:
	smoke_autoplay = OS.get_cmdline_user_args().has("--smoke-autoplay")
	model.load_beats()
	_build_ui()
	_update_text()


func _process(delta: float) -> void:
	total_time += delta
	model.update(delta)
	_poll_discrete_input()
	_handle_movement(delta)

	if smoke_autoplay and not model.is_final():
		smoke_autoplay_elapsed += delta
		if smoke_autoplay_elapsed >= 0.55:
			smoke_autoplay_elapsed = 0.0
			_advance()

	_update_text()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _handle_key_press(event.keycode):
			get_viewport().set_input_as_handled()


func _handle_key_press(keycode: Key) -> bool:
	match keycode:
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			_advance()
			return true
		KEY_ESCAPE:
			_reset_opening()
			return true
		KEY_A, KEY_LEFT:
			_step_player(Vector2.LEFT)
			return true
		KEY_D, KEY_RIGHT:
			_step_player(Vector2.RIGHT)
			return true
		KEY_W, KEY_UP:
			_step_player(Vector2.UP)
			return true
		KEY_S, KEY_DOWN:
			_step_player(Vector2.DOWN)
			return true
	return false


func _step_player(direction: Vector2) -> void:
	player_position += direction * 36.0
	_clamp_player_position()


func _handle_movement(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		return

	player_position += direction * PLAYER_SPEED * delta
	_clamp_player_position()


func _clamp_player_position() -> void:
	if model.is_at("ancient"):
		player_position = player_position.clamp(Vector2(96.0, 306.0), Vector2(1140.0, 500.0))
	else:
		player_position = player_position.clamp(Vector2(110.0, 178.0), Vector2(1136.0, 486.0))


func _poll_discrete_input() -> void:
	var advance_down := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
	if advance_down and not last_advance_down:
		_advance()
	last_advance_down = advance_down

	var reset_down := Input.is_key_pressed(KEY_ESCAPE)
	if reset_down and not last_reset_down:
		_reset_opening()
	last_reset_down = reset_down

	var key_steps := {
		KEY_A: Vector2.LEFT,
		KEY_D: Vector2.RIGHT,
		KEY_W: Vector2.UP,
		KEY_S: Vector2.DOWN,
		KEY_LEFT: Vector2.LEFT,
		KEY_RIGHT: Vector2.RIGHT,
		KEY_UP: Vector2.UP,
		KEY_DOWN: Vector2.DOWN,
	}
	for key: Key in key_steps.keys():
		var down := Input.is_key_pressed(key)
		if down and not bool(last_step_keys[key]):
			_step_player(key_steps[key])
		last_step_keys[key] = down

	var mouse_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if mouse_down and not last_mouse_down:
		var mouse_pos := get_viewport().get_mouse_position()
		if next_button.get_global_rect().has_point(mouse_pos):
			_advance()
		elif reset_button.get_global_rect().has_point(mouse_pos):
			_reset_opening()
	last_mouse_down = mouse_down


func _advance() -> void:
	model.advance()
	if model.is_at("ancient"):
		player_position = Vector2(420.0, 448.0)
	_update_text()


func _reset_opening() -> void:
	model.reset()
	player_position = Vector2(300.0, 438.0)
	_update_text()


func _draw() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var scale: float = min(screen.x / BASE_SIZE.x, screen.y / BASE_SIZE.y)
	var offset: Vector2 = (screen - BASE_SIZE * scale) * 0.5

	draw_set_transform(offset, 0.0, Vector2(scale, scale))
	_draw_scene_background()
	_draw_rgb_noise()

	if model.is_before("ancient"):
		_draw_dungeon_room()
		_draw_protagonist(player_position)

	if model.is_or_after("blood") and model.is_before("ancient"):
		_draw_blood_drop()
	if model.is_or_after("ink") and model.is_before("ancient"):
		_draw_ink_spread()
	if model.is_or_after("flicker") and model.is_before("ancient"):
		_draw_light_flicker()
	if model.is_or_after("fade") and model.is_before("ancient"):
		_draw_reality_fade()
	if model.is_or_after("void") and model.is_before("ancient"):
		_draw_void()
	if model.is_at("ancient"):
		_draw_dungeon_ancient_world()
	_draw_dialogue_panel()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _build_ui() -> void:
	title_label = _make_label("Title", Vector2(64.0, 42.0), Vector2(920.0, 42.0), 26, COLORS.white)
	narration_label = _make_label("Narration", Vector2(64.0, 524.0), Vector2(760.0, 118.0), 24, COLORS.white)
	hint_label = _make_label("Hint", Vector2(64.0, 654.0), Vector2(740.0, 32.0), 16, Color("#b9d5d9"))
	mode_label = _make_label("Mode", Vector2(972.0, 42.0), Vector2(248.0, 32.0), 16, Color("#9ee6ed"))
	letter_label = _make_label("Letter", Vector2(492.0, 236.0), Vector2(300.0, 120.0), 22, COLORS.ink)
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_button = _make_button("Next", "下一段", Vector2(1012.0, 642.0), Vector2(96.0, 42.0))
	next_button.pressed.connect(_advance)
	reset_button = _make_button("Reset", "重置", Vector2(1120.0, 642.0), Vector2(80.0, 42.0))
	reset_button.pressed.connect(_reset_opening)


func _make_label(label_name: String, pos: Vector2, size: Vector2, font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.position = pos
	label.size = size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color("#050508", 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label


func _make_button(button_name: String, text: String, pos: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.position = pos
	button.size = size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	add_child(button)
	return button


func _update_text() -> void:
	var beat: Dictionary = model.current()
	title_label.text = str(beat.get("title", ""))
	narration_label.text = str(beat.get("narration", ""))
	mode_label.text = str(beat.get("mode", "RPG prototype"))
	hint_label.text = "WASD/方向键移动，Space/Enter/下一段推进，Esc/重置返回开头"
	letter_label.text = str(beat.get("letter", ""))
	letter_label.visible = not letter_label.text.is_empty() and model.is_before("void")


func _draw_scene_background() -> void:
	if model.is_at("ancient"):
		draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#18223e"))
		return

	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#11131d"))
	draw_rect(Rect2(Vector2.ZERO, Vector2(BASE_SIZE.x, 514.0)), Color("#20293d"))
	draw_rect(Rect2(Vector2(0.0, 514.0), Vector2(BASE_SIZE.x, 206.0)), Color("#0a0b11", 0.66))


func _draw_dungeon_room() -> void:
	var floor_source := _dungeon_tile(0, 14)
	var wall_source := _dungeon_tile(6, 14)
	var trim_source := _dungeon_tile(9, 14)
	var room_origin := Vector2(64.0, 104.0)
	var tile_size := Vector2(64.0, 64.0)

	draw_rect(Rect2(room_origin - Vector2(16.0, 16.0), Vector2(1152.0, 424.0)), Color("#070914", 0.46))
	for row in range(6):
		for column in range(18):
			var dest := Rect2(room_origin + Vector2(column * tile_size.x, row * tile_size.y), tile_size)
			_draw_sheet_region(DUNGEON_CRAWL, floor_source, dest, Color("#9ba0a8", 0.9))

	for column in range(18):
		_draw_sheet_region(DUNGEON_CRAWL, wall_source, Rect2(room_origin + Vector2(column * tile_size.x, -tile_size.y), tile_size), Color("#8a8f9e", 0.95))
		_draw_sheet_region(DUNGEON_CRAWL, trim_source, Rect2(room_origin + Vector2(column * tile_size.x, 6.0 * tile_size.y), tile_size), Color("#6d7486", 0.78))
	for row in range(6):
		_draw_sheet_region(DUNGEON_CRAWL, wall_source, Rect2(room_origin + Vector2(-tile_size.x, row * tile_size.y), tile_size), Color("#858b9b", 0.9))
		_draw_sheet_region(DUNGEON_CRAWL, wall_source, Rect2(room_origin + Vector2(18.0 * tile_size.x, row * tile_size.y), tile_size), Color("#858b9b", 0.9))

	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(24, 11), Rect2(Vector2(102.0, 170.0), Vector2(96.0, 96.0)))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(25, 11), Rect2(Vector2(198.0, 170.0), Vector2(96.0, 96.0)))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(26, 11), Rect2(Vector2(294.0, 170.0), Vector2(96.0, 96.0)))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(27, 11), Rect2(Vector2(930.0, 154.0), Vector2(96.0, 96.0)))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(28, 11), Rect2(Vector2(1026.0, 154.0), Vector2(96.0, 96.0)))

	_draw_table(Vector2(492.0, 326.0), Vector2(272.0, 92.0))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(18, 15), Rect2(Vector2(580.0, 250.0), Vector2(72.0, 72.0)), Color("#f2dfa6", 1.0))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(49, 12), Rect2(Vector2(1010.0, 350.0), Vector2(82.0, 82.0)))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(0, 11), Rect2(Vector2(858.0, 348.0), Vector2(72.0, 72.0)), Color("#ffbf62", 0.88))

	var pen_y: float = 320.0 + sin(total_time * 1.2) * 2.0
	_draw_rgb_rect(Rect2(Vector2(604.0, pen_y), Vector2(142.0, 10.0)), Color("#08080d"))
	draw_rect(Rect2(Vector2(738.0, pen_y + 1.0), Vector2(28.0, 8.0)), Color("#22243a"))
	if model.is_or_after("pen"):
		draw_circle(Vector2(668.0, pen_y + 5.0), 20.0 + sin(total_time * 4.0) * 2.0, Color("#11131f", 0.42))

	var lamp_strength: float = 0.2
	if model.is_or_after("flicker"):
		lamp_strength = 0.16 + abs(sin(model.beat_time * 12.0)) * 0.38
	draw_circle(Vector2(638.0, 106.0), 120.0, Color("#f6d675", lamp_strength))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(3, 12), Rect2(Vector2(602.0, 76.0), Vector2(72.0, 72.0)), Color("#ffc66b", 0.88))


func _draw_dialogue_panel() -> void:
	draw_rect(Rect2(Vector2(32.0, 510.0), Vector2(1216.0, 178.0)), Color("#05060b", 0.84))
	draw_rect(Rect2(Vector2(38.0, 516.0), Vector2(1204.0, 166.0)), Color("#141926", 0.94))
	draw_rect(Rect2(Vector2(42.0, 520.0), Vector2(1196.0, 4.0)), Color("#e0c376", 0.78))
	draw_rect(Rect2(Vector2(42.0, 678.0), Vector2(1196.0, 4.0)), Color("#2b8e9b", 0.72))


func _draw_room() -> void:
	var lamp_strength: float = 0.22
	if model.is_or_after("flicker"):
		lamp_strength = 0.18 + abs(sin(model.beat_time * 12.0)) * 0.42

	_draw_rgb_rect(Rect2(Vector2(64.0, 132.0), Vector2(168.0, 300.0)), Color("#252944"))
	draw_rect(Rect2(Vector2(88.0, 154.0), Vector2(112.0, 250.0)), Color("#141624"))
	draw_rect(Rect2(Vector2(190.0, 270.0), Vector2(10.0, 52.0)), COLORS.gold)

	draw_rect(Rect2(Vector2(918.0, 116.0), Vector2(214.0, 178.0)), Color("#1b2741"))
	draw_rect(Rect2(Vector2(936.0, 134.0), Vector2(178.0, 142.0)), Color("#10182b"))
	for i in range(4):
		draw_line(Vector2(936.0 + i * 45.0, 134.0), Vector2(936.0 + i * 45.0, 276.0), Color("#43516f"), 3.0)
	for i in range(3):
		draw_line(Vector2(936.0, 134.0 + i * 48.0), Vector2(1114.0, 134.0 + i * 48.0), Color("#43516f"), 3.0)

	draw_circle(Vector2(640.0, 122.0), 34.0, Color("#f2d067", lamp_strength))
	draw_rect(Rect2(Vector2(612.0, 96.0), Vector2(56.0, 18.0)), COLORS.gold)
	draw_line(Vector2(640.0, 0.0), Vector2(640.0, 96.0), Color("#39415d"), 3.0)
	draw_rect(Rect2(Vector2(0.0, 474.0), Vector2(BASE_SIZE.x, 246.0)), Color("#342438", 0.52))


func _draw_table_objects() -> void:
	draw_rect(Rect2(Vector2(408.0, 350.0), Vector2(470.0, 64.0)), COLORS.wood)
	draw_rect(Rect2(Vector2(380.0, 400.0), Vector2(526.0, 38.0)), Color("#51332f"))
	draw_rect(Rect2(Vector2(428.0, 438.0), Vector2(30.0, 126.0)), Color("#2b1c27"))
	draw_rect(Rect2(Vector2(828.0, 438.0), Vector2(30.0, 126.0)), Color("#2b1c27"))

	_draw_rgb_rect(Rect2(Vector2(486.0, 224.0), Vector2(312.0, 146.0)), COLORS.paper_shadow)
	_draw_sheet_region(PAPER_ICONS, Rect2(Vector2.ZERO, Vector2(32.0, 32.0)), Rect2(Vector2(568.0, 222.0), Vector2(152.0, 152.0)))
	_draw_sheet_region(RPG_TILESET, Rect2(Vector2(112.0, 96.0), Vector2(16.0, 16.0)), Rect2(Vector2(470.0, 354.0), Vector2(48.0, 48.0)))
	_draw_sheet_region(RPG_TILESET, Rect2(Vector2(0.0, 128.0), Vector2(16.0, 16.0)), Rect2(Vector2(788.0, 354.0), Vector2(48.0, 48.0)))

	var pen_y: float = 320.0 + sin(total_time * 1.2) * 2.0
	_draw_rgb_rect(Rect2(Vector2(596.0, pen_y), Vector2(154.0, 12.0)), Color("#07070b"))
	draw_rect(Rect2(Vector2(744.0, pen_y + 2.0), Vector2(32.0, 8.0)), Color("#0f0e16"))
	for i in range(7):
		draw_line(Vector2(614.0 + i * 16.0, pen_y + 1.0), Vector2(622.0 + i * 16.0, pen_y + 10.0), Color("#33405b"), 1.0)
	if model.is_or_after("pen"):
		draw_circle(Vector2(670.0, pen_y + 6.0), 18.0 + sin(total_time * 4.0) * 2.0, Color("#11131f", 0.48))


func _draw_blood_drop() -> void:
	var drop_progress: float = clamp(model.beat_time / 1.4, 0.0, 1.0)
	var drop_pos := Vector2(668.0, lerp(302.0, 252.0, drop_progress))
	draw_circle(drop_pos, 6.0, COLORS.red)
	draw_circle(Vector2(650.0, 274.0), 9.0 + drop_progress * 3.0, Color("#a12f36", 0.85))


func _draw_ink_spread() -> void:
	var spread: float = clamp(model.beat_time / 3.6, 0.0, 1.0)
	var origin := Vector2(650.0, 274.0)
	_draw_texture_centered(SPELL_DARKNESS, origin, Vector2(42.0, 42.0) + Vector2.ONE * spread * 118.0, Color("#141018", 0.88))
	draw_circle(origin, 18.0 + spread * 34.0, Color("#090911", 0.88))
	for i in range(18):
		var angle: float = i * TAU / 18.0 + sin(total_time + i) * 0.18
		var length: float = 30.0 + spread * (58.0 + i % 5 * 18.0)
		var end := origin + Vector2(cos(angle), sin(angle)) * length
		draw_line(origin, end, Color("#07070b", 0.78), 4.0 + spread * 4.0)
		draw_circle(end, 4.0 + spread * 6.0, Color("#080810", 0.76))


func _draw_light_flicker() -> void:
	if int(model.beat_time * 12.0) % 2 == 0:
		draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#fbf1a6", 0.08))
	else:
		draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#080812", 0.24))
	_draw_texture_centered(SPELL_MAGIC_ORB, Vector2(640.0, 130.0), Vector2(84.0, 84.0), Color("#fff0a6", 0.42))


func _draw_reality_fade() -> void:
	var p: float = clamp(model.beat_time / 3.8, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#d6d2bc", p * 0.26))
	for i in range(18):
		var x: float = i * 76.0 + sin(total_time * 2.0 + i) * 10.0
		var height: float = p * (90.0 + (i % 4) * 58.0)
		draw_rect(Rect2(Vector2(x, 0.0), Vector2(26.0, height)), Color("#0b0b10", 0.14 + p * 0.22))
		draw_rect(Rect2(Vector2(x + 8.0, 430.0 - height * 0.25), Vector2(16.0, height * 0.9)), Color("#f5e7c3", p * 0.18))
	for i in range(6):
		var spark_center := Vector2(290.0 + i * 142.0, 162.0 + sin(total_time * 2.0 + i) * 44.0)
		_draw_texture_centered(SPELL_SPARKS, spark_center, Vector2(54.0, 54.0), Color("#d5f8ff", p * 0.46))


func _draw_void() -> void:
	var p: float = clamp(model.beat_time / 2.4, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#020207", p))
	var pulse: float = 0.18 + sin(total_time * 5.0) * 0.08
	draw_circle(Vector2(640.0, 318.0), 88.0 + p * 40.0, Color("#1c2136", pulse))
	draw_circle(Vector2(640.0, 318.0), 32.0, Color("#0b0b13", 0.72))


func _draw_ancient_world() -> void:
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#17203a"))
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(BASE_SIZE.x, 330.0)), Color("#26395d"))
	draw_circle(Vector2(1020.0, 112.0), 58.0, Color("#e36c4d", 0.78))
	draw_rect(Rect2(Vector2(0.0, 430.0), Vector2(BASE_SIZE.x, 290.0)), Color("#2b2630"))
	_draw_rpg_ground()

	for i in range(8):
		var x: float = 84.0 + i * 150.0
		_draw_tower(Vector2(x, 252.0 + (i % 2) * 30.0), 86.0 + (i % 3) * 16.0)

	_draw_castle_gate(Vector2(560.0, 198.0))
	draw_rect(Rect2(Vector2(0.0, 404.0), Vector2(BASE_SIZE.x, 34.0)), Color("#141522"))
	for i in range(10):
		var flame_base := Vector2(140.0 + i * 108.0, 398.0 + sin(total_time * 2.0 + i) * 6.0)
		_draw_texture_centered(SPELL_FIREBALL, flame_base + Vector2(0.0, 8.0), Vector2(58.0, 58.0), Color("#ffca64", 0.96))

	_draw_xiali(Vector2(735.0, 480.0))
	_draw_protagonist(player_position)
	draw_rect(Rect2(Vector2(0.0, 618.0), Vector2(BASE_SIZE.x, 102.0)), Color("#08080d", 0.52))


func _draw_dungeon_ancient_world() -> void:
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#17203a"))
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(BASE_SIZE.x, 224.0)), Color("#243653"))
	draw_circle(Vector2(1020.0, 92.0), 56.0, Color("#e36c4d", 0.78))

	var grass_source := _dungeon_tile(0, 13)
	var path_source := _dungeon_tile(4, 13)
	var tile_size := Vector2(64.0, 64.0)
	for row in range(7):
		for column in range(21):
			var source := path_source if abs(column - 10) <= row / 2 else grass_source
			var shade := Color("#b7cba2", 0.86) if row % 2 == 0 else Color("#a6bd93", 0.86)
			_draw_sheet_region(DUNGEON_CRAWL, source, Rect2(Vector2(column * 64.0 - 32.0, 194.0 + row * 50.0), tile_size), shade)

	for column in range(7, 14):
		_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(6, 13), Rect2(Vector2(column * 64.0, 194.0), tile_size), Color("#7c8291", 0.92))
	for column in range(8, 13):
		_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(7, 13), Rect2(Vector2(column * 64.0, 258.0), tile_size), Color("#8a909d", 0.92))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(12, 12), Rect2(Vector2(578.0, 326.0), Vector2(124.0, 124.0)), Color("#8a7363", 0.96))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(13, 12), Rect2(Vector2(702.0, 326.0), Vector2(124.0, 124.0)), Color("#8a7363", 0.96))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(29, 12), Rect2(Vector2(124.0, 266.0), Vector2(96.0, 96.0)), Color("#9fcf89", 0.9))
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(30, 12), Rect2(Vector2(1038.0, 282.0), Vector2(96.0, 96.0)), Color("#9fcf89", 0.9))

	for i in range(8):
		var flame_base := Vector2(164.0 + i * 122.0, 466.0 + sin(total_time * 2.0 + i) * 4.0)
		_draw_texture_centered(SPELL_FIREBALL, flame_base, Vector2(54.0, 54.0), Color("#ffca64", 0.86))

	_draw_xiali(Vector2(735.0, 414.0))
	_draw_protagonist(player_position)


func _dungeon_tile(column: int, row: int) -> Rect2:
	return Rect2(Vector2(column * 32.0, row * 32.0), Vector2(32.0, 32.0))


func _draw_table(pos: Vector2, size: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(0.0, 14.0), size), Color("#6f472e"))
	draw_rect(Rect2(pos, Vector2(size.x, 28.0)), Color("#916137"))
	draw_rect(Rect2(pos + Vector2(22.0, size.y - 2.0), Vector2(28.0, 74.0)), Color("#36281f"))
	draw_rect(Rect2(pos + Vector2(size.x - 50.0, size.y - 2.0), Vector2(28.0, 74.0)), Color("#36281f"))


func _draw_tower(pos: Vector2, height: float) -> void:
	draw_rect(Rect2(pos, Vector2(84.0, height)), Color("#111626"))
	draw_rect(Rect2(pos + Vector2(-10.0, -22.0), Vector2(104.0, 24.0)), Color("#0a0d16"))
	_draw_sheet_region(CASTLE_WALLS, Rect2(Vector2(0.0, 384.0), Vector2(96.0, 96.0)), Rect2(pos + Vector2(-8.0, -18.0), Vector2(100.0, 100.0)), Color("#d5c7e8", 0.62))
	for i in range(3):
		draw_rect(Rect2(pos + Vector2(12.0 + i * 24.0, 28.0), Vector2(10.0, 28.0)), Color("#e58549", 0.48))


func _draw_xiali(pos: Vector2) -> void:
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(13, 31), Rect2(pos + Vector2(-38.0, -20.0), Vector2(76.0, 76.0)))
	draw_rect(Rect2(pos + Vector2(-40.0, 62.0), Vector2(80.0, 10.0)), Color("#08080d", 0.46))


func _draw_protagonist(pos: Vector2) -> void:
	_draw_sheet_region(DUNGEON_CRAWL, _dungeon_tile(10, 31), Rect2(pos + Vector2(-38.0, -20.0), Vector2(76.0, 76.0)))
	draw_rect(Rect2(pos + Vector2(-40.0, 62.0), Vector2(80.0, 10.0)), Color("#08080d", 0.46))


func _draw_rgb_rect(rect: Rect2, base_color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(-PIXEL, 0.0), rect.size), Color("#ef3b48", 0.28))
	draw_rect(Rect2(rect.position + Vector2(PIXEL, 0.0), rect.size), Color("#34d4e3", 0.24))
	draw_rect(rect, base_color)


func _draw_sheet_region(texture: Texture2D, source: Rect2, destination: Rect2, modulate: Color = Color.WHITE) -> void:
	draw_texture_rect_region(texture, destination, source, modulate)


func _draw_texture_centered(texture: Texture2D, center: Vector2, size: Vector2, modulate: Color = Color.WHITE) -> void:
	draw_texture_rect(texture, Rect2(center - size * 0.5, size), false, modulate)


func _draw_rpg_ground() -> void:
	var tile_source := Rect2(Vector2(96.0, 144.0), Vector2(16.0, 16.0))
	for row in range(6):
		for column in range(22):
			var dest := Rect2(Vector2(column * 64.0 - 32.0, 430.0 + row * 48.0), Vector2(64.0, 64.0))
			_draw_sheet_region(RPG_TILESET, tile_source, dest, Color("#7d7686", 0.72))


func _draw_castle_gate(pos: Vector2) -> void:
	_draw_sheet_region(CASTLE_WALLS, Rect2(Vector2(0.0, 192.0), Vector2(192.0, 96.0)), Rect2(pos + Vector2(-246.0, 24.0), Vector2(244.0, 122.0)), Color("#d4b9a8", 0.9))
	_draw_sheet_region(CASTLE_WALLS, Rect2(Vector2(0.0, 192.0), Vector2(192.0, 96.0)), Rect2(pos + Vector2(182.0, 24.0), Vector2(244.0, 122.0)), Color("#d4b9a8", 0.9))
	_draw_sheet_region(CASTLE_PROPS, Rect2(Vector2(134.0, 0.0), Vector2(74.0, 132.0)), Rect2(pos + Vector2(-44.0, -22.0), Vector2(148.0, 264.0)))
	_draw_sheet_region(CASTLE_PROPS, Rect2(Vector2(288.0, 0.0), Vector2(176.0, 112.0)), Rect2(pos + Vector2(190.0, -10.0), Vector2(260.0, 166.0)), Color("#c29b75", 0.92))
	_draw_sheet_region(CASTLE_METAL, Rect2(Vector2(384.0, 0.0), Vector2(96.0, 64.0)), Rect2(pos + Vector2(-300.0, -18.0), Vector2(144.0, 96.0)), Color("#d8d6dc", 0.76))


func _draw_rgb_noise() -> void:
	for i in range(44):
		var x := fmod(i * 97.0 + total_time * 19.0, BASE_SIZE.x)
		var y := fmod(i * 41.0 + sin(total_time + i) * 18.0, BASE_SIZE.y)
		var color := Color("#36e5ef", 0.045) if i % 2 == 0 else Color("#f24e4e", 0.04)
		draw_rect(Rect2(Vector2(x, y), Vector2(PIXEL * 2.0, PIXEL)), color)
