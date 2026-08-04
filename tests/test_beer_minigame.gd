extends GutTest

var minigame: BeerMinigame

func before_each() -> void:
	minigame = BeerMinigame.new()

func test_perfect_pour_heals_full() -> void:
	minigame.fill_level = 0.7
	assert_eq(minigame._calculate_heal(), 100)

func test_low_pour_heals_partial_low() -> void:
	minigame.fill_level = 0.3
	assert_eq(minigame._calculate_heal(), 25)

func test_high_pour_heals_partial_high() -> void:
	minigame.fill_level = 0.95
	assert_eq(minigame._calculate_heal(), 50)

func test_golden_zone_lower_edge() -> void:
	minigame.fill_level = 0.6
	assert_eq(minigame._calculate_heal(), 100)

func test_golden_zone_upper_edge() -> void:
	minigame.fill_level = 0.8
	assert_eq(minigame._calculate_heal(), 100)

func test_just_below_golden_zone() -> void:
	minigame.fill_level = 0.59
	assert_eq(minigame._calculate_heal(), 25)

func test_just_above_golden_zone() -> void:
	minigame.fill_level = 0.81
	assert_eq(minigame._calculate_heal(), 50)
