extends GutTest

var inv: Inventory

func before_each() -> void:
	inv = Inventory.new()
	inv._ready()

func test_starts_empty() -> void:
	assert_eq(inv.get_count("wolf_fang"), 0)

func test_add_part_increases_count() -> void:
	inv.add_part("wolf_fang", 2)
	assert_eq(inv.get_count("wolf_fang"), 2)

func test_has_parts_true_when_sufficient() -> void:
	inv.add_part("wolf_fang", 3)
	assert_true(inv.has_parts({"wolf_fang": 3}))

func test_has_parts_false_when_insufficient() -> void:
	inv.add_part("wolf_fang", 2)
	assert_false(inv.has_parts({"wolf_fang": 3}))

func test_consume_parts_reduces_counts() -> void:
	inv.add_part("wolf_fang", 5)
	inv.consume_parts({"wolf_fang": 3})
	assert_eq(inv.get_count("wolf_fang"), 2)

func test_all_parts_returns_dict() -> void:
	inv.add_part("wolf_fang", 1)
	inv.add_part("boar_tusk", 2)
	var all = inv.all_parts()
	assert_eq(all["wolf_fang"], 1)
	assert_eq(all["boar_tusk"], 2)
