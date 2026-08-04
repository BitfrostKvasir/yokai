class_name CraftingMenu
extends CanvasLayer

@onready var recipe_list: VBoxContainer = $Panel/RecipeList
@onready var close_btn: Button = $Panel/CloseButton

func _ready() -> void:
	layer = 9
	visible = false
	add_to_group("crafting_menu")
	if close_btn:
		close_btn.pressed.connect(close)
	GameState.inventory.parts_changed.connect(_refresh)

func open() -> void:
	_refresh(GameState.inventory.all_parts())
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _refresh(_parts: Dictionary) -> void:
	if not recipe_list:
		return
	for child in recipe_list.get_children():
		child.queue_free()
	for weapon_id in GameState.crafting.RECIPES:
		var recipe = GameState.crafting.RECIPES[weapon_id]
		if not recipe["unlocked"]:
			continue
		var btn := Button.new()
		var can := GameState.crafting.can_craft(weapon_id, GameState.inventory)
		btn.text = Crafting.WEAPONS[weapon_id]["name"]
		btn.disabled = not can
		btn.pressed.connect(_on_craft.bind(weapon_id))
		recipe_list.add_child(btn)

func _on_craft(weapon_id: String) -> void:
	var stats = GameState.crafting.craft(weapon_id, GameState.inventory)
	if stats.is_empty():
		return
	GameState.equip_weapon(weapon_id)
	_refresh(GameState.inventory.all_parts())
