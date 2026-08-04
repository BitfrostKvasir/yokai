extends Node

var inventory: Inventory
var crafting: Crafting
var loot_table: LootTable
var current_weapon_id: String = "wooden_stick"
var current_weapon_stats: Dictionary = {}
var bear_defeated: bool = false

# Battle arena state
var in_battle: bool = false
var returning_from_battle: bool = false
var pending_battle_enemy_scene: String = ""
var pending_battle_enemy_type: String = ""
var world_player_position: Vector3 = Vector3.ZERO
var player_hp_saved: int = 0
var player_sp_saved: float = 0.0

signal weapon_changed(weapon_stats: Dictionary)

func _ready() -> void:
	inventory = Inventory.new()
	add_child(inventory)
	crafting = Crafting.new()
	add_child(crafting)
	loot_table = LootTable.new()
	current_weapon_stats = Crafting.WEAPONS["wooden_stick"].duplicate()

func equip_weapon(weapon_id: String) -> void:
	if weapon_id not in Crafting.WEAPONS:
		return
	current_weapon_id = weapon_id
	current_weapon_stats = Crafting.WEAPONS[weapon_id].duplicate()
	weapon_changed.emit(current_weapon_stats)

func on_bear_defeated() -> void:
	bear_defeated = true
	crafting.unlock_bear_recipes()

func collect_loot(enemy_type: String) -> void:
	var drops: Array[String]
	if enemy_type == "bear":
		drops = loot_table.get_boss_drops("bear")
	else:
		drops = loot_table.roll_enemy_drops(enemy_type)
	for part in drops:
		inventory.add_part(part)
