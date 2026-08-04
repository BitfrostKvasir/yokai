class_name Crafting
extends Node

const WEAPONS: Dictionary = {
	"wooden_stick":    {"name": "Wooden Stick",    "attack": 10, "defense": 5,  "speed": 5.0},
	"bone_club":       {"name": "Bone Club",       "attack": 18, "defense": 5,  "speed": 5.0},
	"tusk_blade":      {"name": "Tusk Blade",      "attack": 22, "defense": 5,  "speed": 6.0},
	"bear_claw_hammer":{"name": "Bear Claw Hammer","attack": 38, "defense": 15, "speed": 4.0},
	"feather_blade":   {"name": "Feather Blade",   "attack": 18, "defense": 3,  "speed": 8.0},
}

var RECIPES: Dictionary = {
	"bone_club":         {"requires": {"wolf_fang": 3},                   "unlocked": true},
	"tusk_blade":        {"requires": {"boar_tusk": 3, "wolf_fang": 1},   "unlocked": true},
	"bear_claw_hammer":  {"requires": {"bear_claw": 2, "bear_pelt": 1},   "unlocked": false},
	"feather_blade":     {"requires": {"crow_feather": 5, "boar_tusk": 1},"unlocked": true},
}

func unlock_bear_recipes() -> void:
	RECIPES["bear_claw_hammer"]["unlocked"] = true

func can_craft(weapon_id: String, inventory: Inventory) -> bool:
	var recipe: Dictionary = RECIPES.get(weapon_id, {})
	if recipe.is_empty():
		return false
	if not recipe["unlocked"]:
		return false
	return inventory.has_parts(recipe["requires"])

func craft(weapon_id: String, inventory: Inventory) -> Dictionary:
	if not can_craft(weapon_id, inventory):
		return {}
	var recipe: Dictionary = RECIPES[weapon_id]
	inventory.consume_parts(recipe["requires"])
	return WEAPONS[weapon_id].duplicate()

func get_unlocked_recipes() -> Array[String]:
	var result: Array[String] = []
	for weapon_id in RECIPES:
		if RECIPES[weapon_id]["unlocked"]:
			result.append(weapon_id)
	return result
