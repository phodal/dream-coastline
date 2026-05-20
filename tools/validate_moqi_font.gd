extends SceneTree

const MoqiText := preload("res://src/nova/ui/moqi_text.gd")
const FONT_PATH := "res://assets/fonts/moqi/MoqiSymbols.ttf"
const CORE_GLYPHS := [
	"name",
	"door",
	"fire",
	"stop",
	"contract",
	"history",
	"star",
	"continue",
	"truth",
	"return",
	"body",
	"move",
	"fast",
	"water",
	"book",
	"light",
	"homecoming",
	"bridge",
	"silence",
	"erase",
	"boundary",
	"repair",
	"protect",
	"state",
	"law",
	"ink",
]


func _init() -> void:
	if not ResourceLoader.exists(FONT_PATH):
		push_error("Moqi font is not visible to Godot: %s" % FONT_PATH)
		quit(1)
		return
	var font := MoqiText.load_font()
	if font == null or not font is Font:
		push_error("Moqi font failed to load as Font: %s" % FONT_PATH)
		quit(1)
		return
	for glyph_id in CORE_GLYPHS:
		if MoqiText.glyph(glyph_id).is_empty():
			push_error("Moqi glyph mapping is missing: %s" % glyph_id)
			quit(1)
			return
	print("moqi-font-godot status=PASS path=%s" % FONT_PATH)
	quit(0)
