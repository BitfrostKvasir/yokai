class_name BartenderHut
extends Node3D

const INTERACT_RANGE := 2.5

var player: Player
var beer_minigame: BeerMinigame

@onready var prompt_label: Label3D = $PromptLabel

func _ready() -> void:
	add_to_group("bartender_hut")
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	beer_minigame = get_tree().get_first_node_in_group("beer_minigame")
	if prompt_label:
		prompt_label.visible = false

func _process(_delta: float) -> void:
	if not player:
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= INTERACT_RANGE and Input.is_action_just_pressed("interact"):
		if beer_minigame:
			beer_minigame.open()
