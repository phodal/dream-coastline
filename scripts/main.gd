extends Node2D

enum Beat {
	ROOM,
	LETTER,
	PEN,
	BLOOD,
	INK,
	FLICKER,
	FADE,
	VOID,
	ANCIENT,
}

const BASE_SIZE := Vector2(1280.0, 720.0)
const PIXEL := 4.0
const AUTO_BEATS := {
	Beat.INK: 4.2,
	Beat.FLICKER: 3.0,
	Beat.FADE: 4.0,
	Beat.VOID: 2.8,
}

const COLORS := {
	"ink": Color("#101018"),
	"deep": Color("#1c2136"),
	"night": Color("#263052"),
	"wall": Color("#657392"),
	"wall_dark": Color("#424b68"),
	"paper": Color("#f4e6b4"),
	"paper_shadow": Color("#c89f66"),
	"wood": Color("#7a4a32"),
	"wood_dark": Color("#3d2635"),
	"cyan": Color("#3fbfd5"),
	"red": Color("#d24a43"),
	"gold": Color("#e5b94e"),
	"skin": Color("#f0b878"),
	"white": Color("#f6f0d8"),
	"shadow": Color("#08080d"),
}

var beat := Beat.ROOM
var beat_time := 0.0
var total_time := 0.0
var can_advance := true
var smoke_autoplay := false
var smoke_autoplay_elapsed := 0.0

var title_label: Label
var narration_label: Label
var hint_label: Label
var letter_label: Label
var mode_label: Label


func _ready() -> void:
	smoke_autoplay = OS.get_cmdline_user_args().has("--smoke-autoplay")
	_build_ui()
	_set_beat(Beat.ROOM)


func _process(delta: float) -> void:
	beat_time += delta
	total_time += delta

	if AUTO_BEATS.has(beat) and beat_time >= AUTO_BEATS[beat]:
		_advance()

	if smoke_autoplay and beat < Beat.ANCIENT:
		smoke_autoplay_elapsed += delta
		if smoke_autoplay_elapsed >= 0.55:
			smoke_autoplay_elapsed = 0.0
			_advance()

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_advance()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
	elif event.is_action_pressed("ui_cancel"):
		_set_beat(Beat.ROOM)


func _draw() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var scale: float = min(screen.x / BASE_SIZE.x, screen.y / BASE_SIZE.y)
	var offset: Vector2 = (screen - BASE_SIZE * scale) * 0.5

	draw_set_transform(offset, 0.0, Vector2(scale, scale))
	_draw_scene_background()
	_draw_rgb_noise()

	if beat < Beat.ANCIENT:
		_draw_room()
		_draw_table_objects()

	if beat >= Beat.BLOOD and beat < Beat.ANCIENT:
		_draw_blood_drop()

	if beat >= Beat.INK and beat < Beat.ANCIENT:
		_draw_ink_spread()

	if beat >= Beat.FLICKER and beat < Beat.ANCIENT:
		_draw_light_flicker()

	if beat >= Beat.FADE and beat < Beat.ANCIENT:
		_draw_reality_fade()

	if beat >= Beat.VOID and beat < Beat.ANCIENT:
		_draw_void()

	if beat == Beat.ANCIENT:
		_draw_ancient_world()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _build_ui() -> void:
	title_label = _make_label("Title", Vector2(64.0, 42.0), Vector2(920.0, 42.0), 26, COLORS.white)
	narration_label = _make_label("Narration", Vector2(64.0, 524.0), Vector2(760.0, 118.0), 24, COLORS.white)
	hint_label = _make_label("Hint", Vector2(64.0, 654.0), Vector2(520.0, 32.0), 16, Color("#b9d5d9"))
	mode_label = _make_label("Mode", Vector2(972.0, 42.0), Vector2(248.0, 32.0), 16, Color("#9ee6ed"))
	letter_label = _make_label("Letter", Vector2(492.0, 236.0), Vector2(300.0, 120.0), 22, COLORS.ink)
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _make_label(label_name: String, pos: Vector2, size: Vector2, font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.position = pos
	label.size = size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color("#050508", 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label


func _set_beat(next_beat: int) -> void:
	beat = next_beat
	beat_time = 0.0
	can_advance = not AUTO_BEATS.has(beat)
	_update_text()
	queue_redraw()


func _advance() -> void:
	if beat >= Beat.ANCIENT:
		return
	_set_beat(beat + 1)


func _update_text() -> void:
	title_label.text = "灯未亮起的夜晚"
	hint_label.text = "Space / 鼠标左键推进，Esc 重置"
	mode_label.text = "90s RGB prototype"
	letter_label.visible = beat >= Beat.LETTER and beat < Beat.VOID

	match beat:
		Beat.ROOM:
			narration_label.text = "纪子轩推开房门。房间里没有人，只有一盏迟迟没亮起的灯。"
			letter_label.text = ""
		Beat.LETTER:
			narration_label.text = "桌上的信只有一句英文。它不像父母会写的话，更像有人故意留下的。"
			letter_label.text = "To be Continue ..."
		Beat.PEN:
			narration_label.text = "那支钢笔通体漆黑，没有品牌，也没有金属反光。笔身刻着极细的古文字。"
			letter_label.text = "To be Continue ..."
		Beat.BLOOD:
			narration_label.text = "纪子轩拿起笔，手指忽然刺痛。血滴落在信纸上。"
			letter_label.text = "To be Continue ..."
		Beat.INK:
			narration_label.text = "墨水像活物一样扩散。原本不合理的英文，被一点点吞掉。"
			letter_label.text = "墨颀历三百一十七年\n王城陷落"
		Beat.FLICKER:
			narration_label.text = "房间里的灯开始闪烁。窗外传来不属于现代城市的钟声。"
			letter_label.text = "墨颀历三百一十七年\n王城陷落"
		Beat.FADE:
			narration_label.text = "墙壁像被水浸开的墨画。现实褪色，家具、门缝和影子一层层剥落。"
			letter_label.text = "墨颀历三百一十七年\n王城陷落"
		Beat.VOID:
			narration_label.text = "黑暗里，一个陌生少年的声音响起：你终于来了。执笔者。"
			letter_label.text = ""
		Beat.ANCIENT:
			narration_label.text = "钟声落下后，纪子轩第一次看见夏离。远处的王城正在燃烧。"
			letter_label.visible = false


func _draw_scene_background() -> void:
	if beat == Beat.ANCIENT:
		draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#18223e"))
		return

	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), COLORS.ink)
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(BASE_SIZE.x, 430.0)), COLORS.wall)
	draw_rect(Rect2(Vector2(0.0, 430.0), Vector2(BASE_SIZE.x, 290.0)), COLORS.wood_dark)

	for y in range(432, 720, 28):
		draw_rect(Rect2(Vector2(0.0, y), Vector2(BASE_SIZE.x, 3.0)), Color("#2b2030"))


func _draw_room() -> void:
	var lamp_strength: float = 0.22
	if beat >= Beat.FLICKER:
		lamp_strength = 0.18 + abs(sin(beat_time * 12.0)) * 0.42

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
	draw_rect(Rect2(Vector2(500.0, 214.0), Vector2(282.0, 138.0)), COLORS.paper)
	draw_rect(Rect2(Vector2(512.0, 226.0), Vector2(258.0, 4.0)), Color("#d8bd82"))
	draw_rect(Rect2(Vector2(520.0, 336.0), Vector2(226.0, 4.0)), Color("#d8bd82"))

	var pen_y: float = 320.0 + sin(total_time * 1.2) * 2.0
	_draw_rgb_rect(Rect2(Vector2(596.0, pen_y), Vector2(154.0, 12.0)), Color("#07070b"))
	draw_rect(Rect2(Vector2(744.0, pen_y + 2.0), Vector2(32.0, 8.0)), Color("#0f0e16"))
	for i in range(7):
		draw_line(Vector2(614.0 + i * 16.0, pen_y + 1.0), Vector2(622.0 + i * 16.0, pen_y + 10.0), Color("#33405b"), 1.0)

	if beat >= Beat.PEN:
		draw_circle(Vector2(670.0, pen_y + 6.0), 18.0 + sin(total_time * 4.0) * 2.0, Color("#11131f", 0.48))


func _draw_blood_drop() -> void:
	var drop_progress: float = clamp(beat_time / 1.4, 0.0, 1.0)
	var drop_pos: Vector2 = Vector2(668.0, lerp(302.0, 252.0, drop_progress))
	draw_circle(drop_pos, 6.0, COLORS.red)
	draw_circle(Vector2(650.0, 274.0), 9.0 + drop_progress * 3.0, Color("#a12f36", 0.85))


func _draw_ink_spread() -> void:
	var spread: float = clamp(beat_time / 3.6, 0.0, 1.0)
	var origin: Vector2 = Vector2(650.0, 274.0)
	draw_circle(origin, 18.0 + spread * 34.0, Color("#090911", 0.88))
	for i in range(18):
		var angle: float = i * TAU / 18.0 + sin(total_time + i) * 0.18
		var length: float = 30.0 + spread * (58.0 + i % 5 * 18.0)
		var end: Vector2 = origin + Vector2(cos(angle), sin(angle)) * length
		draw_line(origin, end, Color("#07070b", 0.78), 4.0 + spread * 4.0)
		draw_circle(end, 4.0 + spread * 6.0, Color("#080810", 0.76))


func _draw_light_flicker() -> void:
	if int(beat_time * 12.0) % 2 == 0:
		draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#fbf1a6", 0.08))
	else:
		draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#080812", 0.24))

	for i in range(5):
		var x: float = 968.0 + i * 26.0
		draw_line(Vector2(x, 116.0), Vector2(x + 92.0, 294.0), Color("#80f3ff", 0.12), 3.0)


func _draw_reality_fade() -> void:
	var p: float = clamp(beat_time / 3.8, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#d6d2bc", p * 0.26))

	for i in range(18):
		var x: float = i * 76.0 + sin(total_time * 2.0 + i) * 10.0
		var height: float = p * (90.0 + (i % 4) * 58.0)
		draw_rect(Rect2(Vector2(x, 0.0), Vector2(26.0, height)), Color("#0b0b10", 0.14 + p * 0.22))
		draw_rect(Rect2(Vector2(x + 8.0, 430.0 - height * 0.25), Vector2(16.0, height * 0.9)), Color("#f5e7c3", p * 0.18))

	for y in range(96, 492, 36):
		draw_line(Vector2(0.0, y + sin(y + total_time * 5.0) * 6.0), Vector2(BASE_SIZE.x, y), Color("#12111a", p * 0.18), 2.0)


func _draw_void() -> void:
	var p: float = clamp(beat_time / 2.4, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#020207", p))
	var pulse: float = 0.18 + sin(total_time * 5.0) * 0.08
	draw_circle(Vector2(640.0, 318.0), 88.0 + p * 40.0, Color("#1c2136", pulse))
	draw_circle(Vector2(640.0, 318.0), 32.0, Color("#0b0b13", 0.72))


func _draw_ancient_world() -> void:
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color("#17203a"))
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(BASE_SIZE.x, 330.0)), Color("#26395d"))
	draw_circle(Vector2(1020.0, 112.0), 58.0, Color("#e36c4d", 0.78))
	draw_rect(Rect2(Vector2(0.0, 430.0), Vector2(BASE_SIZE.x, 290.0)), Color("#2b2630"))

	for i in range(8):
		var x: float = 84.0 + i * 150.0
		_draw_tower(Vector2(x, 252.0 + (i % 2) * 30.0), 86.0 + (i % 3) * 16.0)

	draw_rect(Rect2(Vector2(0.0, 404.0), Vector2(BASE_SIZE.x, 34.0)), Color("#141522"))
	for i in range(10):
		var flame_base: Vector2 = Vector2(140.0 + i * 108.0, 398.0 + sin(total_time * 2.0 + i) * 6.0)
		draw_polygon(PackedVector2Array([
			flame_base + Vector2(-10.0, 34.0),
			flame_base + Vector2(0.0, -18.0 - abs(sin(total_time * 3.0 + i)) * 16.0),
			flame_base + Vector2(12.0, 34.0),
		]), PackedColorArray([COLORS.red, COLORS.gold, COLORS.red]))

	_draw_xiali(Vector2(735.0, 480.0))
	_draw_protagonist(Vector2(542.0, 494.0))

	draw_rect(Rect2(Vector2(0.0, 618.0), Vector2(BASE_SIZE.x, 102.0)), Color("#08080d", 0.52))


func _draw_tower(pos: Vector2, height: float) -> void:
	draw_rect(Rect2(pos, Vector2(84.0, height)), Color("#111626"))
	draw_rect(Rect2(pos + Vector2(-10.0, -22.0), Vector2(104.0, 24.0)), Color("#0a0d16"))
	for i in range(3):
		draw_rect(Rect2(pos + Vector2(12.0 + i * 24.0, 28.0), Vector2(10.0, 28.0)), Color("#e58549", 0.48))


func _draw_xiali(pos: Vector2) -> void:
	_draw_rgb_rect(Rect2(pos + Vector2(-20.0, 42.0), Vector2(42.0, 72.0)), Color("#283e67"))
	draw_circle(pos + Vector2(0.0, 24.0), 19.0, COLORS.skin)
	draw_rect(Rect2(pos + Vector2(-18.0, 10.0), Vector2(36.0, 14.0)), Color("#17101b"))
	draw_rect(Rect2(pos + Vector2(-26.0, 64.0), Vector2(54.0, 20.0)), Color("#d6d2bc"))
	draw_line(pos + Vector2(-38.0, 54.0), pos + Vector2(-12.0, 70.0), Color("#d6d2bc"), 6.0)
	draw_line(pos + Vector2(38.0, 54.0), pos + Vector2(12.0, 70.0), Color("#d6d2bc"), 6.0)
	draw_rect(Rect2(pos + Vector2(-5.0, 44.0), Vector2(10.0, 70.0)), COLORS.gold)


func _draw_protagonist(pos: Vector2) -> void:
	draw_circle(pos + Vector2(0.0, 24.0), 18.0, Color("#efbd84"))
	draw_rect(Rect2(pos + Vector2(-22.0, 42.0), Vector2(44.0, 70.0)), Color("#20283d"))
	draw_rect(Rect2(pos + Vector2(-16.0, 12.0), Vector2(32.0, 14.0)), Color("#18131a"))
	draw_line(pos + Vector2(20.0, 48.0), pos + Vector2(48.0, 60.0), COLORS.ink, 5.0)


func _draw_rgb_rect(rect: Rect2, base_color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(-PIXEL, 0.0), rect.size), Color("#ef3b48", 0.28))
	draw_rect(Rect2(rect.position + Vector2(PIXEL, 0.0), rect.size), Color("#34d4e3", 0.24))
	draw_rect(rect, base_color)


func _draw_rgb_noise() -> void:
	for i in range(44):
		var x := fmod(i * 97.0 + total_time * 19.0, BASE_SIZE.x)
		var y := fmod(i * 41.0 + sin(total_time + i) * 18.0, BASE_SIZE.y)
		var color := Color("#36e5ef", 0.045) if i % 2 == 0 else Color("#f24e4e", 0.04)
		draw_rect(Rect2(Vector2(x, y), Vector2(PIXEL * 2.0, PIXEL)), color)
