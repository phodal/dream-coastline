extends RefCounted

const FONT_PATH := "res://assets/fonts/moqi/MoqiSymbols.ttf"

const GLYPHS := {
	"name": "\uE001",
	"door": "\uE002",
	"fire": "\uE003",
	"stop": "\uE004",
	"contract": "\uE005",
	"history": "\uE006",
	"star": "\uE007",
	"continue": "\uE008",
	"truth": "\uE009",
	"return": "\uE00A",
	"body": "\uE00B",
	"move": "\uE00C",
	"fast": "\uE00D",
	"water": "\uE00E",
	"book": "\uE00F",
	"light": "\uE010",
	"homecoming": "\uE011",
	"bridge": "\uE012",
	"silence": "\uE013",
	"erase": "\uE014",
	"boundary": "\uE015",
	"repair": "\uE016",
	"protect": "\uE017",
	"state": "\uE018",
	"law": "\uE019",
	"ink": "\uE01A",
}

const LABELS := {
	"name": "名",
	"door": "门",
	"fire": "火",
	"stop": "止",
	"contract": "约",
	"history": "史",
	"star": "星",
	"continue": "续",
	"truth": "真",
	"return": "返",
	"body": "身",
	"move": "行",
	"fast": "疾",
	"water": "水",
	"book": "书",
	"light": "光",
	"homecoming": "归",
	"bridge": "桥",
	"silence": "静",
	"erase": "删",
	"boundary": "界",
	"repair": "修",
	"protect": "护",
	"state": "国",
	"law": "律",
	"ink": "墨",
}


static func glyph(glyph_id: String) -> String:
	return str(GLYPHS.get(glyph_id, ""))


static func label(glyph_id: String) -> String:
	return str(LABELS.get(glyph_id, glyph_id))


static func display_name(glyph_id: String) -> String:
	var translated := label(glyph_id)
	return translated if translated != glyph_id else glyph_id


static func load_font() -> Font:
	if ResourceLoader.exists(FONT_PATH):
		return load(FONT_PATH) as Font
	return null
