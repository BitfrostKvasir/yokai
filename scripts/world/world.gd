# scripts/world/world.gd
extends Node3D

const WOLF_COUNT := 6
const BOAR_COUNT := 3
const RESPAWN_TIME := 30.0

@export var wolf_scene: PackedScene
@export var boar_scene: PackedScene
@export var bear_scene: PackedScene
@export var loot_chest_scene: PackedScene

@onready var wolf_spawns: Node3D = $SpawnPoints/WolfSpawns
@onready var boar_spawns: Node3D = $SpawnPoints/BoarSpawns
@onready var boss_spawn: Marker3D = $SpawnPoints/BossSpawn
@onready var chest_spawn: Marker3D = $SpawnPoints/ChestSpawn
var bear_boss: BearBoss = null

func _ready() -> void:
	_spawn_all_enemies()
	_spawn_boss()

func _spawn_all_enemies() -> void:
	_spawn_enemies(wolf_scene, wolf_spawns, WOLF_COUNT)
	_spawn_enemies(boar_scene, boar_spawns, BOAR_COUNT)

func _spawn_enemies(scene: PackedScene, spawn_parent: Node3D, count: int) -> void:
	if not scene or not spawn_parent:
		return
	var markers := spawn_parent.get_children()
	for i in min(count, markers.size()):
		var enemy := scene.instantiate()
		add_child(enemy)
		enemy.global_position = markers[i].global_position
		enemy.died.connect(_on_enemy_died.bind(scene, markers[i].global_position))

func _on_enemy_died(scene: PackedScene, spawn_pos: Vector3) -> void:
	await get_tree().create_timer(RESPAWN_TIME).timeout
	var enemy := scene.instantiate()
	add_child(enemy)
	enemy.global_position = spawn_pos
	enemy.died.connect(_on_enemy_died.bind(scene, spawn_pos))

func _spawn_boss() -> void:
	if not bear_scene:
		return
	bear_boss = bear_scene.instantiate()
	add_child(bear_boss)
	bear_boss.global_position = boss_spawn.global_position
	bear_boss.bear_killed.connect(_on_bear_killed)
	bear_boss.phase_changed.connect(_on_phase_changed)

func _on_bear_killed() -> void:
	if loot_chest_scene:
		var chest := loot_chest_scene.instantiate()
		add_child(chest)
		chest.global_position = chest_spawn.global_position
		chest.open()
	await get_tree().create_timer(60.0).timeout
	_spawn_boss()

func _on_phase_changed(_new_phase: int) -> void:
	pass
