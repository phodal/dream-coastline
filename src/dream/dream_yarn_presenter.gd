class_name DreamYarnPresenter
extends YarnDialoguePresenter

var dialogue_layer: DreamDialogueLayer
var auto_advance := false
var lines: Array[Dictionary] = []
var selected_options: Array[int] = []


func configure(new_dialogue_layer: DreamDialogueLayer, should_auto_advance: bool = false) -> void:
	dialogue_layer = new_dialogue_layer
	auto_advance = should_auto_advance


func run_line(line: YarnLine) -> Variant:
	var title := line.character_name
	if title.is_empty():
		title = "Yarn"
	var text := line.get_plain_text()
	lines.append({
		"title": title,
		"text": text,
		"line_id": line.line_id,
	})
	if auto_advance or dialogue_layer == null:
		return null
	await dialogue_layer.show_message(title, text)
	return null


func run_options(options: Array[YarnOption]) -> int:
	if options.is_empty():
		return -1
	selected_options.append(0)
	return 0
