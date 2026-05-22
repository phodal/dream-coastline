extends CanvasLayer

signal dismissed
signal continue_requested

const SPLASH_IMAGE := "res://assets/branding/dream-coastline-title-loop.png"
const FALLBACK_IMAGE := "res://assets/branding/dream-coastline-splash.png"
const ICON_IMAGE := "res://assets/branding/dream-coastline-icon.png"

var _continue_enabled := false
var _dismissed := false
var _timer := 0.0
var _min_duration := 1.2
var _subtitle: Label


func _ready() -> void:
	layer = 100
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var backdrop := TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(SPLASH_IMAGE):
		backdrop.texture = load(SPLASH_IMAGE)
	elif ResourceLoader.exists(FALLBACK_IMAGE):
		backdrop.texture = load(FALLBACK_IMAGE)
	root.add_child(backdrop)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.025, 0.035, 0.26)
	root.add_child(shade)

	var icon := TextureRect.new()
	icon.anchor_left = 0.5
	icon.anchor_top = 0.17
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.17
	icon.offset_left = -58.0
	icon.offset_top = 0.0
	icon.offset_right = 58.0
	icon.offset_bottom = 116.0
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	if ResourceLoader.exists(ICON_IMAGE):
		icon.texture = load(ICON_IMAGE)
	root.add_child(icon)

	var title := Label.new()
	title.text = "Dream Coastline"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0
	title.anchor_top = 0.36
	title.anchor_right = 1.0
	title.anchor_bottom = 0.36
	title.offset_top = 0.0
	title.offset_bottom = 56.0
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.48))
	root.add_child(title)

	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.anchor_left = 0.0
	_subtitle.anchor_top = 0.76
	_subtitle.anchor_right = 1.0
	_subtitle.anchor_bottom = 0.76
	_subtitle.offset_bottom = 36.0
	_subtitle.add_theme_font_size_override("font_size", 22)
	_subtitle.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))
	root.add_child(_subtitle)
	_refresh_subtitle()


func _process(delta: float) -> void:
	_timer += delta


func _input(event: InputEvent) -> void:
	if _dismissed or not visible:
		return
	if _timer < _min_duration:
		return
	if _continue_enabled and _is_continue_event(event):
		_complete(true)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event is InputEventMouseButton:
		dismiss()
		get_viewport().set_input_as_handled()


func configure_continue(enabled: bool) -> void:
	_continue_enabled = enabled
	_refresh_subtitle()


func dismiss() -> void:
	_complete(false)


func _complete(continue_game: bool) -> void:
	if _dismissed:
		return
	_dismissed = true
	visible = false
	if continue_game:
		continue_requested.emit()
	else:
		dismissed.emit()


func _refresh_subtitle() -> void:
	if _subtitle == null:
		return
	_subtitle.text = "Enter / Space 新游戏 · C 继续" if _continue_enabled else "按 Enter / Space 开始"


func _is_continue_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and not key_event.echo and key_event.keycode == KEY_C
	return false
