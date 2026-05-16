class_name EquipmentCatalog
extends RefCounted

const CATALOG_PATH := "res://data/equipment_catalog.json"
const CONTRACT_ONLY_STATUS := "contract_only"

var catalog: Dictionary = {}
var slots: Dictionary = {}
var items: Dictionary = {}


func load_catalog(path: String = CATALOG_PATH) -> bool:
	catalog.clear()
	slots.clear()
	items.clear()

	if not FileAccess.file_exists(path):
		push_warning("Equipment catalog does not exist: %s" % path)
		return false

	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Could not parse equipment catalog: %s" % path)
		return false

	catalog = parsed
	slots = _as_dict(catalog.get("slots", {}))
	items = _as_dict(catalog.get("items", {}))

	var failures := validate()
	for failure in failures:
		push_warning("Equipment catalog: %s" % failure)
	return failures.is_empty()


func integration_status() -> String:
	return str(catalog.get("integration_status", ""))


func item_data(item_id: String) -> Dictionary:
	return _as_dict(items.get(item_id, {}))


func slot_for(item_id: String) -> String:
	return str(item_data(item_id).get("slot", ""))


func effects_for(item_id: String) -> Dictionary:
	return _as_dict(item_data(item_id).get("effects", {}))


func items_for_slot(slot_id: String) -> Array[String]:
	var result: Array[String] = []
	for item_id in items.keys():
		var item := item_data(str(item_id))
		if str(item.get("slot", "")) == slot_id:
			result.append(str(item_id))
	result.sort()
	return result


func validate() -> Array[String]:
	var failures: Array[String] = []
	if int(catalog.get("schema_version", 0)) != 1:
		failures.append("schema_version must be 1")
	if integration_status() != CONTRACT_ONLY_STATUS:
		failures.append("integration_status must stay %s until runtime wiring starts" % CONTRACT_ONLY_STATUS)
	if slots.is_empty():
		failures.append("slots must not be empty")
	if items.is_empty():
		failures.append("items must not be empty")

	for slot_id in slots.keys():
		var slot := _as_dict(slots[slot_id])
		if str(slot.get("name", "")).is_empty():
			failures.append("slot %s is missing name" % slot_id)
		if int(slot.get("max_equipped", 0)) <= 0:
			failures.append("slot %s must define positive max_equipped" % slot_id)
		if str(slot.get("equip_mode", "")).is_empty():
			failures.append("slot %s is missing equip_mode" % slot_id)

	for item_id in items.keys():
		_validate_item(str(item_id), item_data(str(item_id)), failures)
	return failures


func _validate_item(item_id: String, item: Dictionary, failures: Array[String]) -> void:
	if item.is_empty():
		failures.append("item %s must be a dictionary" % item_id)
		return

	if str(item.get("name", "")).is_empty():
		failures.append("item %s is missing name" % item_id)
	if str(item.get("scene_id", "")).is_empty():
		failures.append("item %s is missing scene_id" % item_id)

	var slot_id := str(item.get("slot", ""))
	if slot_id.is_empty():
		failures.append("item %s is missing slot" % item_id)
	elif not slots.has(slot_id):
		failures.append("item %s references unknown slot %s" % [item_id, slot_id])

	if str(item.get("kind", "")).is_empty():
		failures.append("item %s is missing kind" % item_id)

	var acquisition := _as_dict(item.get("acquisition", {}))
	var source_flags: Array = acquisition.get("source_flags", [])
	if source_flags.is_empty():
		failures.append("item %s must define acquisition.source_flags" % item_id)

	var effects := _as_dict(item.get("effects", {}))
	if effects.is_empty():
		failures.append("item %s must define effects" % item_id)

	var balance := _as_dict(item.get("balance", {}))
	if balance.is_empty():
		failures.append("item %s must define balance" % item_id)
	if int(balance.get("combat_power", 0)) > 2:
		failures.append("item %s combat_power is too high for the current contract" % item_id)


func _as_dict(value) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}
