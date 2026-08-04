extends Node3D

const BATTLE_TIME := 60.0

@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var enemy_spawn: Marker3D = $EnemySpawn

var player: Player = null
var enemy: EnemyBase = null
var time_left: float = BATTLE_TIME
var battle_over: bool = false

var _enemy_hp_bar: ProgressBar
var _player_hp_bar: ProgressBar
var _player_sp_bar: ProgressBar
var _timer_label: Label
var _result_panel: PanelContainer
var _result_label: Label
var _fade_rect: ColorRect

func _ready() -> void:
	GameState.in_battle = true
	_build_hud()
	_spawn_combatants()
	_fade_in()

func _build_hud() -> void:
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade_rect)

	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)

	# Enemy name – top center
	var enemy_name := Label.new()
	enemy_name.anchor_left = 0.25
	enemy_name.anchor_right = 0.75
	enemy_name.anchor_top = 0.0
	enemy_name.anchor_bottom = 0.0
	enemy_name.offset_top = 8
	enemy_name.offset_bottom = 40
	enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_name.add_theme_font_size_override("font_size", 26)
	enemy_name.add_theme_color_override("font_color", Color(1, 1, 1))
	enemy_name.text = GameState.pending_battle_enemy_type.capitalize()
	hud.add_child(enemy_name)

	# Enemy HP bar – below name, top center
	_enemy_hp_bar = ProgressBar.new()
	_enemy_hp_bar.anchor_left = 0.25
	_enemy_hp_bar.anchor_right = 0.75
	_enemy_hp_bar.anchor_top = 0.0
	_enemy_hp_bar.anchor_bottom = 0.0
	_enemy_hp_bar.offset_top = 42
	_enemy_hp_bar.offset_bottom = 66
	_enemy_hp_bar.show_percentage = false
	_enemy_hp_bar.modulate = Color(0.2, 0.9, 0.2)
	hud.add_child(_enemy_hp_bar)

	# Player HP label – top left
	var hp_label := Label.new()
	hp_label.anchor_left = 0.0
	hp_label.anchor_right = 0.0
	hp_label.anchor_top = 0.0
	hp_label.offset_left = 12
	hp_label.offset_right = 52
	hp_label.offset_top = 10
	hp_label.offset_bottom = 30
	hp_label.text = "HP"
	hp_label.add_theme_font_size_override("font_size", 16)
	hp_label.add_theme_color_override("font_color", Color(1, 0.55, 0.55))
	hud.add_child(hp_label)

	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.anchor_left = 0.0
	_player_hp_bar.anchor_right = 0.0
	_player_hp_bar.anchor_top = 0.0
	_player_hp_bar.offset_left = 12
	_player_hp_bar.offset_right = 210
	_player_hp_bar.offset_top = 31
	_player_hp_bar.offset_bottom = 53
	_player_hp_bar.show_percentage = false
	_player_hp_bar.modulate = Color(0.9, 0.2, 0.2)
	hud.add_child(_player_hp_bar)

	# SP label
	var sp_label := Label.new()
	sp_label.anchor_left = 0.0
	sp_label.anchor_right = 0.0
	sp_label.anchor_top = 0.0
	sp_label.offset_left = 12
	sp_label.offset_right = 52
	sp_label.offset_top = 55
	sp_label.offset_bottom = 74
	sp_label.text = "SP"
	sp_label.add_theme_font_size_override("font_size", 14)
	sp_label.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	hud.add_child(sp_label)

	_player_sp_bar = ProgressBar.new()
	_player_sp_bar.anchor_left = 0.0
	_player_sp_bar.anchor_right = 0.0
	_player_sp_bar.anchor_top = 0.0
	_player_sp_bar.offset_left = 12
	_player_sp_bar.offset_right = 210
	_player_sp_bar.offset_top = 55
	_player_sp_bar.offset_bottom = 73
	_player_sp_bar.show_percentage = false
	_player_sp_bar.modulate = Color(0.3, 0.6, 1.0)
	hud.add_child(_player_sp_bar)

	# Timer – top right
	_timer_label = Label.new()
	_timer_label.anchor_left = 1.0
	_timer_label.anchor_right = 1.0
	_timer_label.anchor_top = 0.0
	_timer_label.offset_left = -110
	_timer_label.offset_right = -12
	_timer_label.offset_top = 8
	_timer_label.offset_bottom = 58
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_label.add_theme_font_size_override("font_size", 38)
	_timer_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_timer_label.text = str(int(BATTLE_TIME))
	hud.add_child(_timer_label)

	# Result panel – center screen, hidden
	_result_panel = PanelContainer.new()
	_result_panel.anchor_left = 0.5
	_result_panel.anchor_right = 0.5
	_result_panel.anchor_top = 0.5
	_result_panel.anchor_bottom = 0.5
	_result_panel.offset_left = -220
	_result_panel.offset_right = 220
	_result_panel.offset_top = -65
	_result_panel.offset_bottom = 65
	_result_panel.visible = false
	hud.add_child(_result_panel)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 54)
	_result_panel.add_child(_result_label)

func _spawn_combatants() -> void:
	var p_scene := load("res://scenes/player/player.tscn") as PackedScene
	player = p_scene.instantiate()
	add_child(player)
	player.global_position = player_spawn.global_position
	if GameState.player_hp_saved > 0:
		player.stats.current_hp = GameState.player_hp_saved
		player.stats.sp = GameState.player_sp_saved
	player.stats.died.connect(_on_player_died)
	_player_hp_bar.max_value = player.stats.max_hp
	_player_sp_bar.max_value = player.stats.max_sp
	_player_hp_bar.value = player.stats.current_hp
	_player_sp_bar.value = player.stats.sp

	if GameState.pending_battle_enemy_scene.is_empty():
		return
	var e_scene := load(GameState.pending_battle_enemy_scene) as PackedScene
	if not e_scene:
		return
	enemy = e_scene.instantiate()
	add_child(enemy)
	enemy.global_position = enemy_spawn.global_position
	enemy._battle_emitted = true
	enemy.enter_battle_mode()
	enemy.died.connect(_on_enemy_died)
	_enemy_hp_bar.max_value = enemy.max_hp
	_enemy_hp_bar.value = enemy.max_hp

func _process(delta: float) -> void:
	if battle_over:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_end_battle(false)
		return
	_update_hud()

func _update_hud() -> void:
	_timer_label.text = str(int(ceil(time_left)))
	if player and is_instance_valid(player):
		_player_hp_bar.value = player.stats.current_hp
		_player_sp_bar.value = player.stats.sp
	if enemy and is_instance_valid(enemy):
		_enemy_hp_bar.value = enemy.current_hp

func _on_enemy_died(_e: EnemyBase) -> void:
	_end_battle(true)

func _on_player_died() -> void:
	_end_battle(false)

func _end_battle(won: bool) -> void:
	if battle_over:
		return
	battle_over = true
	GameState.in_battle = false
	GameState.returning_from_battle = true
	if won:
		_result_label.text = "VICTORY!"
		_result_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))
		if player and is_instance_valid(player):
			GameState.player_hp_saved = player.stats.current_hp
			GameState.player_sp_saved = player.stats.sp
	else:
		_result_label.text = "DEFEATED"
		_result_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		if player and is_instance_valid(player):
			GameState.player_hp_saved = player.stats.max_hp
		GameState.player_sp_saved = 0.0
	_result_panel.visible = true
	await get_tree().create_timer(2.5).timeout
	_fade_out_and_return()

func _fade_in() -> void:
	_fade_rect.color = Color(0, 0, 0, 1)
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, 0.6)

func _fade_out_and_return() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, 0.6)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")
