extends Control

signal title_requested
signal restart_requested

var title_label: Label
var summary_label: Label
var restart_button: Button
var title_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.035, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 480)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	panel.add_child(content)

	title_label = Label.new()
	title_label.text = "灯，再次亮起"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	content.add_child(title_label)

	var epilogue := Label.new()
	epilogue.text = "世界没有被一句话拯救。它因为有人继续记录、命名、质疑和建设，终于没有再次被抹去。"
	epilogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	epilogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	epilogue.add_theme_font_size_override("font_size", 20)
	content.add_child(epilogue)

	summary_label = Label.new()
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.add_theme_font_size_override("font_size", 18)
	content.add_child(summary_label)

	var credits := Label.new()
	credits.text = "《梦境海岸线》\n叙事、程序与美术：Dream Coastline Project\n感谢每一位让这个世界被看见的人"
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
	content.add_child(credits)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	content.add_child(actions)

	restart_button = Button.new()
	restart_button.text = "重新开始"
	restart_button.custom_minimum_size = Vector2(180, 52)
	restart_button.pressed.connect(func(): restart_requested.emit())
	actions.add_child(restart_button)

	title_button = Button.new()
	title_button.text = "返回标题"
	title_button.custom_minimum_size = Vector2(180, 52)
	title_button.pressed.connect(func(): title_requested.emit())
	actions.add_child(title_button)


func open(summary: Dictionary) -> void:
	var metrics: Dictionary = summary.get("metrics", {})
	var route_flags: Dictionary = summary.get("route_flags", {})
	var route_name := _route_name(route_flags)
	summary_label.text = "你的延续路线：%s\n识字 %d · 信任 %d · 建设 %d · 求知 %d" % [
		route_name,
		int(metrics.get("literacy", 0)),
		int(metrics.get("trust", 0)),
		int(metrics.get("construction", 0)),
		int(metrics.get("curiosity", 0)),
	]
	show()
	restart_button.grab_focus()


func close() -> void:
	hide()


func _route_name(flags: Dictionary) -> String:
	if bool(flags.get("chose_engineer_route", false)):
		return "工程师共同体"
	if bool(flags.get("chose_parent_route", false)):
		return "家书与记忆"
	if bool(flags.get("chose_royal_route", false)):
		return "王室档案"
	if bool(flags.get("chose_public_route", false)):
		return "公共知识"
	return "未命名的路"
