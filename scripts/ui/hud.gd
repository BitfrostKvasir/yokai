class_name HUD
extends CanvasLayer

@onready var hp_bar: ProgressBar = $TopLeftPanel/TopLeft/HPRow/HPBar
@onready var sp_bar: ProgressBar = $TopLeftPanel/TopLeft/SPRow/SPBar
@onready var weapon_label: Label = $TopLeftPanel/TopLeft/WeaponLabel
@onready var parts_label: Label = $BottomRightPanel/PartsLabel

var player_stats: PlayerStats
var enemy_bars: Dictionary = {}

func _ready() -> void:
	layer = 5
	await get_tree().process_frame
	var p := get_tree().get_first_node_in_group("player") as Player
	if p:
		player_stats = p.stats
		player_stats.hp_changed.connect(_on_hp_changed)
		player_stats.sp_changed.connect(_on_sp_changed)
	GameState.weapon_changed.connect(_on_weapon_changed)
	GameState.inventory.parts_changed.connect(_on_parts_changed)
	_on_weapon_changed(GameState.current_weapon_stats)
	_on_parts_changed(GameState.inventory.all_parts())

func _process(_delta: float) -> void:
	_update_enemy_bars()

func _on_hp_changed(current: int, maximum: int) -> void:
	if hp_bar:
		hp_bar.max_value = maximum
		hp_bar.value = current

func _on_sp_changed(current: float, maximum: float) -> void:
	if sp_bar:
		sp_bar.max_value = maximum
		sp_bar.value = current

func _on_weapon_changed(stats: Dictionary) -> void:
	if weapon_label:
		weapon_label.text = stats.get("name", "Wooden Stick")

func _on_parts_changed(parts: Dictionary) -> void:
	if not parts_label:
		return
	var names := {
		"wolf_fang": "Wolf Fang",
		"boar_tusk": "Boar Tusk",
		"crow_feather": "Crow Feather",
		"bear_claw": "Bear Claw",
		"bear_pelt": "Bear Pelt"
	}
	var lines: Array[String] = []
	for part_id in parts:
		if parts[part_id] > 0:
			lines.append(names.get(part_id, part_id) + ": " + str(parts[part_id]))
	parts_label.text = "\n".join(lines)

func _update_enemy_bars() -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	# Remove bars for dead enemies
	for enemy in enemy_bars.keys():
		if not is_instance_valid(enemy):
			enemy_bars[enemy].queue_free()
			enemy_bars.erase(enemy)
	# Add bars for new live enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy not in enemy_bars:
			_create_enemy_bar(enemy)
	# Update positions
	for enemy in enemy_bars.keys():
		if not is_instance_valid(enemy):
			continue
		var screen_pos := cam.unproject_position(enemy.global_position + Vector3.UP * 2.0)
		enemy_bars[enemy].visible = cam.is_position_in_frustum(enemy.global_position)
		enemy_bars[enemy].position = screen_pos - Vector2(40, 0)

func _create_enemy_bar(enemy: EnemyBase) -> void:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.custom_minimum_size = Vector2(80, 10)
	bar.show_percentage = false
	add_child(bar)
	enemy_bars[enemy] = bar
	enemy.damaged.connect(func(_e: EnemyBase):
		if is_instance_valid(enemy) and is_instance_valid(bar):
			bar.value = float(enemy.current_hp) / float(enemy.max_hp) * 100.0
	)
