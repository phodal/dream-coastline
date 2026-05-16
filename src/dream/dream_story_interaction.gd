class_name DreamStoryInteraction
extends Interaction

var controller: Node
var interaction_kind := ""
var story_scene_id := ""
var location_id := ""
var target_id := ""
var display_name := ""
var payload: Dictionary = {}


func configure(
		new_controller: Node,
		new_kind: String,
		new_scene_id: String,
		new_location_id: String,
		new_target_id: String,
		new_display_name: String,
		new_payload: Dictionary
) -> void:
	controller = new_controller
	interaction_kind = new_kind
	story_scene_id = new_scene_id
	location_id = new_location_id
	target_id = new_target_id
	display_name = new_display_name
	payload = new_payload


func _execute() -> void:
	if controller != null and controller.has_method("run_story_interaction"):
		await controller.run_story_interaction(self)
