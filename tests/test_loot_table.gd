extends GutTest

var loot: LootTable

func before_each() -> void:
	loot = LootTable.new()

func test_boss_drops_always_include_bear_claw() -> void:
	var drops = loot.get_boss_drops("bear")
	assert_true("bear_claw" in drops)

func test_boss_drops_always_include_bear_pelt() -> void:
	var drops = loot.get_boss_drops("bear")
	assert_true("bear_pelt" in drops)

func test_unknown_enemy_drops_empty() -> void:
	var drops = loot.roll_enemy_drops("dragon")
	assert_eq(drops.size(), 0)

func test_wolf_drops_wolf_fang_at_100_percent() -> void:
	loot.ENEMY_DROPS["wolf"][0]["chance"] = 1.0
	var drops = loot.roll_enemy_drops("wolf")
	assert_true("wolf_fang" in drops)

func test_wolf_drops_nothing_at_0_percent() -> void:
	loot.ENEMY_DROPS["wolf"][0]["chance"] = 0.0
	var drops = loot.roll_enemy_drops("wolf")
	assert_eq(drops.size(), 0)
