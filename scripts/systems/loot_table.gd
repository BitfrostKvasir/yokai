class_name LootTable
extends RefCounted

var ENEMY_DROPS: Dictionary = {
	"wolf": [{"part": "wolf_fang", "chance": 0.5}],
	"boar": [{"part": "boar_tusk", "chance": 0.5}],
	"crow": [{"part": "crow_feather", "chance": 0.5}],
}

const BOSS_DROPS: Dictionary = {
	"bear": ["bear_claw", "bear_pelt"],
}

func roll_enemy_drops(enemy_type: String) -> Array[String]:
	var drops: Array[String] = []
	var table: Array = ENEMY_DROPS.get(enemy_type, [])
	for entry in table:
		if randf() <= entry["chance"]:
			drops.append(entry["part"])
	return drops

func get_boss_drops(boss_type: String) -> Array[String]:
	return BOSS_DROPS.get(boss_type, [])
