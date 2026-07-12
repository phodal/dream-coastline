extends CanvasLayer

signal closed
signal accessibility_changed(text_scale: float, high_contrast: bool)

var repository
var volume_label: Label
var volume_slider: HSlider
var text_label: Label
var text_slider: HSlider
var contrast_check: CheckBox
var fullscreen_check: CheckBox
var speed_label: Label
var speed_slider: HSlider
var binding_buttons: Dictionary = {}
var binding_status: Label
var awaiting_action := ""

const BINDING_LABELS := {
	"move_left": "向左",
	"move_right": "向右",
	"move_up": "向上",
	"move_down": "向下",
	"interact": "确认/交互",
	"pause": "暂停",
}


func _ready() -> void:
	layer = 90
	visible = false
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.008, 0.01, 0.016, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 660)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 9)
	margin.add_child(rows)
	var title := Label.new()
	title.text = "设置与辅助功能"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	rows.add_child(title)
	fullscreen_check = CheckBox.new()
	fullscreen_check.text = "全屏显示"
	fullscreen_check.toggled.connect(_set_fullscreen)
	rows.add_child(fullscreen_check)
	volume_label = Label.new()
	rows.add_child(volume_label)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.custom_minimum_size.y = 20
	volume_slider.value_changed.connect(_set_volume)
	rows.add_child(volume_slider)
	text_label = Label.new()
	rows.add_child(text_label)
	text_slider = HSlider.new()
	text_slider.min_value = 1.0
	text_slider.max_value = 1.5
	text_slider.step = 0.25
	text_slider.custom_minimum_size.y = 20
	text_slider.value_changed.connect(_set_text_scale)
	rows.add_child(text_slider)
	speed_label = Label.new()
	rows.add_child(speed_label)
	speed_slider = HSlider.new()
	speed_slider.min_value = 0.0
	speed_slider.max_value = 2.0
	speed_slider.step = 0.25
	speed_slider.custom_minimum_size.y = 20
	speed_slider.value_changed.connect(_set_dialogue_speed)
	rows.add_child(speed_slider)
	contrast_check = CheckBox.new()
	contrast_check.text = "高对比度文字与面板"
	contrast_check.toggled.connect(_set_high_contrast)
	rows.add_child(contrast_check)
	var binding_title := Label.new()
	binding_title.text = "键位重映射（点击后按下新按键）"
	rows.add_child(binding_title)
	var binding_grid := GridContainer.new()
	binding_grid.columns = 3
	rows.add_child(binding_grid)
	for action in BINDING_LABELS.keys():
		var button := Button.new()
		button.custom_minimum_size = Vector2(180, 38)
		button.pressed.connect(_begin_binding.bind(str(action)))
		binding_grid.add_child(button)
		binding_buttons[action] = button
	var reset_button := Button.new()
	reset_button.text = "恢复默认键位"
	reset_button.pressed.connect(_reset_bindings)
	rows.add_child(reset_button)
	binding_status = Label.new()
	binding_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	binding_status.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	rows.add_child(binding_status)
	var help := Label.new()
	help.text = "键盘：方向键 / Enter / Esc　　手柄：方向键或摇杆 / A / B"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", Color(0.72, 0.77, 0.84))
	rows.add_child(help)
	var back := Button.new()
	back.text = "返回暂停菜单"
	back.custom_minimum_size = Vector2(0, 48)
	back.pressed.connect(_close)
	rows.add_child(back)


func configure(value) -> void:
	repository = value


func open() -> void:
	if repository == null:
		return
	fullscreen_check.set_pressed_no_signal(bool(repository.fullscreen))
	volume_slider.set_value_no_signal(float(repository.master_volume))
	text_slider.set_value_no_signal(float(repository.text_scale))
	speed_slider.set_value_no_signal(float(repository.dialogue_speed))
	contrast_check.set_pressed_no_signal(bool(repository.high_contrast))
	_refresh_labels()
	visible = true
	fullscreen_check.grab_focus()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not awaiting_action.is_empty() and event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var keycode := int(key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode)
		if repository.set_key_binding(awaiting_action, keycode):
			binding_status.text = "%s 已设为 %s" % [BINDING_LABELS[awaiting_action], repository.key_label(awaiting_action)]
			repository.save()
		else:
			binding_status.text = "该按键已被其他动作使用，请换一个"
		awaiting_action = ""
		_refresh_binding_labels()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()


func _set_fullscreen(enabled: bool) -> void:
	if repository == null:
		return
	repository.fullscreen = enabled
	_save_apply()


func _set_volume(value: float) -> void:
	if repository == null:
		return
	repository.master_volume = clampf(value, 0.0, 1.0)
	_refresh_labels()
	_save_apply()


func _set_text_scale(value: float) -> void:
	if repository == null:
		return
	repository.text_scale = clampf(value, 1.0, 1.5)
	_refresh_labels()
	repository.save()
	accessibility_changed.emit(repository.text_scale, repository.high_contrast)


func _set_high_contrast(enabled: bool) -> void:
	if repository == null:
		return
	repository.high_contrast = enabled
	repository.save()
	accessibility_changed.emit(repository.text_scale, repository.high_contrast)


func _set_dialogue_speed(value: float) -> void:
	if repository == null:
		return
	repository.dialogue_speed = clampf(value, 0.0, 2.0)
	_refresh_labels()
	_save_apply()


func _begin_binding(action: String) -> void:
	awaiting_action = action
	binding_status.text = "请按下“%s”的新按键…" % BINDING_LABELS[action]


func _reset_bindings() -> void:
	repository.reset_key_bindings()
	repository.save()
	awaiting_action = ""
	binding_status.text = "已恢复默认键位"
	_refresh_binding_labels()


func _refresh_binding_labels() -> void:
	for action in binding_buttons.keys():
		(binding_buttons[action] as Button).text = "%s：%s" % [BINDING_LABELS[action], repository.key_label(str(action))]


func _save_apply() -> void:
	repository.save()
	repository.apply()


func _refresh_labels() -> void:
	volume_label.text = "主音量：%d%%" % int(round(float(repository.master_volume) * 100.0))
	text_label.text = "文字大小：%d%%" % int(round(float(repository.text_scale) * 100.0))
	speed_label.text = "对话速度：%s" % ("立即显示" if is_zero_approx(float(repository.dialogue_speed)) else "%.2fx" % (1.0 / float(repository.dialogue_speed)))
	_refresh_binding_labels()


func _close() -> void:
	visible = false
	closed.emit()
