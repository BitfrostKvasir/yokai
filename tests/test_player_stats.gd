extends GutTest

var stats: PlayerStats

func before_each() -> void:
	stats = PlayerStats.new()

func test_initial_hp_is_full() -> void:
	assert_eq(stats.current_hp, stats.max_hp)

func test_take_damage_reduces_hp() -> void:
	stats.defense = 5
	stats.take_damage(15)
	assert_eq(stats.current_hp, 90)

func test_defense_absorbs_minimum_one() -> void:
	stats.defense = 100
	stats.take_damage(5)
	assert_eq(stats.current_hp, 99)

func test_hp_cannot_go_below_zero() -> void:
	stats.take_damage(99999)
	assert_eq(stats.current_hp, 0)

func test_heal_restores_hp() -> void:
	stats.take_damage(50)
	stats.heal(30)
	assert_eq(stats.current_hp, 80)

func test_heal_cannot_exceed_max_hp() -> void:
	stats.heal(99999)
	assert_eq(stats.current_hp, stats.max_hp)

func test_gain_sp_fills_gauge() -> void:
	stats.gain_sp(10.0)
	assert_eq(stats.sp, 10.0)

func test_sp_cannot_exceed_max() -> void:
	stats.gain_sp(99999.0)
	assert_eq(stats.sp, stats.max_sp)

func test_use_sp_empties_gauge() -> void:
	stats.sp = stats.max_sp
	var result = stats.use_sp()
	assert_true(result)
	assert_eq(stats.sp, 0.0)

func test_use_sp_fails_when_not_full() -> void:
	stats.sp = 50.0
	var result = stats.use_sp()
	assert_false(result)
	assert_eq(stats.sp, 50.0)

func test_is_dead_when_hp_zero() -> void:
	stats.take_damage(99999)
	assert_true(stats.is_dead())
