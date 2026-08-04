class_name Inventory
extends Node

const PART_IDS = ["wolf_fang", "boar_tusk", "crow_feather", "bear_claw", "bear_pelt"]

var _parts: Dictionary = {}

signal parts_changed(parts: Dictionary)

func _ready() -> void:
	for id in PART_IDS:
		_parts[id] = 0

func add_part(part_id: String, amount: int = 1) -> void:
	if part_id not in _parts:
		_parts[part_id] = 0
	_parts[part_id] += amount
	parts_changed.emit(_parts.duplicate())

func get_count(part_id: String) -> int:
	return _parts.get(part_id, 0)

func has_parts(required: Dictionary) -> bool:
	for part_id in required:
		if get_count(part_id) < required[part_id]:
			return false
	return true

func consume_parts(required: Dictionary) -> void:
	for part_id in required:
		_parts[part_id] -= required[part_id]
	parts_changed.emit(_parts.duplicate())

func all_parts() -> Dictionary:
	return _parts.duplicate()
