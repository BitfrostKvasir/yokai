extends GutTest

var crafting: Crafting
var inv: Inventory

func before_each() -> void:
	crafting = Crafting.new()
	inv = Inventory.new()
	inv._ready()

func test_wooden_stick_is_default_weapon() -> void:
	var stats = Crafting.WEAPONS["wooden_stick"]
	assert_eq(stats["attack"], 10)

func test_can_craft_bone_club_with_parts() -> void:
	inv.add_part("wolf_fang", 3)
	assert_true(crafting.can_craft("bone_club", inv))

func test_cannot_craft_bone_club_without_parts() -> void:
	inv.add_part("wolf_fang", 2)
	assert_false(crafting.can_craft("bone_club", inv))

func test_craft_consumes_parts() -> void:
	inv.add_part("wolf_fang", 3)
	crafting.craft("bone_club", inv)
	assert_eq(inv.get_count("wolf_fang"), 0)

func test_craft_returns_weapon_stats() -> void:
	inv.add_part("wolf_fang", 3)
	var stats = crafting.craft("bone_club", inv)
	assert_eq(stats["attack"], 18)

func test_bear_claw_hammer_locked_by_default() -> void:
	inv.add_part("bear_claw", 2)
	inv.add_part("bear_pelt", 1)
	assert_false(crafting.can_craft("bear_claw_hammer", inv))

func test_bear_claw_hammer_unlocks_after_bear_kill() -> void:
	crafting.unlock_bear_recipes()
	inv.add_part("bear_claw", 2)
	inv.add_part("bear_pelt", 1)
	assert_true(crafting.can_craft("bear_claw_hammer", inv))

func test_craft_fails_gracefully_without_parts() -> void:
	var stats = crafting.craft("bone_club", inv)
	assert_eq(stats, {})
