class_name CraftingStump
extends Node3D

const INTERACT_RANGE := 2.5

var player: Player
var crafting_menu: CraftingMenu

@onready var prompt_label: Label3D = $PromptLabel

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	crafting_menu = get_tree().get_first_node_in_group("crafting_menu")

func _process(_delta: float) -> void:
	if not player or not prompt_label:
		return
	var dist := global_position.distance_to(player.global_position)
	prompt_label.visible = dist <= INTERACT_RANGE
	if dist <= INTERACT_RANGE and Input.is_action_just_pressed("interact"):
		if crafting_menu:
			crafting_menu.open()
