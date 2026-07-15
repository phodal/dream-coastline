@tool
extends SceneTree

const CHARACTER_SCRIPT := preload("res://addons/dialogic/Resources/character.gd")
const DEFAULT_PORTRAIT_SCENE := "res://addons/dialogic/Modules/Character/default_portrait.tscn"

const CHARACTERS := {
	"jizi_xuan": {
		"display_name": "纪子轩",
		"nicknames": ["jizi_xuan", "jizixuan"],
		"color": Color(0.92, 0.78, 0.46, 1),
		"description": "Dream Coastline protagonist before finding the black pen.",
		"default_portrait": "phone",
		"portraits": {
			"phone": {
				"image": "res://assets/characters/main/jizi_xuan/portrait_xianjian_phone.png",
				"offset": Vector2(0, 0),
				"scene": DEFAULT_PORTRAIT_SCENE,
			},
		},
		"custom_info": {"style": "xianjian_phone"},
	},
	"xiali": {
		"display_name": "夏离",
		"nicknames": ["xiali"],
		"color": Color(0.58, 0.72, 1.0, 1),
		"description": "Moqi royal survivor carrying the cost of literacy reform.",
		"default_portrait": "default",
		"portraits": {
			"default": {
				"image": "res://assets/characters/main/xiali/portrait.png",
				"offset": Vector2(0, 0),
				"scene": DEFAULT_PORTRAIT_SCENE,
			},
		},
	},
	"wensu": {
		"display_name": "闻素",
		"nicknames": ["wensu"],
		"color": Color(0.72, 0.9, 0.66, 1),
		"description": "Teacher figure for open literacy and public dictionary work.",
		"default_portrait": "default",
		"portraits": {
			"default": {
				"image": "res://assets/characters/main/wensu/model_sheet.png",
				"offset": Vector2(0, 0),
				"scene": DEFAULT_PORTRAIT_SCENE,
			},
		},
	},
	"atang": {
		"display_name": "阿棠",
		"nicknames": ["atang"],
		"color": Color(0.95, 0.62, 0.42, 1),
		"description": "Workshop-aligned builder who translates text systems into tools.",
		"default_portrait": "default",
		"portraits": {
			"default": {
				"image": "res://assets/characters/main/atang/model_sheet.png",
				"offset": Vector2(0, 0),
				"scene": DEFAULT_PORTRAIT_SCENE,
			},
		},
	},
	"xiaoyan": {
		"display_name": "小砚",
		"nicknames": ["xiaoyan"],
		"color": Color(0.86, 0.78, 0.62, 1),
		"description": "Border-camp child who reveals the human cost of name loss.",
		"default_portrait": "default",
		"portraits": {
			"default": {
				"image": "res://assets/characters/main/xiaoyan/portrait.png",
				"offset": Vector2(0, 0),
				"scene": DEFAULT_PORTRAIT_SCENE,
			},
		},
	},
}


func _init() -> void:
	for character_id in CHARACTERS.keys():
		var data: Dictionary = CHARACTERS[character_id]
		var character = CHARACTER_SCRIPT.new()
		character.display_name = str(data.get("display_name", character_id))
		character.nicknames = data.get("nicknames", [])
		character.color = data.get("color", Color.WHITE)
		character.description = str(data.get("description", ""))
		character.scale = 1.0
		character.offset = Vector2.ZERO
		character.mirror = false
		character.default_portrait = str(data.get("default_portrait", ""))
		character.portraits = data.get("portraits", {})
		character.custom_info = data.get("custom_info", {})
		var path := "res://dialogic/characters/%s.dch" % character_id
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_error("Failed to save %s: %s" % [path, FileAccess.get_open_error()])
			quit(1)
			return
		file.store_string(var_to_str(inst_to_dict(character)))
		print("dialogic-character generated %s" % path)
	quit(0)
